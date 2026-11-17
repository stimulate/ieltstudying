#requires -Version 5.1
#requires -RunAsAdministrator
<#
Windows 365 CPC C: / WinRE repair.
Default: Diagnose only. No disk changes.
Apply only after reviewing the Diagnose log:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CPC_WinRE_Repair.ps1 -Mode Apply

Log: C:\ProgramData\CPC-WinRE-Repair\CPC-WinRE-Repair.log
Run as SYSTEM (Intune: logged-on credentials = No; 64-bit PowerShell = Yes).
No reboot is initiated.
#>
[CmdletBinding()]
param([ValidateSet('Diagnose','Apply')][string]$Mode='Apply')

$ErrorActionPreference='Stop'
$LogDir='C:\ProgramData\CPC-WinRE-Repair'
$LogPath=Join-Path $LogDir 'CPC-WinRE-Repair.log'
$BackupDir='C:\WinRE_Backup'
$BackupPath=Join-Path $BackupDir 'winre.wim'
$WinRESource='C:\Windows\System32\Recovery\winre.wim'
$RecoverySizeMB=2048
$RecoveryGuid='de94bba4-06d1-4d40-a16a-bfd50179d6ac'
$RecoveryAttributes='0x8000000000000001'
New-Item -Path $LogDir -ItemType Directory -Force | Out-Null

function Log([string]$Message,[string]$Level='INFO') {
    $line='{0} [{1}] [{2}] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Level,$env:COMPUTERNAME,$Message
    Add-Content -LiteralPath $LogPath -Value $line
    Write-Output $line
}
function Stop-Run([string]$Message) { Log $Message 'ERROR'; throw $Message }
function Get-Info {
    $o=& reagentc.exe /info 2>&1; $ec=$LASTEXITCODE
    foreach($x in $o){Log "REAGENTC: $x"}
    if($ec -ne 0){Stop-Run "reagentc /info failed; exit=$ec"}
    return ($o | Out-String)
}
function Is-Enabled([string]$Info) {
    return ($Info -match '(?im)Windows RE status\s*:\s*Enabled|Windows RE status\s*:\s*有効|Windows RE の状態\s*:\s*有効')
}
function Get-RegisteredPartition([string]$Info,[int]$DiskNo) {
    # Match one literal backslash before "partition"; reagentc path contains \partitionN\
    $pattern='(?i)harddisk'+$DiskNo+'\\partition(\d+)\\'
    $m=[regex]::Match($Info,$pattern)
    if($m.Success){return [int]$m.Groups[1].Value}
    return $null
}
function Run-DiskPart([string]$Step,[string]$Commands) {
    Log "DISKPART START: $Step"
    $o=$Commands | & "$env:SystemRoot\System32\diskpart.exe" 2>&1
    $ec=$LASTEXITCODE
    foreach($x in $o){Log "DISKPART: $x"}
    $s=$o | Out-String
    if($ec -ne 0 -or $s -match '(?i)Virtual Disk Service error|DiskPart has encountered an error|エラー|失敗|引数が不正') {
        Stop-Run "DiskPart failed: $Step; exit=$ec"
    }
    Log "DISKPART OK: $Step"
}

try {
    Log "========== START Mode=$Mode =========="
    $wi=[Security.Principal.WindowsIdentity]::GetCurrent()
    $wp=[Security.Principal.WindowsPrincipal]::new($wi)
    if(-not $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){Stop-Run 'Not elevated. Run as SYSTEM / admin.'}

    $os=Get-Partition -DriveLetter C
    $disk=Get-Disk -Number $os.DiskNumber
    if($disk.PartitionStyle -ne 'GPT'){Stop-Run "OS disk $($disk.Number) is not GPT."}
    $parts=@(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
    $info=Get-Info
    $enabled=Is-Enabled $info
    $registered=Get-RegisteredPartition $info $disk.Number
    $afterC=@($parts | Where-Object {$_.Type -eq 'Recovery' -and $_.Offset -gt $os.Offset})
    $large=@($afterC | Where-Object {$_.Size -ge 2GB})
    Log ("Disk={0}; DiskGiB={1:N2}; CSizeGiB={2:N2}; CFreeGiB={3:N2}; WinREEnabled={4}; RegisteredPartition={5}" -f $disk.Number,($disk.Size/1GB),($os.Size/1GB),((Get-Volume -DriveLetter C).SizeRemaining/1GB),$enabled,$registered)
    foreach($p in $parts){Log ("PARTITION Number={0}; Type={1}; Letter={2}; SizeMiB={3:N1}; OffsetMiB={4:N1}" -f $p.PartitionNumber,$p.Type,$p.DriveLetter,($p.Size/1MB),($p.Offset/1MB))}

    if($Mode -eq 'Diagnose'){
        if($large.Count -eq 1 -and $enabled){Log 'RESULT=ALREADY_REPAIRED'}
        elseif($afterC.Count -eq 1 -and $registered -eq $afterC[0].PartitionNumber){Log 'RESULT=ORIGINAL_LAYOUT_OR_PARTIAL; candidate old WinRE partition identified'}
        else{Log 'RESULT=REVIEW_REQUIRED; layout is not safely identifiable' 'WARN'}
        Log '========== END DIAGNOSE =========='
        exit 0
    }

    if($large.Count -gt 1){Stop-Run 'Multiple >=2 GiB Recovery partitions after C:. Refusing changes.'}
    $target=$null
    if($large.Count -eq 1){
        $target=$large[0]
        Log "Using existing 2 GiB Recovery partition $($target.PartitionNumber) to finish WinRE."
        if($target.PartitionNumber -ne $parts[-1].PartitionNumber){
            Stop-Run 'Existing 2 GiB Recovery partition is not the last partition. Refusing automatic changes.'
        }
        if($target.GptType -and $target.GptType.Trim('{}').ToLowerInvariant() -ne $RecoveryGuid){
            Stop-Run "Existing large Recovery partition has unexpected GPT type $($target.GptType)."
        }
    } else {
        if($afterC.Count -ne 1){Stop-Run "Expected exactly one Recovery partition after C:, found $($afterC.Count)."}
        $old=$afterC[0]
        if($old.PartitionNumber -ne $parts[-1].PartitionNumber){Stop-Run 'Candidate Recovery partition is not the last partition.'}
        if($registered -ne $old.PartitionNumber){Stop-Run "reagentc does not point to candidate partition $($old.PartitionNumber)."}
        if($old.DriveLetter){Stop-Run 'Candidate Recovery partition has a drive letter.'}

        $src=Get-Item -LiteralPath $WinRESource -Force -ErrorAction SilentlyContinue
        if(-not $src -or $src.PSIsContainer){Stop-Run "Cannot find hidden/system WinRE image $WinRESource"}
        New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
        if(-not (Test-Path -LiteralPath $BackupPath)){Copy-Item -LiteralPath $WinRESource -Destination $BackupPath -Force}
        $h1=(Get-FileHash -LiteralPath $WinRESource -Algorithm SHA256).Hash
        $h2=(Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash
        if($h1 -ne $h2){Stop-Run 'WinRE backup SHA256 mismatch; old partition not deleted.'}
        Log "Backup verified SHA256=$h2"

        if($enabled){
            $o=& reagentc.exe /disable 2>&1
            foreach($x in $o){Log "REAGENTC: $x"}
            if($LASTEXITCODE -ne 0){Stop-Run "reagentc /disable failed; exit=$LASTEXITCODE"}
        }

        $offsetBytes=[int64]$disk.Size-[int64](3GB)
        $offsetKB=[int64][math]::Floor($offsetBytes/1KB)
        if($offsetBytes -le ($os.Offset+$os.Size)){Stop-Run 'Insufficient space for new Recovery partition.'}

        Run-DiskPart 'Delete old WinRE partition' @"
select disk $($disk.Number)
select partition $($old.PartitionNumber)
delete partition override
exit
"@
        Run-DiskPart 'Create new 2 GiB Recovery partition' @"
select disk $($disk.Number)
create partition primary size=$RecoverySizeMB offset=$offsetKB
set id=$RecoveryGuid
gpt attributes=$RecoveryAttributes
format quick fs=ntfs label="Windows RE tools"
exit
"@
        $parts2=@(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
        $candidates=@($parts2 | Where-Object {$_.Type -eq 'Recovery' -and $_.Size -ge 2GB -and $_.Offset -gt $os.Offset})
        if($candidates.Count -ne 1){Stop-Run "Expected one new 2 GiB Recovery partition; found $($candidates.Count)."}
        $target=$candidates[0]

    }

    # Retry-safe C: expansion. This runs whether the 2 GiB Recovery partition
    # was created in this run or already existed from an earlier partial run.
    $currentC=Get-Partition -DriveLetter C
    $target=Get-Partition -DiskNumber $disk.Number -PartitionNumber $target.PartitionNumber
    $currentParts=@(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
    $cEnd=[int64]$currentC.Offset+[int64]$currentC.Size
    if($target.Offset -le $cEnd){
        Log 'C: already reaches the Recovery partition boundary; no expansion needed.'
    } else {
        $between=@($currentParts | Where-Object {
            $_.PartitionNumber -ne $currentC.PartitionNumber -and
            $_.PartitionNumber -ne $target.PartitionNumber -and
            $_.Offset -ge $cEnd -and $_.Offset -lt $target.Offset
        })
        if($between.Count -gt 0){
            Stop-Run 'A partition exists between C: and the target Recovery partition. Refusing to resize C:.'
        }
        $supported=Get-PartitionSupportedSize -DriveLetter C
        if($supported.SizeMax -le $currentC.Size){
            Log 'No additional contiguous unallocated space is available after C:.' 'WARN'
        } else {
            $maxBeforeRecovery=[int64]$target.Offset-[int64]$currentC.Offset
            if([int64]$supported.SizeMax -gt $maxBeforeRecovery){
                Stop-Run 'Supported C: maximum extends beyond the target Recovery partition boundary.'
            }
            Log ("Resize C: target maximum {0:N2} GiB" -f ($supported.SizeMax/1GB))
            Resize-Partition -DriveLetter C -Size $supported.SizeMax
            $currentC=Get-Partition -DriveLetter C
            Log ("C: resize complete; new size {0:N2} GiB" -f ($currentC.Size/1GB))
        }
    }

    # Mount recovery partition temporarily, copy and validate image.
    $target=Get-Partition -DiskNumber $disk.Number -PartitionNumber $target.PartitionNumber
    $used=@((Get-Volume | Where-Object DriveLetter | ForEach-Object {$_.DriveLetter.ToString().ToUpperInvariant()}))
    if($target.DriveLetter){
        $letter=$target.DriveLetter.ToString().ToUpperInvariant()
        if($letter -notin @('R','S','T','U','V','W','X','Y','Z')){
            Stop-Run "Target Recovery partition already has unexpected drive letter $letter`:. Refusing to remove it."
        }
        Log "Reusing existing temporary drive letter $letter`: on Recovery partition."
    } else {
        $letter=@('R','S','T','U','V','W','X','Y','Z') | Where-Object {$used -notcontains $_} | Select-Object -First 1
        if(-not $letter){Stop-Run 'No free temporary drive letter R: to Z:.'}
        Set-Partition -DiskNumber $disk.Number -PartitionNumber $target.PartitionNumber -NewDriveLetter $letter
    }
    $root="${letter}:\Recovery\WindowsRE"
    New-Item -Path $root -ItemType Directory -Force | Out-Null
    if(-not (Test-Path -LiteralPath $BackupPath)){
        $src=Get-Item -LiteralPath $WinRESource -Force -ErrorAction SilentlyContinue
        if(-not $src){Stop-Run 'Neither WinRE backup nor source image exists.'}
        New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
        Copy-Item -LiteralPath $WinRESource -Destination $BackupPath -Force
    }
    Copy-Item -LiteralPath $BackupPath -Destination (Join-Path $root 'winre.wim') -Force
    $bh=(Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash
    $ch=(Get-FileHash -LiteralPath (Join-Path $root 'winre.wim') -Algorithm SHA256).Hash
    if($bh -ne $ch){Stop-Run 'Copied WinRE image SHA256 mismatch; temporary drive letter retained.'}

    $o=& reagentc.exe /setreimage /path $root /target C:\Windows 2>&1
    foreach($x in $o){Log "REAGENTC: $x"}
    if($LASTEXITCODE -ne 0){Stop-Run "reagentc /setreimage failed; exit=$LASTEXITCODE; temporary letter retained."}
    $o=& reagentc.exe /enable 2>&1
    foreach($x in $o){Log "REAGENTC: $x"}
    if($LASTEXITCODE -ne 0){Stop-Run "reagentc /enable failed; exit=$LASTEXITCODE; temporary letter retained."}

    $verify=Get-Info
    if(-not (Is-Enabled $verify)){Stop-Run 'WinRE did not report Enabled; temporary letter retained.'}
    $verifyPart=Get-RegisteredPartition $verify $disk.Number
    if($verifyPart -ne $target.PartitionNumber){Stop-Run "WinRE points to partition $verifyPart, expected $($target.PartitionNumber); temporary letter retained."}

    Remove-PartitionAccessPath -DiskNumber $disk.Number -PartitionNumber $target.PartitionNumber -AccessPath "${letter}:\"
    $vol=Get-Volume -DriveLetter C
    Log ("RESULT=SUCCESS; CSizeGiB={0:N2}; CFreeGiB={1:N2}; WinRE=Enabled; RecoveryPartition={2}" -f ($vol.Size/1GB),($vol.SizeRemaining/1GB),$target.PartitionNumber)
    Log '========== END APPLY SUCCESS =========='
    exit 0
}
catch {
    Log $_.Exception.Message 'ERROR'
    Log 'RESULT=FAILED; do not rerun Apply until current disk state and this log are reviewed.' 'ERROR'
    Log '========== END FAILURE =========='
    exit 1
}

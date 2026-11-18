#requires -Version 5.1
#requires -RunAsAdministrator
<#
Windows 365 CPC C: / WinRE repair.
Version 2.2 - scoped to the reported 256 GiB, five-partition CPC.
Supports already-disabled WinRE with a validated System32 recovery image.
Default: Apply (for Intune Platform scripts). This deletes/recreates Partition 5.
Diagnose reads layout and reagentc only; it does not mount or change partitions.
Expected C: about 252.44 GiB; retains the original 3 GiB tail reservation.
On a failed mutation, a persistent marker blocks automatic retries.
Review the log and disk state before an administrator removes that marker.
Optional layout inspection:
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\CPC_WinRE_Remediation_Updated.ps1 -Mode Diagnose

Log: C:\ProgramData\CPC-WinRE-Repair\CPC-WinRE-Repair.log
Run as SYSTEM (Intune: logged-on credentials = No; 64-bit PowerShell = Yes).
No reboot is initiated.
#>
[CmdletBinding()]
param([ValidateSet('Diagnose','Apply')][string]$Mode='Apply')

$ScriptVersion='2.2'
$ExpectedDiskBytes=256GB
$MinimumCBytes=252GB
$MutationStarted=$false
$Mutex=$null
$LockTaken=$false

$ErrorActionPreference='Stop'
$LogDir='C:\ProgramData\CPC-WinRE-Repair'
$LogPath=Join-Path $LogDir 'CPC-WinRE-Repair.log'
$FailureMarker=Join-Path $LogDir 'manual-review-required.txt'
$RunId=(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N')
$BackupDir=Join-Path 'C:\WinRE_Backup' $RunId
$BackupPath=Join-Path $BackupDir 'winre.wim'
$WinRESource='C:\Windows\System32\Recovery\winre.wim'
$RecoverySizeMB=2048
$RecoveryGuid='de94bba4-06d1-4d40-a16a-bfd50179d6ac'
$RecoveryAttributes='0x8000000000000001'
New-Item -Path $LogDir -ItemType Directory -Force | Out-Null

function Log([string]$Message,[string]$Level='INFO') {
    $line='{0} [{1}] [{2}] {3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$Level,$env:COMPUTERNAME,$Message
    Add-Content -LiteralPath $LogPath -Value $line
    Write-Host $line
}
function Stop-Run([string]$Message) { Log $Message 'ERROR'; throw $Message }
function Get-Info {
    $o=& reagentc.exe /info 2>&1; $ec=$LASTEXITCODE
    foreach($x in $o){Log "REAGENTC: $x"}
    if($ec -ne 0){Stop-Run "reagentc /info failed; exit=$ec"}
    return ($o | Out-String)
}
function Is-Enabled([string]$Info) {
    if($Info -match '(?im)(?:Windows RE status|Windows RE の状態|Windows RE 状态|Windows RE 狀態)\s*[:：]\s*(?:Enabled|有効|已启用|已啟用)'){return $true}
    if($Info -match '(?im)(?:Windows RE status|Windows RE の状態|Windows RE 状态|Windows RE 狀態)\s*[:：]\s*(?:Disabled|無効|已禁用|已停用)'){return $false}
    Stop-Run 'Unrecognized reagentc status language/output; refusing to guess.'
}
function Get-RegisteredPartition([string]$Info,[int]$DiskNo) {
    # Match one literal backslash before "partition"; reagentc path contains \partitionN\
    $pattern='(?i)harddisk'+$DiskNo+'\\partition(\d+)\\'
    $m=[regex]::Match($Info,$pattern)
    if($m.Success){return [int]$m.Groups[1].Value}
    return $null
}

function Get-FreeDriveLetter {
    $used = @((Get-Volume | Where-Object DriveLetter | ForEach-Object {
        $_.DriveLetter.ToString().ToUpperInvariant()
    }))
    return (@('R','S','T','U','V','W','X','Y','Z') |
        Where-Object { $used -notcontains $_ } |
        Select-Object -First 1)
}
function Test-OriginalCpcLayout($Partitions, $OsPartition) {
    if ($Partitions.Count -ne 5) { return $false }
    $p = @($Partitions | Sort-Object PartitionNumber)
    if ($p[0].PartitionNumber -ne 1 -or $p[1].PartitionNumber -ne 2 -or
        $p[2].PartitionNumber -ne 3 -or $p[3].PartitionNumber -ne 4 -or
        $p[4].PartitionNumber -ne 5) { return $false }
    if ($p[0].Type -ne 'Reserved' -or $p[1].Type -ne 'Recovery' -or
        $p[2].Type -ne 'System' -or $p[4].Type -ne 'Recovery') { return $false }
    if ($OsPartition.PartitionNumber -ne 4 -or $OsPartition.DriveLetter -ne 'C') { return $false }
    for($i=1; $i -lt $p.Count; $i++){
        if($p[$i].Offset -lt ($p[$i-1].Offset+$p[$i-1].Size)){return $false}
    }
    if($p[3].IsBoot -ne $true -or $p[3].Type -ne 'Basic'){return $false}
    if ([math]::Abs(($p[0].Size / 1MB) - 16) -gt 4) { return $false }
    if ($p[1].Size -lt 300MB -or $p[1].Size -gt 700MB) { return $false }
    if ($p[2].Size -lt 50MB -or $p[2].Size -gt 200MB) { return $false }
    if ($p[4].Size -lt 500MB -or $p[4].Size -gt 1500MB) { return $false }
    if ($p[4].DriveLetter) { return $false }
    if (-not $p[4].GptType -or $p[4].GptType.Trim('{}').ToLowerInvariant() -ne $RecoveryGuid) {
        return $false
    }
    return $true
}
function Test-PartitionWinREImage([int]$DiskNumber, [int]$PartitionNumber, [switch]$BackupImage) {
    $letter = $null
    $added = $false
    try {
        $partition = Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber
        if ($partition.DriveLetter) {
            Log "Partition $PartitionNumber already has drive letter $($partition.DriveLetter); refusing temporary verification." 'WARN' | Out-Null
            return $false
        }
        $letter = Get-FreeDriveLetter
        if (-not $letter) { Stop-Run 'No free temporary drive letter R: to Z:.' }
        Set-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -NewDriveLetter $letter | Out-Null
        $added = $true

        $imagePath = "${letter}:\Recovery\WindowsRE\winre.wim"
        $image = Get-Item -LiteralPath $imagePath -Force -ErrorAction SilentlyContinue
        if (-not $image -or $image.PSIsContainer) {
            Log "Partition $PartitionNumber does not contain Recovery\WindowsRE\winre.wim." 'WARN' | Out-Null
            return $false
        }
        if ($image.Length -lt 100MB -or $image.Length -gt 2GB) {
            Log ("Partition {0} WinRE image size is outside the accepted range: {1:N1} MiB." -f
                $PartitionNumber, ($image.Length / 1MB)) 'WARN' | Out-Null
            return $false
        }
        Log ("Partition {0} WinRE image verified; size={1:N1} MiB." -f
            $PartitionNumber, ($image.Length / 1MB)) | Out-Null
        if($BackupImage){
            Backup-ValidatedWinREImage -SourcePath $imagePath
        }
        return $true
    }
    finally {
        if ($added -and $letter) {
            try {
                Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -AccessPath "${letter}:\" | Out-Null
                Log "Temporary drive letter $letter`: removed from Partition $PartitionNumber." | Out-Null
            } catch {
                Log "WARNING: failed to remove temporary drive letter $letter`: from Partition $PartitionNumber. $($_.Exception.Message)" 'ERROR' | Out-Null
                throw
            }
        }
    }
}

function Backup-ValidatedWinREImage([string]$SourcePath) {
    $image=Get-Item -LiteralPath $SourcePath -Force -ErrorAction Stop
    if($image.PSIsContainer -or $image.Length -lt 100MB -or $image.Length -gt (2GB-300MB)){
        Stop-Run 'WinRE image missing, implausibly small, or too large for the planned recovery partition.'
    }
    New-Item -Path $BackupDir -ItemType Directory -Force | Out-Null
    # Validate a staging copy before replacing any earlier valid backup.
    $staged=Join-Path $BackupDir ('validated-'+[guid]::NewGuid().ToString('N')+'.wim')
    Copy-Item -LiteralPath $SourcePath -Destination $staged -Force
    $h1=(Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
    $h2=(Get-FileHash -LiteralPath $staged -Algorithm SHA256).Hash
    if($h1 -ne $h2){Stop-Run 'WinRE backup SHA256 mismatch.'}
    $meta=Get-WindowsImage -ImagePath $staged -Index 1 -ErrorAction Stop
    if(-not $meta){Stop-Run 'DISM could not read the WinRE backup.'}
    $arch=([string]$meta.Architecture).ToLowerInvariant()
    $hostArch=$env:PROCESSOR_ARCHITECTURE.ToUpperInvariant()
    $archOK=($hostArch -eq 'AMD64' -and $arch -in @('9','x64','amd64')) -or
            ($hostArch -eq 'ARM64' -and $arch -in @('12','arm64'))
    if(-not $archOK){Stop-Run "Image architecture $arch does not match host $hostArch."}
    $imageVersion=[version]$meta.Version
    $osVersion=[version](Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Version
    if($imageVersion.Major -ne $osVersion.Major -or $imageVersion.Minor -ne $osVersion.Minor){
        Stop-Run "Image version $imageVersion does not match OS version family $osVersion."
    }
    # Servicing/build revisions need not match exactly. This is a metadata check,
    # not a guarantee of bootability; final reagentc registration is verified too.
    Log "Image metadata: Name=$($meta.ImageName); Version=$imageVersion; Architecture=$arch; OS=$osVersion"
    Move-Item -LiteralPath $staged -Destination $BackupPath -Force
    $script:VerifiedBackupHash=$h2
    Log "BACKUP_VERIFIED Source=$SourcePath; Backup=$BackupPath; SHA256=$h2"
}

function Prepare-WinREBackup([int]$DiskNumber,[int]$PartitionNumber,[bool]$Enabled) {
    if(-not $Enabled -and (Test-Path -LiteralPath $WinRESource -PathType Leaf)){
        Log 'IMAGE_SOURCE=SYSTEM32; WinRE is disabled. A WIM on the old partition is not required.'
        Backup-ValidatedWinREImage -SourcePath $WinRESource
        return
    }
    if(-not (Test-PartitionWinREImage -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -BackupImage)){
        Stop-Run 'No validated WinRE image available from the eligible source; no partition deletion performed.'
    }
}

function Backup-PartitionContents([int]$DiskNumber,[int]$PartitionNumber) {
    $partition=Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber
    if($partition.DriveLetter){Stop-Run 'Old partition has an unexpected drive letter before content backup.'}
    $letter=Get-FreeDriveLetter
    if(-not $letter){Stop-Run 'No free drive letter for old-partition content backup.'}
    $added=$false
    try {
        Set-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -NewDriveLetter $letter | Out-Null
        $added=$true
        $destination=Join-Path $BackupDir 'OldPartitionContents'
        New-Item -Path $destination -ItemType Directory -Force | Out-Null
        # Preserve remaining files before deletion; do not follow junctions.
        $copyLog=Join-Path $BackupDir 'partition-copy.log'
        & "$env:SystemRoot\System32\robocopy.exe" "${letter}:\" $destination /E /COPY:DAT /DCOPY:DAT /XJ /R:1 /W:1 /XD "${letter}:\System Volume Information" "${letter}:\`$RECYCLE.BIN" "/LOG:$copyLog" | Out-Null
        $copyExit=$LASTEXITCODE
        if($copyExit -ge 8){Stop-Run "Old-partition content backup failed; exit=$copyExit; log=$copyLog"}
        Log "Old partition contents preserved at $destination; robocopy exit=$copyExit"
    }
    finally {
        if($added){Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -AccessPath "${letter}:\" | Out-Null}
    }
}

function Run-DiskPart([string]$Step,[string]$Commands) {
    Log "DISKPART START: $Step"
    $commandFile=Join-Path $LogDir ("diskpart-$RunId.txt")
    Set-Content -LiteralPath $commandFile -Value $Commands -Encoding ASCII
    $o=& "$env:SystemRoot\System32\diskpart.exe" /s $commandFile 2>&1
    $ec=$LASTEXITCODE
    foreach($x in $o){Log "DISKPART: $x"}
    $s=$o | Out-String
    if($ec -ne 0 -or $s -match '(?i)Virtual Disk Service error|DiskPart has encountered an error|エラー|失敗|引数が不正') {
        Stop-Run "DiskPart failed: $Step; exit=$ec"
    }
    Log "DISKPART OK: $Step"
}

try {
    $Mutex=[System.Threading.Mutex]::new($false,'Global\CPC-WinRE-Repair-v2')
    try {$LockTaken=$Mutex.WaitOne(0)} catch [System.Threading.AbandonedMutexException] {$LockTaken=$true}
    if(-not $LockTaken){Stop-Run 'Another CPC repair is running.'}
    Log "========== START Version=$ScriptVersion Mode=$Mode Run=$RunId =========="
    if(-not [Environment]::Is64BitProcess){Stop-Run '64-bit PowerShell required. Create a new Intune policy with 64-bit host = Yes.'}
    if($Mode -eq 'Apply' -and (Test-Path -LiteralPath $FailureMarker)){
        Stop-Run "Previous mutation was interrupted or failed. Review $FailureMarker and current disk state; no automatic retry."
    }
    $wi=[Security.Principal.WindowsIdentity]::GetCurrent()
    $wp=[Security.Principal.WindowsPrincipal]::new($wi)
    if(-not $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){Stop-Run 'Not elevated. Run as SYSTEM / admin.'}

    $os=Get-Partition -DriveLetter C
    $disk=Get-Disk -Number $os.DiskNumber
    if($disk.PartitionStyle -ne 'GPT'){Stop-Run "OS disk $($disk.Number) is not GPT."}
    if([math]::Abs($disk.Size-$ExpectedDiskBytes) -gt 16MB){Stop-Run 'This version is scoped to a 256 GiB OS disk.'}
    if($disk.IsOffline -or $disk.IsReadOnly){Stop-Run 'OS disk is offline or read-only.'}
    $parts=@(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
    $initialCSize=$os.Size
    $info=Get-Info
    $enabled=Is-Enabled $info
    $registered=Get-RegisteredPartition $info $disk.Number
    $afterC=@($parts | Where-Object {$_.Type -eq 'Recovery' -and $_.Offset -gt $os.Offset})
    $large=@($afterC | Where-Object {$_.Size -ge 2GB})
    Log ("Disk={0}; DiskGiB={1:N2}; CSizeGiB={2:N2}; CFreeGiB={3:N2}; WinREEnabled={4}; RegisteredPartition={5}" -f $disk.Number,($disk.Size/1GB),($os.Size/1GB),((Get-Volume -DriveLetter C).SizeRemaining/1GB),$enabled,$registered)
    foreach($p in $parts){Log ("PARTITION Number={0}; Type={1}; Letter={2}; SizeMiB={3:N1}; OffsetMiB={4:N1}" -f $p.PartitionNumber,$p.Type,$p.DriveLetter,($p.Size/1MB),($p.Offset/1MB))}

    if($Mode -eq 'Diagnose'){
        Log 'RESULT=DIAGNOSE_ONLY; no repair attempted; not an Intune Remediations detection script.'
        exit 0
    }

    if($large.Count -gt 1){Stop-Run 'Multiple >=2 GiB Recovery partitions after C:. Refusing changes.'}
    $target=$null
    if($large.Count -eq 1){
        $target=$large[0]
        $expectedOffset=[int64]$disk.Size-[int64](3GB)
        if([math]::Abs($target.Offset-$expectedOffset) -gt 1MB -or $target.Size -ne 2GB){
            Stop-Run 'Existing recovery partition is not at the expected tail offset/size; manual layout review required.'
        }
        if(($enabled -and $registered -ne $target.PartitionNumber) -or ($registered -and $registered -ne $target.PartitionNumber)){Stop-Run 'WinRE registered to a different partition.'}
        Log "Using existing 2 GiB Recovery partition $($target.PartitionNumber) to finish WinRE."
        if($target.PartitionNumber -ne $parts[-1].PartitionNumber){
            Stop-Run 'Existing 2 GiB Recovery partition is not the last partition. Refusing automatic changes.'
        }
        if($target.GptType -and $target.GptType.Trim('{}').ToLowerInvariant() -ne $RecoveryGuid){
            Stop-Run "Existing large Recovery partition has unexpected GPT type $($target.GptType)."
        }
        Prepare-WinREBackup -DiskNumber $disk.Number -PartitionNumber $target.PartitionNumber -Enabled $enabled
    } else {
        if($afterC.Count -ne 1){Stop-Run "Expected exactly one Recovery partition after C:, found $($afterC.Count)."}
        $old=$afterC[0]
        if($old.PartitionNumber -ne 5 -or $old.PartitionNumber -ne $parts[-1].PartitionNumber){
            Stop-Run 'Candidate Recovery partition is not Partition 5 / the last partition.'
        }
        if(-not (Test-OriginalCpcLayout -Partitions $parts -OsPartition $os)){
            Stop-Run 'Disk does not match the expected original five-partition CPC layout. Refusing automatic deletion.'
        }
        if(($enabled -and $registered -ne $old.PartitionNumber) -or ($registered -and $registered -ne $old.PartitionNumber)){
            Stop-Run "reagentc points to partition $registered, not candidate partition $($old.PartitionNumber)."
        }
        if($old.DriveLetter){Stop-Run 'Candidate Recovery partition has a drive letter.'}

        # Layout/type checks above identify the candidate even when /disable
        # has already removed its WIM and cleared WinRE registration.
        Prepare-WinREBackup -DiskNumber $disk.Number -PartitionNumber $old.PartitionNumber -Enabled $enabled

        $offsetBytes=[int64]$disk.Size-[int64](3GB)
        $offsetKB=[int64][math]::Floor($offsetBytes/1KB)
        if($offsetBytes -le ($old.Offset+$old.Size)){Stop-Run 'No clear tail extent for the replacement Recovery partition.'}
        if(($offsetBytes-$os.Offset) -lt $MinimumCBytes){Stop-Run 'Planned C: size is below the required minimum.'}
        Set-Content -LiteralPath $FailureMarker -Value "IN_PROGRESS Run=$RunId Backup=$BackupPath" -Encoding UTF8
        $MutationStarted=$true
        if($enabled){
            $o=& reagentc.exe /disable 2>&1
            $ec=$LASTEXITCODE
            foreach($x in $o){Log "REAGENTC: $x"}
            if($ec -ne 0){Stop-Run "reagentc /disable failed; exit=$ec"}
        }
        $disabledInfo=Get-Info
        if(Is-Enabled $disabledInfo){Stop-Run 'WinRE is still enabled; refusing deletion.'}
        if($enabled){
            # Use the image returned by this disable operation, not an older
            # pre-disable System32 file. Keep the pre-disable backup if this fails.
            Backup-ValidatedWinREImage -SourcePath $WinRESource
        }
        Backup-PartitionContents -DiskNumber $disk.Number -PartitionNumber $old.PartitionNumber

        # Revalidate immediately before deletion; do not rely on the earlier check.
        $oldNow=Get-Partition -DiskNumber $disk.Number -PartitionNumber $old.PartitionNumber
        if($oldNow.DriveLetter){Stop-Run 'Partition 5 acquired a drive letter before deletion. Refusing to continue.'}
        $freshParts=@(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
        $freshC=Get-Partition -DriveLetter C
        if(-not (Test-OriginalCpcLayout -Partitions $freshParts -OsPartition $freshC)){
            Stop-Run 'Partition layout changed before deletion.'
        }
        if($oldNow.Offset -ne $old.Offset -or $oldNow.Size -ne $old.Size -or $oldNow.Guid -ne $old.Guid){
            Stop-Run 'Candidate partition identity changed before deletion.'
        }
        $disabledInfo=Get-Info
        if(Is-Enabled $disabledInfo){Stop-Run 'WinRE became enabled before deletion.'}
        $registeredNow=Get-RegisteredPartition $disabledInfo $disk.Number
        if($registeredNow -and $registeredNow -ne $old.PartitionNumber){Stop-Run 'WinRE registration changed to another partition.'}
        if((Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash -ne $VerifiedBackupHash){
            Stop-Run 'Verified backup changed; refusing deletion.'
        }
        # /disable may move the original WIM. Verify the independent backup,
        # not continued existence of the old partition's WIM.

        Run-DiskPart 'Replace old WinRE partition' @"
select disk $($disk.Number)
select partition $($old.PartitionNumber)
delete partition override
create partition primary size=$RecoverySizeMB offset=$offsetKB
format quick fs=ntfs label="Windows RE tools"
set id=$RecoveryGuid
gpt attributes=$RecoveryAttributes
exit
"@
        Update-HostStorageCache
        $parts2=@(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
        $candidates=@($parts2 | Where-Object {$_.Type -eq 'Recovery' -and $_.Size -ge 2GB -and $_.Offset -gt $os.Offset})
        if($candidates.Count -ne 1){Stop-Run "Expected one new 2 GiB Recovery partition; found $($candidates.Count)."}
        $target=$candidates[0]
        if([math]::Abs($target.Offset-$offsetBytes) -gt 1MB -or $target.Size -ne 2GB){
            Stop-Run 'Replacement recovery partition offset/size does not match the plan.'
        }

    }

    if(-not $MutationStarted){
        Set-Content -LiteralPath $FailureMarker -Value "IN_PROGRESS Run=$RunId Backup=$BackupPath" -Encoding UTF8
        $MutationStarted=$true
    }
    # C: expansion. This runs whether the 2 GiB Recovery partition
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
            if($currentC.Size -lt $MinimumCBytes){Stop-Run 'C: below target and no contiguous expansion space available.'}
            Log 'C: already meets required capacity.'
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

    $currentC=Get-Partition -DriveLetter C
    $gap=[int64]$target.Offset-([int64]$currentC.Offset+[int64]$currentC.Size)
    if($currentC.Size -lt $MinimumCBytes -or $gap -lt 0 -or $gap -gt 2MB){
        Stop-Run "C: size/boundary validation failed; Size=$($currentC.Size); Gap=$gap"
    }
    # Disable before replacing a registered image on an existing target.
    $beforeCopy=Get-Info
    $beforeCopyPart=Get-RegisteredPartition $beforeCopy $disk.Number
    if($beforeCopyPart -and $beforeCopyPart -ne $target.PartitionNumber){Stop-Run 'Unexpected WinRE registration before image copy.'}
    if(Is-Enabled $beforeCopy){
        $o=& reagentc.exe /disable 2>&1
        $ec=$LASTEXITCODE
        foreach($x in $o){Log "REAGENTC: $x"}
        if($ec -ne 0){Stop-Run "reagentc /disable before copy failed; exit=$ec"}
        $disabled=Get-Info
        if(Is-Enabled $disabled){Stop-Run 'WinRE still enabled before image copy.'}
        Backup-ValidatedWinREImage -SourcePath $WinRESource
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
    if(-not (Test-Path -LiteralPath $BackupPath)){Stop-Run 'Verified backup missing.'}
    if((Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash -ne $VerifiedBackupHash){Stop-Run 'Verified backup changed before copy.'}
    Copy-Item -LiteralPath $BackupPath -Destination (Join-Path $root 'winre.wim') -Force
    $bh=(Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256).Hash
    $ch=(Get-FileHash -LiteralPath (Join-Path $root 'winre.wim') -Algorithm SHA256).Hash
    if($bh -ne $ch){Stop-Run 'Copied WinRE image SHA256 mismatch; temporary drive letter retained.'}

    $o=& reagentc.exe /setreimage /path $root 2>&1
    $ec=$LASTEXITCODE
    foreach($x in $o){Log "REAGENTC: $x"}
    if($ec -ne 0){Stop-Run "reagentc /setreimage failed; exit=$ec; temporary letter retained."}
    $o=& reagentc.exe /enable 2>&1
    $ec=$LASTEXITCODE
    foreach($x in $o){Log "REAGENTC: $x"}
    if($ec -ne 0){Stop-Run "reagentc /enable failed; exit=$ec; temporary letter retained."}

    $verify=Get-Info
    if(-not (Is-Enabled $verify)){Stop-Run 'WinRE did not report Enabled; temporary letter retained.'}
    $verifyPart=Get-RegisteredPartition $verify $disk.Number
    if($verifyPart -ne $target.PartitionNumber){Stop-Run "WinRE points to partition $verifyPart, expected $($target.PartitionNumber); temporary letter retained."}

    Remove-PartitionAccessPath -DiskNumber $disk.Number -PartitionNumber $target.PartitionNumber -AccessPath "${letter}:\"
    $verify=Get-Info
    if(-not (Is-Enabled $verify) -or (Get-RegisteredPartition $verify $disk.Number) -ne $target.PartitionNumber){
        Stop-Run 'WinRE verification failed after removing the temporary drive letter.'
    }
    $vol=Get-Volume -DriveLetter C
    $finalC=Get-Partition -DriveLetter C
    if($vol.Size -lt $MinimumCBytes -or $finalC.Size -lt $MinimumCBytes){Stop-Run 'Final C: partition/filesystem capacity below target.'}
    Remove-Item -LiteralPath $FailureMarker -Force
    Log ("C: before={0:N2} GiB; after={1:N2} GiB; delta={2:N2} GiB" -f ($initialCSize/1GB),($finalC.Size/1GB),(($finalC.Size-$initialCSize)/1GB))
    Log ("RESULT=SUCCESS; CSizeGiB={0:N2}; CFreeGiB={1:N2}; WinRE=Enabled; RecoveryPartition={2}" -f ($vol.Size/1GB),($vol.SizeRemaining/1GB),$target.PartitionNumber)
    Log '========== END APPLY SUCCESS =========='
    exit 0
}
catch {
    $failureMessage=$_.Exception.Message
    Log "Version=$ScriptVersion; Run=$RunId; $failureMessage" 'ERROR'
    if($MutationStarted){Log "Mutation may be partial. Backup=$BackupPath; retry blocked by $FailureMarker" 'ERROR'}
    Log 'RESULT=FAILED; do not rerun Apply until current disk state and this log are reviewed.' 'ERROR'
    Log '========== END FAILURE =========='
    exit 1
}

finally {
    if($LockTaken -and $Mutex){$Mutex.ReleaseMutex()}
    if($Mutex){$Mutex.Dispose()}
}

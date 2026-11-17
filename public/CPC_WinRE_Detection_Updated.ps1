#requires -Version 5.1
#requires -RunAsAdministrator
<#
Intune Remediations Detection Script for Windows 365 CPC C: / WinRE repair.
Exit 0 = no supported remediation needed (or layout is not safely identifiable).
Exit 1 = a known, supported repair condition was detected.

The script temporarily assigns a drive letter to Partition 5 only to inspect
Recovery\WindowsRE\winre.wim, and removes that temporary letter in finally.
#>
$ErrorActionPreference = 'Stop'
$RecoveryGuid = 'de94bba4-06d1-4d40-a16a-bfd50179d6ac'
$LogDir = 'C:\ProgramData\CPC-WinRE-Repair'
$LogPath = Join-Path $LogDir 'Detection.log'
$MinWinREBytes = 100MB
$MaxWinREBytes = 2GB

function Write-DetectLog([string]$Message) {
    try {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
        Add-Content -LiteralPath $LogPath -Value ("{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
    } catch {}
    Write-Output $Message
}
function Get-WinREInfo {
    $output = & reagentc.exe /info 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'reagentc /info returned a non-zero exit code.' }
    return ($output | Out-String)
}
function Test-WinREEnabled([string]$Info) {
    return ($Info -match '(?im)Windows RE status\s*:\s*Enabled|Windows RE status\s*:\s*有効|Windows RE の状態\s*:\s*有効')
}
function Get-WinREPartition([string]$Info, [int]$DiskNumber) {
    $pattern = '(?i)harddisk' + $DiskNumber + '\\partition(\d+)\\'
    $match = [regex]::Match($Info, $pattern)
    if ($match.Success) { return [int]$match.Groups[1].Value }
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
function Test-OriginalCpcLayout($Disk, $Partitions, $OsPartition) {
    if ($Partitions.Count -ne 5) { return $false }
    $p = @($Partitions | Sort-Object PartitionNumber)
    if ($p[0].PartitionNumber -ne 1 -or $p[1].PartitionNumber -ne 2 -or
        $p[2].PartitionNumber -ne 3 -or $p[3].PartitionNumber -ne 4 -or
        $p[4].PartitionNumber -ne 5) { return $false }

    if ($p[0].Type -ne 'Reserved' -or $p[1].Type -ne 'Recovery' -or
        $p[2].Type -ne 'System' -or $p[4].Type -ne 'Recovery') { return $false }
    if ($OsPartition.PartitionNumber -ne 4 -or $OsPartition.DriveLetter -ne 'C') { return $false }
    if ([math]::Abs(($p[0].Size / 1MB) - 16) -gt 4) { return $false }
    if ($p[1].Size -lt 300MB -or $p[1].Size -gt 700MB) { return $false }
    if ($p[2].Size -lt 50MB -or $p[2].Size -gt 200MB) { return $false }
    if ($p[4].Size -lt 500MB -or $p[4].Size -gt 1500MB) { return $false }
    if ($p[4].DriveLetter) { return $false }
    if ($p[4].GptType -and $p[4].GptType.Trim('{}').ToLowerInvariant() -ne $RecoveryGuid) {
        return $false
    }
    return $true
}
function Test-PartitionWinREImage([int]$DiskNumber, [int]$PartitionNumber) {
    $letter = $null
    $added = $false
    try {
        $partition = Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber
        if ($partition.DriveLetter) {
            $letter = $partition.DriveLetter.ToString().ToUpperInvariant()
            Write-DetectLog "Partition $PartitionNumber already has drive letter $letter`:; refusing to treat it as a temporary mount." | Out-Null
            return $false
        }
        $letter = Get-FreeDriveLetter
        if (-not $letter) { throw 'No free temporary drive letter R: to Z:.' }
        Set-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -NewDriveLetter $letter | Out-Null
        $added = $true

        $imagePath = "${letter}:\Recovery\WindowsRE\winre.wim"
        $image = Get-Item -LiteralPath $imagePath -Force -ErrorAction SilentlyContinue
        if (-not $image -or $image.PSIsContainer) {
            Write-DetectLog "Partition $PartitionNumber does not contain Recovery\WindowsRE\winre.wim." | Out-Null
            return $false
        }
        if ($image.Length -lt $MinWinREBytes -or $image.Length -gt $MaxWinREBytes) {
            Write-DetectLog ("Partition {0} WinRE image size is outside the accepted range: {1:N1} MiB." -f
                $PartitionNumber, ($image.Length / 1MB)) | Out-Null
            return $false
        }
        Write-DetectLog ("Partition {0} WinRE image verified; size={1:N1} MiB." -f
            $PartitionNumber, ($image.Length / 1MB)) | Out-Null
        return $true
    }
    finally {
        if ($added -and $letter) {
            try {
                Remove-PartitionAccessPath -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -AccessPath "${letter}:\" | Out-Null
                Write-DetectLog "Temporary drive letter $letter`: removed from Partition $PartitionNumber." | Out-Null
            } catch {
                Write-DetectLog "WARNING: failed to remove temporary drive letter $letter`: from Partition $PartitionNumber. $($_.Exception.Message)" | Out-Null
                throw
            }
        }
    }
}

try {
    $c = Get-Partition -DriveLetter C
    $disk = Get-Disk -Number $c.DiskNumber
    if ($disk.PartitionStyle -ne 'GPT') {
        Write-DetectLog 'DETECTION=UNSUPPORTED; OS disk is not GPT. No automatic remediation.'
        exit 0
    }

    $parts = @(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
    if (-not (Test-OriginalCpcLayout -Disk $disk -Partitions $parts -OsPartition $c)) {
        Write-DetectLog 'DETECTION=REVIEW_REQUIRED; disk does not match the expected original five-partition CPC layout. No automatic remediation.'
        exit 0
    }

    $candidate = Get-Partition -DiskNumber $disk.Number -PartitionNumber 5
    $imageVerified = Test-PartitionWinREImage -DiskNumber $disk.Number -PartitionNumber $candidate.PartitionNumber
    if (-not $imageVerified) {
        Write-DetectLog 'DETECTION=REVIEW_REQUIRED; Partition 5 could not be verified as the old WinRE partition. No automatic remediation.'
        exit 0
    }

    $info = Get-WinREInfo
    $enabled = Test-WinREEnabled $info
    $registered = Get-WinREPartition $info $disk.Number
    $supported = Get-PartitionSupportedSize -DriveLetter C
    $cNeedsExpansion = ($supported.SizeMax -gt ($c.Size + 1MB))
    $winreNeedsRepair = (-not $enabled) -or ($registered -ne 5)

    if ($cNeedsExpansion -or $winreNeedsRepair) {
        Write-DetectLog ("DETECTION=NEEDS_REMEDIATION; OriginalFivePartitionLayout=True; Partition5WinREVerified=True; CNeedsExpansion={0}; WinREEnabled={1}; RegisteredPartition={2}; CandidatePartition=5" -f
            $cNeedsExpansion, $enabled, $registered)
        exit 1
    }

    Write-DetectLog ("DETECTION=COMPLIANT; CSizeGiB={0:N2}; WinREEnabled=True; RecoveryPartition=5" -f ($c.Size / 1GB))
    exit 0
}
catch {
    Write-DetectLog ("DETECTION=ERROR; {0}; no automatic remediation." -f $_.Exception.Message)
    exit 0
}

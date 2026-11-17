#requires -RunAsAdministrator
<#
.SYNOPSIS
  Expand the Windows 365 OS (C:) partition and recreate a 2 GiB WinRE partition.
.DESCRIPTION
  Intended for Windows 365 Cloud PCs with the specific layout discussed:
    - GPT OS disk
    - Windows OS on C:
    - One Recovery partition after C: (the old WinRE partition)
    - Unallocated space after that Recovery partition
  The script stops if the layout differs or any safety check fails.
  It logs to C:\ProgramData\WinRE-Resize\WinRE-Resize.log.

  IMPORTANT:
  - Pilot on one CPC before broad deployment.
  - Do not deploy to devices with a different partition layout.
  - The backup under C:\WinRE_Backup is on the same virtual disk, not an
    independent backup.
#>

$ErrorActionPreference = 'Stop'
$LogDirectory = 'C:\ProgramData\WinRE-Resize'
$LogFile = Join-Path $LogDirectory 'WinRE-Resize.log'
$BackupDirectory = 'C:\WinRE_Backup'
$BackupImage = Join-Path $BackupDirectory 'winre.wim'
$SystemWinRE = 'C:\Windows\System32\Recovery\winre.wim'
$RecoverySizeMB = 2048
$RecoveryTypeGuid = 'de94bba4-06d1-4d40-a16a-bfd50179d6ac'
$RecoveryAttributes = '0x8000000000000001'
$TempDriveLetters = @('R','S','T','U','V','W','X','Y','Z')

New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
    )
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $LogFile -Value $line
    Write-Output $line
}

function Stop-Script {
    param([string]$Message)
    Write-Log -Message $Message -Level 'ERROR'
    throw $Message
}

try {
    Write-Log '----- WinRE / C: expansion started -----'

    # 1. Basic checks
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Stop-Script 'Administrator/SYSTEM privileges are required.'
    }

    $osPartition = Get-Partition -DriveLetter C
    $diskNumber = $osPartition.DiskNumber
    $disk = Get-Disk -Number $diskNumber

    if ($disk.PartitionStyle -ne 'GPT') {
        Stop-Script "OS disk $diskNumber is not GPT. No changes were made."
    }

    $allPartitions = @(Get-Partition -DiskNumber $diskNumber | Sort-Object Offset)
    $osPartition = Get-Partition -DriveLetter C
    $recoveryAfterC = @(
        $allPartitions | Where-Object {
            $_.Type -eq 'Recovery' -and $_.Offset -gt $osPartition.Offset
        }
    )

    # Idempotent skip: already has a 2 GiB+ Recovery partition after C: and WinRE is enabled.
    $reagentInfo = (& reagentc.exe /info 2>&1 | Out-String)
    $largeRecoveryAfterC = @($recoveryAfterC | Where-Object { $_.Size -ge 2GB })
    if ($largeRecoveryAfterC.Count -eq 1 -and $reagentInfo -match '(?i)Enabled|有効') {
        Write-Log 'A 2 GiB-or-larger Recovery partition already exists after C: and WinRE appears enabled. Skipping changes.'
        exit 0
    }

    if ($recoveryAfterC.Count -ne 1) {
        Stop-Script "Expected exactly one Recovery partition after C:, found $($recoveryAfterC.Count). No partition changes were made."
    }

    $oldRecovery = $recoveryAfterC[0]

    # Only proceed when the currently registered WinRE location identifies this exact partition.
    if ($reagentInfo -notmatch ('(?i)harddisk' + $diskNumber + '\\partition' + $oldRecovery.PartitionNumber + '\\')) {
        Stop-Script "Current reagentc /info output does not identify disk $diskNumber partition $($oldRecovery.PartitionNumber) as the WinRE location. No partition changes were made."
    }

    $lastPartition = $allPartitions[-1]

    if ($oldRecovery.PartitionNumber -ne $lastPartition.PartitionNumber) {
        Stop-Script 'The Recovery partition after C: is not the last partition on the disk. Layout is not the expected CPC layout.'
    }

    if ($oldRecovery.Offset -le ($osPartition.Offset + $osPartition.Size - 1MB)) {
        Stop-Script 'Unexpected overlap or ordering between C: and the Recovery partition.'
    }

    # Check no drive letter is assigned to the old Recovery partition.
    if ($oldRecovery.DriveLetter) {
        Stop-Script "Old Recovery partition unexpectedly has drive letter $($oldRecovery.DriveLetter):. No changes were made."
    }

    # Ensure there is room for a new 2 GiB partition with a 1 GiB tail reserve.
    $newPartitionOffsetBytes = [int64]$disk.Size - [int64](3GB)
    if ($newPartitionOffsetBytes -le ($osPartition.Offset + $osPartition.Size)) {
        Stop-Script 'Disk does not have enough space after C: for a 2 GiB Recovery partition and the required safety margin.'
    }
    $newPartitionOffsetKB = [int64][math]::Floor($newPartitionOffsetBytes / 1KB)

    # Select an unused temporary drive letter.
    $usedLetters = @((Get-Volume | Where-Object DriveLetter | ForEach-Object { "$($_.DriveLetter)".ToUpperInvariant() }))
    $tempLetter = $TempDriveLetters | Where-Object { $usedLetters -notcontains $_ } | Select-Object -First 1
    if (-not $tempLetter) {
        Stop-Script 'No unused temporary drive letter from R: to Z: is available.'
    }

    # 2. Disable WinRE before removing its current partition.
    if ($reagentInfo -match '(?i)Enabled|有効') {
        Write-Log 'Disabling WinRE.'
        & reagentc.exe /disable | ForEach-Object { Write-Log "$_" }
        if ($LASTEXITCODE -ne 0) {
            Stop-Script "reagentc /disable failed with exit code $LASTEXITCODE."
        }
    } else {
        Write-Log 'WinRE does not appear enabled; continuing after verifying the local image.'
    }

    # 3. Ensure the image exists on C: and create/verify a backup before deleting anything.
    # winre.wim may be hidden/system-protected. Get-Item -Force explicitly
    # includes hidden items; Test-Path has no -Force parameter.
    $systemWinREItem = Get-Item -LiteralPath $SystemWinRE -Force -ErrorAction SilentlyContinue
    if (-not $systemWinREItem -or $systemWinREItem.PSIsContainer) {
        Stop-Script "WinRE image not found at $SystemWinRE after disabling WinRE. Old Recovery partition was not deleted."
    }

    New-Item -Path $BackupDirectory -ItemType Directory -Force | Out-Null
    if (-not (Test-Path -LiteralPath $BackupImage)) {
        Copy-Item -LiteralPath $SystemWinRE -Destination $BackupImage -Force
    }

    $sourceHash = (Get-FileHash -LiteralPath $SystemWinRE -Algorithm SHA256).Hash
    $backupHash = (Get-FileHash -LiteralPath $BackupImage -Algorithm SHA256).Hash
    if ($sourceHash -ne $backupHash) {
        Stop-Script 'WinRE backup SHA256 does not match the source image. Old Recovery partition was not deleted.'
    }
    Write-Log "WinRE backup verified. SHA256=$backupHash"

    # 4. Delete only the identified old Recovery partition, then create the new one at the end.
    Write-Log "Removing old Recovery partition $($oldRecovery.PartitionNumber) on disk $diskNumber."
    $diskpartDelete = @"
select disk $diskNumber
select partition $($oldRecovery.PartitionNumber)
delete partition override
exit
"@
    $diskpartDelete | & diskpart.exe | ForEach-Object { Write-Log "$_" }

    $remaining = @(Get-Partition -DiskNumber $diskNumber)
    if ($remaining | Where-Object { $_.PartitionNumber -eq $oldRecovery.PartitionNumber -and $_.Type -eq 'Recovery' }) {
        Stop-Script 'Old Recovery partition still exists after the delete command.'
    }

    Write-Log "Creating new $RecoverySizeMB MB Recovery partition at offset $newPartitionOffsetKB KB."
    $diskpartCreate = @"
select disk $diskNumber
create partition primary size=$RecoverySizeMB offset=$newPartitionOffsetKB
set id=$RecoveryTypeGuid
gpt attributes=$RecoveryAttributes
format quick fs=ntfs label="Windows RE tools"
exit
"@
    $diskpartCreate | & diskpart.exe | ForEach-Object { Write-Log "$_" }

    $newRecovery = Get-Partition -DiskNumber $diskNumber |
        Where-Object { $_.Type -eq 'Recovery' -and $_.Size -ge 2GB } |
        Sort-Object Offset -Descending |
        Select-Object -First 1

    if (-not $newRecovery) {
        Stop-Script 'New 2 GiB Recovery partition was not detected. WinRE backup remains at C:\WinRE_Backup.'
    }

    # 5. Extend C: into the contiguous unallocated space before the new Recovery partition.
    $supported = Get-PartitionSupportedSize -DriveLetter C
    if ($supported.SizeMax -le $osPartition.Size) {
        Stop-Script 'C: has no additional contiguous space available to extend.'
    }

    Write-Log ("Extending C: from {0:N2} GiB to maximum supported size {1:N2} GiB." -f ($osPartition.Size/1GB), ($supported.SizeMax/1GB))
    Resize-Partition -DriveLetter C -Size $supported.SizeMax

    # 6. Temporarily mount the new Recovery partition, copy the image, and register WinRE.
    Set-Partition -DiskNumber $diskNumber -PartitionNumber $newRecovery.PartitionNumber -NewDriveLetter $tempLetter
    $recoveryRoot = "${tempLetter}:\Recovery\WindowsRE"
    New-Item -Path $recoveryRoot -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $BackupImage -Destination (Join-Path $recoveryRoot 'winre.wim') -Force

    $copiedHash = (Get-FileHash -LiteralPath (Join-Path $recoveryRoot 'winre.wim') -Algorithm SHA256).Hash
    if ($copiedHash -ne $backupHash) {
        Stop-Script 'The copied WinRE image SHA256 does not match the verified backup. Temporary drive letter was left in place for troubleshooting.'
    }

    Write-Log "Registering WinRE image on ${tempLetter}:."
    & reagentc.exe /setreimage /path $recoveryRoot /target C:\Windows | ForEach-Object { Write-Log "$_" }
    if ($LASTEXITCODE -ne 0) {
        Stop-Script "reagentc /setreimage failed with exit code $LASTEXITCODE. Temporary drive letter was left in place."
    }

    & reagentc.exe /enable | ForEach-Object { Write-Log "$_" }
    if ($LASTEXITCODE -ne 0) {
        Stop-Script "reagentc /enable failed with exit code $LASTEXITCODE. Temporary drive letter was left in place."
    }

    $finalInfo = (& reagentc.exe /info 2>&1 | Out-String)
    $expectedPartitionText = "partition$($newRecovery.PartitionNumber)"
    if ($finalInfo -notmatch '(?i)Enabled|有効' -or $finalInfo -notmatch [regex]::Escape($expectedPartitionText)) {
        Write-Log $finalInfo
        Stop-Script 'WinRE final verification did not confirm Enabled on the new Recovery partition. Temporary drive letter was left in place.'
    }
    Write-Log 'WinRE is enabled and points to the new Recovery partition.'

    # 7. Remove temporary drive letter only after successful WinRE verification.
    Remove-PartitionAccessPath -DiskNumber $diskNumber -PartitionNumber $newRecovery.PartitionNumber -AccessPath "${tempLetter}:\"
    Write-Log "Removed temporary drive letter ${tempLetter}:."

    # 8. Final summary.
    $finalC = Get-Volume -DriveLetter C
    $finalRecovery = Get-Partition -DiskNumber $diskNumber -PartitionNumber $newRecovery.PartitionNumber
    Write-Log ("SUCCESS. C: size={0:N2} GiB, free={1:N2} GiB. Recovery partition={2}, size={3:N2} GiB." -f ($finalC.Size/1GB), ($finalC.SizeRemaining/1GB), $finalRecovery.PartitionNumber, ($finalRecovery.Size/1GB))
    Write-Log '----- WinRE / C: expansion completed successfully -----'
    exit 0
}
catch {
    Write-Log $_.Exception.Message 'ERROR'
    Write-Log 'Script stopped. Review the log before retrying; do not manually delete or format additional partitions.' 'WARN'
    exit 1
}

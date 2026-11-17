#requires -Version 5.1
#requires -RunAsAdministrator
<#
Intune Remediations Detection Script for Windows 365 CPC C: / WinRE repair.
Exit 0 = no supported remediation needed (or layout is not safely identifiable).
Exit 1 = a known, supported repair condition was detected; run remediation script.

This script is read-only. It does not change partitions or WinRE configuration.
#>
$ErrorActionPreference = 'Stop'
$RecoveryGuid = 'de94bba4-06d1-4d40-a16a-bfd50179d6ac'
$LogDir = 'C:\ProgramData\CPC-WinRE-Repair'
$LogPath = Join-Path $LogDir 'Detection.log'

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

try {
    $c = Get-Partition -DriveLetter C
    $disk = Get-Disk -Number $c.DiskNumber
    if ($disk.PartitionStyle -ne 'GPT') {
        Write-DetectLog 'DETECTION=UNSUPPORTED; OS disk is not GPT. No automatic remediation.'
        exit 0
    }

    $parts = @(Get-Partition -DiskNumber $disk.Number | Sort-Object Offset)
    $info = Get-WinREInfo
    $enabled = Test-WinREEnabled $info
    $registered = Get-WinREPartition $info $disk.Number
    $afterC = @($parts | Where-Object {
        $_.Type -eq 'Recovery' -and $_.Offset -gt $c.Offset
    })
    $large = @($afterC | Where-Object { $_.Size -ge 2GB })

    if ($large.Count -eq 1) {
        $target = $large[0]
        $isLast = ($target.PartitionNumber -eq $parts[-1].PartitionNumber)
        $correctType = (-not $target.GptType) -or
            ($target.GptType.Trim('{}').ToLowerInvariant() -eq $RecoveryGuid)

        if (-not $isLast -or -not $correctType) {
            Write-DetectLog 'DETECTION=REVIEW_REQUIRED; large Recovery partition layout is not the expected CPC layout.'
            exit 0
        }

        $cEnd = [int64]$c.Offset + [int64]$c.Size
        $between = @($parts | Where-Object {
            $_.PartitionNumber -ne $c.PartitionNumber -and
            $_.PartitionNumber -ne $target.PartitionNumber -and
            $_.Offset -ge $cEnd -and $_.Offset -lt $target.Offset
        })
        if ($between.Count -gt 0) {
            Write-DetectLog 'DETECTION=REVIEW_REQUIRED; another partition exists between C: and Recovery. No automatic remediation.'
            exit 0
        }

        $supported = Get-PartitionSupportedSize -DriveLetter C
        $cNeedsExpansion = ($supported.SizeMax -gt ($c.Size + 1MB))
        $winreNeedsRepair = (-not $enabled) -or ($registered -ne $target.PartitionNumber)

        if ($cNeedsExpansion -or $winreNeedsRepair) {
            Write-DetectLog ("DETECTION=NEEDS_REMEDIATION; CNeedsExpansion={0}; WinREEnabled={1}; RegisteredPartition={2}; TargetPartition={3}" -f
                $cNeedsExpansion, $enabled, $registered, $target.PartitionNumber)
            exit 1
        }

        Write-DetectLog ("DETECTION=COMPLIANT; CSizeGiB={0:N2}; WinREEnabled=True; RecoveryPartition={1}" -f
            ($c.Size / 1GB), $target.PartitionNumber)
        exit 0
    }

    # Recognize only the known original layout: exactly one Recovery partition
    # after C:, it is the final partition, and reagentc points to that partition.
    if ($large.Count -eq 0 -and $afterC.Count -eq 1) {
        $old = $afterC[0]
        $isLast = ($old.PartitionNumber -eq $parts[-1].PartitionNumber)
        if ($isLast -and $registered -eq $old.PartitionNumber -and -not $old.DriveLetter) {
            Write-DetectLog ("DETECTION=NEEDS_REMEDIATION; original layout identified; OldWinREPartition={0}; WinREEnabled={1}" -f
                $old.PartitionNumber, $enabled)
            exit 1
        }
    }

    Write-DetectLog ("DETECTION=REVIEW_REQUIRED; unsupported or ambiguous layout. RecoveryAfterC={0}; LargeRecoveryAfterC={1}; RegisteredPartition={2}. No automatic remediation." -f
        $afterC.Count, $large.Count, $registered)
    exit 0
}
catch {
    Write-DetectLog ("DETECTION=ERROR; {0}; no automatic remediation." -f $_.Exception.Message)
    exit 0
}

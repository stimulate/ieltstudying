
try {
    $partitions = Get-Partition -DiskNumber 0 -ErrorAction Stop

    $result = $partitions | ForEach-Object {
        "PartitionNumber=$($_.PartitionNumber), DriveLetter=$($_.DriveLetter), Type=$($_.Type), Size=$([math]::Round($_.Size / 1GB, 2))GB, Offset=$([math]::Round($_.Offset / 1GB, 2))GB"
    }

    Write-Output ($result -join "; ")

    exit 0
}
catch {
    Write-Output "ERROR: $($_.Exception.Message)"
    exit 1
}



Write-Output "===== DISK AUDIT START ====="

$disks = Get-Disk -ErrorAction SilentlyContinue

foreach ($disk in $disks) {

    Write-Output ""
    Write-Output "===== DISK $($disk.Number) ====="
    Write-Output "Model: $($disk.FriendlyName)"
    Write-Output "Size: $([math]::Round($disk.Size / 1GB, 2)) GB"
    Write-Output "Partition Style: $($disk.PartitionStyle)"
    Write-Output "Operational Status: $($disk.OperationalStatus)"

    try {
        $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction Stop

        if (-not $partitions) {
            Write-Output "No partitions returned."
        }

        foreach ($p in $partitions) {

            Write-Output ""
            Write-Output "--- Partition $($p.PartitionNumber) ---"
            Write-Output "Drive Letter: $($p.DriveLetter)"
            Write-Output "Type: $($p.Type)"
            Write-Output "Size: $([math]::Round($p.Size / 1GB, 2)) GB"
            Write-Output "Offset: $([math]::Round($p.Offset / 1GB, 2)) GB"
            Write-Output "Is Hidden: $($p.IsHidden)"
            Write-Output "Is System: $($p.IsSystem)"
            Write-Output "Is Boot: $($p.IsBoot)"

            try {
                $volumes = $p | Get-Volume -ErrorAction Stop

                foreach ($v in $volumes) {
                    Write-Output "FileSystem: $($v.FileSystem)"
                    Write-Output "Volume Size: $([math]::Round($v.Size / 1GB, 2)) GB"
                    Write-Output "Free Space: $([math]::Round($v.SizeRemaining / 1GB, 2)) GB"
                }
            }
            catch {
                Write-Output "Volume query failed: $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Output "Partition query failed: $($_.Exception.Message)"
    }
}

Write-Output ""
Write-Output "===== DISK AUDIT END ====="

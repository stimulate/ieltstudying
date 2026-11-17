$disks = Get-Disk

foreach ($disk in $disks) {
    Write-Output "Disk: $($disk.Number)"
    Write-Output "Size: $([math]::Round($disk.Size / 1GB, 2)) GB"

    Get-Partition -DiskNumber $disk.Number |
    ForEach-Object {
        Write-Output "Partition: $($_.PartitionNumber)"
        Write-Output "Drive: $($_.DriveLetter)"
        Write-Output "Size: $([math]::Round($_.Size / 1GB, 2)) GB"
    }
}

exit 0

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


Write-Output "===== CPC DISK AUDIT ====="
Write-Output "Computer: $env:COMPUTERNAME"
Write-Output "User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"

# 1. CIM Physical Disks
Write-Output "`n===== CIM DISKS ====="

try {
    Get-CimInstance Win32_DiskDrive -ErrorAction Stop |
    ForEach-Object {
        Write-Output "Disk Index: $($_.Index)"
        Write-Output "Model: $($_.Model)"
        Write-Output "Size GB: $([math]::Round($_.Size / 1GB, 2))"
        Write-Output "Partitions: $($_.Partitions)"
    }
}
catch {
    Write-Output "CIM Disk Error: $($_.Exception.Message)"
}

# 2. CIM Partitions
Write-Output "`n===== CIM PARTITIONS ====="

try {
    Get-CimInstance Win32_DiskPartition -ErrorAction Stop |
    ForEach-Object {
        Write-Output "Disk Index: $($_.DiskIndex)"
        Write-Output "Partition: $($_.Index)"
        Write-Output "Name: $($_.Name)"
        Write-Output "Type: $($_.Type)"
        Write-Output "Size GB: $([math]::Round($_.Size / 1GB, 2))"
        Write-Output "Offset GB: $([math]::Round($_.StartingOffset / 1GB, 2))"
    }
}
catch {
    Write-Output "CIM Partition Error: $($_.Exception.Message)"
}

# 3. Logical Disks
Write-Output "`n===== LOGICAL DISKS ====="

try {
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    ForEach-Object {
        Write-Output "Drive: $($_.DeviceID)"
        Write-Output "Size GB: $([math]::Round($_.Size / 1GB, 2))"
        Write-Output "Free GB: $([math]::Round($_.FreeSpace / 1GB, 2))"
    }
}
catch {
    Write-Output "Logical Disk Error: $($_.Exception.Message)"
}

Write-Output "`n===== AUDIT COMPLETE ====="
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

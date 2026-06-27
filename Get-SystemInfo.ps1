<#
.SYNOPSIS
  Collects basic information from a Windows PC
.DESCRIPTION
    Gathers the computer name, OS version, uptime in days, CPU, total ram in GB
    and the logged-in user into a single object. By default the information is displayed on
    screen; with -ExportCsv it is also saved to a CSV.
.PARAMETER ExportCsv
    When specified, it will export the collected information to a CSV file named SystemInfo_<ComputerName>.csv
    in the current folder instead of only displaying it on the screen.
.EXAMPLE
    Get-SystemInfo
    Displays system information for the local computer on screen.
    Get-SystemInfo -ExportCsv
    Collects system information and saves it to a CSV in the current folder
#>
function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [switch]$ExportCsv
    )
 #BY CHRIS KONTOULIS
    try {
        Write-Verbose "Starting system info collection on $env:COMPUTERNAME"
        Write-Verbose "Collecting Operating System info..."
        $os = Get-CimInstance Win32_OperatingSystem

        Write-Verbose "Collecting Computer System info..."
        $cs = Get-CimInstance Win32_ComputerSystem

        Write-Verbose "Collecting Processor Info..."
        $cpu = Get-CimInstance Win32_Processor

        $disks = Get-CimInstance Win32_LogicalDisk
        $diskSummary = ($disks | ForEach-Object {
            "$($_.DeviceID) $([math]::Round($_.FreeSpace/1GB,1))GB free of $([math]::Round($_.Size/1GB,1))GB"
        
        }) -join '; '  #this part above just flattens the drive info into one readable string, i did this because the CSV export does not store the nested disk objects cleanly
        
        $info = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            OSVersion    = $os.Caption
            UptimeDays   = (((Get-Date) - $os.LastBootUpTime).Days)
            CPU          = $cpu.Name
            RAM_GB       = [math]::Round($cs.TotalPhysicalMemory/1GB, 1)
            Disks        = $diskSummary
            LoggedInUser = $env:USERNAME
        }

        if ($ExportCsv) {
            $path = "SystemInfo_$($info.ComputerName).csv"
            $info | Export-Csv -Path $path -NoTypeInformation
            Write-Output "Saved report to $path"

        }
        else {
            $info
        }
        
    }
    catch {
        Write-Error "Failed to collect system info: $($_.Exception.Message)"
    }
}


Get-SystemInfo
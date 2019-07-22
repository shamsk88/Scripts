
<# This Script works only on windows server 2008 R2 and above*
# Powershell Version should be 2.0 and above*
-----------------------------------------------------------------#>
cls

$logFile="C:\supportfiles\logs\SANMigration.txt"

# To get Computer Name

$computername=$env:COMPUTERNAME

# To get Disk Information

$diskinfo=Get-WmiObject -Class win32_Logicaldisk | select DeviceID,volumename,@{Name="Size (GB)";Expression={"{0:N2}" -f ($_.Size / 1GB)}}, @{Name="FreeSpace(GB)";Expression={"{0:N2}" -f ($_.FreeSpace / 1GB)}} | Format-Table -AutoSize

# To Display High Level HBA I/O Paths & attached LUN's

$Fileexists=Test-Path "C:\Program Files\EMC\PowerPath\powermt.exe"
if($Fileexists -eq $true)
  {
    write-output "EMC Powerpath is present n $computername" | Out-File $logFile -Append

    $HBApath=powermt display
}
    else
    {
    Write-Output "EMC PowerPath doesn't found on $computername" | Out-File $logFile -Append
    exit 10 
    }

# To Display all attached LUN's

$HBALun=powermt display dev=all

# To check HBA Dead Path

foreach($item in $HBALun)
{
 if($HBALun -match 'state=dead')
  {
  Write-Output "PowerPath configuration has Dead Path to be removed" | Out-File $logFile -Append
  Exit 13 
  }
}
    Write-Output "PowerPath configuration has  no Dead Path to be removed" | Out-File $logFile -Append

 
# To save the output 

$computername,$diskinfo,$HBApath,$HBALun | Out-File $logFile -Append

# Script block for cluster servers

if ((Get-Service -DisplayName 'Cluster Service').status -eq "running" )

 { 
    
    Import-Module Failoverclusters

# To get clustergroup, clusterresource, disksignature,DiskIDGuid status & information

    Get-ClusterResource | Out-File $logFile -Append

    Get-ClusterGroup | Out-File $logFile -Append

    Get-ClusterResource | Where {$_.ResourceType.Name -eq "Physical Disk"} |Get-ClusterParameter -Name "DiskSignature","DiskIDGuid"  | Format-Table -AutoSize | Out-File $logFile -Append

#$resourcestatus= cluster resource /status
#Write-Output $resourcestatus | Out-File Out-File $logFile -Append

    Set-Service -Name clussvc -StartupType Manual
    Stop-Service -DisplayName 'Cluster Service'
    Write-Output "Cluster Service is stopped on $computername" |  Out-File $logFile -Append
}

else
    {
    Write-Output "Not able to stop the cluster service on $computername" | Out-File $logFile -Append
    exit 11
    }
Get-Date |Add-Content $logfile

# Exit 10 --> EMC PowerPath doesn't found on server
# Exit 11 --> Not able to stop the cluster service on server.
# Exit 12 --> PowerPath configuration has Dead Path to be removed
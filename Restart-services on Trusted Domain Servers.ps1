cls
$Computers = get-content C:\temp\Serverlist.txt
$Services = Get-Content C:\temp\services.txt
foreach ($computer in $computers)
 {
   foreach($service in $Services)
   {
   if(($Servicestatus.Status -match "Started") -or ($Servicestatus.Status -match "Stopped"))
   {
     Restart-Service -DisplayName $service
     sleep 5
     }

   <#$Servicestatus = Get-Service -DisplayName $Service -ComputerName $computer | select DisplayName,status,MachineName
      if($Servicestatus.Status -match "Stopped")
      {
        Start-Service $Service
        sleep 5
      }
      elseif(($Servicestatus.Status -match "Starting") -or ($Servicestatus.Status -match "Stopping"))
      {
        Stop-Service $service -Force
        sleep 5
        Start-Service $Service
      }#>
        $Serviceresult=Get-Service -DisplayName $Service -ComputerName $computer | select DisplayName,status,MachineName 

      $Serviceresult| Export-Csv -NoTypeInformation  C:\temp\result.csv -Append 
   }
       
}
 

<#

NAME:     addGroup2LPU.ps1

AUTHOR:   Shamsher Khan - Associate Tech Lead - Refinitiv

COMMENT:  This script to do Pre-check task on SAN Migration

DEPENDENCY REQUIREMENTS:  Powershell 2.0 and up, Windows Server 2008R2 and up

-----------------------------------------------------------------#>
cls

Function Get-CurrentLineNumber () {
	$MyInvocation.ScriptLineNumber
}
Function VerifyLogDir () {
	Write-Host "[$Now] Verifying existance of [C:\Supportfiles\Logs]"
	If (test-path C:\Supportfiles\Logs){
		Write-Host "[$Now] C:\Supportfiles\Logs exists, bypassing creation"
	}Else{
	  Write-Host "[$Now] C:\Supportfiles\Logs does not exist, creating..."
		New-Item C:\Supportfiles\Logs -type directory
	}
}
Function Start-Log () {
	#Start Transcript Logging
	#------------------------
	Write-Host "[$Now] Initiating Logging Engine..." -NoNewline
	Try {
		$Transcript_Start = Start-Transcript -Path $LogFile -Append:$false -Confirm:$false
    If ($Transcript_Start -like 'Transcript started*'){
      Write-Host "Start Transcript Logging : SUCCESS"
    }
    Else{
      Write-Host "Start Transcript Logging: FAILURE"
    }
	}
	Catch [System.Exception]{
		Write-Host "FAILURE"
		Write-Host "  EXCEPTION:" $_
		Log-Cleanup-and-Exit "Line($(Get-CurrentLineNumber)): Starting transcription logging failure" 10
	}
}

Function Stop-Log () {
	#Start Transcript Logging
	#------------------------
	Write-Host "[$Now] Stopping Logging..." -NoNewline
	Try {
		$Transcript_Stop = Stop-Transcript 
    If ($Transcript_Stop -like 'Transcript stopped*'){
      Write-Host "Stopping Logging: SUCCESS"
    }
    Else{
      Write-Host "Stopping Logging: FAILURE"
    }
	}
	Catch [System.Exception]{
		Write-Host "FAILURE"
		Write-Host "  EXCEPTION:" $_
		Log-Cleanup-and-Exit "Line($(Get-CurrentLineNumber)): Stopping transcription logging failure" 11
	}
}

Function diskinfo()
{
# To get Disk Information

$diskinfo=Get-WmiObject -Class win32_Logicaldisk | select DeviceID,volumename,@{Name="Size (GB)";Expression={"{0:N2}" -f ($_.Size / 1GB)}}, @{Name="FreeSpace(GB)";Expression={"{0:N2}" -f ($_.FreeSpace / 1GB)}} | Format-Table -AutoSize 
$diskinfo
}

# To check HBA Dead Path & Display all attached LUN's

Function HBADeadPath()
{
   $HBALun=powermt display dev=all
   $HBALun
    foreach($item in $HBALun)
      { 
        if($HBALun -match 'state=dead')
            {
              Write-Host "FAILURE"
              Log-Cleanup-and-Exit "PowerPath configuration has Dead Path to be removed" 13
            }
      }
 Write-Output "PowerPath configuration has no Dead Path to be removed" 
}

# To Display High Level HBA I/O Paths & attached LUN's

Function EMCPowerPathCheck()
{

    $Fileexists=Test-Path "C:\Program Files\EMC\PowerPath\powermt.exe"
        if($Fileexists -eq $true)
            {
             Write-Host "Checking EMC Powerpath..."
             Write-Host "SUCCESS: EMC Powerpath is present on $global:Computer" 
             $HBApath=powermt display
             $HBApath
            }
        else
           {
            Write-Host "FAILURE :EMC PowerPath doesn't found on $global:Computer"
            Log-Cleanup-and-Exit "EMC PowerPath doesn't found on $global:Computer" 10
           }
}

Function Log-Cleanup-and-Exit ($outcome,$rc) {
  $ScriptName = 'Trend1'
  $Line2 = "-"*25 + ' ' + $ScriptName + ' Results ' + "-"*25
  $Line7 = "-"*$Line2.length
	Write-Host ""
  Write-Host $Line2
	Write-Host ""
	Write-Host "  Result: " -NoNewline
	Write-Host "$outcome"
	Write-Host ""
  Write-Host $Line7
  If ($Host.Name -notlike '*PowerGUI*'){
		#---------------
		#Stop Transcript
		#---------------
		Write-Host "[$Now] Stopping Logging..." -NoNewline 
		Try {
			$ResultText_Transcript = Stop-Transcript
		  If ($ResultText_Transcript -like 'Transcript stopped*'){
		    Write-Host "SUCCESS"
		  }
		  Else{
		    Write-Host "FAILURE"
		  }
		}
		Catch [System.Exception]{
			Write-Host "FAILURE"
			Write-Host "  EXCEPTION:" $_
		}
		#---------------------
		#Update Log Formatting
		#---------------------
		Write-Host "[$Now] Updating the format of the Log File..." -NoNewline
		Try {
		  [string]::join("`r`n",(Get-Content $global:LogFile)) | Out-File $global:LogFile
			Write-Host "SUCCESS"
		}
		Catch [System.Exception]{
			Write-Host "FAILURE"
			Write-Host "  EXCEPTION:" $_
		}
 		Write-Host "[$Now] Updating the Log File type..." -NoNewline
		Try {
		  Set-Content $global:LogFile -Encoding ASCII -Value (Get-Content $global:LogFile)
			Write-Host "SUCCESS"
		}
		Catch [System.Exception]{
			Write-Host "FAILURE"
			Write-Host "  EXCEPTION:" $_
		}
	}
	Exit $rc
}
<#
    ______          __   ______                 __  _                 
   / ____/___  ____/ /  / ____/_  ______  _____/ /_(_)___  ____  _____
  / __/ / __ \/ __  /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
 / /___/ / / / /_/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  ) 
/_____/_/ /_/\__,_/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/  
#>           

Clear-Host
$global:sw = [Diagnostics.Stopwatch]::StartNew()
$WhereAmI = Split-Path $MyInvocation.MyCommand.Definition
$global:Now = Set-PSBreakpoint -Variable Now -Mode Read -Action { $global:Now = Get-Date }
$global:LogFile = 'c:\Supportfiles\Logs\Sanprecheck.log'
$global:Computer = $env:computername.ToUpper()
#

VerifyLogDir
If ($Host.Name -notlike '*PowerGUI*'){
  Start-Log
}
diskinfo
HBADeadPath
EMCPowerPathCheck
Log-Cleanup-and-Exit "SUCCESS" 0
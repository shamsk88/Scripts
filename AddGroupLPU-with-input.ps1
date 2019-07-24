<#
NAME:     addGroup2LPU.ps1

AUTHOR:   Shamsher Khan - Associate Tech Lead - Refinitiv

COMMENT:  This script adds passed domain\group to LAG
DEPENDENCY REQUIREMENTS:  Powershell 2.0 and up, Windows Server 2008R2 and up

VERSION HISTORY:
	VERSION HISTORY:
	1.0 	07/24/2019 - Need to Input the group name need to be add in Local Power Users 
   

NOTES:
#>
#requires -Version 2.0
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
	Try {
		$ResultText_Transcript_Start = Start-Transcript -Path $global:LogFile -Append:$false -Confirm:$false
  	Write-Host "[$Now] Begin Group Add"
  	Write-Host "[$Now] Initiating Logging Engine..." -NoNewline
    If ($ResultText_Transcript_Start -like 'Transcript started*'){
      Write-Host "SUCCESS"
    }
    Else{
      Write-Host "FAILURE"
    }
	}
	Catch [System.Exception]{
		Write-Host "FAILURE"
		Write-Host "  EXCEPTION:" $_
		LogCleanupandExit "Starting transcription logging failed." 1
	}
}
Function Add2LPU ($domain,$group){
  $Error.clear()
  $domainGroup = $domain + "/" + $group
  Write-Host "[$Now] Adding $domainGroup to local Power Users group on $Computer..." -NoNewline
  $AdminGroup = [ADSI]"WinNT://$Computer/Power Users"
  $ErrorActionPreference = 'SilentlyContinue'
  $AdminGroup.add("WinNT://$domainGroup")
  $ErrorActionPreference = 'Continue'
  If (($Error.Count -eq 0) -or ($Error -match 'is already a member of the group')){
  	Write-Host "SUCCESS"
    #Write-Host "[$Now]"
  }
  Else{
  	Write-Host "FAILURE"
    #Write-Host "[$Now]"
  	LogCleanupandExit "Failed to add group $domainGroup to local Power Users group" 2
  }

}
Function GetDomainForLPUAdd (){
  Write-Host "[$Now] Determining what domain to get the new group from"
  $DomainComputer = [ADSI]"WinNT://$env:computername"
  $DomainComputerMemberOf = ($DomainComputer).parent.split("//")[2].ToLower()
  Write-Host "[$Now] This computer is a member of the $DomainComputerMemberOf domain"
  Switch ($DomainComputerMemberOf){
    abacus-app { Return 'MGMT'}
    abacus-qa { Return 'MGMT'}
    amers { Return 'TLR'}
    clrrs { Return 'MGMT'}
    cw-qa { Return 'MGMT'}
    cw { Return 'CW'}
    ecom { Return 'MGMT'}
    ecomqc { Return 'MGMT'}
    elitecorp { Return 'TLR'}
    emea { Return 'TEN'}
    epropertytax { Return 'MGMT'}
    erf { Return 'TEN'}
    erfqc { Return 'TENPPE'}
    h1ecom { Return 'MGMT'}
    intprod { Return 'MGMT'}
    intqa { Return 'MGMT'}
    lhtrp { Return 'MGMT'}
    lhtrqa { Return 'MGMT'}
    mgmt { Return 'MGMT'}
    mgmtqa { Return 'MGMT'}
    mgmtsec { Return 'MGMT'}
    portal-uk { Return 'MGMT'}
    portalqa-uk { Return 'MGMT'}
    taxstream { Return 'MGMT'}
    ten { Return 'TEN'}
    tenppe { Return 'TENPPE'}
    tfcorp { Return 'TLR'}
    tfprod { Return 'MGMT'}
    tft1core { Return 'MGMT'}
	tft1coreqa { Return 'MGMT'}
    tip { Return 'MGMT'}
    tipqa { Return 'MGMT'}
    tlr { Return 'TLR'}
    tlrqa { Return 'TLR'}
    tz { Return 'TZ'}
    tztst { Return 'MGMT'}
    default { Return 'OOPS'}
  }
}
Function LogCleanupandExit ($outcome,$rc) {
  $ScriptName = 'addGroup2LPU'
  $Line2 = "-"*25 + ' ' + $ScriptName + ' Results ' + "-"*25
  $Line7 = "-"*$Line2.length
	Write-Host ""
  Write-Host $Line2
	Write-Host ""
	Write-Host "  Result..." -NoNewline
	Write-Host "$outcome"
	Write-Host ""
  Write-Host $Line7
  $sw.Stop()
  $Hours = $sw.Elapsed.Hours
  $Minutes = $sw.Elapsed.Minutes
  $Seconds = $sw.Elapsed.Seconds
  $Milliseconds = $sw.Elapsed.Milliseconds
  Write-Host "[$Now] Total elapsed time in Hours: $Hours, Minutes: $Minutes, Seconds: $Seconds, Milliseconds: $Milliseconds"
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
    #-------------------------------------------------
		#Removing CRLF that KB3000850/KB3014136 introduced
    #-------------------------------------------------
    if($PSVersionTable.Psversion.Major -gt 2)
	{
		(Get-Content $global:LogFile).Replace("...`r`n","...") | Set-Content $global:LogFile -Force
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
$global:LogFile = 'c:\Supportfiles\Logs\addGroup2LPU.log'
$global:Computer = $env:computername.ToUpper()
#
Write-Host $args[0]
VerifyLogDir
If ($Host.Name -notlike '*PowerGUI*'){
  Start-Log
}
$domain2use = GetDomainForLPUAdd
If ($domain2use -eq 'OOPS'){
  LogCleanupandExit "$Computer is in a domain this script does not support" 3
}
Write-Host "[$Now] For $Computer, we will look in $domain2use for group to add"
if($args[0] -eq $null)
{
LogCleanupandExit "Invalid Input Passed Please Input the correct group name need to be added " 4
}
Add2LPU $domain2use $args[0]
Write-Host "[$Now] Contents of local Power Users group after update"
$localadmins = net localgroup "Power Users" | Select-Object -Skip 5
[string]::join("`r`n[$Now] ",$localadmins)
#
LogCleanupandExit "SUCCESS" 0

# VARIABLES
$arrayIP = "172.16.0.29"
 
######################################################################################################################################################
#  0. Create report information
######################################################################################################################################################
#Creating report filename
$Invocation     = (Get-Variable MyInvocation -Scope 0).Value
$rootpath       = Split-Path $Invocation.MyCommand.Path
$datetime       = "{0:yyyyMMdd_HHmm}" -f (Get-Date)
$reportfilepath =  ($($Invocation.MyCommand).Name).TrimEnd(".ps1")
$reportfilepath = "$rootpath\Reports\$reportfilepath-$datetime.txt"
 
#Initialise Report
$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path $reportfilepath -append | Out-Null
 
######################################################################################################################################################
#  1. Connect to Pure Storage Array 
######################################################################################################################################################
Write-Host "*******************************************************************************************************"
Write-Host " Eradicate ALL destroyed volumes v1.0"
Write-Host " ---"
Write-Host " Find and remove any volumes that are currently in the recycle bin (pending eradication)"
Write-Host "*******************************************************************************************************"
Write-Host "`n1. Connect to Pure Storage array [$arrayIP]"
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
#Get authentication
$Creds = Get-Credential
#Connect to array
$FlashArray = New-PfaArray -EndPoint $arrayIP -Credentials $Creds -IgnoreCertificateError
#Get controller information
Get-PfaControllers -Array $FlashArray
$Controllers = Get-PfaControllers –Array $FlashArray
 
######################################################################################################################################################
#  2. Get pending volumes and snapshots 
######################################################################################################################################################
Write-Host "2. Get list of volumes that are in `"pending`" state."
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
$pendingvolumelist = Get-PfaPendingDeleteVolumes -Array $FlashArray
$pendingsnaplist = Get-PfaPendingDeleteVolumeSnapshots -Array $FlashArray

######################################################################################################################################################
#  3. List all volumes and snapshots to be removed 
######################################################################################################################################################
Write-Host "3. Listing `"PENDING`" volumes and snapshots that exist on the array."
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
Write-Host "VOLUMES IN PENDING STATE"
foreach ($volume in $pendingvolumelist){
    Write-Host " -" $volume.name
}
Write-Host "SNAPSHOTS IN PENDING STATE"
foreach ($volumesnap in $pendingsnaplist){
    Write-Host " -" $volumesnap.name
}

######################################################################################################################################################
#  4. Get user confirmation to proceed. 
######################################################################################################################################################
$confirmstring = "Proceed"
Write-Host "`n4. Please confirm that you wish to proceed."
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
Write-Host "Please type `"$confirmstring`" to eardicate the pending deleted volumes & snapshots."
Write-Host "The action will initiate immediately upon inputting $confirmstring" -fore yellow
$user_response = Read-Host "`t"
if (($user_response.ToLower() -ne $confirmstring.ToLower())){
    Write-Host "Your input was [$user_response].`nNothing will be done.`nThe program will now close.`n"
    Stop-Transcript | Out-Null
    exit
}
######################################################################################################################################################
#  5. Now delete stuff. 
######################################################################################################################################################
Write-Host "5. Eradicating `"PENDING`" volumes and snapshots."
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
Write-Host "VOLUMES IN PENDING STATE"
foreach ($volume in $pendingvolumelist){
    Write-Host " -" $volume.name
    Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $volume.name -Eradicate
}
Write-Host "SNAPSHOTS IN PENDING STATE"
foreach ($volumesnap in $pendingsnaplist){
    Write-Host " -" $volumesnap.name
    Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name $volumesnap.name -Eradicate
}

######################################################################################################################################################
Write-Host "`n`rThe script will now exit."
 
#End report
Stop-Transcript | Out-Null

# Version v3.1
# Changes - Added two-way updating and confirmation for updates.

# VARIABLES
$arrayIP = "172.16.0.29"
$pgroupname = "dummy-pg"
$suffix = "_backup" 
 
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
Write-Host " Snap Volume Copy Script - v3.1"
Write-Host " ---"
Write-Host " Overwrite volumes from the latest snapshot in the protection group [$pgroupname]"
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
#  2. Get snapshots accosiated to the selected p group.
######################################################################################################################################################
Write-Host "2. Get latest snap from $pgroupname"
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
$pgroupsnap = (Get-PfaProtectionGroupSnapshots -Array $FlashArray -Name $pgroupname)[-1]
echo $pgroupsnap
 
######################################################################################################################################################
#  3. Get volumes from snapshots 
######################################################################################################################################################
Write-Host "3. Get list of volumes from latest (complete) snapshot"
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
$volumelist = ((Get-PfaProtectionGroupVolumeSnapshots -Array $FlashArray -Name $pgroupname).name | Select-String $pgroupsnap.name).Line
echo $volumelist
$snapshot = $pgroupsnap.name

######################################################################################################################################################
#  4. Get user confirmation 
######################################################################################################################################################
$sourceoverwritestring = "IAmGoingToOverwriteTheSourceVolumes"
$backupoverwritestring = "DR"
$examplesourcevolfull = $volumelist[0]
$examplesourcevol = $examplesourcevolfull -replace ".*$snapshot."

Write-Host "`n4. User confirmation to initiate."
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
Write-Host "The listed snapshot volumes above will be used to update/overwrite the volumes."
Write-Host "Please type your preference (below), or type anything else to exit."
Write-Host "Producuction`tTo update/overwrite the data in the production volumes, type `"$sourceoverwritestring`""
$examplevol = $examplesourcevol -replace "$suffix.*"
Write-Host "`t`t`t`t eg. [$examplesourcevolfull] -> [$examplevol]" -fore darkgray
Write-Host "DR`t`t`t`tTo update/overwrite the data in the DR volumes, type `"$backupoverwritestring`""
$examplevol = $examplesourcevol + $suffix
Write-Host "`t`t`t`t eg. [$examplesourcevolfull] -> [$examplevol]" -fore darkgray
Write-Host "The action will initiate immediately upon inputting your selection." -fore yellow
$user_response = Read-Host "`t"
if (($user_response.ToLower() -ne $backupoverwritestring.ToLower()) -and ($user_response.ToLower() -ne $sourceoverwritestring.ToLower())){
    Write-Host "Your input was [$user_response].`nThat is not a valid option.`nThe program will now close.`n"
    Stop-Transcript | Out-Null
    exit
}
Write-Host "You have selected [$user_response]. Executing volume update/overwrites.`n"

######################################################################################################################################################
#  5. Overwrite volumes from snap volume 
######################################################################################################################################################
Write-Host "5. Overwrite the target volume from the latest snapshot..."
Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
$volcount = $volumelist.Length
$count = 0
foreach ($sourcevolume in $volumelist)
{
    $count++
    if ($user_response -eq $backupoverwritestring){
        $destinationvolume = $sourcevolume.replace("$snapshot.","") + $suffix
    }
    else
    {
        $destinationvolume = $sourcevolume -replace ".*$snapshot." -replace "$suffix.*" 
    }
    Write-Host "VOL#[$count]: Updating [$destinationvolume] from [$sourcevolume]"
    New-PfaVolume -Array $FlashArray -Source $sourcevolume -VolumeName $destinationvolume -Overwrite
    Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------`n"
}
######################################################################################################################################################
Write-Host "`n`rThe script will now exit."
 
#End report
Stop-Transcript | Out-Null

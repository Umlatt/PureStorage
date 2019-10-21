************************************************************************************************************************************************************************************************************************************************************
 
# VARIABLES
$arrayIP = "172.16.0.29"
$hostgroupname = "delete-me"
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
echo "*******************************************************************************************************"
echo " Snap Volume Copy Script - v2.1"
echo " ---"
echo " Copy volumes from latest snapshot in protection group [$pgroupname] and attach to [$hostgroupname]"
echo "*******************************************************************************************************"
echo "1. Connect to Pure Storage array [$arrayIP]"
#Get authentication
$Creds = Get-Credential
#Connect to array
$FlashArray = New-PfaArray -EndPoint $arrayIP -Credentials $Creds -IgnoreCertificateError
#Get controller information
Get-PfaControllers -Array $FlashArray
$Controllers = Get-PfaControllers –Array $FlashArray
echo $Controllers
 
######################################################################################################################################################
#  2. Connect to Pure Storage Array 
######################################################################################################################################################
echo "2. Get latest snap from $pgroupname"
$pgroupsnap = (Get-PfaProtectionGroupSnapshots -Array $FlashArray -Name $pgroupname)[-2]
echo $pgroupsnap
 
######################################################################################################################################################
#  3. Get volumes from snapshots 
######################################################################################################################################################
echo "3. Get list of volumes from latest (complete) snapshot"
$volumelist = ((Get-PfaProtectionGroupVolumeSnapshots -Array $FlashArray -Name $pgroupname).name | Select-String $pgroupsnap.name).Line
echo $volumelist
 
######################################################################################################################################################
#  4. Overwrite volumes from snap volume 
######################################################################################################################################################
echo "4. Overwrite the target volume from the latest snapshot..."
$volcount = $volumelist.Length
$snapshot = $pgroupsnap.name
$hostgroupvolumes = Get-PfaHostGroupVolumeConnections -Array $FlashArray -HostGroupName $hostgroupname
foreach ($sourcevolume in $volumelist)
{
    echo "-----------------------------------------------------------------------------------------------------------------------------------------`n"
    $destinationvolume = $sourcevolume.replace("$snapshot.","") + $suffix
    echo "STEP1: Updating [$destinationvolume] from [$sourcevolume]"
    New-PfaVolume -Array $FlashArray -Source $sourcevolume -VolumeName $destinationvolume -Overwrite
    
    echo "STEP2: Attaching [$destinationvolume] to [$hostgroupname]"
    echo "Checking if volume already connected to host group."
    if ($hostgroupvolumes.vol.Contains($destinationvolume)){
       echo "Volume is already connected. No action needed." 
    }
    else {
        echo "Volume is not connected to host group. Connecting volume now."
        New-PfaHostGroupVolumeConnection -Array $FlashArray -HostGroupName $hostgroupname -VolumeName $destinationvolume
    }
}
 
######################################################################################################################################################
echo "`n`rProcess complete.`n`rThe script will now exit."
 
#End report
Stop-Transcript | Out-Null

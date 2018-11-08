#Initialise script
cls
Write-Host "**************************************************************"
Write-Host "  Best practice check - v1.3 - Windows 2012 r2 (3 October 2018)"
Write-Host "**************************************************************"
 
 
#Check Logical Disk Manager and Partition Alignment
#Get-WmiObjectWin32_DiskPartition -ComputerName $env:COMPUTERNAME | select Name, Index, BlockSize, StartingOffset | Format-Table 
 
Write-Host "NOTE"
Write-Host "`t[INFO] There may be additional best practice information for the following technologies, which are not checked with this tool yet: " -ForegroundColor Gray
Write-Host "`t-File service technology (SMB, NFS...)" -ForegroundColor Gray
Write-Host "`t-Hyper-V Services" -ForegroundColor Gray
Write-Host "`t-Hyper-V Network Virtualization (not storage specfic but may improve reliability)" -ForegroundColor Gray
Write-Host "`t-Remote Desktop Services" -ForegroundColor Gray
Write-Host "`t-Clustered environment (if this host is part of a clustered environment)" -ForegroundColor Gray
 
#Check for hotfixes
Write-Host "`n`r1. HOTFIXES"
$hotfixlist = Get-WmiObject -Class Win32_QuickFixEngineering | Select-Object -Property HotFixID
if ($hotfixlist -match "KB3185279" -ne "") {Write-Host "`t[OK] Rollup KB3185279 is installed." -ForegroundColor Green}
else {Write-Host "`t[NOT OK] Please install windows KB3185279 (or confirm that it is contained in a newer installed Windows KB)." -ForegroundColor Yellow } 
if ($hotfixlist -match "KB3185279" -ne "") {Write-Host "`t[OK] Rollup KB2995388 is installed." -ForegroundColor Green}
else {Write-Host "`t[NOT OK] Please install windows KB2995388 (or confirm that it is contained in a newer installed Windows KB)." -ForegroundColor Yellow }
 
#Check for SSD TRIM
Write-Host "`n`r2. SSD TRIM"
if (fsutil behavior query disabledeletenotify -eq "DisableDeleteNotify = 0") {Write-Host "`t[OK] SSD Trim is enabled" -ForegroundColor Green}
else {Write-Host "`t[NOT OK] SSD Trim seems to be disabled. Please check that it is enabled, or an equivalent feature is enabled." -ForegroundColor Red}
 
#Check that the multipathing feature and Pure driver is enabled
Write-Host "`n`r3. Multipathing"
if ((Get-WindowsFeature -Name "Multipath-IO").InstallState -eq "Installed") {
    Write-Host "`t[OK] The MPIO feature is installed." -ForegroundColor Green
    if ((Get-MSDSMSupportedHW).VendorId -eq "PURE") {Write-Host "`t[OK] The Pure storage MPIO driver is available." -ForegroundColor Green}
    else {Write-Host "`t[NOT OK] The Pure storage MPIO driver needs to be installed." -ForegroundColor Red}
}
else { Write-Host "`t[NOT OK] The MPIO feature is not installed. Please install it." -ForegroundColor Red }
Write-Host "`t*Please ensure that all other (non-generic windows) multipathing drivers are uninstalled (i.e. EMC's powerpath)" -ForegroundColor Gray
 
#Check the SAN policy
Write-Host "`n`r4. Disk Online Policy"
if ((Get-StorageSetting).NewDiskPolicy -eq "OnlineAll") {Write-Host "`t[OK] The disk policy is set to online all." -ForegroundColor Green}
else {Write-Host "`t[NOT OK] Please set the disk policy to OnlineAll (Set-StorageSetting -NewDiskPolicy OnlineAll)" -ForegroundColor Red}
 
#Check MPIO settings 
Write-Host "`n`r5. MPIO Settings"
if (Get-MPIOSetting -NewPathRecoveryInterval -eq 20){ Write-Host "`t[OK] NewPatheRecoveryInterval is 20" -ForegroundColor Green}
else {Write-Host "`t[NOT OK] NewPatheRecoveryInterval is not 20 (Set-MPIOSetting -NewPathRecoveryInterval 20)" -ForegroundColor Red}
if (Get-MPIOSetting -CustomPathRecovery -eq Enabled){Write-Host "`t[OK] CustomerPathRecovery is Enabled" -ForegroundColor Green}
else {Write-Host "`t[NOT OK] CustomPathRecovery is not enabled (Set-MPIOSetting -CustomPathRecovery Enabled)" -ForegroundColor Red}
if (Get-MPIOSetting -NewPDORemovePeriod -eq 30){Write-Host "`t[OK] NewPDORemovePeriod is 30" -ForegroundColor Green}
else {Write-Host "`t[NOT OK] NewPDORemovePeriod is not 30 (Set-MPIOSetting -NewPDORemovePeriod 30)" -ForegroundColor Red}
if (Get-MPIOSetting -NewDiskTimeout -eq 60){Write-Host "`t[OK] NewDiskTimeout is 60" -ForegroundColor Green}
else {Write-Host "`t[NOT OK] NewDiskTimeout is not 60 (Set-MPIOSetting -NewDiskTimeout 60)" -ForegroundColor Red}
 
#Check the multipathing policy on the Pure Disks
Write-Host "`n`r6. MPIO Disk Policy (Pure Volumes)"
$uniqueIds = Get-Disk
ForEach ($uniqueId in $uniqueIds)
{
    If ($uniqueId.FriendlyName -like "PURE FlashArray*") 
    {
       $disknumber = $uniqueId.Number
       $mpclaimdisks = mpclaim -s -d
       $teststring = $mpclaimdisks | Select-String "Disk $disknumber" | Select-String "LQD"
       if ([string]::IsNullOrEmpty($teststring)) {
            Write-Host "`t[NOT OK] Disk $disknumber - Please configure the volume's multipathing policy to 'Least Queue Depth'" -ForegroundColor Red
       } else {
            Write-Host "`t[OK] Disk $disknumber is set to Least Queue Depth" -ForegroundColor Green
       }       
    }
} 
 
#Display the HBA settings.
Write-Host "`n`r7. HBA Settings"
Write-Host "Please ensure that the following settings are applied to your HBA's:" -ForegroundColor Yellow
Write-Host "`tEmulex`n`r`t`tQueue Depth 32" -ForegroundColor Gray
Write-Host "`t`tNode Timeout 0" -ForegroundColor Gray
Write-Host "`tQLogic`n`r`t`tPort Down Retry Count 5" -ForegroundColor Gray
Write-Host "`t`tLink Down Timeout Seconds 5" -ForegroundColor Gray
Write-Host "`tBrocade`n`r`t`tQueue Depth 32" -ForegroundColor Gray
 
 
#Write-Host "`n`r`n`rTo get furthur details on resolving any above detected issues, please go to:`n`rhttps://support.purestorage.com/Solutions/Operating_Systems/Microsoft_Windows/Windows_Server%3A_Best_Practices" -ForegroundColor Gray
#Read-Host "Enter to Exit"   

Write-Host "`n`r`n`r8. Would you like to apply some of the best pracitce settings? (THIS WILL REQUIRE A REBOOT)"
$answer = Read-Host "`tType [YESANDIMGOINGTOREBOOTTHISSERVERAFTERWARDS] if you want to set the settings."
if ($answer -like "YESANDIMGOINGTOREBOOTTHISSERVERAFTERWARDS") {
    Write-Host "`n`r`n`r`tOK, you asked for it... Let's do this!`n"
    Write-Host "`t8.2 Setting TRIM to ON."
    fsutil behavior set DisableDeleteNotify 0
    Write-Host "`t8.3 Configuring multipathing."
    Add-WindowsFeature -Name 'Multipath-IO'
    New-MSDSMSupportedHw -VendorId PURE -ProductId FlashArray
    Write-Host "`t8.4 Setting Disk Online Policy to OnlineAll."
    Set-StorageSetting -NewDiskPolicy OnlineAll
    Write-Host "`t8.5 Configuring the Multipathing settings. [NewPathRecoveryInterval 20] [CustomPathRecovery Enabled] [NewPDORemovePeriod 30] [NewDiskTimeout 60] [NewPathVerificationState Enabled]"
    Set-MPIOSetting -NewPathRecoveryInterval 20 -CustomPathRecovery Enabled -NewPDORemovePeriod 30 -NewDiskTimeout 60 -NewPathVerificationState Enabled
    Write-Host "`t8.6 Set multipathing policy to Least Queue Depth (LQD)"
    Write-Host "`t`t*Setting the LQD globally (for all new disks)"  -ForegroundColor Yellow
    Set-MSDSMGlobalDefaultLoadBalancePolicy -Policy LQD
    $uniqueIds = Get-Disk
    ForEach ($uniqueId in $uniqueIds)
    {
        If ($uniqueId.FriendlyName -like "PURE FlashArray*") 
        {
            $disknumber = $uniqueId.Number
            $mpclaimdisks = mpclaim -l -d $disknumber 4
            Write-Host "`t`tDisk $disknumber - Volume's multipathing policy is now set to 'Least Queue Depth'"     
        }
    } 
    Write-Host "`n`r`tSettings have been applied.`n`r`tAfter reboot, please re-run the script to check if the settings have been succefully applied." -ForegroundColor Green
    Write-Host "`tPlease also note that this script won't install the necessary windows hotfixes [Section 1] or configure the HBA settings [Section 7]. *You'll need to do that yourself." -ForegroundColor Yellow 

    $answer = Read-Host "`tWould you like to reboot this PC? (YESREBOOTNOW)/(NOIMNOTWEARINGMYLUCKYUNDERPANTS)"
    if ($answer -like "YESREBOOTNOW") {Restart-Computer}
    }
else {
    Write-Host "`tFine. Fix it yourself. =D"  -ForegroundColor Green
    }
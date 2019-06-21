# QA script was created to help with the verification of recently imaged PC
# 01/03/19 - Created by Tom Kunz
# 01/10/19 - Updated by Tom Kunz to include the Basic Info portion
# 01/14/19 - Updated by Tom Kunz to include Driver, and Wifi Check
# 01/21/19 - Updated by Tom Kunz for formatting
# 01/22/19 - Testing Build triggers
# 01/30/19 - Changed the check for permission group as the .Contains() function was case sensitive and the permission group would change cases 
# 02/19 - Uploaded to VSTS, look there for future change comments

#To Do:
# - Add Lenovo Driver and BIOS check
#    - when last ran
#    - if BIOS is the latest from Repo)
# - add chassis type as info
# - If adobe acrobat, export xml, modify, then import, then check - The import function of default apps is not working anymore
# - Panasonic QA
#   - Add website checks
#       - Facility View
#       - Viryanet
#   - Configuration checks
#       - IPC configuration check
#       - netmotion config check
# - fix default app for pdf, it prompts "do you still want to use adobe reader, or do you want to open with edge browser"
<#
 - Import the registry image tag and restructure the QA script as follows
 import-imageTag
 All functions
 if (Offline Image checks)
 else (Base Image checks)
 switch (imageTag)
    CSA - REP
    CSA - Supervisor
    Field Service
    Distribution
    Ranches
        - ArcGIS desktop
        - shortcuts (facility view, workday, netmotion client)
        - netmotion
        - disable aircard service
        - drive screen
        - IPC agent
        - windows device center
#>

# Check is user is Admin
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Please re-run this script as an Administrator.`n`n"
    Break
}

$dateTime = Get-Date -Format "yyyy_MM_dd_HHmm"
Start-Transcript -Path "C:\ITCS\LVVWD-QA_$dateTime.log" -Force

# Basic Info
Function ColorHealth {

    param($value1,$value2,$critical,$warning)
    $percentage = ([math]::round(($value1/$value2)*100))
    If ($percentage -lt $critical){
        $color = "Red"
    } ElseIf ($percentage -lt $warning){
        $color = "Yellow"
    } Else {
        $color = "Green"
    }
    return $color
}

# Get Info
$PCInfo = Get-WmiObject Win32_computerSystem
$OSInfo = Get-ciminstance win32_OperatingSystem
if (($null -eq $PCInfo) -or ($null -eq $OSInfo)){
    $WMIquestion = Read-Host "WMI is broken on this PC, do you want to attempt to fix it (y/n)?"
    if ($WMIquestion -eq "y"){
        Write-Host "Attempting to fix WMI, please stand by..." -ForegroundColor Yellow
         Write-Host "Pausing the WMI service..."
            net pause winmgmt
            $WMIRepo = "c:\windows\system32\wbem"
            Push-Location $WMIRepo
            $files = Get-ChildItem *.dll
            Foreach ($file in $files){
                Write-Host "$env:COMPUTERNAME - Registering $file ..." -NoNewline
                Try {
                    Start-Process -FilePath 'regsvr32.exe' -Args "/S $file" -Wait
                    Write-Host "Done!" -ForegroundColor Green
                } catch {
                    Write-Host "Failed!" -ForegroundColor Red
                }
            }
            Pop-Location
            net continue winmgmt
            Write-Host "Done. Please restart the PC and try again"
    } elseif ($WMIquestion -eq "n"){
        read-Host "no? ok then, press any key to exit"
        exit
    } else {
        read-host "thats not a valid response, exiting script"
        exit
    }
}
Write-Host "ITCSD QA Script" -ForegroundColor Yellow
Write-Host "`nNote: Any values in " -NoNewline; Write-Host "Red" -ForegroundColor Red -NoNewLine; Write-Host " or " -NoNewLine; Write-Host "Yellow" -ForegroundColor Yellow -NoNewLine; Write-Host " should be verified, a " -NoNewLine; write-host "Green" -ForegroundColor Green -NoNewLine; write-host " color indicates a good status."
Write-Host "`nBasic Info" -ForegroundColor Cyan
Write-Host "PC Name: " $env:COMPUTERNAME
Write-Host "Description: " -NoNewLine
$desc = get-wmiobject -class win32_operatingsystem | select description
if ($desc.Description.Length -eq 0){
    $desc = Write-Host "No description found! SHAME!" -ForegroundColor Red
    Write-Host " -Launching System Properties for you to add it now." -ForegroundColor Yellow
    Start-Process sysdm.cpl
} else {
    Write-Host $desc.Description -ForegroundColor Green
    }
Write-Host "Domain: " $PCInfo.Domain
Write-Host "OS: " $OSInfo.Caption 

try {
    $WinRelease, $WinVer = Get-ItemPropertyValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" ReleaseId, CurrentMajorVersionNumber, CurrentMinorVersionNumber, CurrentBuildNumber, UBR
    $WindowsVersion = "$($WinVer -join '.') ($WinRelease)"
} catch {
    $WindowsVersion = [System.Environment]::OSVersion.Version
}

Write-Host "Version: " $WindowsVersion

#Write-Host "Version " (get-itemproperty -path "hklm:\software\microsoft\windows nt\currentversion" -name releaseid).releaseid
#Write-Host "Build " $OSInfo.BuildNumber

Write-Host "Windows Installed Date: " $OSInfo.installdate
Write-Host "Manufacturer: " $PCInfo.Manufacturer
Write-Host "Model: " $PCInfo.Model

$hardwareType = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty PCSystemType
switch($hardwareType){
    1 {$hardwareType = "Desktop"}
    2 {$hardwareType = "Laptop"}
}

# Windows Health
write-host "`nWindows Health" -ForegroundColor Cyan

# WMI Check
write-host "WMI Check..." -NoNewline
If ($PCInfo -ne $null){
    write-host "Success!" -ForegroundColor Green
} Else {write-host "Failed!" -ForegroundColor Red}

# Driver Check
Function Test-Drivers {
    Write-Host "Checking Drivers for errors..." -NoNewline
    $ProblemDevicesRAW = Get-WmiObject Win32_PNPEntity | Where-Object{$_.ConfigManagerErrorCode -ne 0} | Select Name, DeviceID, ConfigManagerErrorCode
    $ProblemDevices = @()
    foreach ($ProblemDevice in $ProblemDevicesRAW){
        if (($hardwareType -eq "Desktop") -and ($ProblemDevice.Name -like "*Wireless*")){}
        else{$ProblemDevices += $ProblemDevice}
    }

    if ($ProblemDevices.Count -eq 0){
        Write-Host "No Errors!" -ForegroundColor Green
    } else {
        Write-Host "Errors found!" -ForegroundColor Red
        Write-Host "See below:"
    }
    ForEach($ProblemDevice in $ProblemDevices){
        $ErrorDesc = Switch ($ProblemDevice.ConfigManagerErrorCode){
            1 {"Device is not configured correctly."}
            2 {"Windows cannot load the driver for this device."}
            3 {"Driver for this device might be corrupted, or the system may be low on memory or other resources."}
            4 {"Device is not working properly. One of its drivers or the registry might be corrupted."}
            5 {"Driver for the device requires a resource that Windows cannot manage."}
            6 {"Boot configuration for the device conflicts with other devices."}
            7 {"Cannot filter."}
            8 {"Driver loader for the device is missing."}
            9 {"Device is not working properly. The controlling firmware is incorrectly reporting the resources for the device."}
            10 {"Device cannot start."}
            11 {"Device failed."}
            12 {"Device cannot find enough free resources to use."}
            13 {"Windows cannot verify the device's resources."}
            14 {"Device cannot work properly until the computer is restarted."}
            15 {"Device is not working properly due to a possible re-enumeration problem."}
            16 {"Windows cannot identify all of the resources that the device uses."}
            17 {"Device is requesting an unknown resource type."}
            18 {"Device drivers must be reinstalled."}
            19 {"Failure using the VxD loader."}
            20 {"Registry might be corrupted."}
            21 {"System failure. If changing the device driver is ineffective, see the hardware documentation. Windows is removing the device."}
            22 {"Device is disabled."}
            23 {"System failure. If changing the device driver is ineffective, see the hardware documentation."}
            24 {"Device is not present, not working properly, or does not have all of its drivers installed."}
            25 {"Windows is still setting up the device."}
            26 {"Windows is still setting up the device."}
            27 {"Device does not have valid log configuration."}
            28 {"Device drivers are not installed."}
            29 {"Device is disabled. The device firmware did not provide the required resources."}
            30 {"Device is using an IRQ resource that another device is using."}
            31 {"Device is not working properly.  Windows cannot load the required device drivers."}
        }
        Write-Host "$($ProblemDevice.Name): " -NoNewline -ForegroundColor Yellow
        Write-Host "$ErrorDesc" -ForegroundColor Red
    }
}

Test-Drivers

# .Net Framework 3.5
Write-Host "Checking .Net 3.5..." -NoNewline
$dotNet35 = Get-WindowsOptionalFeature -online | where featurename -like "netfx3"
if ($dotNet35.State -eq "Enabled"){
    Write-Host "Enabled" -ForegroundColor Green
} else {Write-Host "$($dotNet35.State)" -ForegroundColor Red}

# Wifi Disabled Status
function Check-WiFi {
    Write-Host "Checking Wifi adapter..." -NoNewline
    try {
        $WifiStatus = (Get-NetAdapter -Name Wi-Fi -ErrorAction Stop).Status
    } 
    catch {
        $WifiStatus = $_.Exception.Message
        if ($WifiStatus -match "No MSFT_NetAdapter objects found"){
            Write-Host "No Wifi Adapter Found" -ForegroundColor Green
        } else {
            Write-Host $WifiStatus -ForegroundColor Yellow
        }
    } 
    if ($null -eq $WifiStatus){
        Write-Host "Could not get Wifi Status" -ForegroundColor Yellow
    } 
    else {

        if($hardwareType -eq "Desktop"){
            if (($WifiStatus -eq "No MSFT_NetAdapter objects found") -or ($WifiStatus -eq "Disabled") -or ($WifiStatus -eq $null)){
                Write-Host "Disabled" -ForegroundColor Green
            }
            elseif (($WifiStatus -eq "Up") -or ($WifiStatus -eq "Disconnected")){
                Write-Host "Enabled" -ForegroundColor Red
            }
        }
        elseif ($hardwareType -eq "Laptop"){
            if (($WifiStatus -eq "No MSFT_NetAdapter objects found") -or ($WifiStatus -eq "Disabled") -or ($WifiStatus -eq $null)){
                Write-Host "Disabled" -ForegroundColor Red
            }
            if (($WifiStatus -eq "Up") -or ($WifiStatus -eq "Disconnected")){
                Write-Host "Enabled" -ForegroundColor Green
            }
        }
    }
    #Corrective Action Code
    #   Disable-NetAdapter -Name Wi-Fi -Confirm:$false
}
Check-WiFi

# Memory
$PhysicalMemory = Get-WmiObject -Class "`nWin32_PhysicalMemory" -Namespace "root/CIMV2"
$RAMtotal = ($PhysicalMemory | Measure-Object Capacity -Sum).Sum
$RAMfree = ($OSInfo | Measure-Object FreePhysicalMemory -Sum).Sum
$vRAMtotal = ($OSInfo | Measure-Object TotalVirtualMemorySize -Sum).Sum
$vRAMfree = ($OSInfo | Measure-Object FreeVirtualMemory -sum).Sum
$percentageRAM = ([math]::round(($RAMfree/(($RAMtotal)/1024))*100))
$percentagevRAM = ([math]::round($vRAMfree/($vRAMtotal)*100))
Write-Host "`nMemory Health" -ForegroundColor Cyan
Write-Host "RAM - Total: " ([int](($RAMtotal)/1GB)) "GB"
Write-Host "RAM - Available: " -NoNewline 
Write-Host ([int]((($RAMfree)/1024)/1024)) "GB" "($percentageRAM%)" -ForegroundColor (ColorHealth -value1 ($RAMfree) -value2 ($RAMtotal/1024) -critical 5 -warning 15 )
Write-Host "Virtual Memory - Total: " ([int]((($vRAMtotal)/1024)/1024)) "GB"
Write-Host "Virtual Memory - Available: " -NoNewline 
Write-Host ([int]((($vRAMfree)/1024)/1024)) "GB" "($percentagevRAM%)" -ForegroundColor (ColorHealth -value1 ($vRAMfree) -value2 ($vRAMtotal/1024) -critical 5 -warning 15 )

# Disk
$count = 1
Write-Host "`nDisk Health" -ForegroundColor Cyan
$Disks = Get-WmiObject -Class Win32_logicaldisk
ForEach ($Disk in $Disks){
    Write-Host "Disk $count"
    Write-Host "Assigned Letter: " $Disk.DeviceID
    Write-Host "Description: " $Disk.Description
    if ($Disk.Description -ne "CD-ROM Disc"){
        Write-Host "Free Space: " -NoNewline
        Write-Host ([math]::round($Disk.FreeSpace/1GB)) "GB" -ForegroundColor (ColorHealth -value1 ($Disk.FreeSpace) -value2 ($Disk.Size) -critical 10 -warning 20)
        Write-Host "Total Space: " ([math]::round($Disk.Size/1GB)) "GB"
        Write-Host "Used: " ([math]::round($Disk.Size/1GB - $Disk.FreeSpace/1GB)) "GB`n"
    }else{}
    $count += 1
}

# Check Installed Applications
write-host "Checking if Apps are installed:" -ForegroundColor Cyan
Function Check-AppInstall{
    param($swName,$swPath,$color1 = "green",$color2 = "red")
    $script:installed = $false
    write-host "$swName..." -NoNewline
    if (Get-ChildItem -Path $swPath -ErrorAction SilentlyContinue){
        write-host "Installed" -ForegroundColor Green
        $script:installed = $true
    } else{
        if($swName -eq "Adobe Reader"){
            if (Get-ChildItem -Path "C:\Program Files (x86)\Adobe\Acrobat DC\Acrobat\Acrobat.exe" -ErrorAction SilentlyContinue){
                Write-Host "Acrobat DC installed" -ForegroundColor $color1
            } else {}
        } else {
            write-host "Not Installed" -ForegroundColor $color2
            $script:installed = $false
        }
    }
}
Check-AppInstall -swName "Adobe Reader" -swPath "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
Check-AppInstall -swName "Google Chrome" -swPath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
Check-AppInstall -swName "Microsoft Office 365" -swPath "C:\Program Files (x86)\Microsoft Office\root\Office16\WINWORD.exe"
Check-AppInstall -swName "Condeco" -swPath "C:\Program Files (x86)\Condeco\Condeco Outlook Add-in*\en-US\CondecoAddinV2.resources.dll"
Check-AppInstall -swName "Trend Micro" -swPath "C:\Program Files (x86)\Trend Micro\OfficeScan Client\PccNTMon.exe"
if ($PCInfo.Manufacturer -like "Lenovo"){
    Check-AppInstall -swName "Lenovo TVSU" -swPath "C:\Program Files (x86)\Lenovo\System Update\tvsu.exe" -color2 "yellow"
    if ($installed -eq $false){
        Write-Host " -Installing TVSU..." -NoNewline
        $tvsuPath = "\\storage\lvvwd\setup\_Tools\TVSU\systemupdate*.exe"
        $tvsuPath | unblock-file -ErrorAction SilentlyContinue
        try {
            start-process "\\storage\lvvwd\setup\_Tools\TVSU\systemupdate*.exe" -Args "/silent" -Wait
            write-host "installed" -ForegroundColor green
            write-host " -launching TVSU for you to run"
            start-process "${env:ProgramFiles(x86)}\Lenovo\System Update\tvsu.exe"
        } catch {
            write-host "failed" -ForegroundColor Red
        }
    }
    if ($installed -eq $true){
        Write-host " -# of Updates installed..." -NoNewline
        $updates = get-childitem $env:ProgramData\Lenovo\SystemUpdate\sessionSE\Repository -ErrorAction SilentlyContinue
        $updatesInstalled = ($updates).count
        if ($updatesInstalled -gt 0){
            Write-Host $updatesInstalled -ForegroundColor Green
        } elseif ($updatesInstalled -eq 0) {
            Write-Host "$updatesInstalled, Please run TVSU to install the latest updates" -ForegroundColor Red
        } else {
            Write-Host "Sorry, Tom can't code. Here's an error: " $_.Exception.Message
        }
    }
}
Write-Host "`n - Detected Panasonic laptop, additional checks being made:" -ForegroundColor Cyan
if ($PCInfo.Manufacturer -match "Panasonic"){
    Check-AppInstall -swName "Microsoft Office Professional Plus 2016" -swPath "${env:ProgramFiles(x86)}\Microsoft Office\Office16\WINWORD.exe"
    Check-AppInstall -swName "AirCardWindowsServiceISSetup" -swPath "${env:ProgramFiles(x86)}\Air Card Windows Service\AirCardWindowsService.exe"
    Check-AppInstall -swName "DriveScreen" -swPath "${env:ProgramFiles(x86)}\Innovative Products Company\DriveScreen\DriveScreen.exe"
    Check-AppInstall -swName "FreeFileSync" -swPath "$env:ProgramFiles\FreeFileSync\FreeFileSync.exe"
    Check-AppInstall -swName "IPC Agent" -swPath "${env:ProgramFiles(x86)}\Innovative Products Company\IPC Agent\IPC Agent.exe"
    if ($installed -eq $true){
        $IPCAgent = "installed"
    }
    Check-AppInstall -swName "Itron MC Driver Helper" -swPath "${env:ProgramFiles(x86)}\Itron\Mobile Collection\drivers\MCHelper\MCDHApplication.exe"
    Check-AppInstall -swName "Itron Mobile Collection" -swPath "${env:ProgramFiles(x86)}\Itron\Mobile Collection\bin\MISApplication.exe"
    if ($installed -eq $true){
        $Itron = "installed"
    }
    Check-AppInstall -swName "Java 8 Update 191" -swPath "${env:ProgramFiles(x86)}\Java\jre1.8.0_191\bin\java.exe"
    Check-AppInstall -swName "Microsoft MapPoint North America 2013" -swPath "${env:ProgramFiles(x86)}\Microsoft MapPoint 2013\MapPoint.exe"
    Check-AppInstall -swName "Microsoft Office 365 ProPlus" -swPath "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\OUTLOOK.exe"
    Check-AppInstall -swName "NetMotion diagnostics Client" -swPath "${env:ProgramFiles(x86)}\NetMotion Diagnostics Client\Locality.exe"
    Check-AppInstall -swName "NetMotion Mobility Client" -swPath "$env:ProgramFiles\NetMotion Client\nmclient.exe"
    Check-AppInstall -swName "Sierra Wireless Mobile Broadband Driver Package" -swPath "${env:ProgramFiles(x86)}\Sierra Wireless Inc\Driver Package\DriverInst64.exe"
    Check-AppInstall -swName "Viryanet Sync Agent" -swPath "$env:SystemDrive\Viryanet\MicroServer\Launcher.exe"
    Check-AppInstall -swName "Windows Mobile Device Center Driver Update" -swPath "$env:windir\WindowsMobile\Drivers\Serial\wmdc.exe"
    Check-AppInstall -swName "ArcGIS Desktop" -swPath "${env:ProgramFiles(x86)}\ArcGIS\Desktop*\bin\ArcMap.exe"
    if ($installed -eq $true){
        $ArcGIS = "installed"
    }
    write-host "`nConfiguration check" -ForegroundColor Cyan
    if ($IPCAgent -eq "installed"){
        $config = [xml] (get-content "$env:ProgramData\Innovative Products Company\ipc.config")
        write-host "IPC Agent config check:"
        write-host "- GPS enabled..." -NoNewline
        if (($config.Settings.Gps).Enabled -eq "true"){
            write-host "true" -ForegroundColor Green
        } else {
            write-host $config.Settings.Gps -ForegroundColor Yellow
        }
        $config = [xml] (Get-Content "$env:ProgramData\Innovative Products Company\ipc.config")
    }
}

# Check if applications are running
write-host "`nChecking if Apps are running:" -ForegroundColor Cyan
Function Check-RunningApp{
    param($appName,[parameter(mandatory=$true)][ValidateSet("service","process")]$type,$appSvcName,$appProcName)
    write-host "$appName $type..." -NoNewline
    if ($type -eq "service"){$svc = Get-Service -Name $appSvcName -ErrorAction SilentlyContinue} 
    elseif ($type -eq "process"){$proc = Get-Process -Name $appProcName -ErrorAction SilentlyContinue}
    if ($proc){write-host "running!" -ForegroundColor Green} 
    elseif ($svc){write-host "started!" -ForegroundColor Green} 
    else {write-host "not found!" -ForegroundColor Red}
}
Check-RunningApp -appName "TrendMicro Listener" -type "service" -appSvcName "tmlisten"
Check-RunningApp -appName "TrendMicro Listener" -type "process" -appProcName "TmListen"
Check-RunningApp -appName "TrendMicro RealTimeScan" -type "service" -appSvcName "ntrtscan"
Check-RunningApp -appName "TrendMicro RealTimeScan" -type "process" -appProcName "ntrtscan"

# Check Windows Settings
write-host "`nChecking Windows Settings" -ForegroundColor Cyan

# Domain joining status
write-host "Domain..." -NoNewline
$domain = (Get-WmiObject Win32_ComputerSystem).Domain
if ($domain -eq "ntlan.lvvwd.com"){
    write-host "NTLAN" -ForegroundColor Green
} else{write-host "$domain" -ForegroundColor Red}

# Check Default Apps
Function Check-DefaultApp{
    param($swName, $extention)
    write-host "Checking default for $extention files..." -NoNewline
    dism.exe /online /export-defaultappassociations:c:\temp\CustomFileAssoc.xml | Out-Null
    [XML]$DefaultApps = Get-Content -Path "C:\temp\CustomFileAssoc.xml"
    $DefaultAppName = $DefaultApps.DefaultAssociations.Association | Where-Object -Property Identifier -EQ $extention | Select-Object -ExpandProperty ApplicationName    
    If ($DefaultAppName -eq $swName){
        write-host "set to $swName, YAY!" -ForegroundColor Green
    } elseif ($DefaultAppName -eq "Adobe Acrobat DC") {
        write-host "set to $DefaultAppName, YAY!" -ForegroundColor Green
    } elseif (-Not($DefaultAppName)){
        write-Host "No Associated App, please open a $extention file and choose one" -ForegroundColor Red
    }
    Else {write-host "Oh noes! It's set to $DefaultAppName" -ForegroundColor Red}
}

Check-DefaultApp -swName "Internet Explorer" -extention ".html"
Check-DefaultApp -swName "Adobe Acrobat Reader DC" -extention ".pdf"

# Check Files/Folders
Function Check-Folder{
    param($name,$path)
    write-host "Checking folder for $name..." -NoNewline
    $folder = Get-Item -Path $path -Force -ErrorAction SilentlyContinue
    if($folder){
        write-host "it's there!" -ForegroundColor Green
    } else {write-host "not found!" -ForegroundColor Red}
}
Check-Folder -name "CIRT" -path "$env:SystemDrive\CIRT"
Check-Folder -name "ITCS" -path "$env:SystemDrive\ITCS"

# Check location services
write-host "Location Services..." -NoNewline
$locSet1 = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location").Value
$locSet2 = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}").SensorPermissionState
#$set3 = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration").Status

if(($locSet1 -eq "Allow") -and ($locSet2 -eq 1)){
    write-host "Turned on" -ForegroundColor Green
} else {write-host "Turned off" -ForegroundColor Red}

write-host "Cortana..." -NoNewline
try {
    $cortana1 = (Get-ItemProperty -Path "HKLM:\SOFTWARE\POLICIES\MICROSOFT\WINDOWS\Windows Search" -ErrorAction Stop).AllowCortana
    if ($cortana1 -eq 0){
        write-host "Disabled!" -ForegroundColor Green
    } else {write-host "Enabled!" -ForegroundColor Red}
} catch {Write-Host "Not Installed" -ForegroundColor Yellow}

# RDP Remoting
write-host "RDP Remoting..." -NoNewline
$remote = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server").fDenyTSConnections
if ($remote -eq 0){
    write-host "Enabled!" -ForegroundColor Green
} else {write-host "Disabled!" -ForegroundColor Red}

# Check SMBv1
write-host "checking if SMBv1 is enabled..." -NoNewline
$SMBv1 = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
if ($SMBv1.State -eq "Enabled"){
    write-Host "Enabled - only needed for old network drives" -ForegroundColor Yellow
} elseif ($SMBv1.State -eq "Disabled") {
    write-Host "Disabled" -ForegroundColor Green
} else {
    write-host $SMBv1.State -ForegroundColor Yellow
}

Function Check-Reg {
    param($Path,$valueName,$goodValue,$successMsg,$failureMsg)
    try {
        $reg = (Get-ItemProperty -Path $Path -ErrorAction Stop).$valueName
        if ($reg -eq $goodValue){
            Write-Host $successMsg -ForegroundColor Green
        } else {
            Write-Host "Currently set to $reg, $failureMsg" -ForegroundColor Red
        }
    } catch {
        Write-Host "Not Found" -ForegroundColor Red
    }
}

# Checking GPO items
Write-Host "`nChecking GPO items:" -ForegroundColor Cyan

#Not found, may not be needed to be checked
#Write-Host "Checking Edge Shortcut..." -NoNewline
#Check-Reg -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -valueName "DisableEdgeDesktopShortcutCreation" -goodValue 1 -successMsg "Removed!" -failureMsg "Not Removed!" 

write-host "Cached Logins..." -NoNewline
Check-Reg -Path 'HKLM:\SOFTWARE\Windows NT\CurrentVersion\Winlogon' -valueName "CachedLogonsCount" -goodValue 1 -successMsg "set to 1" -failureMsg "not 1!"
Write-Host "NTLMv2 session security..." -NoNewline
Check-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -valueName "LmCompatibilityLevel" -goodValue 1 -successMsg "Enabled" -failureMsg "not Enabled!"
Write-Host "SMB Signing Config 1..." -NoNewline
Check-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -valueName "EnableSecuritySignature" -goodValue 0 -successMsg "Disabled Security Sig" -failureMsg "SMB requiring Security Sig"
Write-Host "SMB Signing Config 2..." -NoNewline
Check-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -valueName "RequireSecuritySignature" -goodValue 0 -successMsg "Disabled Security Sig" -failureMsg "SMB requiring Security Sig"
Write-Host "Oracle access over network..." -NoNewline
Check-Reg -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" -valueName "TNS_Admin" -goodValue "\\storage\lvvwd\apps\Oracle" -successMsg "Setup" -failureMsg "Not setup"

# Checking permission groups
Write-Host "Checking if NTLAN/LocalAdministrators is added..." -NoNewline
$localAdmin = ([ADSI]"WinNT://localhost/Administrators,group").Members() | ForEach-Object { ([ADSI]$_).Path.Substring(8) }
if ($localAdmin -like "NTLAN/Local Administrators"){
    Write-Host "It's there!" -ForegroundColor Green
} else {Write-Host "Oh noes! couldn't find it" -ForegroundColor Red}

Write-Host "Checking if Remote Desktop Users is added..." -NoNewline
$remoteDesktopUsers = ([ADSI]"WinNT://localhost/Remote Desktop Users,group").Members() | ForEach-Object { ([ADSI]$_).Path.Substring(8) }
if ($remotedesktopUsers -like "NTLAN/Domain Users"){
    Write-Host "It's there!" -ForegroundColor Green
} else {Write-Host "Oh noes! couldn't find it" -ForegroundColor Red}

Write-Host "Checking if Domain Users have access to Public Desktop..." -NoNewline
$pubDesk = "c:\users\public\desktop"
$acl = (get-acl $pubDesk).Access
if ($acl.IdentityReference -contains ("NTLAN\Domain Users")){
    Write-Host "They have permission, yay!" -ForegroundColor Green
} Else {
    Write-Host "They don't have permission, :(" -ForegroundColor Yellow
    Write-Host " -Changing permissions so users have access..." -NoNewline
        $aclroot = get-acl $pubDesk
        $DomainUsersAccessFull = New-Object System.Security.AccessControl.FileSystemAccessRule("NTLAN\Domain Users","FullControl","ContainerInherit,ObjectInherit","None","Allow")
        $aclroot.AddAccessRule($DomainUsersAccessFull)
        $aclroot | set-acl $pubDesk
        $acl = (get-acl $pubDesk).Access
        if ($acl.IdentityReference -contains ("NTLAN\Domain Users")){
            Write-Host "permissions applied" -ForegroundColor Green
        } else {
            Write-Host "couldn't change permission, please do so manually" -ForegroundColor Red
        }
    }

# Checking Power settings
Write-Host "Checking Power Plan..." -NoNewline
$plan = (Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power -Filter "isActive='true'").ElementName  
if ($plan -eq "High performance"){
    Write-Host "High Performance" -ForegroundColor Green
} else {Write-Host "it's $plan, should be High Performance" -ForegroundColor Red}

# Checking if Remote Registry service is started
Write-Host "Checking if Remote Registry service is set to Auto..." -NoNewline
$remoteReg = Get-Service -Name RemoteRegistry
if ($remoteReg.StartType -eq "Automatic"){
    Write-Host "Auto" -ForegroundColor Green
} else {
    Write-Host $remoteReg.StartType -ForegroundColor Red
}

# Panasonic Checks
if ($PCInfo.Manufacturer -match "Panasonic"){
    # Check COM Ports
    Write-host "`nCOM Port check" -ForegroundColor Cyan
    function Check-COM{
        param(
            $name,
            $comPort
        )
        write-host "$name on $comPort..." -NoNewline
        $comCheck = Get-WmiObject -Class Win32_PnPEntity | Where-Object classguid -match '{4d36e978-e325-11ce-bfc1-08002be10318}' | Where-Object name -like "$name* ($comPort)"
        if ($comCheck){
            write-host "set" -ForegroundColor Green
        } else {
            write-host "not found" -ForegroundColor Red
        }
    }
    #Sierra Wireless NMEA Port on COM11
    Check-COM -name "Sierra Wireless" -comPort "COM11"
    #Sierra Wireless DM Port on COM10
    Check-COM -name "Sierra Wireless" -comPort "COM10"
    Check-COM -name "u-blox Virtual COM Port" -comPort "COM2"
    Check-COM -name "Intel(R) Active Management Technology - SOL" -comPort "COM20"
    Check-COM -name "u-blox Virtual COM Port" -comPort "COM15"

    # Check group Membership
    Write-Host "`nGroup Membership Check" -ForegroundColor Cyan
    function read-groupmembership{
        param(
            $member,
            $group
        )
        write-host "Check if $member is part of group $group..." -NoNewline
        $groupObj = [ADSI]"WinNT://./$group,group"
        if ($groupObj.Path -ne $null){
            $membersObj = @($groupObj.psbase.Invoke("Members"))
            $members = ($membersObj | ForEach-Object {$_.GetType().InvokeMember("Name",'GetProperty',$null,$_,$null)})
            if ($members -contains $member){
                write-host "true" -ForegroundColor Green
            } else {
                write-host "false, user needs to be added" -ForegroundColor Red
            }
        } else {
            Write-Host "group not found" -ForegroundColor Red
        }
    }
    $groupsChecked = 0
    if ($Itron -eq "installed"){
        write-host "- Itron Groups" -ForegroundColor Cyan
        $groupsChecked = 1
        read-groupmembership -member "IT_PC_Support" -group "Mobile Administrators"
        read-groupmembership -member "itronprod_desktop" -group "Mobile Administrators"
        read-groupmembership -member "itronprod_collect" -group "Mobile Meter Readers"
    } 
    if ($groupsChecked = 0){
        write-host "No groups to check"
    }

    write-host "`nDesktop Shortcuts (public)" -ForegroundColor Cyan
    function read-desktopShortcuts{
        param(
            $name,
            $url
        )
        Write-Host "$name..." -NoNewline
        function Get-ShortcutTarget {
            param (
                $path
            )
            $Shell = New-Object -ComObject WScript.Shell
            $lnk = $Shell.CreateShortcut($path)
            [pscustomobject]@{
                ShortcutName = Split-Path $path -Leaf
                Path = $path
                Target = $lnk.TargetPath
            }
            [Runtime.InteropServices.Marshal]::ReleaseComObject($Shell) | Out-Null
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        $Shortcuts = Get-ChildItem "$env:public\desktop" -Include *.lnk -Recurse -ea 0 | select -exp fullname
        $results = $Shortcuts | % {Get-ShortcutTarget $_}
        $names = $results.ShortcutName
        $targets = $results.Target
        if ($names -match $name){
            write-host "found..." -foregroundcolor green -NoNewline
            if ($targets -contains $url){
                write-host "url correct" -ForegroundColor Green
            } else {
                write-host "url not found" -ForegroundColor Red
            }
        } else {
            write-host "not found" -ForegroundColor Red
        }            
    }
    read-desktopShortcuts -name "FreeFileSync" -url "$env:ProgramFiles\FreeFileSync\FreeFileSync.exe"
    read-desktopShortcuts -name "itron-data-dump" -url "$env:SystemDrive\itron-data-dump"
    read-desktopShortcuts -name "meterread-menu" -url "$env:SystemDrive\meterread-status\bin\meterread-menu.hta"
    read-desktopShortcuts -name "Mobile Administration" -url "${env:ProgramFiles(x86)}\Itron\Mobile Collection\bin\AdminApplication.exe"
    read-desktopShortcuts -name "Mobile Interface" -url "${env:ProgramFiles(x86)}\Itron\Mobile Collection\bin\MISApplication.exe"
    read-desktopShortcuts -name "Net Motion Client" -url "$env:ProgramFiles\NetMotion Client\nmclient.exe"
    read-desktopShortcuts -name "RealtimeSync" -url "$env:ProgramFiles\FreeFileSync\RealtimeSync.exe"
    read-desktopShortcuts -name "Viryanet Sync Agent" -url "$env:SystemDrive\Viryanet\MicroServer\Launcher.exe"
    read-desktopShortcuts -name "ViryaNet X DB Folder" -url "$env:SystemDrive\Viryanet\MicroServer\dumpmcp.bat"
    read-desktopShortcuts -name "VXField Dispatch" -url "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe" #Need to add check for additional path
}

# Check SCCM Client install
write-host "`nSCCM Client install" -ForegroundColor Cyan

# Installed Status
write-host "Install State..." -NoNewline
try {
$sms = New-Object -ComObject 'Microsoft.SMS.Client' -ErrorAction Stop
write-host "Installed" -ForegroundColor Green
} catch {write-host "Not installed" -ForegroundColor Red}

If ($sms -ne $null){
    #confirmAssignedSiteIs22
    write-host "Site assigned to..." -NoNewline
    If(($sms.GetAssignedSite() -eq "S22")){
        write-host "S22" -ForegroundColor Green
    } else{write-host $sms.GetAssignedSite() -ForegroundColor Red}
}

# SMS Version
write-host "SMS Version..." -NoNewline
try {
     $smsVersion = (Get-WmiObject -Namespace root/ccm SMS_Client -ErrorAction Stop).ClientVersion
     Write-Host $smsVersion
    <# Health check on SMS version
    if ($smsVersion -gt "5.00.8577.1115"){
        write-host "Up-to-date" -ForegroundColor Green
    } else {write-host "$smsVersion, supposed to be at least 5.00.8577.1115" -ForegroundColor Red}
    #>
} catch {Write-Host "Could not receive version" -ForegroundColor Red}

Write-Host "Running machine policy retrieval..." -NoNewline

# Invoking the Machine Policy Retrieval
$methodresult = Invoke-WmiMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule '{00000000-0000-0000-0000-000000000021}' -ErrorAction SilentlyContinue -ErrorVariable err
# if an error occurred write message.
if ($err) {
    Write-host "An Error Occurred while performing the Machine Policy Retrieval. Error Details $err" -ForegroundColor Red
    # if the error is invalid namespace provide additional details.
    if ($err -like "*Invalid Namespace*") {
        write-host "Additional Details: The SCCM client may not be installed on this system, or WMI is not working properly." -ForegroundColor Red
    }
}
# Gather the exit code for the command execution
$exitcode = $methodresult.ReturnValue

# if the exit code is not blank produce error.
if ($exitcode -ne $null) {
    write-host "An error occurred during the Trigger Action of Machine Policy Retrieval. Exit Code Value: $exitcode"
}
# if no error continue to the Policy Evaluation
if (-Not($err)) {
    Write-host "Ran Successfully." -ForegroundColor Green

    Write-Host "Running machine policy evaluation..." -NoNewline
    # Invoking the Machine Policy Evaluation
    $methodresult = Invoke-WmiMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule '{00000000-0000-0000-0000-000000000022}' -ErrorAction SilentlyContinue -ErrorVariable err

    # if an error occurred write message.
    if ($err) {
        Write-host "An Error Occurred while performing the Machine Policy Evaluation. Error Details $err" -ForegroundColor Red
    }
    # Gather the exit code for the command execution
    $exitcode = $methodresult.ReturnValue
    # if the exit code is not blank produce error.
    if ($exitcode -ne $null) {
        write-host "An error occurred during the Trigger Action of Machine Policy Evaluation. Exit Code Value: $exitcode" -ForegroundColor Red
    }
    # if no error
    if (!$err) {
        Write-host "Ran Successfully." -ForegroundColor Green
    }
 }
write-host "`nManual checks" -ForegroundColor Cyan
function color-status {
    param (
        $status
    )
    $status = $status.ToLower()
    if ($status -eq "y"){
        write-host "test was successful!" -ForegroundColor Green
    }
    elseif ($status -eq "n"){
        write-host "test was not successful" -ForegroundColor Red
    } else {
        write-host "...you put $status, I don't know what that means" -ForegroundColor Yellow
    }
}
write-host "The below checks require you to manually verify and report back with a Y or N if the test was successful."
write-host "This is until we can find a way to automatically check it"
if ($PCInfo.Manufacturer -match "Panasonic"){
    write-host "- Facility view webpage" -ForegroundColor Cyan
    write-host "launching http://fv.lvvwd.com for verification..." -NoNewline
    start-process -FilePath "http://fv.lvvwd.com/"
    write-host "Did it work (y/n)?" -ForegroundColor Yellow -NoNewline; $confirm = Read-host; color-status -status $confirm
}

Write-Host "- computrace" -ForegroundColor Cyan
if ($hardwareType -eq "Desktop"){
    Write-Host "This is a desktop, computrace check is skipped."
    Write-Host "All Done!" -ForegroundColor Green
}elseif ($hardwareType -eq "Laptop") {
    Write-Host "This is a laptop and Computrace must be installed and active!"
    Write-Host "launching \\storage\lvvwd\isexch\2305\2320\_IT KB Posts\CompuTrace\ctmweb for verification..." -NoNewline
    start-process -FilePath "\\storage\lvvwd\isexch\2305\2320\_IT KB Posts\CompuTrace\ctmweb.exe"
    write-host "was it successful? (y/n)?" -ForegroundColor Yellow -NoNewline; $confirm = Read-Host; color-status -status $confirm; $confirm = $confirm.ToLower()
    if ($confirm -ne "y"){
        Write-Host "WARNING: Do not deploy this PC until you verify computrace is working." -ForegroundColor Red -BackgroundColor Yellow
    }
}

write-host "That's All, folks!" -ForegroundColor Green
Read-Host "`n`nPress any key to exit..."

Stop-Transcript
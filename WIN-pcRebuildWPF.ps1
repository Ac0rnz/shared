<#pcRebuild WPF

Install Options:
- Install
- Uninstall
- Upgrade
- Backup
- Restore
- List whats installed
# blah

Config Options
- show all tray icons
- start powershell shortcut as admin
- start vscode shortcut as admin

Backup/Restore Options
- SABnzbd
- Plex
- firefox bookmarks
- chrome bookmarks
- sonarr
- radarr
- lidarr
- uTorrent (download parse script, and webgui)
- openvpn
#>
#GUI
#Remove the following:
# - x:Class="pcRebuild.MainWindow"
# - xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
# - mc:Ignorable="d"
[xml]$xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:local="clr-namespace:pcRebuild"
        Title="WIN-pcRebuildWPF" Height="450" Width="680.16">
    <Grid>
        <Border BorderBrush="Black" BorderThickness="1" HorizontalAlignment="Left" Height="218" Margin="512,75,0,0" VerticalAlignment="Top" Width="136"/>
        <Label Content="maintenance" HorizontalAlignment="Left" Margin="540,44,0,0" VerticalAlignment="Top"/>
        <Label Content="standard setup" HorizontalAlignment="Left" Margin="31,44,0,0" VerticalAlignment="Top" FontWeight="Bold" FontStyle="Italic"/>
        <Label Content="workstation" HorizontalAlignment="Left" Margin="147,44,0,0" VerticalAlignment="Top" FontWeight="Bold" FontStyle="Italic"/>
        <Label Content="gamer" HorizontalAlignment="Left" Margin="262,44,0,0" VerticalAlignment="Top" FontWeight="Bold" FontStyle="Italic"/>
        <Label Content="server" HorizontalAlignment="Left" Margin="367,44,0,0" VerticalAlignment="Top" FontWeight="Bold" FontStyle="Italic"/>
        <Button x:Name="btnInstall" Content="Install" HorizontalAlignment="Left" Margin="110,379,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="btnUninstall" Content="Uninstall" HorizontalAlignment="Left" Margin="196,379,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="btnUpgrade" Content="Upgrade" HorizontalAlignment="Left" Margin="286,379,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="btnBackup" Content="Backup" HorizontalAlignment="Left" Margin="373,379,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="btnRestore" Content="Restore" HorizontalAlignment="Left" Margin="461,379,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="btnClean" Content="clean" HorizontalAlignment="Left" Margin="522,110,0,0" VerticalAlignment="Top" Width="117"/>
        <Button x:Name="btnQa" Content="qa" HorizontalAlignment="Left" Margin="522,85,0,0" VerticalAlignment="Top" Width="117"/>
        <Button x:Name="btnRemoveWin10Apps" Content="remove win10 apps" HorizontalAlignment="Left" Margin="522,135,0,0" VerticalAlignment="Top" Width="117"/>
        <CheckBox x:Name="cbxFirefox" Content="firefox" HorizontalAlignment="Left" Margin="31,70,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxPia" Content="pia" HorizontalAlignment="Left" Margin="31,90,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxAdobeReader" Content="adobe reader" HorizontalAlignment="Left" Margin="31,110,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxPeazip" Content="peazip" HorizontalAlignment="Left" Margin="31,130,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxChrome" Content="chrome" HorizontalAlignment="Left" Margin="147,70,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxVsCode" Content="vscode" HorizontalAlignment="Left" Margin="147,90,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxVsCommunity" Content="vscommunity" HorizontalAlignment="Left" Margin="147,110,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxOffice365" Content="office 365" HorizontalAlignment="Left" Margin="147,130,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxVlc" Content="vlc" HorizontalAlignment="Left" Margin="147,150,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxPoshcore" Content="poshcore" HorizontalAlignment="Left" Margin="147,170,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxGeforce" Content="geforce" HorizontalAlignment="Left" Margin="262,70,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxSteam" Content="steam" HorizontalAlignment="Left" Margin="262,90,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxCorsairCue" Content="corsair cue" HorizontalAlignment="Left" Margin="262,110,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxEpicGames" Content="epic games" HorizontalAlignment="Left" Margin="262,130,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxOrigin" Content="origin" HorizontalAlignment="Left" Margin="262,150,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxPlexServer" Content="plex media server" HorizontalAlignment="Left" Margin="367,70,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxUtorrent" Content="utorrent" HorizontalAlignment="Left" Margin="367,90,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxSabnzbd" Content="sabnzbd" HorizontalAlignment="Left" Margin="367,110,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxSonarr" Content="sonarr" HorizontalAlignment="Left" Margin="367,130,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxLidarr" Content="lidarr" HorizontalAlignment="Left" Margin="367,150,0,0" VerticalAlignment="Top"/>
        <CheckBox x:Name="cbxOpenVPN" Content="openvpn" HorizontalAlignment="Left" Margin="367,170,0,0" VerticalAlignment="Top"/>
    </Grid>
</Window>
"@
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
Add-Type -AssemblyName PresentationFramework
#update connect protocol request
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$window=[Windows.Markup.XamlReader]::Load($reader)
#icon
$base64 = "iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAMAAAD04JH5AAABqlBMVEUAAABEREBEREBEREBEREBEREBCJSIkHhgjHhchGxQgGhMcHBNEREAqIxohGhZEREBEREArJBxEREArJR0jHBhEREBEREAmHRQjHRlEREAkGxIjHRlEREAkHRlEREAhGxcmHhUvKSIwKiMcHBwgHBghHRknIx8nJCAnIhwhGhYAAAAhGhYhGxc4ODUkHho5OTYgGxUhGxUjHRcjHhgkHxklHxklHxoiHBYmIRsnIhwkHhgiHBchHBYhGhYhGhYgGhYjHRkkHRkjHRgjHRkhGxciGhcmJhc1NTIjHBUiGhYhGhYgGRUfGhQhGhYhGhYhGxUkGBggICAhGhcgIBBAAAAhGhYhGhYhHBYhGhYhGhUkHRYcHBwhGhYhGhYgGhYiGxckHhklHxsnIR0mIBslIh8mHxolIBwjHhslHhkjHRkjGRQlHRwhGhYhGRYiGRYhGRUhGhYjHBUhGhYfGhUhGhYhGhYkJCQoKCchGRchGhYhGhYhGxUgHRg4ODUmIx4hHBghGhYjHRkjHRkjHRkjHBghFhYkHxklIBkiGxchGhYiHBgjHBgjHRkhGxd5Gym4AAAAiHRSTlMAAQIDBAUJLCspKBsGIbAHCCMJI7MKCx2zDBy0DrQPsR4oKhJAQkpLX8QDpKURqRIwVFdYWVpaVV1eWVYxlP3cxsbY+sBZERZNruNIMtGVyhUI1xAEuvou62wjCfDOppZye1V0SoBYo37dMx/8q5g96iToMfZ1Bwp6+OWFOxdEh+f+8fD+Fy0tQDAc2wAABNZJREFUeNrtm/lb3EQcxnezGxG7QoxuNDGsRxdQLgtUgVbQWrUCHnggindt7eHRw7a21draCiQb+J9NNnvMzE7Id2YyE/s85Ceedzf5vOwOb958QwqF/9tW1DStmIPW3krRloPWtlbWdb1cBGiP9PU92v9YdzvEsG+v1nlNr1QqehGiPe55ProNMOzbo3VeGzQMY7AI0p7A+f4Aw76k1nnNME3TKMK0J3G+/xTDvgadr1Uty6pqQO1pnN94hmFfjc63bNu2NKjmYPwgeJZh3wS+67o28X47WXNwfjDEsC/1+6/abs0l3u/WaokaaiDY3d0dYtgXA7fXhhW6YzmGg/OD57j4xZLW+tsww2+H6XdwcL4/wMUvxwaKumFaFttn6OB8zACYr+uxgXLFMKuM36GD81EDYP5gRS9Fa6CkVwyDdQ05OB8xAOVrhhEaaC4EvUJkI+AYDs7vGgDzq6ZRKTd/Kuk6Mz820OV3DID5lmUaMVcrldn5TQMIv20AzA8T0Wx97lqJgx8ZQPktA2B+mIhW+5xEnJqAx3BwfmwAzq+5djXhnAg8xvM4v2mAgV9zk85J0GO8gPMjAyz8mi3Id1/E+aEBJr4L4x+u1+vDI6OjoyPDdXQLtZdwvv9ywvsi7TAvvzA2Tqx1In9h2vgYLz90MJEvv6BNTqnj29T18sqUKr7l0tfr5IQS/j6dMFqJ8viQTog6yJgP7IRdB1nzoZ2w7SBrPrwTxg6y5rN0QvZMTOUzdkLWTEzns3ZCtkxM57N3QpZMTOfzdEJ4Jqbz+TohNBMBfM5OCMtECJ+3E0IyEcTn7oTpmQjju9ydNC0TZfPTMlE+f/9MVMHfLxPF+Db4uiIpE8X4SZ0QnolCfMY5IS0T+fi8c8LeTOTiC8wJyUzk4wvMCYlM5OOLzAnxTOTjC80JsUzk4gvOCdFM5OMLzgmRTOTji84Ju5nIxxeeE3YykY8vPifsZCIfX3xOKKoJzwlFNTtnvnvAP+ALdUI5fJZOKIHPfO84Kz73veNsNIFOmA1fpBNmwW92wiPT0zOzR199bW4a3ebmFxYW5iVrx2Znjr9eWPR9zyP+JyeL+yTpWhO7GBrYy4ffaCAGcuAHkQG/ZSAPfmTAjw34ufCDJp9mQAl/NzTg0w2o4YcGfLoBRfyORhpQzScNKOcTBtTzcQM58DEDefBRA/L5S2+8eeKtk7jWNRAEkvlvv/Nu1AlOvbe8RDPQCA3I5K+sdjvJ+x909Q9bBrzQgEz+R2toJ/p4mTTgNRpS+Z98ineyz9ZbnWQvNuBFBiTyP98gO+HaF3Enig14kQG5f2s9nfTLuJN1DMjtJJu9nfirrxV2wm9onfxbhZ3wO9p1wvcKO+EPtDnhaYWd8EfanPCMwk54ljYn/ElhJzxHmxOeV9gJL9DmhOsqO+HF3uvkn39R2Ql/7b1O/01tJ1wl+ZeW1HbCy1dw/uZV1Z1wZQPl/76ivhNeu36jzf/j5q1cOuHtP/86Vavd+fvuPT+PTtjU/rn/4F9CU9UJkzRVnTBxTqWoEybPyRR1wuQ5naJOeDAnfOjmhAElE7LXkjuhGn7inLARbeq0HgNhIjTINSFTIw14lEyQqi0WtpCnl/u3d3Z2ttHnmaVrW/g9JP5np7N47jrv585zeu7+PxAAj+P0rIvmAAAAAElFTkSuQmCC"
$bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.StreamSource = [System.IO.MemoryStream][System.Convert]::FromBase64String($base64)
$bitmap.EndInit()
$bitmap.Freeze()
$window.Icon = $bitmap
#Connect to Controls 
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {
    New-Variable  -Name $_.Name -Value $Window.FindName($_.Name) -Force
}
#arrays
$cbxAll = @($cbxFirefox,$cbxPia,$cbxAdobeReader,$cbxPeazip,$cbxChrome,$cbxVsCode,$cbxVsCommunity,$cbxOffice365,$cbxVlc,$cbxPoshcore,$cbxGeforce,$cbxSteam,$cbxCorsairCue,$cbxEpicGames,$cbxOrigin,$cbxPlexServer,$cbxUtorrent,$cbxSabnzbd,$cbxSonarr,$cbxLidarr,$cbxOpenVPN)
$downloads = @{}
#functions
#functions | GUI
function write-2ColorStatus {
    param (
        $checkValue,
        $color1 = "green",
        $color2 = "yellow",
        $ifWrite,
        $elseWrite
    )
    if ($checkValue){
        write-host "$ifWrite" -ForegroundColor $color1
    } else {
        write-host "$elseWrite" -ForegroundColor $color2
    }
}
#functions | Process
function get-InstalledAppViaReg {
    param
    (
        [string]$lookupName = "*",
        [string]$lookupNameEXACT
    )
    if ([IntPtr]::Size -eq 4) {
        $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    else {
        $regpath = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
    }
    if ($lookupNameExact){
        Get-ItemProperty $regpath | .{process{if($_.DisplayName -and $_.UninstallString) { $_ } }} | Select-Object * | Where-Object {$_.DisplayName -like "$lookupNameEXACT"}
    } else {
        Get-ItemProperty $regpath | .{process{if($_.DisplayName -and $_.UninstallString) { $_ } }} | Select-Object * | Where-Object {$_.DisplayName -like "*$lookupName*"}
    }
}
Function get-InstalledAppViaFile{
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
Function get-ProgramFromWeb {
    param (
        [parameter(mandatory=$true)]
        [string]$name,
        [string]$lookupName = $name,              #ex. "Firefox"
        [string]$directDlUrl,       #ex. "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
        [string]$fileType,          #ex. "exe"
        $versionCheck,
        $webVersion,
        $localAppExe
    )
    $dlLoc = "$env:systemdrive\users\$env:USERNAME\downloads"
    Write-Host "$($name): download started" -ForegroundColor Cyan
    write-host "latest version is: $webVersion"
    #disable IE first run wizard, which prevents the Invoke-WebRequest from running on new OS installs
    $regPath = "HKLM:\software\policies\Microsoft\Internet Explorer\Main"
    New-Item -Path $regPath -Force | Out-Null
    New-ItemProperty -Path $regPath -Name "DisableFirstRunCustomize" -PropertyType "DWORD" -Value 1 | Out-Null
    #get installed version
    Write-Host "Checking if $name is currently installed..." -NoNewLine
    $localInstall = get-InstalledAppViaReg -lookupName "*$lookupName*"
    if (-Not($localInstall)){
        if ($localAppExe){
            $localInstall = (test-path $localAppExe)
            $localVer = get-versionFromFile -filePath $localAppExe
        }
    }
    if ($localInstall){
        $localVer = $localInstall.DisplayVersion | select-object -last 1 #The last 1 was because plex installs with two registry versions, sigh...
    } else {
        $localVer = "not installed"
    }
    if ($localInstall){
        Write-Host "Installed " -foregroundcolor green -nonewline;write-host "(version " -NoNewline;write-host $localVer -ForegroundColor Green -NoNewline;write-host ")"
    } else {
        Write-Host "Not installed"
    }
    #version check web
    if ($versionCheck){
        if ($localVer -eq $webVersion){
            write-host "Installed version ($localVer) is the same as latest ($webVersion), no need to install" -ForegroundColor Yellow
            return
        } else {
            write-host "installed version: $localVer, latest version: $webVersion"
        }
    }
    #download from Web
    write-Host "Downloading newest version from web..." -NoNewline
    $save = "$dlLoc\$name.$fileType"
    $start_time = Get-Date
    Import-Module BitsTransfer
    try {
        Start-BitsTransfer -Source $directDlUrl -Destination $save -TransferType Download -ErrorAction Stop
    } catch {
        write-host "bittransfer failed, trying webClient..." -NoNewline
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($directDlUrl,$save)
    }
    if (Test-Path $save){
        Write-Host "Saved to $save" -ForegroundColor Green
        $downloads.add($name, $save)
        Write-Output "Download took: $((Get-Date).Subtract($start_time).seconds) second(s)"
    } else {
        Write-Host "failed" -ForegroundColor Red
    }
    #Finished
    Write-Host "$($name): download finished`n" -ForegroundColor cyan
}
function install-App {
    param (
        $name,
        $installArgs,
        $installer
    )
    write-host "$($name): installation started" -ForegroundColor cyan
    Write-Host "installing $name..." -NoNewline
    Try {
        if (($installArgs -eq "") -or ($null -eq $installArgs)){
            Start-Process -FilePath $installer -ErrorAction Stop
        } else {
            Start-Process -FilePath $installer -ArgumentList $installArgs -ErrorAction Stop -Wait
        }
       Write-Host "done!" -ForegroundColor Green
    } catch {
        Write-Host "failed" -ForegroundColor Red
        return
    }
    write-host "$($name): installation finished`n" -ForegroundColor Cyan
}
function uninstall-App {
    param(
        [parameter(Mandatory=$true)]
        $name,
        $lookupName = $name,
        $lookupNameEXACT,
        [validateset("msiexec","exe")]
        $removeMethod,
        $uninstallArgs,
        $uninstallEXE
    )
    write-host "$($name): uninstall started" -ForegroundColor Cyan
    if ($lookupNameEXACT){
        $localInstall = get-InstalledAppViaReg -lookupNameEXACT $lookupNameEXACT
    } else {
        $localInstall = get-InstalledAppViaReg -lookupName "*$lookupName*"
    }
    if ($localInstall){
        try {
            write-host "stopping all instances of $name..." -NoNewline
            stop-process -name "*$name*" -Force
            write-host "done!" -ForegroundColor Green
            write-host "uninstalling $name..." -NoNewline
            if ($uninstallEXE){
                start-process $uninstallEXE -ArgumentList $uninstallArgs -Wait
                write-host "Done!" -ForegroundColor Green
            } else {
                $uninstall = $localInstall.UninstallString
                if ($removeMethod -eq "msiexec"){
                    $GUID = $localInstall.PSChildName
                    Start-Process msiexec.exe -ArgumentList "/X$GUID /quiet" -Wait
                    Write-Host "Done!" -ForegroundColor Green
                } elseif ($removeMethod -eq "exe") {
                    if (($uninstallArgs -eq "") -or ($null -eq $uninstallArgs)) {
                        start-process $uninstall -Wait -ErrorAction Stop
                    } else {
                        start-process $uninstall -ArgumentList $uninstallArgs -Wait -ErrorAction stop
                    }
                    Write-Host "Done!" -ForegroundColor Green
                }
            } 
        } catch {
            write-host "failed" -ForegroundColor Red
            Write-Warning "You will need to uninstall it manually"
        }
    } else {
        write-host "not installed, skipping"
    }
    write-host "$($name): uninstall finished`n" -ForegroundColor Cyan
}
function remove-download {
    param (
        $name
    )
    write-host "$($name): clean up started" -ForegroundColor cyan
    write-host "deleting downloaded files..." -NoNewline
    try {
        Remove-Item $downloads.$name -Force | Out-Null
        write-host "done!" -ForegroundColor green
    } catch {
        write-host "failed" -ForegroundColor red
    }
    write-host "$($name): clean up finished" -ForegroundColor cyan
}
function get-versionFromFile{
    param (
        $filePath
    )
    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($filePath).FileVersion
    return $fileVersion
}
#functions | app specific
function install-firefox {
    $name = "firefox"
    $webParse = Invoke-WebRequest  "https://product-details.mozilla.org/1.0/firefox_versions.json" | ConvertFrom-Json
    $webVersion = $webParse.psobject.properties.value[-1]
    $directDlUrl = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
    $fileType = "exe"
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType $fileType -webVersion $webVersion -versionCheck $true
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/s"
        install-App -name $name -installArgs "/s" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-firefox {
    uninstall-App -name "firefox" -removeMethod "exe" -uninstallArgs "/s"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-pia {
    $name = "pia"
    $lookupName = "private internet access"
    $dlWebpage = invoke-webrequest -Uri "https://www.privateinternetaccess.com/installer/x/download_installer_win/64"
    $dlWebpageUrl = $dlWebpage.AllElements | Where-object {$_.TagName -eq "meta"} | select-string ".exe"
    $directDlUrl = ($dlWebpageUrl.ToString() -split "=") -split '"' | Select-String ".exe" | Select-Object -First 1
    $fileType = "exe"
    $removeMethod = "exe"
    
    $dlWebpage2 = invoke-webrequest -Uri "https://www.privateinternetaccess.com/pages/download"
    $filename = ($dlWebpage2.ParsedHtml.getElementsByClassName("filename") | Select-Object innerText | Select-Object -First 1).innerText
    $versionMajor = $filename.Substring(16,5)
    $versionMinor = $filename.Substring(22,5)
    $webVersion = "$versionMajor+$versionMinor"

    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType $fileType -webVersion $webVersion -versionCheck $true 
    if ($downloads.$name){
        uninstall-App -name $name -lookupName $lookupName -removeMethod $removeMethod
        install-App -name $name -lookupName $lookupName -installArgs "" -installer $downloads.$name
        remove-download -name $name
        write-host "all finished!`n" -ForegroundColor Green
    } else {
        write-host "file didn't download, skipped install"
    }
}
function uninstall-pia {
    $name = "pia"
    $lookupName = "private internet access"
    $removeMethod = "exe"
    uninstall-App -name $name -lookupName $lookupName -removeMethod $removeMethod
    write-host "all finished!`n" -ForegroundColor Green
}
function install-adobeReader {
    $name = "adobe reader"
    $lookupName = "Acrobat Reader"
    $readerDlpage = Invoke-WebRequest -Uri "https://get.adobe.com/reader/"
    $webVersion = ($readerDlpage.AllElements | Where-Object class -eq "NoBottomMargin" | Select-Object -First 1).innerText
    $webVersion = $webVersion.Replace("Version 20","")
    $ver = $webVersion.Replace(".","")
    $directDlUrl = "http://ardownload.adobe.com/pub/adobe/reader/win/AcrobatDC/$($ver)/AcroRdrDC$($ver)_en_US.exe"
    $fileType = "exe"

    get-ProgramFromWeb -name $name -lookupName $lookupName -directDlUrl $directDlUrl -fileType $fileType -webVersion $webVersion -versionCheck $true
    if ($downloads.$name){
        uninstall-App -name $name -lookupName $lookupName -removeMethod "msiexec"
        install-App -name $name -lookupName $lookupName -installArgs "/sAll" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-adobeReader {
    uninstall-App -name "adobe reader" -lookupName "acrobat reader" -removeMethod "msiexec"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-peazip {
    $name = "peazip"
    $releases = 'https://github.com/giorgiotani/PeaZip/releases'
    $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing
    <#32-bit
    $url32  = $download_page.links | ? href -match 'WINDOWS.exe$' | select -First 1 -expand href
    $version   = $url32 -split '-|.WINDOWS.exe' | select -Last 1 -Skip 1
    URL32    = 'https://github.com' + $url32
    #>
    $url64 = $download_page.links | Where-Object href -match 'WIN64.exe$' | Select-Object -First 1 -expand href
    $webVersion   = $url64 -split '-|.WIN64.exe' | Select-Object -Last 1 -Skip 1
    $url64 = 'https://github.com' + $url64
    get-ProgramFromWeb -name $name -directDlUrl $url64 -fileType "exe" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/SILENT"
        install-app -name $name -installArgs "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -installer $downloads.$name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-peazip {
    uninstall-App -name "peazip" -removeMethod "exe" -uninstallArgs "/SILENT"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-chrome {
    $name = "chrome"
    $directDlUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi" 
    [xml]$rssReleaseFeed = Invoke-webRequest 'http://feeds.feedburner.com/GoogleChromeReleases'
    try{
        [string]$webVersion = ($rssReleaseFeed.feed.entry | Where-object{$_.title.'#text' -match 'Stable'}).content | Select-Object{$_.'#text'} | Where-Object{$_ -match 'Windows'} | ForEach-Object{[version](($_ | Select-string -allmatches '(\d{1,4}\.){3}(\d{1,4})').matches | select-object -first 1 -expandProperty Value)} | Sort-Object -Descending | Select-Object -first 1
    } catch {
        Write-Warning "Could not find latest version"
        $webVersion = "Not Found"
    }
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "msi" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "msiexec"
        install-App -name $name -installArgs "/qn" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-chrome {
    uninstall-App -name "chrome" -removeMethod "msiexec"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-vsCode{
    $name = "vscode"
    $lookupName = "Visual Studio Code"
    $webReleases = Invoke-WebRequest -uri "https://github.com/Microsoft/vscode/releases" -UseBasicParsing
    $webVersion = ($webReleases.Links | Where-Object href -match "/Microsoft/vscode/releases/tag/" | Select-Object -First 1).href
    $webVersion = $webVersion.Substring(31,6)
    $directDlUrl = "https://vscode-update.azurewebsites.net/latest/win32-x64/stable"
    get-ProgramFromWeb -name $name -lookupName $lookupName -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -lookupName $lookupName -removeMethod "exe" -uninstallArgs "/SILENT"
        try {
            install-App -name $name -installArgs "/silent /mergetasks='!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath'" -installer $downloads.$name
            remove-download -name $name
            write-host "$($name): app config started" -ForegroundColor cyan
            Write-Host "setting shortcut to run as admin..." -NoNewline
            $shortcutLoc = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Visual Studio Code\Visual Studio Code.lnk"
            $bytes = [System.IO.File]::ReadAllBytes($shortcutLoc)
            $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
            [System.IO.File]::WriteAllBytes($shortcutLoc, $bytes)
            write-host "done!" -ForegroundColor Green
            write-host "installing extentions..." -NoNewline
            $codeCmdPath = "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
            $extensions = @("ms-vscode.PowerShell","ms-vsts.team","robertohuertasm.vscode-icons","dotjoshjohnson.xml") + $AdditionalExtensions
            foreach ($extension in $extensions) {
                & $codeCmdPath --install-extension $extension --force
            }
            write-host "done!" -ForegroundColor Green
            write-host "$($name): app configuration finished" -ForegroundColor Cyan
        } catch {
            write-host "failed to install" -ForegroundColor red
        }
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n"-ForegroundColor Green
}
function uninstall-vsCode {
    uninstall-App -name "vscode" -lookupName "Microsoft Visual Studio Code" -removeMethod "exe" -uninstallArgs "/SILENT"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-vsCommunity {
    $name = "vsCommunity"
    $nameOfInstaller = "vsInstaller"
    $lookupNameOfInstaller = "Visual Studio Installer"
    $lookupName = "Visual Studio Community"
    # releases: https://docs.microsoft.com/en-us/visualstudio/install/visual-studio-build-numbers-and-release-dates?view=vs-2017
    # commandline options: https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2017
    $web = Invoke-WebRequest -Uri "https://github.com/MicrosoftDocs/visualstudio-docs/blob/master/docs/install/visual-studio-build-numbers-and-release-dates.md" -UseBasicParsing
    $content = $web.Content -split "`n" 
    $releases = $content -match "<td>" ; $releases = $releases -notmatch "<td><div>" ; $releases = $releases -replace "<td>", "" ; $releases = $releases -replace "</td>", "" ; $releases = $releases -match "^[0-9]"
    $latestRelease = $releases | Select-Object -first 2 | Select-Object -Last 1
    $downloadSite = Invoke-WebRequest -Uri "https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=Community&rel=15" -UseBasicParsing
    $content = $downloadSite.Content -split "`n" ; $content = $content -match ".exe" ; $content = $content -split ''''
    $directDlUrl = $content[3]
    get-ProgramFromWeb -name $name -lookupName $lookupName -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $latestRelease
    if ($downloads.$name){
        uninstall-App -name $name -lookupName $lookupName -removeMethod "exe" -uninstallArgs "uninstall --installPath ""${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community"" --passive" -uninstallEXE "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
        uninstall-App -name $nameOfInstaller -lookupName $lookupNameOfInstaller -removeMethod "exe" -uninstallArgs "/uninstall --passive" -uninstallEXE "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
        install-App -name $name -installArgs "--installPath c:\vs --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --passive --norestart" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-vsCommunity {
    uninstall-App -name "vscommunity" -lookupName "Visual Studio Community" -removeMethod "exe" -uninstallArgs "uninstall --installPath ""${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community"" --passive" -uninstallEXE "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
    uninstall-App -name "vsinstaller" -lookupName "Visual Studio Installer" -removeMethod "exe" -uninstallArgs "/uninstall --passive" -uninstallEXE "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-office365{
    $name = "office deployment tool"
    $deploymentTool = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11306-33602.exe"
    get-ProgramFromWeb -name $name -directDlUrl $deploymentTool -fileType "exe"
    write-host "extracting deployment tool..." -NoNewline
    start-process -filePath $downloads.$name -ArgumentList "/extract:$env:userprofile\downloads /quiet" -wait
    write-host "done!" -ForegroundColor Green
    #create uninstall xml
    write-host "creating xml install config file..." -ForegroundColor Cyan -NoNewline
[xml]$xml = @"
<Configuration ID="b9d16ddc-9ef9-444a-9f6b-1af83cc7562c">
<Add OfficeClientEdition="32" Channel="Monthly" ForceUpgrade="TRUE">
<Product ID="O365HomePremRetail">
<Language ID="MatchOS" />
</Product>
</Add>
<Property Name="SharedComputerLicensing" Value="0" />
<Property Name="PinIconsToTaskbar" Value="TRUE" />
<Property Name="SCLCacheOverride" Value="0" />
<Updates Enabled="TRUE" />
<RemoveMSI />
<AppSettings>
<Setup Name="Company" Value="TomsNet" />
</AppSettings>
<Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@
    $xml.save("$env:userprofile\downloads\installAll.xml")
    write-host "done!" -ForegroundColor Green
    write-host "starting install..." -NoNewline 
    start-process -FilePath "$env:userprofile\downloads\setup.exe" -ArgumentList "/configure $env:userprofile\downloads\installAll.xml" -Wait
    write-host "done!" -ForegroundColor Green
    write-host "cleaning up..." -NoNewline
    remove-item $downloads.$name -Force
    remove-item "$env:userprofile\downloads\*.xml" -Force
    remove-item "$env:userprofile\downloads\setup.exe" -Force
    write-host "done!" -ForegroundColor Green
    write-host "`nall finished!`n" -ForegroundColor Green
}
function uninstall-office365{
    #get Office Deployment Tool
    $name = "office deployment tool"
    $deploymentTool = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_11306-33602.exe"
    get-ProgramFromWeb -name $name -directDlUrl $deploymentTool -fileType "exe"
    write-host "extracting deployment tool..." -NoNewline
    start-process -filePath $downloads.$name -ArgumentList "/extract:$env:userprofile\downloads /quiet" -wait
    write-host "done!" -ForegroundColor Green
    #create uninstall xml
    write-host "creating xml uninstall config file..." -ForegroundColor Cyan -NoNewline
[xml]$xml = @"
<Configuration>
<Display Level="None" AcceptEULA="TRUE" />
<Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
<Remove>
<Product ID="O365HomePremRetail">
<Language ID="en-us" />
</Product>
</Remove>
</Configuration>
"@
    $xml.save("$env:userprofile\downloads\uninstallAll.xml")
    write-host "done!" -ForegroundColor Green
    write-host "starting uninstall..." -NoNewline 
    start-process -FilePath "$env:userprofile\downloads\setup.exe" -ArgumentList "/configure $env:userprofile\downloads\uninstallAll.xml" -Wait
    write-host "done!" -ForegroundColor Green
    write-host "cleaning up..." -NoNewline
    remove-item $downloads.$name -Force
    remove-item "$env:userprofile\downloads\*.xml" -Force
    remove-item "$env:userprofile\downloads\setup.exe" -Force
    write-host "done!" -ForegroundColor Green
    write-host "`nall finished!`n" -ForegroundColor Green
}
function install-vlc{
    $name = "vlc"
    $dlPage = Invoke-WebRequest "http://download.videolan.org/pub/videolan/vlc/last/win64/"
    $installFiles = ($dlPage.Links).href
    $latest = $installFiles | where-object{$_ -like "*.msi"}
    $directDlUrl = "http://download.videolan.org/pub/videolan/vlc/last/win64/$latest"
    $webVersion = $latest -replace "vlc-",""; $webVersion = $webVersion -replace "-win64.msi",""
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "msi" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/S"
        install-App -name $name -installArgs "/passive" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor green
}
function uninstall-vlc{
    uninstall-App -name "vlc" -removeMethod "msiexec"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-poshcore{
    $name = "poshcore"
    $lookupName = "PowerShell"
    $webReleases = Invoke-WebRequest -uri "https://github.com/PowerShell/PowerShell/releases/latest" -UseBasicParsing
    $directDlUrl = ($webReleases.Links | Where-Object href -match "x64.msi" | Select-Object -First 1).href
    $directDlUrl = "https://github.com$directDlUrl"
    $webVersion = $directDlUrl.Substring(42,5) + ".0"
    get-ProgramFromWeb -name $name -lookupName $lookupName -directDlUrl $directDlUrl -fileType "msi" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -lookupName $lookupName -removeMethod "msiexec"
        install-App -name $name -installArgs "/qn /norestart" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-poshcore{
    uninstall-App -name "poshcore" -lookupName "PowerShell" -removeMethod "msiexec"
    write-host "all finished!`n" -ForegroundColor Green
}
function install-geforce{
    $experienceName = "geforce experience"
    $driverName = "nvidia graphics driver"
    $experiencePage = Invoke-WebRequest -Uri "https://www.nvidia.com/en-us/geforce/geforce-experience/"
    $experienceLinks = ($experiencePage.links).href
    [string]$experienceDirectDlUrl = $experienceLinks -match ".exe"
    $experienceWebVersion = $experienceDirectDlUrl.Substring(45,10)
    $driverPage = 'http://www.geforce.com/proxy?proxy_url=http%3A%2F%2Fgfwsl.geforce.com%2Fservices_toolkit%2Fservices%2Fcom%2Fnvidia%2Fservices%2FAjaxDriverService.php%3Ffunc%3DDriverManualLookup%26psid%3D101%26pfid%3D815%26osID%3D57%26languageCode%3D1078%26beta%3D0%26isWHQL%3D1%26dltype%3D-1%26sort1%3D0%26numberOfResults%3D10'
    $driverDirectDlUrl = (Invoke-WebRequest $driverPage | ConvertFrom-Json | Select-Object -ExpandProperty IDS)[0].downloadInfo.DownloadURL
    $driverWebVersion = ([System.Uri]$driverDirectDlUrl).Segments[-2].Trim('/')
    get-ProgramFromWeb -name $experienceName -directDlUrl $experienceDirectDlUrl -fileType "exe" -versionCheck $true -webVersion $experienceWebVersion
    get-ProgramFromWeb -name $driverName -directDlUrl $driverDirectDlUrl -fileType "exe" -versionCheck $true -webVersion $driverWebVersion
    if ($downloads.$experienceName){
        $experienceInstall = get-InstalledAppViaReg -lookupName "*$experienceName*"
        # uninstall old nvidia experience
        if ($experienceInstall){
            write-host "$($experienceName):uninstalling old version..." -NoNewline -ForegroundColor Cyan
            $file = $experienceInstall.UninstallString -replace "\s.*$"
            $silentArgs = $experienceInstall.UninstallString -replace "^.*?\s" -replace "$"," -silent"
            start-process -FilePath $file -ArgumentList $silentArgs -Wait
            write-host "done!" -ForegroundColor Green
        }
        install-App -name $experienceName -installArgs "-s -noreboot" -installer $downloads.$experienceName
        remove-download -name $experienceName
    } else {
        write-host "$experienceName didn't download, skipped install."
    }
    if ($downloads.$driverName){
        $driverInstall = get-InstalledAppViaReg -lookupName "*$driverName*"
        if ($driverInstall){
            write-host "$($driverName):uninstalling old version..." -NoNewline -ForegroundColor Cyan
            $file = $driverInstall.UninstallString -replace "\s.*$"
            $silentArgs = $driverInstall.UninstallString -replace "^.*?\s" -replace "$"," -silent"
            start-process -FilePath $file -ArgumentList $silentArgs -Wait
            write-host "done!" -ForegroundColor Green
        }
        install-App -name $driverName -installArgs "-s -noreboot" -installer $downloads.$driverName
        remove-download -name $experienceName
    } else {
        write-host "$driverInstall didn't download, skipped install."
    }
    write-host "`nall finished!`n" -ForegroundColor Green
}
function uninstall-geforce{
    start-process -FilePath "C:\Windows\SysWOW64\RunDll32.EXE" -ArgumentList """C:\Program Files\NVIDIA Corporation\Installer2\InstallerCore\NVI2.DLL"",UninstallPackage Display.GFExperience" -Wait
    write-host "all finished!`n"
}
function install-steam{
    $name = "steam"
    $directDlUrl = "https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe"
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "exe" -versionCheck $false
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/S"
        install-App -name $name -installArgs "/S" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "$name didn't download, skipped install"
    }
    write-host "`nall finished!`n" -ForegroundColor Green
}
function uninstall-steam{
    uninstall-App -name "steam" -removeMethod "exe" -uninstallArgs "/S"
}
function install-corsairCue{
    $name = "corsair icue"
    $directDlUrl = ((invoke-webrequest -uri "https://www.corsair.com/us/en/icue").links | Where-Object href -like "*.msi").href
    $webVersion = $directDlUrl.Substring(49,8)
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "msi" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "msiexec"
        install-App -name $name -installArgs "/QN" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "$name didn't download, skipped install"
    }
    write-host "`nall finished!`n" -ForegroundColor Green
}
function uninstall-corsairCue{
    uninstall-App -name "corsair icue" -removeMethod "msiexec"
    write-host "`nall finished!`n" -ForegroundColor Green
}
function install-epicGames{
    $name = "epic games launcher"
    $directDlUrl = "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi?productName=unrealtournament"
    $x = Invoke-WebRequest -method head -Uri $directDlUrl
    $webVersion = ($x.BaseResponse.ResponseUri.AbsolutePath).Substring(60,5)
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "msi" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -lookupNameEXACT $name -removeMethod "msiexec"
        install-App -name $name -installArgs "/qn /norestart" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "$name didn't download, skipped install"
    }
    write-host "`nall finished`n" -ForegroundColor Green
}
function uninstall-epicGames{
    uninstall-App -lookupNameEXACT "epic games launcher" -removeMethod "msiexec"
    write-host "`nall finished!`n" -ForegroundColor Green
}
function install-origin{
    $name = "origin"
    $directDlUrl = "https://www.dm.origin.com/download"
    $webRequest = invoke-webrequest -Uri "https://chocolatey.org/packages?q=origin"
    $webVersion = ($webRequest.links | Where-Object {$_.href -like "*/origin/*"} | Select-Object -first 1).href ; $webVersion = $webVersion.Substring(17,13)
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/noUpdate /uninstall /silent"
        install-App -name $name -installArgs "/silent" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "$name didn't download, skipped install"
    }
    write-host "`nall finished`n" -ForegroundColor Green
}
function uninstall-origin{
    uninstall-App -name "origin" -removeMethod "exe" -uninstallArgs "/noUpdate /uninstall /silent"
    write-host "`all finished!`n" -ForegroundColor Green
}
function install-plexServer{
    $name = "plex media server"
    $web = Invoke-WebRequest -Uri "https://plex.tv/api/downloads/1.json?channel=plexpass" | ConvertFrom-Json
    $directDlUrl = $web.computer.windows.releases.url
    $webVersion = ($web.computer.windows.version).Substring(0,$webVersion.IndexOf('-'))
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/uninstall /quiet" -uninstallEXE "C:\ProgramData\Package Cache\{0a25946e-e061-47a7-9da4-d055bb78571d}\pms.exe"
        install-app -name $name -installArgs "/quiet" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "$name didn't download, skipped install"
    }
    write-host "`nall finished`n" -ForegroundColor Green
}
function uninstall-plexServer{
    uninstall-App -name "plex media server" -removeMethod "exe" -uninstallArgs "/uninstall /quiet" -uninstallEXE "C:\ProgramData\Package Cache\{0a25946e-e061-47a7-9da4-d055bb78571d}\pms.exe"
    write-host "`nall finished`n" -ForegroundColor Green
}
function install-utorrent{
    $name = "utorrent"
    $lookupName = "torrent"
    $directDlUrl = "http://download.ap.bittorrent.com/track/stable/endpoint/utorrent/os/windows"
    $web = invoke-webrequest -uri "https://www.utorrent.com/downloads/win"
    $webVer = ($web.AllElements | where-object {$_.tagName -eq "h3"} | select-object innerHTML) -like "*Stable*"
    $webVer = ($webVer.split('(')).split(')')[1] ; $webVer = $webVer.Replace(" build ",".")
    get-ProgramFromWeb -name $name -lookupName $lookupName -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-app -name $name -uninstallArgs "/uninstall /S" -lookupName $lookupName -removeMethod "exe" -uninstallEXE "$env:APPDATA\uTorrent\uTorrent.exe"
        install-App -name $name -installArgs "/S" -installer $downloads.$name
        remove-download $name
    } else {
        write-host "$name didn't download, skipped install"
    }
    write-host "`nall finished`n" -ForegroundColor Green
}
function uninstall-utorrent{
    uninstall-app -name "utorrent" -uninstallArgs "/uninstall /S" -lookupName "torrent" -removeMethod "exe" -uninstallEXE "$env:APPDATA\uTorrent\uTorrent.exe"
    write-host "`nall finished!`n" -ForegroundColor Green
}
function install-sabnzbd{
    $name = "sabnzbd"
    $webReleases = Invoke-WebRequest -uri "https://github.com/sabnzbd/sabnzbd/releases/latest" -UseBasicParsing
    $directDlUrl = ($webReleases.Links | Where-Object href -match ".exe" | Select-Object -First 1).href
    $directDlUrl = "https://github.com$directDlUrl"
    $webVersion = $directDlUrl.Substring(53,5)
    get-ProgramFromWeb -name $name -lookupName $lookupName -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallEXE "$env:ProgramFiles\SABnzbd\uninstall.exe" -uninstallArgs "/S"
        install-App -name $name -installArgs "/S" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}

function uninstall-sabnzbd{
    uninstall-App -name "sabnzbd" -removeMethod "exe" -uninstallEXE "$env:ProgramFiles\SABnzbd\uninstall.exe" -uninstallArgs "/S"
    write-host "`nall finished!`n" -ForegroundColor Green
}
function install-sonarr{
    $name = "sonarr"
    $webReleases = Invoke-WebRequest -uri "https://github.com/sonarr/sonarr/releases" -UseBasicParsing
    $webVersion = ($webReleases.Links | Where-Object href -match "/Sonarr/Sonarr/releases/tag/" | Select-Object -First 1).href
    $webVersion = $webVersion.Substring(29,($webVersion.length - 29))
    $directDlUrl = ($webReleases.Links | Where-Object href -match ".exe" | Select-Object -First 1).href
    $directDlUrl = "https://download.sonarr.tv/v2/master/latest/NzbDrone.master.exe"
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion -localAppExe "$env:ProgramData\NzbDrone\bin\NzbDrone.exe"
    if ($downloads.$name){
        if (test-path $env:ProgramData\NzbDrone\bin){
            write-host "uninstalling manually since there's no uninstaller" -ForegroundColor Cyan
            write-host "uninstalling service..." -NoNewline
            Start-Process -FilePath "$env:ProgramData\NzbDrone\bin\ServiceUninstall.exe" -Wait
            write-host "done!" -ForegroundColor Green
            write-host "deleting folder..." -NoNewline
            remove-item $env:ProgramData\NzbDrone -Force
            if (test-path $env:ProgramData\NzbDrone){
                write-host "folder is still there. sorry i couldn't delete it" -ForegroundColor Yellow
            } else {
                write-host "done!" -ForegroundColor Green
            }
        } else {
            write-host "sonarr is not installed, skipping uninstall."
        }
        install-App -name $name -installArgs "/S" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-sonarr{
    if (test-path $env:ProgramData\NzbDrone\bin){
        write-host "uninstalling manually since there's no uninstaller" -ForegroundColor Cyan
        write-host "uninstalling service..." -NoNewline
        Start-Process -FilePath "$env:ProgramData\NzbDrone\bin\ServiceUninstall.exe" -Wait
        write-host "done!" -ForegroundColor Green
        write-host "deleting folder..." -NoNewline
        remove-item $env:ProgramData\NzbDrone -Force
        if (test-path $env:ProgramData\NzbDrone){
            write-host "folder is still there. sorry i couldn't delete it" -ForegroundColor Yellow
        } else {
            write-host "done!" -ForegroundColor Green
        }
    } else {
        write-host "sonarr is not installed, skipping uninstall."
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function install-radarr{
    $name = "radarr"
    $webReleases = Invoke-WebRequest -uri "https://github.com/Radarr/Radarr/releases" -UseBasicParsing
    $webVersion = ($webReleases.Links | Where-Object href -match "/Radarr/Radarr/releases/tag/" | Select-Object -First 1).href
    $webVersion = $webVersion.Substring(29,($webVersion.Length - 29))
    $directDlUrl = ($webReleases.Links | Where-Object href -match ".exe" | Select-Object -First 1).href
    $directDlUrl = "https://github.com$directDlUrl"
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion -localAppExe "$env:ProgramData\radarr\bin\Radarr.exe"
    if ($downloads.$name){
        if (test-path $env:ProgramData\Lidarr\bin){
            write-host "uninstalling manually since there's no uninstaller" -ForegroundColor Cyan
            write-host "uninstalling service..." -NoNewline
            Start-Process -FilePath "$env:ProgramData\Lidarr\bin\ServiceUninstall.exe" -Wait
            write-host "done!" -ForegroundColor Green
            write-host "deleting folder..." -NoNewline
            remove-item $env:ProgramData\Lidarr -Force
            if (test-path $env:ProgramData\Lidarr){
                write-host "folder is still there. sorry i couldn't delete it" -ForegroundColor Yellow
            } else {
                write-host "done!" -ForegroundColor Green
            }
        } else {
            write-host "lidarr is not installed, skipping uninstall."
        }
        install-App -name $name -installArgs "/S" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-radarr{
    write-host "all finished!`n" -ForegroundColor Green
}
function install-lidarr{
    $name = "lidarr"
    $webReleases = Invoke-WebRequest -uri "https://github.com/lidarr/Lidarr/releases" -UseBasicParsing
    $webVersion = ($webReleases.Links | Where-Object href -match "/lidarr/Lidarr/releases/tag/" | Select-Object -First 1).href
    $webVersion = $webVersion.Substring(29,($webVersion.Length - 29))
    $directDlUrl = ($webReleases.Links | Where-Object href -match ".exe" | Select-Object -First 1).href
    $directDlUrl = "https://github.com$directDlUrl"
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion -localAppExe "$env:ProgramData\Lidarr\bin\Lidarr.exe"
    if ($downloads.$name){
        if (test-path $env:ProgramData\Lidarr\bin){
            write-host "uninstalling manually since there's no uninstaller" -ForegroundColor Cyan
            write-host "uninstalling service..." -NoNewline
            Start-Process -FilePath "$env:ProgramData\Lidarr\bin\ServiceUninstall.exe" -Wait
            write-host "done!" -ForegroundColor Green
            write-host "deleting folder..." -NoNewline
            remove-item $env:ProgramData\Lidarr -Force
            if (test-path $env:ProgramData\Lidarr){
                write-host "folder is still there. sorry i couldn't delete it" -ForegroundColor Yellow
            } else {
                write-host "done!" -ForegroundColor Green
            }
        } else {
            write-host "lidarr is not installed, skipping uninstall."
        }
        install-App -name $name -installArgs "/S" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function uninstall-lidarr{
    if (test-path $env:ProgramData\Lidarr\bin){
        write-host "uninstalling manually since there's no uninstaller" -ForegroundColor Cyan
        write-host "uninstalling service..." -NoNewline
        Start-Process -FilePath "$env:ProgramData\Lidarr\bin\ServiceUninstall.exe" -Wait
        write-host "done!" -ForegroundColor Green
        write-host "deleting folder..." -NoNewline
        remove-item $env:ProgramData\Lidarr -Force
        if (test-path $env:ProgramData\Lidarr){
            write-host "folder is still there. sorry i couldn't delete it" -ForegroundColor Yellow
        } else {
            write-host "done!" -ForegroundColor Green
        }
    } else {
        write-host "lidarr is not installed, skipping uninstall."
    }
    write-host "all finished!`n" -ForegroundColor Green
}
function install-openVPN{
    $name = "openVPN"
    $webReleases = Invoke-WebRequest -uri "https://github.com/OpenVPN/openvpn/releases" -UseBasicParsing
    $directDlUrl = Invoke-WebRequest -Uri "https://openvpn.net/community-downloads/" -UseBasicParsing
    $directDlUrl = ($directDlUrl.Links | Where-Object href -like "https://swupdate.openvpn.org/community/releases/*.exe" | Select-Object -First 1).href
    $webVersion = ($webReleases.Links | Where-Object href -match "/OpenVPN/openvpn/releases/tag/" | Select-Object -First 1).href
    $webVersion = $webVersion.Substring(31,($webVersion.length - 31))
    get-ProgramFromWeb -name $name -directDlUrl $directDlUrl -fileType "exe" -versionCheck $true -webVersion $webVersion
    if ($downloads.$name){
        uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/S"
        install-App -name $name -installArgs "/S" -installer $downloads.$name
        remove-download -name $name
    } else {
        write-host "file didn't download, skipped install"
    }
    write-host "`nall finished!`n" -ForegroundColor Green
}
function uninstall-openVPN{
    uninstall-App -name $name -removeMethod "exe" -uninstallArgs "/S"
    write-host "`nall finished!`n" -ForegroundColor Green
}
#events
$btnInstall.Add_Click({
    write-host "user clicked install button" -ForegroundColor gray -BackgroundColor Black
    $cbxAll_checked = @()
    $cbxAll_notChecked = @()
    foreach($item in $cbxAll){
        if ($item.IsChecked){
            $cbxAll_checked += $item
        }
        else {
            $cbxAll_notChecked += $item
        }
    }
    if (-Not($cbxAll_checked)){
        write-host "no software selected, please select something to install" -ForegroundColor Yellow
    } else {
        foreach ($item in $cbxAll_checked){
            switch ($item.Content){
                "firefox" {install-firefox}
                "pia" {install-pia}
                "adobe reader" {install-adobeReader}
                "peazip" {install-peazip}
                "chrome" {install-chrome}
                "vscode" {install-vsCode}
                "vscommunity" {install-vsCommunity}
                "office 365" {install-office365}
                "vlc" {install-vlc}
                "poshcore" {install-poshcore}
                "geforce" {install-geforce}
                "steam" {install-steam}
                "corsair cue" {install-corsairCue}
                "epic games" {install-epicGames}
                "origin" {install-origin}
                "plex media server" {install-plexServer}
                "utorrent" {install-utorrent}
                "sabnzbd" {install-sabnzbd}
                "sonarr" {install-sonarr}
                "radarr" {install-radarr}
                "lidarr" {install-lidarr}
                "openvpn" {install-openvpn}
                default {write-host "sorry, i don't have a installer for $($item.Content) yet" -ForegroundColor Yellow} 
            }
        }
    }
})
$btnUninstall.Add_Click({
    write-host "user clicked uninstall button" -ForegroundColor gray -BackgroundColor Black
    $cbxAll_checked = @()
    $cbxAll_notChecked = @()
    foreach($item in $cbxAll){
        if ($item.IsChecked){
            $cbxAll_checked += $item
        }
        else {
            $cbxAll_notChecked += $item
        }
    }
    if (-Not($cbxAll_checked)){
        write-host "no software selected, please select something to uninstall" -ForegroundColor Yellow
    } else {
        foreach ($item in $cbxAll_checked){
            switch ($item.Content){
                "firefox" {uninstall-firefox}
                "pia" {uninstall-pia}
                "adobe reader" {uninstall-adobeReader}
                "peazip" {uninstall-peazip}
                "chrome" {uninstall-chrome}
                "vscode" {uninstall-vsCode}
                "vscommunity" {uninstall-vsCommunity}
                "office 365" {uninstall-office365}
                "vlc" {uninstall-vlc}
                "poshcore" {uninstall-poshcore}
                "geforce" {uninstall-geforce}
                "steam" {uninstall-steam}
                "corsair cue" {uninstall-corsairCue}
                "epic games" {uninstall-epicGames}
                "origin" {uninstall-origin}
                "plex media server" {uninstall-plexServer}
                "utorrent" {uninstall-utorrent}
                "sabnzbd" {uninstall-sabnzbd}
                "sonarr" {uninstall-sonarr}
                "radarr" {uninstall-radarr}
                "lidarr" {uninstall-lidarr}
                "openvpn" {uninstall-openvpn}
                default {write-host "sorry, i don't have an uninstaller for $($item.Content) yet" -ForegroundColor Yellow} 
            }
        }
    }
})
$btnUpgrade.Add_Click({
    write-host "user clicked upgrade button" -ForegroundColor gray -BackgroundColor Black
    $cbxAll_checked = @()
    $cbxAll_notChecked = @()
    foreach($item in $cbxAll){
        if ($item.IsChecked){
            $cbxAll_checked += $item
        }
        else {
            $cbxAll_notChecked += $item
        }
    }
    if (-Not($cbxAll_checked)){
        write-host "no software selected, please select something to upgrade" -ForegroundColor Yellow
    } else {
        foreach ($item in $cbxAll_checked){
            write-host "starting upgrade of $($item.Content)" -ForegroundColor cyan
        }
    }
})
$btnBackup.Add_Click({
    write-host "user clicked backup button" -ForegroundColor gray -BackgroundColor Black
    $cbxAll_checked = @()
    $cbxAll_notChecked = @()
    foreach($item in $cbxAll){
        if ($item.IsChecked){
            $cbxAll_checked += $item
        }
        else {
            $cbxAll_notChecked += $item
        }
    }
    if (-Not($cbxAll_checked)){
        write-host "no software selected, please select something to backup" -ForegroundColor Yellow
    } else {
        foreach ($item in $cbxAll_checked){
            write-host "starting backup of $($item.Content)" -ForegroundColor cyan
        }
    }
})
$btnRestore.Add_Click({
    write-host "user clicked Restore button" -ForegroundColor gray -BackgroundColor Black
    $cbxAll_checked = @()
    $cbxAll_notChecked = @()
    foreach($item in $cbxAll){
        if ($item.IsChecked){
            $cbxAll_checked += $item
        }
        else {
            $cbxAll_notChecked += $item
        }
    }
    if (-Not($cbxAll_checked)){
        write-host "no software selected, please select something to restore" -ForegroundColor Yellow
    } else {
        foreach ($item in $cbxAll_checked){
            write-host "starting restore of $($item.Content)" -ForegroundColor cyan
        }
    }
})
$btnQa.Add_Click({
    write-host "user clicked qa button" -ForegroundColor gray -BackgroundColor Black
    Write-host "Checking Installed Apps status" -ForegroundColor Cyan
    function get-AppStatus {
        param (
            [parameter(Mandatory=$true)]
            $name,
            $lookupName = $name,
            $byFilePath,
            $swPath
        )
        write-host "$name..." -NoNewline
        if ($file){
            $app = Get-ChildItem -Path $swPath -ErrorAction SilentlyContinue
            write-2ColorStatus -checkValue $app -ifWrite "installed" -elseWrite "not installed"  
        } else {
            $app = get-InstalledAppViaReg -lookupName "*$lookupName*"
            write-2ColorStatus -checkValue $app -ifWrite "installed" -elseWrite "not installed"
        }
    }
   get-AppStatus -name "firefox"
   get-AppStatus -name "pia" -lookupName "private internet access"
   get-AppStatus -name "adobe reader" -lookupName "Adobe Acrobat Reader DC"
   get-AppStatus -name "peazip"
   get-AppStatus -name "chrome"
   get-AppStatus -name "vscode" -lookupName "Microsoft Visual Studio Code"
   get-AppStatus -name "vscommunity" -lookupName  "Visual Studio Community"
   get-AppStatus -name "office 365"
   get-AppStatus -name "vlc"
   get-AppStatus -name "poshcore" -lookupName  "powershell 6"
   get-AppStatus -name "geforce experience"
   get-AppStatus -name "steam"
   get-AppStatus -name "corsair cue" -lookupName  "corsair icue"
   get-AppStatus -name "epic games"
   get-AppStatus -name "origin"
   get-AppStatus -name "plex server" -lookupName  "plex media server"
   get-AppStatus -name "uTorrent" -lookupName "torrent"
   get-AppStatus -name "SABnzbd"
   get-AppStatus -name "sonarr" -byFilePath "$env:ProgramData\NzbDrone\bin\NzbDrone.exe"
   get-AppStatus -name "radarr" -byFilePath "$env:ProgramData\radarr\bin\Radarr.exe"
   get-AppStatus -name "lidarr" -byFilePath "$env:ProgramData\Lidarr\bin\Lidarr.exe"
   get-AppStatus -name "openVPN"
   write-host "`nall finished!`n" -ForegroundColor Green
})
$btnClean.Add_Click({
    #Get Stats before
    $FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
    $datetime = (Get-Date).toString("yyyyMMddHHmmss")

    # Check for Admin rights
    Write-host "Checking to make sure you have Local Admin rights..." -foreground Cyan -NoNewline
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Warning "Please run this script as an Administrator!"
        If (!($psISE)){"Press any key to continue…";[void][System.Console]::ReadKey($true)}
        Exit 1
    }
    Write-Host "Done!" -ForegroundColor Green

    #Delete DNS cache
    Write-Host "Deleting DNS Cache..." -ForegroundColor Cyan -NoNewline
        Clear-DnsClientCache
    Write-Host "Done!" -ForegroundColor Green

    #Delete System Restore Points
    function Delete-ComputerRestorePoints{
        [CmdletBinding(SupportsShouldProcess=$True)]
        param(  
            [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
            $restorePoints
        )
        begin{
            $fullName="SystemRestore.DeleteRestorePoint"
            $isLoaded=([AppDomain]::CurrentDomain.GetAssemblies() | foreach {$_.GetTypes()} | where {$_.FullName -eq $fullName}) -ne $null
            if (!$isLoaded){
                $SRClient= Add-Type -memberDefinition  @"
                [DllImport ("Srclient.dll")]
                public static extern int SRRemoveRestorePoint (int index);
"@  -Name DeleteRestorePoint -NameSpace SystemRestore -PassThru
            }
        }
        process{
            foreach ($restorePoint in $restorePoints){
                if($PSCmdlet.ShouldProcess("$($restorePoint.Description)","Deleting Restorepoint")) {
                    [SystemRestore.DeleteRestorePoint]::SRRemoveRestorePoint($restorePoint.SequenceNumber) | Out-Null
                }
            }
        }
    }

    Write-Host "Deleting System Restore Points..." -ForegroundColor Cyan -NoNewline
        $removeDate = (Get-Date).AddDays(-14) 
        Get-ComputerRestorePoint | Where { $_.ConvertToDateTime($_.CreationTime) -lt $removeDate } | Delete-ComputerRestorePoints
    Write-Host "Done!" -ForegroundColor Green

    # Clean Rouge folders
    Write-host "Deleting Rouge folders..." -foreground Cyan -NoNewline
        if (test-path C:\Config.Msi) {remove-item -Path C:\Config.Msi -force -recurse -ErrorAction SilentlyContinue}
        if (test-path c:\Intel) {remove-item -Path c:\Intel -force -recurse}
        if (test-path c:\Lenovo) {remote-item -Path c:\Lenovo -force -recurse}
        if (test-path c:\PerfLogs) {remove-item -Path c:\PerfLogs -force -recurse}
        if (test-path $env:windir\memory.dmp) {remove-item $env:windir\memory.dmp -force}
    Write-host "Done!" -ForegroundColor Green

    # Delete Windows Error Reporting files
    Write-host "Deleting Windows Error Reporting files..." -foregroundColor Cyan -NoNewline
        if (test-path C:\ProgramData\Microsoft\Windows\WER) {Get-ChildItem -Path C:\ProgramData\Microsoft\Windows\WER -Recurse | Remove-Item -force -recurse}
    Write-Host "Done!" -ForegroundColor Green

    # Delete System and User Temp files
    Write-host "Deleting System and User Temp Files..." -ForegroundColor Cyan -NoNewline
        $ErrorActionPreference = 'SilentlyContinue'
        Remove-Item -Path "$env:windir\Temp\*" -Force -Recurse 
        Remove-Item -Path "$env:windir\minidump\*" -Force -Recurse 
        Remove-Item -Path "$env:windir\Prefetch\*" -Force -Recurse 
        $Env:temp | Remove-Item -Recurse -Force 
        $appDataWinDir = "C:\Users\*\AppData\Local\Microsoft\Windows"
        Remove-Item -Path "$appDataWinDir\WER\*" -Force -Recurse 
        Remove-Item -Path "$appDataWinDir\Temporary Internet Files\*" -Force -Recurse
        Remove-Item -Path "$appDataWinDir\IECompatCache\*" -Force -Recurse
        Remove-Item -Path "$appDataWinDir\IECompatUaCache\*" -Force -Recurse
        Remove-Item -Path "$appDataWinDir\IEDownloadHistory\*" -Force -Recurse
        Remove-Item -Path "$appDataWinDir\INetCache\*" -Force -Recurse
        Remove-Item -Path "$appDataWinDir\INetCookies\*" -Force -Recurse
        Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\*" -Force -Recurse
    Write-Host "Done!" -ForegroundColor Green

    #Delete Windows Updates Downloads
    Write-host "Deleting Windows Updates Downloads..." -ForegroundColor cyan -NoNewline
        Stop-Service wuauserv -Force
        Stop-Service TrustedInstaller -Force
        Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Force -Recurse -ErrorAction SilentlyContinue
        Remove-Item $env:windir\Logs\CBS\* -force -recurse -ErrorAction SilentlyContinue
        Start-Service wuauserv
        Start-Service TrustedInstaller
    Write-Host "Done!" -ForegroundColor Green

    #Install Windows Cleanup
    if (!(Test-Path c:\windows\System32\cleanmgr.exe)) {
        Write-host "Installing Windows Cleanup..." -foreground Cyan
        copy-item $env:windir\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe $env:windir\System32
        copy-item $env:windir\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui $env:windir\System32\en-US
        Write-Host "Done!" -ForegroundColor Green
    }

    # Run Windows Disk Cleanup Utility
    Write-host "Running Windows System Cleanup..." -foreground Cyan -NoNewline

    # Set StateFlags setting for each item in Windows disk cleanup utility
    $StateFlags = 'StateFlags0013'
    $StateRun = $StateFlags.Substring($StateFlags.get_Length()-2)
    $StateRun = '/sagerun:' + $StateRun 
    $regPathVolumeCaches = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        if  (-not (get-itemproperty -path "$regPathVolumeCaches\Active Setup Temp Folders" -name $StateFlags)) {
            set-itemproperty -path "$regPathVolumeCaches\Active Setup Temp Folders" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\BranchCache" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Downloaded Program Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Internet Cache Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Offline Pages Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Old ChkDsk Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Previous Installations" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Memory Dump Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Recycle Bin" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Service Pack Cleanup" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Setup Log Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\System error memory dump files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\System error minidump files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Temporary Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Temporary Setup Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Thumbnail Cache" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Update Cleanup" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Upgrade Discarded Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\User file versions" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows Defender" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows Error Reporting Archive Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows Error Reporting Queue Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows Error Reporting System Archive Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows Error Reporting System Queue Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows Error Reporting Temp Files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows ESD installation files" -name $StateFlags -type DWORD -Value 2
            set-itemproperty -path "$regPathVolumeCaches\Windows Upgrade Log Files" -name $StateFlags -type DWORD -Value 2
        }

    Start-Process -FilePath CleanMgr.exe -ArgumentList $StateRun  -WindowStyle Hidden -Wait
    Write-Host "Done!" -ForegroundColor Green

    #Clear Event Logs
    Write-host "Clearing All Event Logs..." -foreground Cyan -NoNewline
        $EventLogs = wevtutil el 
        ForEach ($EventLog in $EventLogs){
            try{
                wevtutil cl "$EventLog"
            } catch {}
        }
    Write-Host "Done!" -ForegroundColor Green

    #Google Chrome Cleanup
    Write-Host "Cleaning Google Chrome..." -ForegroundColor Cyan -NoNewline
        Stop-Process -name "chrome" -Force
        Start-Sleep -Seconds 5
        $chromeItems = @('Archived History',
                    'Cache\*',
                    'Cookies',
                    'History',
                    'Login Data',
                    'Top Sites',
                    'Visited Links',
                    'Web Data')
        $chromeFolder = "$($env:LOCALAPPDATA)\Google\Chrome\User Data\Default"
        $chromeItems | % { 
            if (Test-Path "$Folder\$_") {
                Remove-Item "$Folder\$_" 
            }
        }
    Write-Host "Done!" -ForegroundColor Green

    #Firefox Cleanup
    Write-Host "Cleaning Mozilla Firefox..." -ForegroundColor Cyan -NoNewline
        Stop-Process -name "firefox" -force
        Start-Sleep -Seconds 5
        Remove-Item -path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache\* -Recurse -Force -EA SilentlyContinue
        Remove-Item -path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache\*.* -Recurse -Force -EA SilentlyContinue
        Remove-Item -path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cache2\entries\*.* -Recurse -Force -EA SilentlyContinue
        Remove-Item -path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\thumbnails\* -Recurse -Force -EA SilentlyContinue
        Remove-Item -path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\cookies.sqlite -Recurse -Force -EA SilentlyContinue
        Remove-Item -path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\webappsstore.sqlite -Recurse -Force -EA SilentlyContinue
        Remove-Item -path C:\Users\*\AppData\Local\Mozilla\Firefox\Profiles\*.default\chromeappsstore.sqlite -Recurse -Force -EA SilentlyContinue

    Write-Host "Done!" -ForegroundColor Green
    ""

    # Report Stats
    Write-host "Disk Usage before and after cleanup" -foreground Yellow
        $FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
    Write-Host "Free Space Before:" ([math]::round($FreespaceBefore, 4)) "GB"
    Write-Host "Free Space After:" ([math]::round($FreespaceAfter, 4)) "GB"

    #Get-ChildItem –Path "C:\temp\WinClean*.log" -Force | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | Remove-Item
})
$btnRemoveWin10Apps.Add_Click({
    write-host "user clicked remove win10 apps button" -ForegroundColor gray -BackgroundColor Black
     # Get a list of all apps
     Write-Host "Starting built-in AppxPackage, AppxProvisioningPackage and Feature on Demand V2 removal process" -ForegroundColor Cyan
     $AppArrayList = Get-AppxPackage -PackageTypeFilter Bundle -AllUsers | Select-Object -Property Name, PackageFullName | Sort-Object -Property Name
     # White list of appx packages to keep installed
     $WhiteListedApps = @(
         "Microsoft.Windows.Photos",
         "Microsoft.WindowsCalculator",
         "Microsoft.WindowsStore"
     )
     foreach ($App in $AppArrayList) {
         # If application name not in appx package white list, remove AppxPackage and AppxProvisioningPackage
         if ($App.Name -in $WhiteListedApps) {
             Write-Host "Skipping excluded application package: $($App.Name)"
         }
         else {
             # Gather package names
             $AppPackageFullName = Get-AppxPackage -PackageTypeFilter Bundle -AllUsers -Name $App.Name | Select-Object -ExpandProperty PackageFullName
             $AppProvisioningPackageName = Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $App.Name } | Select-Object -ExpandProperty PackageName
             # Attempt to remove AppxPackage
             if ($AppPackageFullName -ne $null) {
                 try {
                     Write-Host "Removing AppxPackage: $($AppPackageFullName)..." -NoNewline
                     Remove-AppxPackage -Package $AppPackageFullName -ErrorAction Stop | Out-Null
                     Write-Host "Done!" -ForegroundColor Green
                 }
                 catch [System.Exception] {
                     Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                 }
             }
             else {
                 Write-Host "Unable to locate AppxPackage: $($AppPackageFullName)"
             }

             # Attempt to remove AppxProvisioningPackage
             if ($AppProvisioningPackageName -ne $null) {
                 try {
                     Write-Host "Removing AppxProvisioningPackage: $($AppProvisioningPackageName)..." -NoNewLine
                     Remove-AppxProvisionedPackage -PackageName $AppProvisioningPackageName -Online -ErrorAction Stop | Out-Null
                     Write-Host "Done!" -ForegroundColor Green
                 }
                 catch [System.Exception] {
                     Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
                 }
             }
             else {
                 Write-Host "Unable to locate AppxProvisioningPackage: $($AppProvisioningPackageName)" -ForegroundColor Yellow
             }
         }
     }
     # White list of Features On Demand V2 packages
     Write-Host "Starting Features on Demand V2 removal process" -ForegroundColor Cyan
     $WhiteListOnDemand = "NetFX3|Tools.Graphics.DirectX|Tools.DeveloperMode.Core|Language|Browser.InternetExplorer|OneCoreUAP|Media.WindowsMediaPlayer|OpenSSH.Server|OpenSSH.Client|Hello.Face.Resource"
     # Get Features On Demand that should be removed
     try {
         $OSBuildNumber = Get-WmiObject -Class "Win32_OperatingSystem" | Select-Object -ExpandProperty BuildNumber
         # Handle cmdlet limitations for older OS builds
         $OnDemandFeatures = Get-WindowsCapability -Online -LimitAccess -ErrorAction Stop | Where-Object { $_.Name -notmatch $WhiteListOnDemand -and $_.State -like "Installed"} | Select-Object -ExpandProperty Name
         foreach ($Feature in $OnDemandFeatures) {
             try {
                 Write-Host "Removing Feature on Demand V2 package: $($Feature)..." -NoNewline
                 # Handle cmdlet limitations for older OS builds
                 if ($OSBuildNumber -le "16299") {
                     Get-WindowsCapability -Online -ErrorAction Stop | Where-Object { $_.Name -like $Feature } | Remove-WindowsCapability -Online -ErrorAction Stop | Out-Null
                     Write-Host "Done!" -ForegroundColor Green
                 }
                 else {
                     Get-WindowsCapability -Online -LimitAccess -ErrorAction Stop | Where-Object { $_.Name -like $Feature } | Remove-WindowsCapability -Online -ErrorAction Stop | Out-Null
                     Write-Host "Done!" -ForegroundColor Green
                 }
             }
             catch [System.Exception] {
                 Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
             }
         }
     }
     catch [System.Exception] {
         Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor DarkCyan
     }
     # Complete
     Write-Host "Completed built-in AppxPackage, AppxProvisioningPackage and Feature on Demand V2 removal process" -ForegroundColor Cyan
     write-host "All Finished!" -ForegroundColor Green
})
#show GUI
$window.ShowDialog() | out-Null
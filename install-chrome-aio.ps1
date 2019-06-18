#Requires -RunAsAdministrator

# enable TLS 1.2
#  - This is needed sometimes when working with websites
write-host "enabling TLS 1.2..." -NoNewline
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
write-host "done!" -ForegroundColor Green

# downloading chrome
write-host "downloading google chrome..." -NoNewline
$directDlUrl = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$saveToPath = "$env:USERPROFILE\desktop\chrome.msi"
# Invoke-WebRequest -Uri $directDlUrl -OutFile $saveToPath
write-host "done" -ForegroundColor Green

# checking if chrome is installed via Registry
$regpath = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
$installedChrome = Get-ItemProperty $regpath | .{process{if($_.DisplayName -and $_.UninstallString) { $_ }}} | Select-Object * | Where-Object {$_.DisplayName -like "*chrome*"}

# uninstalling if chrome is already installed
if ($installedChrome){
    write-host "stopping all instances of chrome..." -NoNewline
    stop-process -name "*chrome*" -Force -ErrorAction SilentlyContinue
    write-host "done!" -ForegroundColor Green
    
    write-host "uninstalling chrome..." -NoNewline
    $GUID = $installedChrome.PSChildName
    try {
        Start-Process msiexec.exe -ArgumentList "/X$GUID /quiet" -Wait
        write-host "done!" -ForegroundColor Green
    } catch {
        write-host "failed" -ForegroundColor Red
        Write-Warning "!@#$...error be like..."
        throw $_.exception.message
    }
}

# installing chrome
write-host "installing chrome..." -NoNewline
try {
    Start-Process -FilePath $saveToPath -ArgumentList "/qn" -ErrorAction Stop -Wait
    write-host "done!" -ForegroundColor Green
} catch {
    write-host "!@#$...didn't install...heres the error..." -ForegroundColor Red
    throw $_.exception.message
}

# housecleaning
write-host "deleting the downloaded chrome msi..." -NoNewline
remove-item $savetoPath -Force | Out-Null
write-host "done!" -ForegroundColor Green

write-host "`n`nalright sparky! we done done!`n"

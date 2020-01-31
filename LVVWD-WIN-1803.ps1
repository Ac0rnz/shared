# Windows In-Place upgrade Command Center
#
# ~ 2017 - Initially created by Micah Lewis and Dustin Murphy in 2017 to do a Windows In-place upgrade
# 11/06/18 - TomK - Updated to include Lenovo Driver/BIOS update functionality
# 11/14/18 - TomK - Updated to include Driver/BIOS Log button and path as well as Model column
# 11/15/18 - TomK - Changed color scheme and added Restart PC button
# 01/10/18 - TomK - Added Wake on Lan and WMI fix button. Added Groupboxes and rearranged button layout.
#					- Added check to not include mlodel 30AS in driver pushes
# 01/16/19 - TomK - Changed Wake on Lan user to a Read-Only SQL user (from lansweeperuser to lansweeperRO)

$StartLocation = Get-Location

function Get-TimeStamp {
    
    return "--{0:MM/dd/yy} {0:HH:mm:ss}--" -f (Get-Date)
    
}

Function Get-LoggedOnUser
 {
	$output = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $args[0]).UserName
	If ($output -eq $null)
	{
		$output = ""
	}
	return $output
 }

Function Get-BIOSStatus
{
	param([string]$PC)
    $CurrentFull = (Get-WmiObject -Class Win32_BIOS -Namespace root\cimv2 -ComputerName $PC).SMBIOSBIOSVersion
	$Current = $CurrentFull.Substring(0,6)
	$HKLM = 2147483650 #HKEY_LOCAL_MACHINE 
	$reg = [wmiclass]"\\$PC\root\default:StdRegprov"
	$key = "SYSTEM\ITCSD\BIOS" 
	$value = "Latest_Version" 
	$StrValue = $reg.GetStringValue($HKLM, $key, $value)  ## REG_SZ
	$Latest = $StrValue.sValue
	If ($Latest -eq $null){
		$BIOSStatus = "Not Completed"	
	}
	Else {
		$LatestShort = $Latest.Substring(0,6)
		If ($LatestShort -eq $Current){
			$BIOSStatus = "Completed"
		}
		Else {
			$BIOSStatus = "Not Completed"
		}
	}
	return $BIOSStatus
}

Function Get-DriverStatus
{
	param([string]$PC)

	$Path = "\\$PC\c$\Lenovo\Logs\ThinInstaller.log"
	If (Test-Path $Path){
		$Find = Select-String -Path $Path -Pattern "balloon been suppressed"
		If ($Find){
			$DriverStatus = "Completed"
		}
		Else {
		$DriverStatus = "Not Completed"
		}
	}
	Else {
		$DriverStatus = "Not Completed"
	}
	return $DriverStatus
}

function SortListView
{
 param([parameter(Position=0)][UInt32]$Column)
$Numeric = $true # determine how to sort
# if the user clicked the same column that was clicked last time, reverse its sort order. otherwise, reset for normal ascending sort
if($Script:LastColumnClicked -eq $Column)
{
    $Script:LastColumnAscending = -not $Script:LastColumnAscending
}
else
{
    $Script:LastColumnAscending = $true
}
$Script:LastColumnClicked = $Column
$ListItems = @(@(@())) # three-dimensional array; column 1 indexes the other columns, column 2 is the value to be sorted on, and column 3 is the System.Windows.Forms.ListViewItem object
foreach($ListItem in $lstView.Items)
{
    # if all items are numeric, can use a numeric sort
    if($Numeric -ne $false) # nothing can set this back to true, so don't process unnecessarily
    {
        try
        {
            $Test = [Double]$ListItem.SubItems[[int]$Column].Text
        }
        catch
        {
            $Numeric = $false # a non-numeric item was found, so sort will occur as a string
        }
    }
    $ListItems += ,@($ListItem.SubItems[[int]$Column].Text,$ListItem)
}
# create the expression that will be evaluated for sorting
$EvalExpression = {
    if($Numeric)
    { return [Double]$_[0] }
    else
    { return [String]$_[0] }
}
# all information is gathered; perform the sort
$ListItems = $ListItems | Sort-Object -Property @{Expression=$EvalExpression; Ascending=$Script:LastColumnAscending}
## the list is sorted; display it in the listview
$lstView.BeginUpdate()
$lstView.Items.Clear()
foreach($ListItem in $ListItems)
{
    $lstView.Items.Add($ListItem[1])
}
$lstView.EndUpdate()
}
Function Get-FreeSpace
{
	$share = "\\" + $args[0] + "\C$"
	$nwobj = New-Object -ComObject WScript.Network
	$status = $nwobj.MapNetworkDrive("X:",$share)
	$drive = Get-PSDrive X
	$gb = (1024 * 1024 * 1024)
	$free = ($drive.Free) /$gb
	$free2 = [math]::Round($free,2)
	$free3 = "$free2 GB"
	$nwobj.RemoveNetworkDrive("X:")
	return $free3
}
#Start Building Form
Add-Type -AssemblyName System.Windows.Forms

$frmMain = New-Object system.Windows.Forms.Form
$frmMain.Text = "Windows 10 In-Place Upgrade Control Center"
$frmMain.BackColor = "#233656"
$frmMain.Width = 1075
$frmMain.Height = 750
$frmMain.Add_Load({
	$cmBox_Deployment.Items.Clear()
	$Deployments = [IO.Directory]::GetFiles($PSScriptRoot,"*.txt")
	ForEach($Deploy in $Deployments)
	{
		$Deploy = Split-Path -Path $Deploy -Leaf
		$Deploy = $Deploy -replace ".txt",""
		$cmBox_Deployment.Items.Add($Deploy)
	}
})

$cmBox_Deployment = New-Object system.windows.Forms.ComboBox
$cmBox_Deployment.Text = "Please Select a Deployment to Control"
$cmBox_Deployment.Width = 320
$cmBox_Deployment.Height = 20
$cmBox_Deployment.Add_SelectedIndexChanged({
	$PC_Path = $PSScriptRoot + "\" + $cmBox_Deployment.SelectedItem + ".txt"
	$computers = Get-Content -Path $PC_Path
	$lstView.Clear()
	$colPCName = $lstView.Columns.Add('PC Name')
	$colPCName.Width = 130
	$colCurOS = $lstView.Columns.Add('Current OS')
	$colCurOS.Width = 80
	$colStatus = $lstView.Columns.Add('Status')
	$colStatus.Width = 80
	$colSize = $lstView.Columns.Add('Free Space')
	$colSize.Width = 80
	$colLoggedOn = $lstView.Columns.Add('Logged On')
	$colLoggedOn.Width = 100
	$colBIOS = $lstView.Columns.Add('BIOS Update')
	$colBIOS.Width = 100
	$colDriver = $lstView.Columns.Add('Driver Update')
	$colDriver.Width = 100
    #$colLogPath = $lstView.Columns.Add('Log Path')
    #$colLogPath.Width = 200
    $colModel = $lstView.Columns.Add('Model')
    $colModel.Width = 50
	$strTotal = 0
	$lblOffline_Count.Text = ""
	$lblStaged_Count.Text = ""
	$lblUpgraded_Count.Text = ""
	$lblCompleted_Count.Text = ""
	$lblTotal_Count.Text = ""
	ForEach ($pc in $computers)
	{
		$item1 = New-Object System.Windows.Forms.ListViewItem("$pc",0)
		$item1.Name = "$pc"
		$item1.SubItems.Add("Unknown")
		$item1.SubItems.Add("Unknown")
		[void] $lstView.Items.Add($item1)
		$strTotal = $strTotal + 1
	}
	$lblTotal_Count.Text = $strTotal
})
$cmBox_Deployment.Add_SelectedValueChanged({
#add here code triggered by the event
})
$cmBox_Deployment.location = new-object system.drawing.point(258,11)
$cmBox_Deployment.Font = "Microsoft Sans Serif,10"
$frmMain.controls.Add($cmBox_Deployment)

$lstView = New-Object system.windows.Forms.ListView
$lstView.Width = 784
$lstView.Height = 582
$lstView.location = new-object system.drawing.point(12,71)
$lstView.CheckBoxes = $True
$lstView.View = 1
$lstView.FullRowSelect = $True
$lstView.Gridlines = $True
$colPCName = $lstView.Columns.Add('PC Name')
$colPCName.Width = 135
$colCurOS = $lstView.Columns.Add('Current OS')
$colCurOS.Width = 85
$colStatus = $lstView.Columns.Add('Status')
$colStatus.Width = 80
$colSize = $lstView.Columns.Add('Free Space')
$colSize.Width = 80
$colLoggedOn = $lstView.Columns.Add('Logged On')
$colLoggedOn.Width = 130
$colBIOS = $lstView.Columns.Add('BIOS Update')
$colBIOS.Width = 110
$colDriver = $lstView.Columns.Add('Driver Update')
$colDriver.Width = 110
#$colLogPath = $lstView.Columns.Add('Log Path')
#$colLogPath.Width = 200
$colModel = $lstView.Columns.Add('Model')
$colModel.Width = 50
$frmMain.controls.Add($lstView)
$lstView.add_ColumnClick({SortListView $_.Column})



$btnUpdate = New-Object system.windows.Forms.Button
$btnUpdate.BackColor = "#99ccff"
$btnUpdate.Text = "Update Status"
$btnUpdate.Width = 120
$btnUpdate.Height = 28
$btnUpdate.Add_Click({
	$PC_Path = $PSScriptRoot + "\" + $cmBox_Deployment.SelectedItem + ".txt"
	$computers = Get-Content -Path $PC_Path
	$lstView.Clear()
	$colPCName = $lstView.Columns.Add('PC Name')
	$colPCName.Width = 130
	$colCurOS = $lstView.Columns.Add('Current OS')
	$colCurOS.Width = 80
	$colStatus = $lstView.Columns.Add('Status')
	$colStatus.Width = 80
	$colSize = $lstView.Columns.Add('Free Space')
	$colSize.Width = 80
	$colLoggedOn = $lstView.Columns.Add('Logged On')
	$colLoggedOn.Width = 100
	$colBIOS = $lstView.Columns.Add('BIOS Update')
	$colBIOS.Width = 100
	$colDriver = $lstView.Columns.Add('Driver Update')
	$colDriver.Width = 100
    #$colLogPath = $lstView.Columns.Add('Log Path')
    #$colLogPath.Width = 200
    $colModel = $lstView.Columns.Add('Model')
    $colModel.Width = 50
	$strOffline = 0
	$lblOffline_Count.Text = ""
	$strStaged = 0
	$lblStaged_Count.Text = ""
	$strUpgraded = 0
	$lblUpgraded_Count.Text = ""
	$strCompleted = 0
	$lblCompleted_Count.Text = ""
	ForEach ($pc2 in $computers)
	{
		$OS_Ver2 = "Not Available"
		$strStatus = "Not Present"
		$strLoggedOn = ""
		$strLoggedOn2 = ""
		$strSpace = ""
		$strBIOS = ""
		$strLenovo = ""
        $strModel = ""

        Write-Host "$(Get-TimeStamp) Getting Info for $pc2..."

		If (Test-Connection -ComputerName $pc2 -Count 1 -Quiet){
			try {$OS_Ver = Get-WmiObject Win32_OperatingSystem -ComputerName $pc2 -ErrorAction Stop} catch
                {$OS_Ver = "Nothing"}
			$OS_Ver2 = $OS_Ver.Version
            If ($OS_Ver2 -eq $null){$OS_Ver2 = "Not Found"}
			$strLoggedOn = Get-LoggedOnUser $pc2
			#$strLoggedOn2 = $strLoggedOn.UserName
			$strSpace = Get-FreeSpace $pc2
			$strPath = "\\$pc2\C$\Win10_Upg\Status\Staged.txt"
			If (Test-Path $strPath -PathType Leaf){
				$strStatus = "Staged"
			}
			$strPath = "\\$pc2\C$\Win10_Upg\Status\Upgraded.txt"
			If (Test-Path $strPath -PathType Leaf){
				$strStatus = "Upgraded"
			}
			$strPath = "\\$pc2\C$\Win10_Upg\Status\Completed.txt"
			If (Test-Path $strPath -PathType Leaf){
				$strStatus = "Completed"
			}
			$strBIOS = Get-BIOSstatus -PC "$pc2"
			$strDriver = Get-DriverStatus -PC "$pc2"
            $product = Get-WmiObject -Class Win32_ComputerSystemProduct -Namespace root\cimv2 -ComputerName $pc2
            $model = $product.name.substring(0,4)
            $strModel = $model
			
		}Else{
			$strStatus = "Offline"
			$strBIOS = "Offline"
			$strDriver = "Offline"
		}
			If ($strStatus -EQ "Offline"){
				$strOffline = $strOffline + 1
			}
			If ($strStatus -EQ "Staged"){
				$strStaged = $strStaged + 1
			}
			If ($strStatus -EQ "Upgraded"){
				$strUpgraded = $strUpgraded + 1
			}
			If ($strStatus -EQ "Completed"){
				$strCompleted = $StrCompleted + 1
			}
			$item1 = New-Object System.Windows.Forms.ListViewItem("$pc2",0)
			$item1.Name = "$pc2"
			$item1.SubItems.Add($OS_Ver2)
			$item1.SubItems.Add($strStatus)
			$item1.SubItems.Add($strSpace)
			$item1.SubItems.Add($strLoggedOn)
			$item1.SubItems.Add($strBIOS)
			$item1.SubItems.Add($strDriver)
            #$item1.SubItems.Add($strLogPath)
            $item1.SubItems.Add($strModel)
			[void] $lstView.Items.Add($item1)
	}
	$lblOffline_Count.Text = $strOffline
	$lblStaged_Count.Text = $strStaged
	$lblUpgraded_Count.Text = $strUpgraded
	$lblCompleted_Count.Text = $strCompleted

    Write-Host "$(Get-TimeStamp) Done Getting Info"
})
$btnUpdate.location = new-object system.drawing.point(675,35)
$btnUpdate.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnUpdate)

$lblOffline = New-Object system.windows.Forms.Label
$lblOffline.Text = "Offline"
$lblOffline.AutoSize = $true
$lblOffline.Width = 25
$lblOffline.Height = 10
$lblOffline.location = new-object system.drawing.point(810,82)
$lblOffline.Font = "Microsoft Sans Serif,12,style=Bold"
$lblOffline.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblOffline)

$lblOffline_Count = New-Object system.windows.Forms.Label
$lblOffline_Count.AutoSize = $true
$lblOffline_Count.Width = 25
$lblOffline_Count.Height = 10
$lblOffline_Count.location = new-object system.drawing.point(810,109)
$lblOffline_Count.Font = "Microsoft Sans Serif,12,style=Bold"
$lblOffline_Count.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblOffline_Count)

$lblStaged = New-Object system.windows.Forms.Label
$lblStaged.Text = "Staged"
$lblStaged.AutoSize = $true
$lblStaged.Width = 25
$lblStaged.Height = 10
$lblStaged.location = new-object system.drawing.point(810,136)
$lblStaged.Font = "Microsoft Sans Serif,12,style=Bold"
$lblStaged.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblStaged)

$lblStaged_Count = New-Object system.windows.Forms.Label
$lblStaged_Count.AutoSize = $true
$lblStaged_Count.Width = 25
$lblStaged_Count.Height = 10
$lblStaged_Count.location = new-object system.drawing.point(810,163)
$lblStaged_Count.Font = "Microsoft Sans Serif,12,style=Bold"
$lblStaged_Count.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblStaged_Count)

$lblUpgraded = New-Object system.windows.Forms.Label
$lblUpgraded.Text = "Upgraded"
$lblUpgraded.AutoSize = $true
$lblUpgraded.Width = 25
$lblUpgraded.Height = 10
$lblUpgraded.location = new-object system.drawing.point(810,190)
$lblUpgraded.Font = "Microsoft Sans Serif,12,style=Bold"
$lblUpgraded.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblUpgraded)

$lblUpgraded_Count = New-Object system.windows.Forms.Label
$lblUpgraded_Count.AutoSize = $true
$lblUpgraded_Count.Width = 25
$lblUpgraded_Count.Height = 10
$lblUpgraded_Count.location = new-object system.drawing.point(810,217)
$lblUpgraded_Count.Font = "Microsoft Sans Serif,12,style=Bold"
$lblUpgraded_Count.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblUpgraded_Count)

$lblCompleted = New-Object system.windows.Forms.Label
$lblCompleted.Text = "Completed"
$lblCompleted.AutoSize = $true
$lblCompleted.Width = 25
$lblCompleted.Height = 10
$lblCompleted.location = new-object system.drawing.point(810,244)
$lblCompleted.Font = "Microsoft Sans Serif,12,style=Bold"
$lblCompleted.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblCompleted)

$lblCompleted_Count = New-Object system.windows.Forms.Label
$lblCompleted_Count.AutoSize = $true
$lblCompleted_Count.Width = 25
$lblCompleted_Count.Height = 10
$lblCompleted_Count.location = new-object system.drawing.point(810,271)
$lblCompleted_Count.Font = "Microsoft Sans Serif,12,style=Bold"
$lblCompleted_Count.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblCompleted_Count)

$lblTotal = New-Object system.windows.Forms.Label
$lblTotal.Text = "Total"
$lblTotal.AutoSize = $true
$lblTotal.Width = 25
$lblTotal.Height = 10
$lblTotal.location = new-object system.drawing.point(810,298)
$lblTotal.Font = "Microsoft Sans Serif,12,style=Bold"
$lblTotal.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblTotal)

$lblTotal_Count = New-Object system.windows.Forms.Label
$lblTotal_Count.AutoSize = $true
$lblTotal_Count.Width = 25
$lblTotal_Count.Height = 10
$lblTotal_Count.location = new-object system.drawing.point(810,325)
$lblTotal_Count.Font = "Microsoft Sans Serif,12,style=Bold"
$lblTotal_Count.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblTotal_Count)

$btnStage = New-Object system.windows.Forms.Button
$btnStage.BackColor = "#EEF4F2"
$btnStage.Text = "Stage PCs"
$btnStage.Width = 113
$btnStage.Height = 27
$btnStage.Add_Click({
	ForEach ($Dest_PC in $lstView.CheckedItems)
	{
		$strSource = "\\storage\lvvwd\smssource$\Windows_10\1803_Upgrade\Pre-Stage"
		$temp = "$Dest_PC"
		$strLength = $temp.Length
		$strShow = ($strLength - 16)
		$Dest_PC2 = $temp.Substring(15,$strShow)
		$strDest = "\\$Dest_PC2\C$\Win10_Upg"
		$strDest2 = "\\$Dest_PC2\C$\Win10_Upg\Status\Staged.txt"
		Write-Host "$(Get-TimeStamp) Staging $Dest_PC2...(This will take a few minutes)"
		#Copy-Item -Path $strSource -Recurse -Destination $strDest
		Copy-Item -Path $strSource -Recurse -Destination $strDest #-Container
		$strFile = Get-Date
		$StrFile2 = "$Dest_PC2, $strFile"
		Out-File -FilePath $strDest2 -InputObject $StrFile2 -Force
		Write-Host "$(Get-TimeStamp) Completed Staging $Dest_PC2."
	}
	ForEach ($Line in $lstView.Items)
	{
		$Line.Checked = $False
	}
})
$btnStage.location = new-object system.drawing.point(810,380)
$btnStage.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnStage)

$btnSelectAll = New-Object system.windows.Forms.Button
$btnSelectAll.BackColor = "#EEF4F2"
$btnSelectAll.Text = "Select All"
$btnSelectAll.Width = 113
$btnSelectAll.Height = 27
$btnSelectAll.Add_Click({
	ForEach ($Line in $lstView.Items)
	{
		$Line.Checked = $True
	}
})
$btnSelectAll.location = new-object system.drawing.point(20,665)
$btnSelectAll.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.Controls.Add($btnSelectAll)

$btnSelectNone = New-Object system.windows.Forms.Button
$btnSelectNone.Backcolor = "#EEF4F2"
$btnSelectNone.Text = "Unselect All"
$btnSelectNone.Width = 113
$btnSelectNone.Height = 27
$btnSelectNone.Add_Click({
	ForEach ($Line in $lstView.Items)
	{
		$Line.Checked = $False
		#$Line.BackColor = "4315e3"
	}
})
$btnSelectNone.Location = new-object system.drawing.point(145,665)
$btnSelectNone.Font = "Microsoft San Serif,10,style=Bold"
$frmMain.Controls.Add($btnSelectNone)

$btnUpgrade = New-Object system.windows.Forms.Button
$btnUpgrade.BackColor = "#EEF4F2"
$btnUpgrade.Text = "Upgrade PCs"
$btnUpgrade.Width = 113
$btnUpgrade.Height = 27
$btnUpgrade.Add_Click({
	ForEach ($Item2 in $lstView.CheckedItems)
	{
		$temp = "$Item2"
		$strLength = $temp.Length
		$strShow = ($strLength -16)
		$Dest_PC2 = $temp.Substring(15,$strShow)
		Write-Host "$(Get-TimeStamp) Starting Upgrade on $Dest_PC2."
		Start-Process -Wait -PSPath ".\PsExec.exe" -ArgumentList "\\$Dest_PC2 -s -w C:\Win10_Upg\source -d cmd /c Auto-Upgrade.cmd"
		Write-Host "$(Get-TimeStamp) Upgrade started on $Dest_PC2."
	}
	ForEach ($Line in $lstView.Items)
	{
		$Line.Checked = $False
	}
})
$btnUpgrade.location = new-object system.drawing.point(810,420)
$btnUpgrade.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnUpgrade)

$btnPost = New-Object system.windows.Forms.Button
$btnPost.BackColor = "#b8c7c4"
$btnPost.Text = "Post-Config"
$btnPost.Width = 113
$btnPost.Height = 27
$btnPost.Add_Click({
	ForEach ($Item2 in $lstView.CheckedItems)
	{
		$temp = "$Item2"
		$strLength = $temp.Length
		$strShow = ($strLength - 16)
		$Dest_PC2 = $temp.Substring(15,$strShow)
		Write-Host "$(Get-TimeStamp) Starting Post-Config on $Dest_PC2."
		Start-Process -Wait -PSPath ".\PsExec.exe" -ArgumentList "\\$Dest_PC2 -s -w C:\Win10_Upg\source -d cmd /c Post-OS-Config.cmd"
		Write-Host "$(Get-TimeStamp) Post-Config started on $Dest_PC2."
	}
	ForEach ($Line in $lstView.Items)
	{
		$Line.Checked = $False
	}
})
$btnPost.location = new-object system.drawing.point(810,460)
$btnPost.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnPost)

$btnClean = New-Object system.windows.Forms.Button
$btnClean.BackColor = "#b8c7c4"
$btnClean.Text = "Clean-Up"
$btnClean.Width = 113
$btnClean.Height = 27
$btnClean.Add_Click({
	ForEach ($Item2 in $lstView.CheckedItems)
	{
		$temp = "$Item2"
		$strLength = $temp.Length
		$strShow = ($strLength - 16)
		$Dest_PC2 = $temp.Substring(15,$strShow)
		Write-Host "$(Get-TimeStamp) Starting CleanUp on $Dest_PC2."
		$folderToDelete = "\\$Dest_PC2\C$\Win10_Upg"
		$ErrorActionPreference='silentlycontinue'
		[io.directory]::delete($folderToDelete, $true)
		$fso = New-Object-ComObject scripting.FileSystemObject
		$fso.DeleteFolder($folderToDelete,$true)
		If (Test-Path ($folderToDelete)) {
			New-Item -ItemType directory -Path .\EmptyFolder
			robocopy .\EmptyFolder $folderToDelete /mir
			Remove-Item .\EmptyFolder
			Remove-Item $folderToDelete
		}
		Write-Host "$(Get-TimeStamp) Completed CleanUp on $Dest_PC2."
	}
	ForEach ($Line in $lstView.Items)
	{
		$Line.Checked = $False
	}
})
$btnClean.location = new-object system.drawing.point(810,500)
$btnClean.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnClean)

$btnLenovo = New-Object system.windows.Forms.Button
$btnLenovo.BackColor = "#7B9BA6"
$btnLenovo.Text = "Update BIOS and Drivers"
$btnLenovo.Width = 113
$btnLenovo.Height = 37
$btnLenovo.Add_Click({
	$DateTime = Get-Date -UFormat "%Y%m%d_%H%M"
	$FileSelected = $cmBox_Deployment.SelectedItem
	$FileSelectedFormatted = "$DateTime" + "_" + "$FileSelected"
    $PCList = "C:\temp\$FileSelectedFormatted" + ".txt"
	New-Item $PCList -Force
	
	$Compatible = @()

	ForEach ($Item in $lstView.CheckedItems){
		$temp = "$Item"
		$strLength = $temp.Length
		$strShow = ($strLength - 16)
		$Dest_PC = $temp.Substring(15,$strShow)

		$product = Get-WmiObject -Class Win32_ComputerSystemProduct -Namespace root\cimv2 -ComputerName $Dest_PC
        $model = $product.name.substring(0,4)
		
		if(-Not($model -eq "30AS")){
			Write-Host "$(Get-TimeStamp) Adding $Dest_PC to list of PCs to receive Lenovo updates."
			$Compatible += $Dest_PC
			Add-Content $PCList -Value $Dest_PC
		} else {
			Write-Host "The 30AS model is not stable, skipping BIOS/Driver Update on $Dest_PC."
		}
	}

	# Create connection to SCCM
	$SiteCode = "S22:"
	$SiteCode2 = "S22"
	$ProviderMachineName = "lvvwdsccm.ntlan.lvvwd.com"
	Import-Module -Name "$(split-path $Env:SMS_ADMIN_UI_PATH)\ConfigurationManager.psd1"
	Set-Location -Path $SiteCode

	# Create Collection
	$ScheduleCol = New-CMSchedule -Start (Get-Date) -RecurInterval Days -RecurCount 7
	$NewCollectionName = New-CMDeviceCollection -Name $FileSelectedFormatted -LimitingCollectionName "DS - All" -RefreshSchedule $ScheduleCol -RefreshType Periodic
	$CollectionID = $NewCollectionName.CollectionID
	$PCs = Get-Content $PCList
	$formatted = $PCs | foreach {"'" + $_ + "',"}
	$formatted[-1] = $formatted[-1].TrimEnd(",")
	$Query = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where name in ($formatted)"
	Add-CMDeviceCollectionQueryMembershipRule -CollectionID $CollectionID -QueryExpression $Query -RuleName "Query"

	#Move Collection to Win10_Inplace folder
	$col = Get-CMDeviceCollection -name $FileSelectedFormatted
	Move-CMObject -inputobject $col -folderpath 's22:\devicecollection\ds\ds-prod\sup\win10_inplace'

	#Create Task Sequence
	$Datetime_Start = ((Get-Date).AddMinutes(30)).ToString('yyyy-MM-dd HH:mm')
	$DateTime_End = ((Get-Date).AddHours(2)).ToString('yyyy-MM-dd HH:mm')
	$schedule = New-CMSchedule -Start $Datetime_Start -End $DateTime_End -Nonrecurring
	New-CMTaskSequenceDeployment -TaskSequencePackageId "S2200042" -CollectionId $CollectionID -DeployPurpose Required -AvailableDateTime $Datetime_Start -DeadlineDateTime $DateTime_End -UseUtcForAvailableSchedule $false -Schedule $schedule -RerunBehavior AlwaysRerunProgram -AllowUsersRunIndependently $false -ShowTaskSequenceProgress $false -SoftwareInstallation $false -SystemRestart $false -InternetOption $false -DeploymentOption DownloadAllContentLocallyBeforeStartingTaskSequence -AllowSharedContent $false -AllowFallback $false

	# Update Collection Membership 
	$null = Invoke-WmiMethod -Path "ROOT\SMS\Site_$($SiteCode2):SMS_Collection.CollectionId='$($CollectionID)'" -Name RequestRefresh -ComputerName $ProviderMachineName
    
    Set-Location $StartLocation

	ForEach ($Line in $lstView.Items)
	{
		$Line.Checked = $False
	}
})
$btnLenovo.location = new-object system.drawing.point(810,540)
$btnLenovo.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnLenovo)

$btnOpenLog = New-Object System.Windows.Forms.Button
$btnOpenLog.BackColor = "#f7efb2"
$btnOpenLog.Text = "Open Log(s)"
$btnOpenLog.Width = 113
$btnOpenLog.Height = 27
$btnOpenLog.Add_Click({
    ForEach ($Item in $lstView.CheckedItems)
    {
        $temp = "$Item"
		$strLength = $temp.Length
		$strShow = ($strLength - 16)
		$PC = $temp.Substring(15,$strShow)
        $LogPath = "\\$PC\c`$\Lenovo\Logs"
        If (Test-Path $LogPath){
            Invoke-Item -Path $LogPath
        } Else {
            Write-Host "Logs do not exist for $PC" -ForegroundColor Yellow
        }
    }
})
$btnOpenLog.location = new-object system.drawing.point(935,380)
$btnOpenLog.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnOpenLog)

$btnRestart = New-Object System.Windows.Forms.Button
$btnRestart.BackColor = "#99ccff"
$btnRestart.Text = "Restart PC(s)"
$btnRestart.Width = 113
$btnRestart.Height = 27
#$btnRestart.ForeColor = "#ffffff"
$btnRestart.Add_Click({
    ForEach ($Item in $lstView.CheckedItems)
    {
        $temp = "$Item"
        $strLength = $temp.Length
		$strShow = ($strLength - 16)
		$PC = $temp.Substring(15,$strShow)
        Write-Host "Sending Restart command to $PC..." -NoNewline
        try {
            Restart-Computer -ComputerName $PC -ErrorAction Stop
            Write-Host "Done!" -ForegroundColor Green
        }
        catch [System.Exception] {
            Write-Host "Looks like someone might be signed in." -ForegroundColor Yellow
            $Option = Read-Host "Do you want to force a reboot? (y/n)"
                try {
                    switch ($Option){
                        'y'{
                            Write-Host "Attempting to restart $PC with the Force option..." -NoNewline
                            Restart-Computer -ComputerName $PC -Force -ErrorAction Stop
                            Write-Host "Done!" -ForegroundColor Green
                        }
                        'n' {
                            Write-Host "You chose to NOT restart the computer in FORCE mode."
                        }
                        default {
                        Write-Host "I didn't receive a 'y' or a 'n', so your gonna have to reboot it yourself"
                        }
                    }
                }
                catch [System.Exception] {
                    Write-Host "Well...that didn't work either :(. Your going to have to reboot it manually, sorry"
                }
        }
    }
})
$btnRestart.location = new-object system.drawing.point(935,420)
$btnRestart.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnRestart)

$btnWMI = New-Object System.Windows.Forms.Button
$btnWMI.BackColor = "#99ccff"
$btnWMI.Text = "WMI Fix"
$btnWMI.Width = 113
$btnWMI.Height = 27
#$btnRestart.ForeColor = "#ffffff"
$btnWMI.Add_Click({
    ForEach ($Item in $lstView.CheckedItems){
        $temp = "$Item"
        $strLength = $temp.Length
		$strShow = ($strLength - 16)
		$PC = $temp.Substring(15,$strShow)
        Write-Host "Starting WMI Fix on $PC" -ForegroundColor Cyan
        try{
            Write-Host "Connecting to $PC..." -NoNewline
            $session = New-PSSession -ComputerName $PC -ErrorAction Stop
            Write-Host "Success" -ForegroundColor Green
        }catch{
            Write-Host "Failed" -ForegroundColor Red
            Write-Host "Looks like PSRemoting is turned off,...attempting to turn on..." -NoNewline
            Start-Process robocopy -ArgumentList "\\storage\lvvwd\smssource$\Applications\Sandbox\kunzt\SysinternalsSuite c:\temp\ PsService.exe"
            Start-Process c:\temp\PsService.exe -ArgumentList "\\$PC setconfig WinRM auto"
            Start-Process c:\temp\PsService.exe -ArgumentList "\\$PC start WinRM"
            $session = New-PSSession -ComputerName $PC -ErrorAction Ignore
                If(get-pssession | where {$_.ComputerName -eq $PC}){
                    write-host "Success!" -ForegroundColor Green
                }Else{
                    Write-Host "Failed" -ForegroundColor Red
                }
        }
        Invoke-Command -Session $session -ScriptBlock {
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
        }
        Write-Host "Finished WMI Fix on $PC" -ForegroundColor Cyan
    }
})
$btnWMI.location = new-object system.drawing.point(935,460)
$btnWMI.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnWMI)

$btnWOL = New-Object System.Windows.Forms.Button
$btnWOL.BackColor = "#99ccff"
$btnWOL.Text = "Wake On Lan"
$btnWOL.Width = 113
$btnWOL.Height = 27
#$btnRestart.ForeColor = "#ffffff"
$btnWOL.Add_Click({
	$lansweeperPW = Read-Host "Please enter the password to the Lansweeper SQL user (lansweeperRO):" -AsSecureString
    ForEach ($Item in $lstView.CheckedItems){
        $temp = "$Item"
        $strLength = $temp.Length
		$strShow = ($strLength - 16)
		$PC = $temp.Substring(15,$strShow)
		Write-Host "Sending WOL Command to $PC..."  -NoNewline
		
		function Send-WOL{
			[CmdletBinding()]
			param(
				[Parameter(Mandatory=$True,Position=1)]
				[string]$mac,
				[string]$ip="255.255.255.255", 
				[int]$port=9
			)
			$broadcast = [Net.IPAddress]::Parse($ip)
			$mac=(($mac.replace(":","")).replace("-","")).replace(".","")
			$target=0,2,4,6,8,10 | % {[convert]::ToByte($mac.substring($_,2),16)}
			$packet = (,[byte]255 * 6) + ($target * 16)
			$UDPclient = new-Object System.Net.Sockets.UdpClient
			$UDPclient.Connect($broadcast,$port)
			[void]$UDPclient.Send($packet, 102) 
		}
		function Invoke-SQL {
			param(
				[string] $sqlServer,[string] $database,[string] $uid,[string] $pwd,[string] $sqlQuery
			  )
		
			$connectionString = "Data Source=$sqlServer; Initial Catalog=$database; User ID = $uid; Password = $pwd"
		
			$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
			$command = new-object system.data.sqlclient.sqlcommand($sqlQuery,$connection)
			$connection.Open()
		
			$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
			$dataset = New-Object System.Data.DataSet
			$adapter.Fill($dataSet) | Out-Null
		
			$connection.Close()
			$dataSet.Tables
		}
		$PCformatted = "'$PC'"
		
        try{
            $query = Invoke-SQL -sqlServer sqlentprod -database lansweeperdb -uid "lansweeperRO" -pwd $lansweeperPW -sqlQuery "Select Top 1000000 tblAssets.AssetID,
  tblAssets.AssetName,
  tblAssets.IPAddress,
  tblAssets.Mac
From tblAssets
  Inner Join tblAssetCustom On tblAssets.AssetID = tblAssetCustom.AssetID
  Inner Join tsysAssetTypes On tsysAssetTypes.AssetType = tblAssets.Assettype
Where tblAssetCustom.State = 1 AND AssetName = $PCformatted"

			Send-WOL -mac $query.Mac -ip $query.IPAddress
            Write-Host "Success" -ForegroundColor Green
        }catch{Write-Host "Failed" -ForegroundColor Red}
    }
})
$btnWOL.location = new-object system.drawing.point(935,500)
$btnWOL.Font = "Microsoft Sans Serif,10,style=Bold"
$frmMain.controls.Add($btnWOL)

$gb_Win10Inplace = New-Object system.Windows.Forms.Groupbox
$gb_Win10Inplace.height 	= 228
$gb_Win10Inplace.width 		= 129
$gb_Win10Inplace.text		= "Win10 In-Place"
#$gb_Win10Inplace.BackColor  = "#0a1a35"
$gb_Win10Inplace.ForeColor  = "#ffffff"
$gb_Win10Inplace.location	= New-Object System.Drawing.Point(800,360)
$frmMain.controls.Add($gb_Win10Inplace)


$gb_Tools = New-Object system.Windows.Forms.Groupbox
$gb_Tools.height 		= 180
$gb_Tools.width 		= 129
$gb_Tools.text			= "Tools"
#$gb_Tools.BackColor  	= "#0a1a35"
$gb_Tools.ForeColor  	= "#ffffff"
$gb_Tools.location		= New-Object System.Drawing.Point(925,360)
$frmMain.controls.Add($gb_Tools)

<#
$lblTools = New-Object system.windows.Forms.Label
$lblTools.Text = "Tools"
$lblTools.AutoSize = $true
$lblTools.Width = 25
$lblTools.Height = 10
$lblTools.location = new-object system.drawing.point(965,350)
$lblTools.Font = "Microsoft Sans Serif,10"
$lblTools.ForeColor = "#EEF4F2"
$frmMain.controls.Add($lblTools)
#>
[void]$frmMain.ShowDialog()
$frmMain.Dispose()
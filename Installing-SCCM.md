# Installation Steps

Resouces:
- [Recommended hardware for Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/plan-design/configs/recommended-hardware)
- [Size and scale numbers for System Center Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/plan-design/configs/size-and-scale-numbers)
- [Client numbers for sites and hierarchies](https://docs.microsoft.com/en-us/configmgr/core/plan-design/configs/size-and-scale-numbers#bkmk_clientnumbers)
- [The content library in System Center Configuration Manager (no_sms_on_drive.sms file)](https://docs.microsoft.com/en-us/configmgr/core/plan-design/hierarchy/the-content-library)
- [Configuration Manager Perf and Scale Guidance Whitepaper - Preview](https://gallery.technet.microsoft.com/Configuration-Manager-ba55428e)

## Configuring the recommended disk configurations for SCCM
- Disks
    - D: | SCCM_Install | 50GB
    - E: | SCCM_SQL_MDF | 75GB
    - F: | SCCM_SQL_LDF | 25GB
    - H: | SQL_TempDB | 25GB
    - G: | SQL_WSUS_Database | 25GB
    - I: | SCCM_Application_Sources | 500GB
    - J: | SCCM_ContentLibrary | 500GB
    - copy no_sms_on_drive.sms to all drives but J:
        Note: This prevents SCCM from copying content library files to the drive
- Servers
    - DC
    - SQL
    - SCCM
    - CA

## Setup DHCP
```ps
$DNSDomain = 'tomslab.com'
$DNSServerIP = '172.16.11.2'
$DHCPServerIP = '172.16.11.2'
$StartRange = '172.16.11.100'
$EndRange = '172.16.11.200'
$Subnet = '255.255.255.0'
$Router = '172.16.11.1'

Install-WindowsFeature -Name 'DHCP' -IncludeManagementTools

Start-Process "cmd.exe" -Argumentlist '/c "netsh dhcp add securitygroups"' -wait -NoNewWindow
Restart-Service dhcpserver
Add-DHCPServerInDC -DnsName $Env:COMPUTERNAME
Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
Add-DhcpServerV4Scope -Name "DHCP Scope" -StartRange $StartRange -EndRange $EndRange -SubnetMask $Subnet
Set-DhcpServerV4OptionValue -DnsDomain $DNSDomain -DnsServer $DNSServerIP -Router $Router 
Set-DhcpServerv4Scope -ScopeId $DHCPServerIP -LeaseDuration 1.00:00:00
```


## Setting up Service Accounts

Resources:
- [Client Push Installation Account](https://docs.microsoft.com/en-us/configmgr/core/plan-design/hierarchy/accounts#client-push-installation-account)
- [Network Access Account ](https://docs.microsoft.com/en-us/configmgr/core/plan-design/hierarchy/accounts#network-access-account)
- [Reporting Services Point Account](https://docs.microsoft.com/en-us/configmgr/core/plan-design/hierarchy/accounts#reporting-services-point-account)

- Create a Service account in AD for SQL Services
http://harmikbatth.com/2017/02/02/sccm-2016-create-service-and-user-accounts/#page-content
``` ps
New-ADOrganizationalUnit -Name "Service Accounts" -Path "DC=tomslab,DC=com"
$sPassword = "Somepass1" | ConvertTo-SecureString -AsPlainText -Force

# SCCM Service Users
class svcAccount {
    [string]$name
    [string]$description;
}
$svcAccounts = @(`
[svcAccount]@{name="svc_SCCM_SQLService";description="Account used for SQL Server service account on SQL Server"}
[svcAccount]@{name="svc_SCCM_NetAccess";description="Account used for Network Access Account"}
[svcAccount]@{name="svc_SCCM_ClientPush";description="Account use for Installing SCCM client on Client workstations"}
[svcAccount]@{name="svc_SCCM_SSRS";description="Account used for SQL Reporting Services"}
[svcAccount]@{name="svc_SCCM_DomainJoin";description="Domain account used to join machine to the domain during OSD"})

Foreach ($svcAccount in $svcAccounts){
    New-ADUser -Name $($svcAccount.name) -AccountPassword $sPassword -Description $($svcAccount.description) -Enabled $true -PasswordNeverExpires $true
    Get-ADUser $($svcAccount.name) | Move-ADObject -TargetPath "OU=Service Accounts,DC=tomslab,DC=com"
}

# SCCM Service Groups

class svcGroups {
    [string]$name
    [string]$description;
}
$svcGroups = @(`
[svcGroups]@{name="svc_SCCM_Admins";description="Require Local Admin rights for all SCCM Servers and Client Computers"}
[svcGroups]@{name="svc_SCCM_SiteServs";description="Domain group containing all SCCM servers in the hierarchy Group"})

Foreach ($svcGroup in $svcGroups){
    New-ADGroup -Name $($svcGroup.name) -Description $($svcGroup.description) -GroupScope Global
}

Invoke-Command -ComputerName "lab1-sccm.tomslab.com" -ScriptBlock { Add-LocalGroupMember -Group "Administrators" -Member "svc_SCCM_Admins", "svc_SCCM_SiteServs" }

```

## Installing IIS, BITS, and RDC (Remote Differential Compression)
``` ps
Install-WindowsFeature Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Http-Redirect,Web-Net-Ext,Web-ISAPI-Ext,Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,Web-Http-Tracing,Web-Windows-Auth,Web-Filtering,Web-Stat-Compression,Web-Mgmt-Tools,Web-Mgmt-Compat,Web-Metabase,Web-WMI,BITS,RDC
```

## Installing SQL 2017, SSMS, and Report Server
- Resources :
    - [Supported SQL Server versions for Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/plan-design/configs/support-for-sql-server-versions)

- Set SQL Server to run under a Domain Account
```ps
setspn -A MSSQLSERVER/SQL:1433 tomslab\svc_SCCM_SQL
setspn -A MSSQLSERVER/SQL.tomslab.com:1433 tomslab\svc_SCCM_SQL
```
- Open Firewall Ports
1433 - SQL Service
4022 - SQL Broker Service
``` ps
New-NetFirewallRule -DisplayName "SQL" -Profile Domain,Public,Private -Direction Inbound -LocalPort 1433,4022 -RemotePort Any -Protocol TCP -Program Any -Action Allow -Group "Tom's Rules"
```
- Install SQL Server
```ps
Start-Process "I:\setup.exe" -ArgumentList '/qs /action="install" /IACCEPTSQLSERVERLICENSETERMS /Features="SQL" /INSTANCENAME="MSSQLSERVER" /SQLSVCAccount="tomslab\svc_SCCM_SQL" /SQLSVCPassword="Somepass1" /SQLSYSAdminAccounts="BUILTIN\ADMINISTRATORS" /SQLSVCStartUpType="automatic" /AGTSVCAccount="tomslab\svc_SCCM_SQL" /AGTSVCPassword="Somepass1" /AGTSVCStartUpType="automatic" /SQLCollation="SQL_Latin1_General_CP1_CI_AS" /SecurityMode="SQL" /SAPWD="Somepass1" /SQLUSERDBDIR="E:\Data" /SQLUSERDBLOGDIR="F:\Logs" /SQLBackupDir="G:\Backups" /SQLTempdbDir="H:\TempDB" /SQLTempdbFileCount="8" /SQLTempdbFileSize="8" /SQLTempdbFileGrowth="256" /SQLTempdbLogDir="H:\TempDB" /SQLTempdbLogFileGrowth="256" /SQLTempdbLogFilesize="8" /FileStreamLevel=0 /ErrorReporting=0 /SQMReporting=0 /SQLSvcInstantFileInit="False" /BrowserSvcStartupType="Disabled"' -Wait
```
- Install SQL Server Cumulative Update
```ps
# Install
Start-Process ".\SQLServer2017-KB4527377-x64.exe" -ArgumentList "/q /IAcceptSQLServerLicenseTerms /Action=Patch /AllInstances" -Wait
Restart-Computer
```
```sql
--Verify--
Select SERVERPROPERTY('ProductUpdateLevel') as 'ProductUpdate Level'
```
- Install SQL Server Management Studio
```ps
Start-Process ".\SSMS-Setup-ENU.exe" -Argumentlist "/install /quiet /passive /norestart" -Wait
```
## Install SQL Report Server
```ps
# Initial Install
Start-Process ".\SQLServerReportingServices.exe" -Argumentlist "/quiet /norestart /IAcceptLicenseTerms /Edition=Eval /log c:\temp\SSRSInstall.log" -Wait

# Configuration
function Get-ConfigSet()
{
	return Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" `
		-class MSReportServer_ConfigurationSetting -ComputerName localhost
}

# Allow importing of sqlps module
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Retrieve the current configuration
$configset = Get-ConfigSet

$configset

If (! $configset.IsInitialized)
{
	# Get the ReportServer and ReportServerTempDB creation script
	[string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script

	# Import the SQL Server PowerShell module
	Import-Module sqlps -DisableNameChecking | Out-Null

	# Establish a connection to the database server (localhost)
	$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $env:ComputerName
	$conn.ApplicationName = "SSRS Configuration Script"
	$conn.StatementTimeout = 0
	$conn.Connect()
	$smo = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $conn

	# Create the ReportServer and ReportServerTempDB databases
	$db = $smo.Databases["master"]
	$db.ExecuteNonQuery($dbscript)

	# Set permissions for the databases
	$dbscript = $configset.GenerateDatabaseRightsScript($configset.WindowsServiceIdentityConfigured, "ReportServer", $false, $true).Script
	$db.ExecuteNonQuery($dbscript)

	# Set the database connection info
	$configset.SetDatabaseConnection("(local)", "ReportServer", 2, "", "")

	$configset.SetVirtualDirectory("ReportServerWebService", "ReportServer", 1033)
	$configset.ReserveURL("ReportServerWebService", "http://+:80", 1033)

	# For SSRS 2016-2017 only, older versions have a different name
	$configset.SetVirtualDirectory("ReportServerWebApp", "Reports", 1033)
	$configset.ReserveURL("ReportServerWebApp", "http://+:80", 1033)

	$configset.InitializeReportServer($configset.InstallationID)

	# Re-start services?
	$configset.SetServiceState($false, $false, $false)
	Restart-Service $configset.ServiceName
	$configset.SetServiceState($true, $true, $true)

	# Update the current configuration
	$configset = Get-ConfigSet

	# Output to screen
	$configset.IsReportManagerEnabled
	$configset.IsInitialized
	$configset.IsWebServiceEnabled
	$configset.IsWindowsServiceEnabled
	$configset.ListReportServersInDatabase()
	$configset.ListReservedUrls();

	$inst = Get-WmiObject –namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14" `
		-class MSReportServer_Instance -ComputerName localhost

	$inst.GetReportServerUrls()
}

```

## Installing WSUS Role
```ps
# Install the WSUS role
Install-WindowsFeature -ComputerName localhost -Name UpdateServices-Services, UpdateServices-DB -IncludeManagementTools -Restart

# Create the directory for WSUS
Invoke-Command -ComputerName localhost -ScriptBlock { New-Item -Name WSUS -Type Directory -Path "\\lab1-storage\Admin" -Force | Out-Null }

# Run the post installation task command to configure WSUS
Invoke-Command -ComputerName $WsusServer -ScriptBlock { Start-Process -FilePath "C:\Program Files\Update Services\Tools\wsusutil.exe" -ArgumentList "postinstall CONTENT_DIR=\\lab1-storage\Admin\WSUS SQL_INSTANCE_NAME=lab1-SQL.tomslab.com" -Wait -NoNewWindow }

# Enable remote IIS management
Install-WindowsFeature -ComputerName localhost -Name Web-Mgmt-Service

# Create a firewall exception by running the following command in PowerShell
New-NetFirewallRule -Group "Tom's Rules" -Name "IISRemote management" -DisplayName "IISRemote management" -Description "IISRemote management" -Enabled True -Profile Domain,public,private -Action Allow -Direction Inbound -Service "WMSVC"
or
Invoke-Command -ComputerName localhost -ScriptBlock { Start-Process -FilePath C:\Windows\system32\netsh.exe -ArgumentList 'advfirewall firewall add rule name="IIS Remote Management" dir=in action=allow service=WMSVC'}

# Enable remote IIS management in the registry
Invoke-Command -ComputerName localhost -ScriptBlock { New-Item -Path "HKLM:\SOFTWARE\Microsoft\WebManagement\Server" -Name Favorites -ItemType Directory -Force | Out-Null }
Invoke-Command -ComputerName localhost -ScriptBlock {New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WebManagement\Server" -Name "EnableRemoteManagement" -PropertyType DWord -Value "00000001" -Force}

# Configure the Service WMSVC to start automatically and start the service
Get-Service -ComputerName localhost -Name WMSVC | Set-Service -StartupType Automatic
Invoke-Command -ComputerName localhost -ScriptBlock { Start-Service -Name WMSVC }

# Set the Private Memory Limit (KB) for the WSUS Application Pool to 0 (zero) and reset IIS
Invoke-Command -ComputerName localhost -ScriptBlock { Set-WebConfiguration "/system.applicationHost/applicationPools/add[@name='WsusPool']/recycling/periodicRestart/@privateMemory" -Value 0 }
Invoke-Command -ComputerName localhost -ScriptBlock { iisreset }

# Update WSUS IIS App Pool settings
# https://docs.microsoft.com/en-us/sccm/core/plan-design/configs/recommended-hardware
$wsusPool = get-item IIS:\AppPools\WsusPool
$wsusPool.queueLength = 2000
$wsusPool.recycling.periodicRestart.privateMemory = 1024000

# If you need to move the DB, you can stop the AppPool and WSUS service, move it then start them up again
Stop-WebAppPool WSUSPool
Stop-Service WsusService
Start-Service WsusService
Start-WebAppPool WSUSPool
```

## Installing the Windows 10 ADK
Required for use during imaging and for the prereqs for SCCM
https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-8.1-and-8/dn621910(v=win.10)
Logs located at: %temp%\adk
```ps
Start-Process ".\adksetup.exe" -Argumentlist "/quiet /features OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.UserStateMigrationTool" -Wait
```

## Extending the AD Schema

Resources: 
- [Prepare Active Directory for site publishing](https://docs.microsoft.com/en-us/configmgr/core/plan-design/network/extend-the-active-directory-schema)

```ps
start-process .\SC_Configmgr_SCEP_1902.exe -ArgumentList "/auto" -Wait

# Adds Boundaries and site information for clients
start-process "c:\SC_Configmgr_SCEP_1902\SMSSETUP\BIN\X64\extadsch.exe" -Wait

$validation = Select-String -Path "c:\ExtADSch.log" -Pattern "Successfully extended the Active Directory schema"
if ($validation){"Successful!"}else{"Check log at c:\ExtADSch.log"}
```

## Creating the System Management container and setting the permissions

```ps
$root = (Get-ADRootDSE).defaultNamingContext

# Get or create the System Management container
try {$ou = Get-ADObject "CN=System Management,CN=System,$root"}catch{}

if ($ou -eq $null){$ou = New-ADObject -Type Container -name "System Management" -Path "CN=System,$root" -Passthru}

# Get the current ACL for the OU
$acl = get-acl "ad:CN=System Management,CN=System,$root"

# Get the computer's SID
$computer = get-adcomputer "lab1-sccm"
$sid = [System.Security.Principal.SecurityIdentifier] $computer.SID

# Create a new access control entry to allow access to the OU
$adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
$type = [System.Security.AccessControl.AccessControlType] "Allow"
$inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
$ace = new-object System.DirectoryServices.ActiveDirectoryAccessRule $sid,$adRights,$type,$inheritanceType

# Add the ACE to the ACL, then set the ACL to save the changes
$acl.AddAccessRule($ace)
Set-acl -aclobject $acl "ad:CN=System Management,CN=System,$root"
```

## Configuring the Database

```sql
USE master;
GO
CREATE DATABASE CM_S01
ON
( NAME = CM_S01_1,
    FILENAME = 'E:\Data\CM_S01_1.mdf',
    SIZE = 256MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 128MB ),
( NAME = CM_S01_2,
    FILENAME = 'E:\Data\CM_S01_2.mdf',
    SIZE = 256MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 128MB ),
( NAME = CM_S01_3,
    FILENAME = 'E:\Data\CM_S01_3.mdf',
    SIZE = 256MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 128MB ),
( NAME = CM_S01_4,
    FILENAME = 'E:\Data\CM_S01_4.mdf',
    SIZE = 256MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 128MB )
LOG ON
( NAME = CM_S01_log,
    FILENAME = 'F:\Logs\CM_S01_log.mdf',
    SIZE = 512MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 256MB );
GO
USE CM_S01;
EXEC sp_changedbowner 'sa';
ALTER DATABASE CM_S01 SET RECOVERY SIMPLE;
GO

```

## Installing SCCM

```ps
--give SCCM Server admin rights on SQL server
if (-not (Get-LocalGroupMember -Group Administrators -Member "lab1-sccm$" -ErrorAction SilentlyContinue))
    {
        Add-LocalGroupMember -Group Administrators -Member "lab1-sccm$"
    }
```

```ps
# Download SCCM PreReqs
Start-Process 'C:\SC_Configmgr_SCEP_1902\SMSSETUP\BIN\X64\setupdl.exe' -ArgumentList '\\lab1-storage\admin\SCCMPreReqs' -Wait

# Copy the CMTrace.exe tool to the share
Copy-Item "C:\SC_Configmgr_SCEP_1902\SMSSETUP\TOOLS\CMTrace.exe" -Destination "\\lab1-storage\admin\Applications\Unscripted\Microsoft"

#Build the Installation unattended .INI file
$setupConfigFileContent = @"
[Identification]
Action=InstallPrimarySite
      
[Options]
ProductID=EVAL
SiteCode=S01
SiteName=Primary Site 1
SMSInstallDir=C:\Program Files\Microsoft Configuration Manager
SDKServer=lab1-sccm.tomslab.com
RoleCommunicationProtocol=HTTPorHTTPS
ClientsUsePKICertificate=0
PrerequisiteComp=1
PrerequisitePath=\\lab1-storage\admin\SCCMPreReqs
MobileDeviceLanguage=0
ManagementPoint=lab1-sccm.tomslab.com
ManagementPointProtocol=HTTP
DistributionPoint=lab1-sccm.tomslab.com
DistributionPointProtocol=HTTP
DistributionPointInstallIIS=0
AdminConsole=1
JoinCEIP=0
       
[SQLConfigOptions]
SQLServerName=lab1-sql.tomslab.com
DatabaseName=CM_S01
SQLSSBPort=4022
SQLDataFilePath=E:\Data
SQLLogFilePath=F:\Logs
       
[CloudConnectorOptions]
CloudConnector=0
CloudConnectorServer=lab1-sccm.tomslab.com
UseProxy=0
       
[SystemCenterOptions]
       
[HierarchyExpansionOption]
"@

#Save the config file to disk, and copy it to the SCCM Server
New-Item -Path "c:\" -Name "Temp" -ItemType Directory
$setupConfigFileContent | Out-File -FilePath 'C:\temp\ConfigMgrUnattend.ini' -Encoding ascii

# Install SCCM
Start-Process 'C:\SC_Configmgr_SCEP_1902\SMSSETUP\BIN\X64\setup.exe' -Argumentlist '/Script "C:\Temp\ConfigMgrUnattend.ini" /NoUserInput' -Wait

# Monitor install
C:\ConfigMgrSetup.log
C:\Program Files\Microsoft Configuration Manager\Logs\sitecomp.log
```

- [Log file reference](https://docs.microsoft.com/en-us/configmgr/core/plan-design/hierarchy/log-files)

# Post Installation Steps

## Add SCCM Server Roles
- Resources : 
    - [Site and site system prerequisites for Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/plan-design/configs/site-and-site-system-prerequisites)

### Role: Service Connection Point
``` ps
Add-CMServiceConnectionPoint -SiteSystemServerName "lab1-SCCM.tomslab.com" -SiteCode S01 -Mode Online
```

### Role: Endpoint Protection point
```ps
Add-CMEndpointProtectionPoint -SiteSystemServerName "lab1-SCCM.tomslab.com" -SiteCode "S01" -LicenseAgreed:$true -ProtectionService BasicMembership
```

### Role: Fallback status point
Note: You would typically want to install the Fallback status point on a separate server incase of a DDOS attack.
- Source: [Determine the site system roles for Configuration Manager clients](https://docs.microsoft.com/en-us/configmgr/core/clients/deploy/plan/determine-the-site-system-roles-for-clients)

Log: C:\Program Files\Microsoft Configuration Manager\Logs\fspmgr.log
```ps
Add-CMFallbackStatusPoint -SiteSystemServerName "lab1-SCCM.tomslab.com" -SiteCode "S01" -StateMessageNum 10000 -ThrottleInterval 60
```

### Role: Reporting Services point
- Resources : 
    - [How to install a SCCM reporting Services Point](https://www.enhansoft.com/how-to-install-a-sccm-reporting-services-point/)

Note: This has to be done manually (for now). An account must be added first before running the below command. I'm not sure how to create it via commandline... Work in Progress
Log: C:\Program Files\Microsoft Configuration Manager\Logs\srsp.log
```ps
Add-CMReportingServicePoint -SiteSystemServerName "lab1-SQL.tomslab.com" -SiteCode "S01" -UserName "tomslab.com\admin"
```

Note: After the Reporting Services role is installed, you may need to wait 15-20min before doing the following checks
- Go to http://lab1-sql.tomslab.com/reports/browse on the Reporting server, you should see a folder called "ConfigMgr_*"
- Go into the ConfigMgr_* folder and run a report
- Do the same on a machine that is not the Reporting Server, you should see the same results

### Role: Software update point
```ps 
Add-CMSoftwareUpdatePoint -SiteSystemServerName "lab1-sccm.tomslab.com" -SiteCode "S01" -WsusIisPort "8530" -WsusIisSslPort "8531"
```
Update settings
- Config Manager > Administration > Site Configuration > Sites > Primary Site (Right-Click) > Configure Site Components > Software Update Point
    - Classifications
        - Critical Updates
        - Definition Updates
        - Security Updates
        - Service Packs
        - Update Rollups
        - Updates
        - Upgrades
    - Products (check, then uncheck all)
        - Windows 10
            - Windows Defender
        - Microsoft SQL Server 2019
        - Windows Server 2016
        - Windows Server 2019
    - Sync Schedule
        - Enable synchronization on a schedule = checked
            - Custom schedule
                - Occurs every 1 day effective 1/20/2020 12:00 AM
    - Supersedence Rules
        - Immediately expire a superseded software update (lab only)
        - Immediately expire a superseded feature update (lab only)
        - Run WSUS cleanup after synchronization (lab only)
    - Languages
        - English
- Config Manager > Software Library > Software Updates > All Software Updates > Synchronize Software Updates

Log: C:\Program Files\Microsoft Configuration Manager\Logs\wsyncmgr.log

## Configure SCCM Accounts

### Client Push

Resources
- [Ports Used During Configuration Manager Client Deployment](https://docs.microsoft.com/en-us/configmgr/core/clients/deploy/windows-firewall-and-port-settings-for-clients)

Used for installing clients using client push
- Config Manager > Administration > Sites Configuration > Sites > Site (Right-Click)
    - Client Push Installation Settings > Client Push Installation
        - Accounts > New Account > Browse > Enter "svc_SCCM_ClientPush" and enter the password > Apply
Assign local administrator permissions via GPO
- Create a new GPO under Workstations
    - Name "SCCM Settings" > Edit > Computer Configuration > Preferences > Control Panel Settings > Local Users and Groups > New Local Group
        - Group Name = Administrators (built-in)
        - Local Group Member = svc_SCCM_ClientPush
Add Firewall Settings via GPO
- Edit "SCCM Settings" GPO > Computer Configuration > Policies > Windows Settings > Security Settings > Windows Defender Firewall with Advanced Security > Windows Defender Firewall with Advanced > Inbound Rules 
    - New Rule
        - Predefined: Windows Management Instrumentation (WMI)
        - Allow All Connections
    - New Rule
        - Predefined: File and Printer Sharing
        - Allow All Connections

Verify Push account gets added to the clients
- Go to the client VM > Local Users and Groups > Administrators
Verify the Push account (svc_SCCM_ClientPush) got added to the group


### Network Access Account
Used for clients that are not domain joined, operating system deployment, or workgroup clients. For Distribution point to push settings
- Config Manager > Administration > Sites Configuration > Sites > Site (Right-Click)
    - Configure Site Components > Software Distribution > Network Access Account > Specify the account that accesses network locations > New Account > Browse > Enter "svc_SCCM_NetAccess" and enter the password > Apply

## Configure Boundaries and Boundary Groups

Resources:
- [Define site boundaries and boundary groups for System Center Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/servers/deploy/configure/define-site-boundaries-and-boundary-groups)


Boundaries represent a location on your network
- Config Manager > Administration > Hierarchy Configuration > Boundaries (Right-Click) > New Boundary
    - Description = Lab - IP Range"
    - Type = IP address range
    - Starting IP address = 172.16.11.1
    - Ending IP address = 172.16.11.254
- Config Manager > Administration > Hierarchy Configuration > Boundaries (Right-Click) 

A Boundary group tells the clients which distribution point to go to for content
- Config Manager > Administration > Hierarchy Configuration > Boundary Groups > Righ-click > Create Boundary Group
    - Name = Lab IP Range - DP to SCCM
    - Add = 172.16.11.1-172.16.11.254
    - References > Add
        - \\lab1-sccm.tomslab.com

Create a Boundary Group for site assignment
By splitting them out, you can see what boundaries your using for content and what boundaries your using for sites
- Config Manager > Administration > Hierarchy Configuration > Boundary Groups > Righ-click > Create Boundary Group
    - Name = Site Assignment for S01
    - Add = 172.16.11.1-172.16.11.254
    - Reference
        - Use this boundary group for site assignment > check

## Enable Active Directory Discovery Methods

- [Support for Active Directory domains in Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/plan-design/configs/support-for-active-directory-domains)
- [About discovery methods for System Center Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/servers/deploy/configure/about-discovery-methods)

Logs: c:\Program Files\Microsoft Configuration Manager\Logs\adsysdis.log

```ps

# Connect to SCCM
Import-Module "$env:SMS_ADMIN_UI_PATH\..\ConfigurationManager.psd1"
cd s01:

# Enable the Active Directory Forest Discovery
$Schedule = New-CMSchedule -RecurInterval Days -RecurCount 7
Set-CMDiscoveryMethod -ActiveDirectoryForestDiscovery -SiteCode "S01" -Enabled:$true -PollingSchedule $Schedule -EnableActiveDirectorySiteBoundaryCreation:$true -EnableSubnetBoundaryCreation:$true

# Enable the Active Directory Group Discovery
$Schedule = New-CMSchedule -RecurInterval Days -Start ((get-date).ToString("yyyy/MM/dd") + " 00:00:00") -RecurCount 1
Set-CMDiscoveryMethod -ActiveDirectoryGroupDiscovery -SiteCode "S01" -Enabled:$true -PollingSchedule $Schedule -DeltaDiscoveryIntervalMinutes 8 -EnableDeltaDiscovery $True -EnableFilteringExpiredLogon $True -TimeSinceLastLogonDays 90

# Enable the Active Directory System Discovery
$Schedule = New-CMSchedule -RecurInterval Days -Start ((get-date).ToString("yyyy/MM/dd") + " 00:00:00") -RecurCount 1
Set-CMDiscoveryMethod -ActiveDirectorySystemDiscovery -SiteCode "S01" -DeltaDiscoveryIntervalMinutes 8 -Enabled $True -EnableDeltaDiscovery $True -EnableFilteringExpiredLogon $True -PollingSchedule $Schedule -TimeSinceLastLogonDays 90

# Enable the Active Directory User Discovery
$Schedule = New-CMSchedule -RecurInterval Days -Start ((get-date).ToString("yyyy/MM/dd") + " 00:00:00") -RecurCount 1
Set-CMDiscoveryMethod -ActiveDirectoryUserDiscovery -SiteCode "S01" -Enabled:$true -PollingSchedule $Schedule 

# Enable Search By Heartbeat
$Schedule = New-CMSchedule -RecurInterval Minutes -Start ((get-date).ToString("yyyy/MM/dd") + " 00:00:00") -RecurCount 10
Set-CMDiscoveryMethod -Heartbeat -SiteCode "S01" -Enabled $True -PollingSchedule $Schedule

# Enable Search by Network Discovery
Set-CMDiscoveryMethod -NetworkDiscovery -SiteCode "S01" -Enabled $True -NetworkDiscoveryType ToplogyAndClient -SlowNetworkSpeed $True 
```

### Add Scope to Groups

```ps
$DiscoveryAgents = @("SMS_AD_SECURITY_GROUP_DISCOVERY_AGENT","SMS_AD_SYSTEM_DISCOVERY_AGENT","SMS_AD_USER_DISCOVERY_AGENT")

foreach ($agent in $DiscoveryAgents){

    $Discovery = get-ciminstance -Namespace 'root\sms\site_S01' -classname SMS_SCI_Component -filter "componentname =""$agent"""

    if ($agent -eq "SMS_AD_SECURITY_GROUP_DISCOVERY_AGENT"){
        #need to add new Embedded Property to the Props specifying the Search Base...we can overwrite the already existing one too.
        $NewProp = New-CimInstance -ClientOnly -Namespace "root/sms/site_s01" -ClassName SMS_EmbeddedPropertyList -Property @{PropertyListName="Search Bases:Search Scope";Values=[string[]]"LDAP://DC=tomslab,DC=com"}
        $Discovery.PropLists += $NewProp
        
        $ADContainerProp = $Discovery.PropLists | where { $_.PropertyListName -eq "AD Containers" }
        $ADContainerProp.Values = "Search Scope",0,0,1  #Name, Type Setting (Location [0] or Group [1]),Recursive,don't know what this does
    } else {
        $ADContainerProp = $Discovery.PropLists | where { $_.PropertyListName -eq "AD Containers" }
        $ADContainerProp.Values = "LDAP://DC=tomslab,DC=com",0,0,1  #Name, Type Setting (Location [0] or Group [1]),Recursive,don't know what this does
    }

    #set the Changes back to the CIM Instance
    get-ciminstance -Namespace 'root\sms\site_S01' -classname SMS_SCI_Component -filter "componentname =""$agent""" | Set-CimInstance -Property @{PropLists=$Discovery.PropLists}

}

# To run AD Forest Disovery now
Invoke-CMForestDiscovery -SiteCode "S01"
Invoke-CMGroupDiscovery -SiteCode "S01"
Invoke-CMSystemDiscovery -SiteCode "S01"
Invoke-CMUserDiscovery -SiteCode "S01"

# Update the Group Memberships
$AllUserCollection = Get-CMUserCollection -Name "All Users"
Invoke-WmiMethod -Path "ROOT\SMS\Site_S01:SMS_Collection.CollectionId='$($AllUserCollection.CollectionId)'" -Name RequestRefresh -ComputerName "lab1-sccm.tomslab.com"
```
## Configure Client Settings

Resources:
- [Learn how clients find site resources and services for System Center Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/plan-design/hierarchy/understand-how-clients-find-site-resources-and-services) 
- [Client installation methods in System Center Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/clients/deploy/plan/client-installation-methods)
- [How To Install Clients With Client Push](https://docs.microsoft.com/en-us/configmgr/core/clients/deploy/deploy-clients-to-windows-computers#BKMK_ClientPush)

- Config Manager > Administration > Client Settings > Create Custom Client Device Settings
    - Name = Lab Default Settings
    - Client Policy
        - Client policy polling interval (minutes) = 15 #only in Lab, production shouldn't go below 60
    - Software Center
        - Select these new settings to specify company information = Yes
            - Customize
                - Name = Toms Lab
                - Browse = select a logo
                - Select Color
    - Endpoint Protection
        - Manage Endpoint Protection client on client computers = Yes
    - Computer Agent
        - Organization name displayed in Software Center = Tom's Lab
        - PowerShell execution policy = Bypass
- Config Manager > Administration > Client Settings > Lab Default Settings (Right-Click) > Deploy > All Desktop and Server Clients

### Test : Install Client from SCCM
Log: C:\Program Files\Microsoft Configuration Manager\Logs\ccm.log
- Config Manager > Assets and Compliance > Devices > lab1-client (Right-Click) > Install Client
    - Install the client fotware from a specified site = checked
        - Site = S01
or 
- Config Manager > Assets and Compliance > Device Collections > All Systems (Right-Click) > Install Client
- Install the client fotware from a specified site = checked
        - Site = S01-Primary Site 1

## WSUS Config
Log : C:\Program Files\Microsoft Configuration Manager\Logs\WCM.log

# Setup for HTTPS/PKI

## Install Microsoft Certificate Authority using Active Directory Certificate Services

### Install the Role
- Server Manager > Manage > Add Roles and Features > Server Roles
    - Active Directory Certificate Services
### Post Installation
- Configure Active Directory Certificate Services on the destination server > Credentials
    - Credentials (must be a Enterprise administrator)
    - Role Services
        - Certificate Authority
    - Setup Type
        - Enterprise CA (lab) (Production would be Standalone for root then will be taken offline)
    - CA Type
        - Root CA (Default)
    - Private Key
        - Create a new private key (default)
        - Cryptography (default)
        - Validity Period
            - 10 Years
    - Certificate Database (default)

## Create the certificate templates for SCCM
- Active Directory Users and Computers > New > Group
    - Name = SCCM IIS Servers
    - Add = lab1-sccm, lab1-sql
- Reboot both sccm and sql after you join to the security group
- Start > Windows Administrative Tools > Certificate Authority > Certificate Templates (Right-Click) > Manage 

- SCCM IIS Certificate
    - Web Server (Right-Click) > Duplicate Template
        - General
            - Name = SCCM IIS Certificate
        - Security
            - Add "SCCM IIS Server" group (Read, Enroll)
- SCCM DP Certificate
    - Workstation Authentication (Right-Click) > Duplicate Template
        - General
            - Name = SCCM DP Certificate
            - Validity period = 3 years
        - Request Handling
            - Allow private key to be exported = Checked
        - Security
            - Add "SCCM IIS Server" group (Read, Enroll)
            - Remove "Domain Computers"
- SCCM Client Certificate
    - Workstation Authentication (Right-Click) > Duplicate Template
        - General
            - Name = SCCM Client Certificate
            - Validity period = 3 years
        - Security
            - Add "Domain Computers" (Read, Enroll, Autoenroll)

## Deploy the certificate templates
- Certificate Authority > Certificate Templates (Right-Click) > New > Certificate Template to Issue > Select all the 3 above you created > Choose Ok

## Create an auto-enroll GPO for clients
- Group Policy Management > SCCM Settings GPO > Edit > Computer Configuration > Policies > Windows Settings > Security Settings > Public Key Policies > Certificate Services Client - Auto Enrollment Properties
    - Configuration Model = Enabled
    - Renew expired certificates, update pending certificates, and remove revoked certificates = Checked
    - Update certificates that use certificate templates = Checked

## Request certificates in the site system(s) and client(s)
- SCCM > mmc.exe > Add Snap-in > Certificates > Computer account > Personal > Certificates
- cmd > gpupdate /force
- Back to Certificates and refresh, you should see the new Client Certificate
- Do the same for your Lab Windows 10 Clients

- SCCM > Certificates > Personal > Certificates (Right-Click) > All Tasks > Request New Certificate
    - Request Certificates
        - SCCM DP Certificate
        - SCCM IIS Certificate
            - Subject
                - Alternative Name = DNS =  lab1-sccm and lab1-sccm.tomslab.com
            - General
                - Friendly Name = SCCM IIS Cert
    - Enroll

- SCCM DP Certificate (Right-Click) > All Tasks > Export
    - Yes, export the private key = Selected
    - Personal Information Exchange (default)
    - Password = Somepass1
    - Browse = Save to desktop "OSDCert.pfx"
    - Next, Finish

## Changing WSUS to require HTTPS
- SCCM > IIS > Sites > Default Site > Edit Bindings > https
    - SSL Certificate = SCCM IIS Cert
- SCCM > IIS > Sites > WSUS Administration > Edit Bindings > https
    - SSL Certificate = SCCM IIS Cert

- IIS > Sites > WSUS Administration > ApiRemoting30 > SSL Settings
    - Require SSL = Checked
    - Client Certificates = ignore (default)
- IIS > Sites > WSUS Administration > ClientWebService > SSL Settings
    - Require SSL = Checked
    - Client Certificates = ignore (default)
- IIS > Sites > WSUS Administration > DssAuthWebService > SSL Settings
    - Require SSL = Checked
    - Client Certificates = ignore (default)
- IIS > Sites > WSUS Administration > ServerSyncWebService > SSL Settings
    - Require SSL = Checked
    - Client Certificates = ignore (default)
- IIS > Sites > WSUS Administration > SimpleAuthWebService > SSL Settings
    - Require SSL = Checked
    - Client Certificates = ignore (default)

```bs
cd c:\Program Files\Update Services\Tools
.\WsusUtil.exe configuressl lab1-sccm.tomslab.com
```
## Changing the site system to use HTTPS
SCCM > Administration > Site Configuration > Sites > Select Site Server > Properties > Client Computer Communication
    - Site system settings = HTTPS or HTTP
    - Use PKI client certificate (client authentication capability) when available = Checked

### Change Site Roles
SCCM > Administration > Site Configuration > Servers and Site System Roles > Select Site Server

- Distribution Point > Properties
    - General
        - HTTPS = Selected
        - Import Certificate = OSDCert.pfx (from desktop)
        - Password: Somepass1
- Management Point > Properties
    - General
        - HTTPS = Selected
Log: c:\Program Files\Microsoft Configuration Manager\Logs\sitecomp.log - Site Component manager, handles installations of new components within our site
Log: c:\Program Files\Microsoft Configuration Manager\Logs\MPsetup.log - Install file for the management point
Log: c:\Program Files\Microsoft Configuration Manager\Logs\MPcontrol.log - monitors whether the management point is online and whether we can request and see that its available and can reach IIS

Quick verification Step
https://lab1-sccm/SMS_MP/.SMS_AUT?MPLIST - should show HTTP Error 403.7 - Client Certificate required
    - Internet Options > Content > Certificates > Import OSDCert.pfx > Enter Password
        - do not allow for export
    - Refresh IE
    - Should then see the MPList XML
    - Remove cert after check is done

## Verify the clients use HTTPS to communicate with the site
SCCM > Administration > Site Configuration > Servers and Site System Roles > Software Update Point > Properties
    - General
        - Require SSL communication to the WSUS server
Log: C:\Microsoft Configuration Manager\Logs\WCM.log - Configures WSUS server, syncs the updates to the Microsoft configuration

On Win10 client
```bs
gpupdate /force
```
- Verify certificate gets the client cert
- Control Panel > Configuration Manager Properties
    - General
        - Client Certificate = Should be PKI (not self-signed)

Troubleshooting: 
- Run Machine Policy Retrieval & Evaluation Cycle if it doesn't update right away
- Restart SMS Agent Host Service
Log: C:\Windows\CCM\Logs\CcMessaging.log
Log: C:\Windows\CCM\Logs\PolicyAgent.log
Log: C:\Windows\CCM\Logs\LocationServices.log

# Setup Cloud Management Gateway (CMG)
https://www.youtube.com/watch?v=kTOPhVHyZtE&list=PLlbnpTGUMlnXND6or4NNTcr7qoURGIgDj&index=11
https://docs.microsoft.com/en-us/sccm/core/clients/manage/cmg/certificates-for-cloud-management-gateway

## Prereqs
Need
1) Web IIS Cert (public one via digicert or Let's Encrypt)

If the clients are NOT Azure AD joined:
2) Client Certificate
3) Root CA Certificate

## Get Public SSL Cert
Note: If this is a dev environment, use Let's Encrypt
 - https://z-nerd.com/blog/2019/05/20-lets-encrypt-cloud-management-gateway/
 - Go to https://sslforfree.com and input cmgkunzlv.kunzlv.com > click "Create free SSL Certificate"
 - click manually verify and Add the DNS record
 - Click the "Download SSL Certificate" button

 ### Install OpenSSL
 - Go to https://wiki.openssl.org/index.php/Binaries and source and find the Win64 binary for OpenSSL

### Create pfx cert file
 - Powershell > navigate to C:\Program Files\OpenSSL-Win64\bin
 ```ps
.\openssl.exe pkcs12 -export -out "C:\Users\tomku\Downloads\sslforfree\cmgkunzlv-kunzlv-com.pfx" -inkey "C:\Users\tomku\Downloads\sslforfree\private.key" -in "C:\Users\tomku\Downloads\sslforfree\certificate.crt" -certfile "C:\Users\tomku\Downloads\sslforfree\ca_bundle.crt"
 ```
 - enter the password and verify password

## Setup DNS
- Log into DNS provider > Add CNAME
    - Name = lvvwdcmgtest or cmgkunzlv
    - Domain Name = lvvwdcmgttest.cloudapp.net or cmgkunzlv.cloudapp.net

## Set Client Settings
- SCCM > Administration > Client Settings > Lab Default Settings > Properties
    - Cloud Services
        - Automatically register new Windows 10 domain joined devices with Azure Active Directory = Yes
        - Enable clients to use a cloud management gateway = Yes
        - Allow access to cloud distribution point = Yes

## Setup Azure Services
- SCCM > Administration > Cloud Services > Azure Services > Configure Azure Services
    - Name = ConfigMgr - Azure Subscription
    - Cloud Management - Selected
    - Azure Environment = AzurePublicCloud
        - Web app > Browse... > Create
            - Name = ConfigMgr - Server App
            - Secret key validitiy period = 2 Years
            - Sign in... (signin with a Global Admin account to the subscripton)
                - This user has to be Co-administrator of the subscription, as well as given "owner" role
            - Choose "Ok" > Select the app > Choose "OK"
        - Native Client app > Browse... > Create
            - Name = ConfigMgr - Client app
            - Sign in... (signin with a Global Admin account to the subscripton)
                - This user has to be Co-administrator of the subscription, as well as given "owner" role
            - Choose "OK" > Select the app > choose "Ok"

Note: you will probably be blocked as IE enhanced security is turned on, add the cert by:
- Open IE Internet Options > Security > Trusted Sites > Add > login.microsoftonline.com, microsoftonline-p.com
            
    - Enable Azure Active Directory User Discovery = checked
    - Next > Close

## Grant Permissions to SCCM Azure Apps
- Azure > App registrations > View All applications > ConfigMgr - Client App > API permissions > Grat Admin consent for kunzlv > Yes
- Azure > App registrations > View All applications > ConfigMgr - Server App > API permissions > Grat Admin consent for kunzlv > Yes

## Setup SCCM Cloud Management Gateway in SCCM
- SCCM > Administration > Cloud Services > Cloud Management Gateway (Right-Click) > Create Cloud Management Gateway
    - Azure Resource Manager deployment (default)
    - Signin (signin with a Global Admin account to the subscripton)
    Note: Make sure the Subscription ID populates, otherwise you may not be a "Owner" and a "Co-administrator" of the subscription
    - Region = West US
    - Resource Group = Create New > kunzlvconfigmgr
    - Certificate file = cmgkunzlv-kunzlv-com.pfx (from OpenSSL/Let's Encrypt)
    - Service FQDN = lvvwdcmgtest.kunztlv.com or cmgkunzlv.kunzlv.com
    - Service name: lvvwdcmgtest.cloudapp.net or cmgkunzlv.cloudapp.net
    - Certificates = Root CA Cert
    - Verify Client Certificate Revocation = Not Checked
    - Allow CMG to function as a cloud distribution point and serve content from Azure storage = Checked

Log: C:\Program Files\Microsoft Configuration Manager\Logs\CloudMgr.log
- Takes 10-15mins for it to create in Azure
- SCCM > Administration > Cloud Services > Cloud Management Gateway > lvvwdcmgtest.kunzlv.com
    - Status = should show Ready
    - Status Description = should show Provisioning completed

Note: new Azure subscriptions will need to enable a service called Microsoft.ClassicCompute
- Azure Web Portal > Subscription > Resource providers
    - Search for "Microsoft.ClassicCompute
    - Select it and click Register
    - Note: Make sure there are no Resource groups before you delete and recreate the CMG

## Setup Cloud Management Gateway Connection Point
- SCCM > Administration > Site Configuration > Servers and Site System Roles > Site Server (Right-Click) > Add Site System Roles
    - System Role Selection
        - Cloud Management Gateway Connection Point
            - Cloud management gateway name = (should auto detect)
            - Region = (should auto detect)
        - Next > Close

## Setup CMG to be used on Site Roles
- SCCM > Administration > Site Configuration > Servers and Site System Roles > Management Point (Right-Click) > Properties
    - HTTPS
        - Allow Configuration Manager cloud management gateway traffic = Checked

- SCCM > Administration > Site Configuration > Servers and Site System Roles > Software Update Point (Right-Click) > Properties
    - Allow Configuration Manager cloud management gateway traffic = Checked

## Distribute an application
- SCCM > Software Library > Application Management > Applications > 7-Zip > Distribute Content
    - Content Destination = Select lvvwdcmgtest.kunzlv.com
- SCCM > Software Library > Software Updates > Deployment Packages > Select One (Right-Click) > Distribute Content 
    - Content Destination = Select lvvwdcmgtest.kunzlv.com
    Note: Do not distribute Microsoft updates, the internet based clients will get the binaries from windows update

## Remote Desktop into the CMG server in Azure
- Azure > Dashboard > Resource Manager > lvvwdcmgtest (cloud service) 
    - Remote Desktop
        - Enabled = Selected
        - Username = localadmin
        - Password = (Secure Password)
        - Encryption certificate = DC=Microsoft Azure Service Management for MachineKey
        - Expires on = (defaults to a month)
        - Save
    - Overview
        - ProxyService IN 0 > Reboot
        - ProxyService IN 0 > Connect
        - Open RDP shortcut

- Copy of CMTrace to the new server
- Regedit > HKLM:\SOFTWARE\Microsoft\SMS
    - Tracing
        - CMGSetup
            - TraceFilename = E:\approot\logs\CMGSetup.log
- IIS > Sites > ProxyService_IN_0_Web > Logging
    - Copy Directory (this is your IIS logs)
    - Log File Rollover
        - Schedule = Weekly
            - Apply

## Client Verifications

### Domain Joined Only
- Services > Restart SMS Agent Host
- SCCM Client > Network
        - Internet-based management point (FQDN) = lvvwdcmgtest.kunzlv.com
- Log: C:\Windows\CCM\Logs\ClientLocation.log 
    - (every 24hrs the client will do a query for new locations, or you can restart the SMS Agent Host service)

- Test over internet only
    - Disconnect from Domain, and just have internet
    - Once its connected to being comanaged, switch the hyperv network adapter to be on the internet
    - In the ClientLocation.log, it should show an entry that says "Domain joined client is in Internet"

- check logs
    - Open the following logs in CMTrace and choose to Merge them:
        - Log: C:\Windows\CCM\Logs\UpdatesDeployment.log
        - Log: C:\Windows\CCM\Logs\ScanAgent.log

- Perform test notification from SCCM
    - Config Manager > Assets and Devices > Devices > All Desktop and Server Clients (Right-Click) > Client Notification > Evaluate Software Update Deployments
    - You should see traffic in the UpdatesDeployment.log

- Verify you can get applications
    - Software Center > Click Install on your application
    - Log: C:\Windows\CCM\Logs\CAS.log
        - Distribution Point="https://lvvwdcmgtest.kunzlv.com/..."

### Setup Co-Management for On-Prem Domain Join (Making them Hybrid Joined)

Resources:
- [Enroll a Windows 10 device automatically using Group Policy](https://docs.microsoft.com/en-us/windows/client-management/mdm/enroll-a-windows-10-device-automatically-using-group-policy)
- [Troubleshoot an object that is not synchronizing with Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/tshoot-connect-object-not-syncing)
- [HOWTO: Add the required Hybrid Identity URLs to the Local Intranet list of Internet Explorer and Edge](https://dirteam.com/sander/2019/10/15/howto-add-the-required-hybrid-identity-urls-to-the-local-intranet-list-of-internet-explorer-and-edge/)

- Active Directory Users > Setup a user in AD under "Domain Users" OU so its organized and make the UPN like doej@kunzlvtest.com
- Install Azure AD Connect
    - https://www.microsoft.com/en-us/download/details.aspx?id=47594
- Configure Azure AD Connect
    - Launch Azure AD Connect configuration > Agree to terms > Continue
    - Customize > Install required components (keep default) > Install
    - User Signin > keep selected "Password Hash Synchronization" > Next
    - Connect to Azure AD > enter azure gloabl admin > Next
    - Connect your directories > Add Directory > enter On-Prem enterprise admin account > Next
    - Azure AD sing-in > Check "Continue without matching all UPN suffixes to verified domains > Next
    - Domain/OU filtering > Select "Sync selected domains and OUs > Select the OU for Computers and Users you want to sync > Next
    - Identifying Users > (leave default) > Next
    - Filtering > keep Synchronize all users and devices > Next
    - Optional Features > make sure the two are selected:
        - Password hash syncronization
        - Password writeback (this ensures if a user changes there password in azure it updates on prem AD)
    - Configure > Install
    - Select Start the synchronization process
    - Exit
- Assign a license to the newly synced users
    - Go to Portal.azure.com > Users
        - Make sure your on-prem user accounts are showing in Azure
        - Assign a license so they can use Intune
- Setup GPO for devices to auto enroll (Optional, since SCCM can auto enroll them)
    - Have a GPO with the following setting
        - Local Computer Policy > Administrative Templates > Windows Components > 
            - MDM
                - Enable automatic MDM enrollment using default Azure AD credentials = Enabled
                    - Device Credential
            - Internet Explorer > Internet Control Panel > Security Page
                - Site to Zone Assignment List
                    - Enabled
                    - values
                        - https://login.microsoftonline.com = value 1
                        - https://secure.aadcdn.microsoftonline-p.com = value 1
- Configure AD Connect for Device Options
    - Launch AD Connect > Tasks > Configure device options > Next
        - Overview > Next
        - Connect to Azure AD > use Global Admin account
        - Select "configure Hybrid Azure AD join" > Next
        - SCP > Select the Forest > click "Add" > Use enterprise admin for local domain > Next
        - Device Systems > Select "Windows 10 or later domain-joined devices" > Next
        - Configure > Configure > Exit
- Ensure the devices are Azure AD Hybrid Joined (Azure AD Registered)
```ps
dsregcmd /status
```
    - Should show "AzureAdJoined = YES" and "DomainJoined = Yes"
    - Start > Settings > Accounts > Access work or school > Select the domain 
        - You should see a "Info" button next to Disconnect
    - Task Scheduler > Microsoft > Windows > EnterpriseMgmt
        - tasks should be created if Azure AD registered
    - Config Manager client > General
        - Co-management capabilities = 3
        - Co-management = Enabled
    - Config Manager client > Actions
        - Select Discovery Data Collection Cycle > Run Now
            - This sends data back to the site
        - Hardware Inventory Cycle > Run Now
    - Device should now be seen in Intune devices
    - SCCM Configuration Manager > Montior > Co-Management
        - Should show Co-management Status
            - Should see Success numbers

- Troubleshooting
    - Log: c:\windows\ccm\logs\ClientIDManagerStartup.log
        - This log shows the client registering with the SCCM Manager Site
            - Should show below:
                `Registering client using AAD auth.`
                `Client is registered...Approval status 3`
    - Log: c:\windows\ccm\logs\PolicyAgent.log
        - This log shows policies from the site that are being downloaded
            - Should show some downloading


# Setup Software Metering based on Asset Intelligence
- Resources :
    - [Introduction to Asset Intelligence in Configuration Manager](https://docs.microsoft.com/en-us/previous-versions/system-center/system-center-2012-R2/gg681998(v=technet.10)?redirectedfrom=MSDN)
    - [How to Setup, Configure, and Use SCCM's Asset Intelligence](https://www.enhansoft.com/how-to-setup-configure-and-use-sccms-asset-intelligence/)
    - [SCCM 2012 Software Metering Reports](https://www.systemcenterdudes.com/sccm-2012-software-metering-reports/)
    - [SCCM Automatically Uninstall Application](https://www.systemcenterdudes.com/sccm-automatically-uninstall-application/)
    - [Automatically Create Device Collections based on software Meetering rules](https://www.mroenborg.com/automatically-create-device-collections-based-on-software-meetering-rules/)

## Configure the Asset Intelligence Inventory Classes
- Config Manager > Assets and Compliance > Asset Intelligence (Right-Click) > Edit Inventory Classes
    - Select Everyone except SMS_SoftwareShortcut

```
    [√] SMS_InstalledSoftware               [√] Win32_USBDevice
    [√] SMS_SystemConsoleUsage (default)    [√] SMS_InstalledExecutable
    [√] SMS_SystemConsoleUser (default)     [ ] SMS_SoftwareShortcut
    [√] SMS_AutoStartSoftware               [√] SoftwareLicensingService
    [√] SMS_BrowserHelperObject             [√] SoftwareLicensingProduct
    [√] SMS_SoftwareTag
```

## Enable Workstation Logon Audit Policy in Order to Collect Top Console User Details
- Resource
    - [Enable Workstation Logon Audit Policy in Order to Collect Top Console User Details](https://www.enhansoft.com/enable-workstation-logon-audit-policy-in-order-to-collect-top-console-user-details/)
    - [Asset Intelligence Client WMI Classes](https://docs.microsoft.com/en-us/previous-versions/system-center/developer/cc143569(v=msdn.10))

GPO > Edit
    - Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Audit Policy > Audit logon events
        - check 'Success'

## Setup Asset Intelligence Synchronization Point
Config Manager > Administration > Site Configuration > Servers and Site System Roles > [Site System] (Right-Click) > Add Site System Roles
    - Next > Next > Asset Intelligence synchronization point > Next > Next
        - Change Simple schedule = 1 Day

## Submit Asset Intelligence Titles (Optional)
Config Manager > Assets and Compliance > Asset Intelligence > Inventoried Software > Unidentified and Not Pending Online Identification (Right-Click) > Request Catalog Update
    - I have read and understood this message = Checked
    - Ok

Note: It may take several weeks or months before the results are updated within the catalog

## Enable Software Metering (enabled by default)
Config Manager > Administration > Client Settings > Default Settings > Software Metering
    - Enable software metering on clients = Yes
    - Schedule data collection = Occurs every 7 days...

## Create Software Metering Rules
Config Manager > Assets and Compliance > Software Metering > Create Software Metering Rule

There are 13 Reports where you can see this information
- All Software metering rules applied to this site
- Computers that have a metered program installed but have not run the program
- Computers that have run a specific metered software program
- Concurrent usage for all metered software programs
- Concurrent usage trend analysis of a specific metered software program
- Install base for all metered software programs
- Software metering summarization progress
- Time of day usage summary for a specific metered software program
- Total usage for all metered software programs
- Total usage for all metered software programs on Windows Terminal Servers
- Total usage for trend analysis for a specific metered software program
- Total usage for trend analysis for a specific metered software program on Windows
- Users that have run a specific metered software program

## Use Custom labels in Asset Intelligence

## Create a link between Asset Intelligence and Software Metering

## Use Reporting to share the usage of each installation in your organization

Resources (Video)
- [Configuring SQL Reporting Services](https://youtu.be/vZpuBrs0LwM?t=64)
- [Installing Site System Roles (Endpoint Protection Point, Fallback Status Point, Reporting Services Point. Software Update Point)](https://youtu.be/vZpuBrs0LwM?t=248)
- [Configuring the Client Push and Network Access Account](https://youtu.be/vZpuBrs0LwM?t=807)
- [Creating GPO to add Client Push to local administrators on clients and enabling the Firewall exception for WMI and File and Print Sharing](https://youtu.be/vZpuBrs0LwM?t=940)
- [Configuring Boundaries and Boundary Groups](https://youtu.be/vZpuBrs0LwM?t=1132)
- [Configure Client Discovery (AD System Discovery)](https://youtu.be/vZpuBrs0LwM?t=1453)
- [Create and deploy a custom Client Settings](https://youtu.be/vZpuBrs0LwM?t=1704)
- [Performing a Client Push from the SCCM Console](https://youtu.be/vZpuBrs0LwM?t=1867)
- [Verify Software Update Point Synced Products and Enable Windows 10 in the Products](https://youtu.be/vZpuBrs0LwM?t=2032)
- [Verify Reports are working and run a report on Client Push](https://youtu.be/vZpuBrs0LwM?t=2214)


Resources
- [Reference for maintenance tasks for System Center Configuration Manager](https://docs.microsoft.com/en-us/configmgr/core/servers/manage/reference-for-maintenance-tasks)

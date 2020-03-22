Add-Type -AssemblyName presentationframework

[xml]$XAML  = @"
  <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:local="clr-namespace:MyFirstWPF"
  Title="PowerShell Computer Utility" Height="450"  Width="525">
    <Grid>
      <GroupBox  x:Name="Actions" Header="Actions"  HorizontalAlignment="Left" Height="108"  VerticalAlignment="Top" Width="77" Margin="0,11,0,0">
        <StackPanel>
          <Button  x:Name="Services_btn" Content="Services"/>
          <Label  />
          <Button  x:Name="Processes_btn" Content="Processes"/>
          <Label  />
          <Button  x:Name="Drives_btn" Content="Drives"/>
        </StackPanel>
      </GroupBox>
      <GroupBox  x:Name="Computername" Header="Computername"  HorizontalAlignment="Left" Margin="92,11,0,0"  VerticalAlignment="Top" Height="45" Width="415">
          <TextBox  x:Name="PCInput_txtbx" TextWrapping="Wrap"/>
      </GroupBox>
      <GroupBox  x:Name="Username" Header="Username"  HorizontalAlignment="Left" Margin="92,61,0,0"  VerticalAlignment="Top" Height="45" Width="415">
          <TextBox  x:Name="UserInput_txtbx" TextWrapping="Wrap"/>
      </GroupBox>
      <GroupBox  x:Name="Password" Header="Password"  HorizontalAlignment="Left" Margin="92,111,0,0"  VerticalAlignment="Top" Height="45" Width="415">
          <PasswordBox x:Name="PassInput_txtbx"/>
      </GroupBox>
      <GroupBox  x:Name="Results" Header="Results"  HorizontalAlignment="Left" Margin="92,161,0,0"  VerticalAlignment="Top" Height="248" Width="415">
        <TextBox  x:Name="Output_txtbx" IsReadOnly="True"  HorizontalScrollBarVisibility="Auto"  VerticalScrollBarVisibility="Auto" />
      </GroupBox>
    </Grid>
  </Window>
"@

$reader=(New-Object System.Xml.XmlNodeReader  $xaml)
$Window=[Windows.Markup.XamlReader]::Load($reader)

#Connect to Controls 
$xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object {
  New-Variable  -Name $_.Name -Value $Window.FindName($_.Name) -Force
} 

function createPSCreds {
  [string]$user = $UserInput_txtbx.Text
  $pass = ConvertTo-SecureString $($PassInput_txtbx.Password) -AsPlainText -Force
  $creds = New-Object System.Management.Automation.PSCredential($user,$pass)
  return $creds
}

#region Events 
  $Services_btn.Add_Click({
    If (-NOT ([string]::IsNullOrEmpty($PCInput_txtbx.Text)))  {
          $Computername = $PCInput_txtbx.Text
          Write-Verbose  "Gathering services from $Computername"  -Verbose
          $creds = createPSCreds
          Try  {
            $Services  = invoke-command -ComputerName $Computername -ScriptBlock {Get-Service} -Credential $creds
            $Output_txtbx.Text = ($Services | Out-String)
          }

          Catch  {
            Write-Warning  $_
          }
    }
  })

$Processes_btn.Add_Click({
    If (-NOT ([string]::IsNullOrEmpty($PCInput_txtbx.Text)))  {
        $Computername  = $PCInput_txtbx.Text
        Write-Verbose  "Gathering processes from $Computername"  -Verbose
        $creds = createPSCreds
        Try  {
            $Processes  = invoke-command -ComputerName $Computername -ScriptBlock {Get-Process} -Credential $creds
            $Output_txtbx.Text = ($Processes |  Out-String)
        }

        Catch  {
            Write-Warning  $_
        }
    }
})

$Drives_btn.Add_Click({
  If (-NOT ([string]::IsNullOrEmpty($PCInput_txtbx.Text)))  {
    $Computername  = $PCInput_txtbx.Text
    Write-Verbose  "Gathering drives from $Computername"  -Verbose
    Try  {
        $Drives  = Get-CIMInstance -ClassName Win32_LogicalDisk -ComputerName $Computername
        $Output_txtbx.Text = ($Drives | Out-String)
    }
    Catch  {
        Write-Warning  $_
    }
  }
}) 

#endregion Events 
$Window.ShowDialog()

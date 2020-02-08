﻿Add-Type -AssemblyName presentationframework

[xml]$XAML  = @"

  <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"

  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"

  xmlns:d="http://schemas.microsoft.com/expression/blend/2008"

  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"

  xmlns:local="clr-namespace:MyFirstWPF"

  Title="PowerShell Computer Utility" Height="350"  Width="525">

  <Grid>

  <GroupBox  x:Name="Actions" Header="Actions"  HorizontalAlignment="Left" Height="299"  VerticalAlignment="Top" Width="77"  Margin="0,11,0,0">

  <StackPanel>

  <Button  x:Name="Services_btn" Content="Services"/>

  <Label  />

  <Button  x:Name="Processes_btn" Content="Processes"/>

  <Label  />

  <Button  x:Name="Drives_btn" Content="Drives"/>

  </StackPanel>

  </GroupBox>

  <GroupBox  x:Name="Computername" Header="Computername"  HorizontalAlignment="Left" Margin="92,11,0,0"  VerticalAlignment="Top" Height="45" Width="415">

  <TextBox  x:Name="InputBox_txtbx" TextWrapping="Wrap"/>

  </GroupBox>

  <GroupBox  x:Name="Results" Header="Results"  HorizontalAlignment="Left" Margin="92,61,0,0"  VerticalAlignment="Top" Height="248" Width="415">

  <TextBox  x:Name="Output_txtbx" IsReadOnly="True"  HorizontalScrollBarVisibility="Auto"  VerticalScrollBarVisibility="Auto" />

  </GroupBox>
    </Grid>

  </Window>

"@ 


$reader=(New-Object System.Xml.XmlNodeReader  $xaml)

  $Window=[Windows.Markup.XamlReader]::Load(  $reader )


#Connect to Controls 

  $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach {

  New-Variable  -Name $_.Name -Value $Window.FindName($_.Name) -Force

  }

#region Events 

  $Services_btn.Add_Click({
    If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
          Write-Verbose  "Gathering services from $Computername"  -Verbose
          $Computername  = $InputBox_txtbx.Text

          Try  {
            $Services  = Get-Service -ComputerName $Computername
            $Output_txtbx.Text = ($Services | Out-String)
          }

          Catch  {
            Write-Warning  $_
          }
    }
  })

$Processes_btn.Add_Click({
    If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
        Write-Verbose  "Gathering processes from $Computername"  -Verbose
        $Computername  = $InputBox_txtbx.Text
        Try  {
            $Processes  = Get-Process -ComputerName $Computername
            $Output_txtbx.Text = ($Processes |  Out-String)
        }

        Catch  {
            Write-Warning  $_
        }
    }
})

$Drives_btn.Add_Click({
  If (-NOT ([string]::IsNullOrEmpty($InputBox_txtbx.Text)))  {
    Write-Verbose  "Gathering drives from $Computername"  -Verbose
    $Computername  = $InputBox_txtbx.Text
    Try  {
        $Drives  = Get-WMIObject  -Class Win32_LogicalDisk  -ComputerName $Computername
        $Output_txtbx.Text = ($Drives | Out-String)
    }
    Catch  {
        Write-Warning  $_
    }
  }
}) 

#endregion Events 

$Window.ShowDialog()

read-host "what"
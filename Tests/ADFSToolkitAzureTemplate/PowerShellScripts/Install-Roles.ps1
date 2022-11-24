function Register-ADFSToolkitLabScheduledTask {
    param (
        $Name,
        $Description,
        $Command,
        [switch]$AtStartup,
        [datetime]$At,
        [switch]$DeployScript
    )
    
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Installing Windows Feature ADFS-Federation"

    if ($DeployScript) {
        $Command = Join-Path $PSScriptRoot $Command
    }

    $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
        -Argument "-ExecutionPolicy Unrestricted -NoProfile -WindowStyle Hidden -Command &{$Command}"

    if ($AtStartup) {
        $stTrigger = New-ScheduledTaskTrigger -AtStartup
    }

    if (![string]::IsNullOrEmpty($At)) {
        $stTrigger = New-ScheduledTaskTrigger -At $At -Once:$false
    }

    $stSettings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromMinutes(15)) 

    try {
        $Task = Register-ScheduledTask -Action $stAction -Trigger $stTrigger -TaskName "ADFSToolkit Lab - $Name" -Description $Description -RunLevel Highest -Settings $stSettings -TaskPath "\ADFSToolkit Lab\" -User "System"
    
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
    }
    catch {
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
        Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
    }
}

#Create log folder
$LogFilePath = "C:\ADFSToolkitLab"
if (!(Test-Path $LogFilePath)) {
    New-Item $LogFilePath -ItemType Directory
}

$TranscriptLogFile = Join-Path $LogFilePath "Transcript_Roles.txt"
Start-Transcript -Path $TranscriptLogFile

$MainLogFile = Join-Path $LogFilePath "Mainlog.txt"
Add-Content -Path $MainLogFile -Value "------------------------------------------------------"
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Install-Roles.ps1 script started..."
Add-Content -Path $MainLogFile -Value "------------------------------------------------------"
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Running from '$PSScriptRoot'"

#region Install Windows Features

#Installing Windows Feature AD-Domain-Services
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Installing Windows Feature AD-Domain-Services"
try {
    Install-WindowsFeature  -Name AD-Domain-Services -IncludeManagementTools
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}
catch {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
}

#Installing Windows Feature ADFS-Federation 
Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Installing Windows Feature ADFS-Federation"
try {
    Install-windowsfeature ADFS-Federation -IncludeManagementTools
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}
catch {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Error!"
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): $_"
}

#endregion

#region Create Scheduled Tasks to do next installations

#Create Scheduled Task to run next script
$TaskName = "Install ADDS"
$schedTask = Get-ScheduledTask -TaskName "ADFSToolkit Lab - $TaskName" -TaskPath "\ADFSToolkit Lab\" -ErrorAction SilentlyContinue
if ([string]::IsNullOrEmpty($schedTask)) {
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Creating scheduled task: 'ADFSToolkit Lab - $TaskName'"
    Register-ADFSToolkitLabScheduledTask -Name $TaskName -Description "This script installes ADDS on startup" -Command "Install-ADDS.ps1" -AtStartup -DeployScript
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}

#Create Scheduled Task to reboot in 2 mins
$TaskName = "Reboot 1"
$schedTask = Get-ScheduledTask -TaskName "ADFSToolkit Lab - $TaskName" -TaskPath "\ADFSToolkit Lab\" -ErrorAction SilentlyContinue
if ([string]::IsNullOrEmpty($schedTask)) {
    $RebootTime = (Get-Date).AddMinutes(2)
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Creating scheduled task: 'ADFSToolkit Lab - $TaskName'"
    Register-ADFSToolkitLabScheduledTask -Name $TaskName -Description "This script reboots the server at $RebootTime" -Command "Restart-Computer -Confirm:`$false -Force" -At $RebootTime
    Add-Content -Path $MainLogFile -Value "$((Get-Date).ToString()): Done!"
}

#endregion

Stop-Transcript

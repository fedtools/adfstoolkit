function Register-ADFSTkScheduledTask {
    [cmdletbinding()]
    param ([switch]$Force)
    
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText confCheckIfScheduledTaskIsPresent)
    $schedTask = Get-ScheduledTask -TaskName (Get-ADFSTkLanguageText confImportMetadata) -TaskPath "\ADFSToolkit\" -ErrorAction SilentlyContinue

    if (($PSBoundParameters.ContainsKey('Force') -and $Force -ne $false) `
            -and -not [string]::IsNullOrEmpty($schedTask)) {
        
                Write-ADFSTkLog (Get-ADFSTkLanguageText confRemoveScheduledTask)
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cRemoving -f $schedTask.TaskName)

                $schedTask | Unregister-ScheduledTask -Confirm:$false
                
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
        $schedTask = $null
    }

    if ([string]::IsNullOrEmpty($schedTask)) {
        Write-ADFSTkLog (Get-ADFSTkLanguageText cCreating -f "Scheduled Task")

        $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
            -Argument "-NoProfile -WindowStyle Hidden -Command &{Sync-ADFSTkAggregates}"

        $stTrigger = New-ScheduledTaskTrigger -Daily -DaysInterval 1 -At (Get-Date)
        $stSettings = New-ScheduledTaskSettingsSet -Disable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromHours(12))

        $Task = Register-ScheduledTask -Action $stAction `
            -Trigger $stTrigger `
            -TaskName (Get-ADFSTkLanguageText confImportMetadata) `
            -Description (Get-ADFSTkLanguageText confThisSchedTaskWillDoTheImport) `
            -RunLevel Highest `
            -Settings $stSettings `
            -TaskPath "\ADFSToolkit\"

        $Task.Triggers.Repetition.Duration = ""
        $Task.Triggers.Repetition.Interval = "PT1H"
        $Task | Set-ScheduledTask -User "$env:USERDOMAIN\$env:USERNAME"

        Write-Host " "
        
        Write-ADFSTkLog (Get-ADFSTkLanguageText cDone)
        Write-Host (Get-ADFSTkLanguageText confScheduledTaskInfo)
    }
    else {
        Write-Host (Get-ADFSTkLanguageText cAlreadyPresent -f "Import Metadata Scheduled Task")
    }
}
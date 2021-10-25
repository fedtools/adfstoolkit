function Register-ADFSTkScheduledTask {
    $schedTask = Get-ScheduledTask -TaskName 'Import Federated Metadata with ADFSToolkit' -TaskPath "\ADFSToolkit\" -ErrorAction SilentlyContinue

    if ([string]::IsNullOrEmpty($schedTask)) {
        $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
            -Argument "-NoProfile -WindowStyle Hidden -Command &{Sync-ADFSTkAggregates}"

        $stTrigger = New-ScheduledTaskTrigger -Daily -DaysInterval 1 -At (Get-Date)
        $stSettings = New-ScheduledTaskSettingsSet -Disable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromHours(12))

        Register-ScheduledTask -Action $stAction `
            -Trigger $stTrigger `
            -TaskName (Get-ADFSTkLanguageText confImportMetadata) `
            -Description (Get-ADFSTkLanguageText confTHisSchedTaskWillDoTheImport) `
            -RunLevel Highest `
            -Settings $stSettings `
            -TaskPath "\ADFSToolkit\"
    }
    else {
        Write-Host "Scheduled Task already present!"
    }
}
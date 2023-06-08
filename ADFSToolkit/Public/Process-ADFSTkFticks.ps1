function Process-ADFSTkFticks {

    Verify-ADFSTkEventLogUsage -LogName ADFSToolkit -Source 'Process-ADFSTkFticks' | Out-Null
    Write-ADFSTkLog -SetEventLogSource 'Process-ADFSTkFticks'
    
    $LoginEvents = Get-ADFSTkLoginEvents -LatestRecordsOnly
    Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticksProcessStarted -f $LoginEvents.Count) -EventID 300 -EntryType Information

    if ([string]::IsNullOrEmpty($Global:ADFSTkConfiguration)) {
        $Global:ADFSTkConfiguration = Get-ADFSTkConfiguration
    }
    
    #Whatif the syslog server isn't configured?
    $Server = $Global:ADFSTkConfiguration.Fticks.Server #Where to send the f-ticks
    $Hostname = (Get-AdfsProperties).Identifier.Host
    $IdP = (Get-AdfsProperties).Identifier.AbsoluteUri 
    $Application = "ADFSToolkitv{0}:" -f (Get-Module ADFSToolkit).Version.ToString()

    $ErrorOccurred = $false

    foreach ($LoginEvent in $LoginEvents | Sort RecordID) {
        $LogRecordID = $LoginEvent.RecordID
        try {
            $FtickMessage = New-ADFSTkFtickMessage -entityID $LoginEvent.SP -userName $LoginEvent.UserName -IdP $IdP -LoggedTime $LoginEvent.DateTime -AuditResult $LoginEvent.AuditResult -AuthnContextClass $LoginEvent.AuthnContextClass
            # $FtickMessage
            Send-SyslogMessage -Message $FtickMessage -Server $Server -Severity Information -Facility Auth -Hostname $Hostname -Application $Application -Protocol UDP -Port 514

            $LastRecordID = $LogRecordID #When everything went well, lets save this RecordID in case the next Record fails.
        }
        catch {
            $LogRecordID = $LastRecordID #We don't want to save the current RecordID due to an error. Log the last one.

            #Do some logging
            Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticksProcessStarted -f $_) -EventID 310 -EntryType Warning
            Exit
        }
    }

    if (![string]::IsNullOrEmpty($LoginEvents)) {
        Set-ADFSTkConfiguration -FticksLastRecordId $LogRecordID
    }
    Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticksProcessFinished) -EventID 301 -EntryType Information
}
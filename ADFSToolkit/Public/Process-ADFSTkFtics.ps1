function Process-ADFSTkFtics {

    $LoginEvents = Get-ADFSTkLoginEvents -LatestRecordsOnly
    Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticsProcessStarted -f $LoginEvents.Count) -EventID 300 -EntryType Information

    if ([string]::IsNullOrEmpty($Global:ADFSTkConfiguration)) {
        $Global:ADFSTkConfiguration = Get-ADFSTkConfiguration
    }
    
    $Server = $Global:ADFSTkConfiguration.Ftics.Server #Where to send the f-tics
    $Hostname = (Get-AdfsProperties).Identifier.Host
    $IdP = (Get-AdfsProperties).Identifier.AbsoluteUri 
    $Application = "ADFSToolkitv{0}:" -f (Get-Module ADFSToolkit).Version.ToString()

    $ErrorOccurred = $false

    foreach ($LoginEvent in $LoginEvents | Sort RecordID) {
        $LogRecordID = $LoginEvent.RecordID
        try {
            $FticMessage = New-ADFSTkFticMessage -entityID $LoginEvent.SP -userName $LoginEvent.UserName -IdP $IdP -LoggedTime $LoginEvent.DateTime -AuditResult $LoginEvent.AuditResult -AuthnContextClass $LoginEvent.AuthnContextClass
            # $FticMessage
            Send-SyslogMessage -Message $FTicMessage -Server $Server -Severity Information -Facility Auth -Hostname $Hostname -Application $Application -Protocol UDP -Port 514

            $LastRecordID = $LogRecordID #When everything went well, lets save this RecordID in case the next Record fails.
        }
        catch {
            $LogRecordID = $LastRecordID #We don't want to save the current RecordID due to an error. Log the last one.

            #Do some logging
            Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticsProcessStarted -f $_) -EventID 310 -EntryType Warning
            Exit
        }
    }

    if (![string]::IsNullOrEmpty($LoginEvents)) {
        Set-ADFSTkConfiguration -FticsLastRecordId $LogRecordID
    }
    Write-ADFSTkLog -Message (Get-ADFSTkLanguageText fticsProcessFinished) -EventID 301 -EntryType Information
}
function Process-ADFSTkFtics {

    $LoginEvents = Get-ADFSTkLoginEvents -LatestRecordsOnly

    if ([string]::IsNullOrEmpty($Global:ADFSTkConfiguration)) {
        $Global:ADFSTkConfiguration = Get-ADFSTkConfiguration
    }
    
    $Server = $Global:ADFSTkConfiguration.Ftics.Server #Where to send the f-tics
    $Hostname = (Get-AdfsProperties).Identifier.Host
    $IdP = (Get-AdfsProperties).Identifier.AbsoluteUri 
    $Application = "ADFSToolkitv{0}:" -f (Get-Module ADFSToolkit).Version.ToString()

    foreach ($LoginEvent in $LoginEvents) {

        $FticMessage = New-ADFSTkFticMessage -entityID $LoginEvent.SP -userName $LoginEvent.UserName -IdP $LoginEvent.Host -LoggedTime $LoginEvent.DateTime -AuditResult $LoginEvent.AuditResult -AuthnContextClass $LoginEvent.AuthnContextClass
        $FticMessage
        #Send-SyslogMessage -Message $FTicMessage -Server $Server -Severity Information -Facility Auth -Hostname $Hostname -Application $Application -Protocol UDP -Verbose -Port 514
        
    }

    if (![string]::IsNullOrEmpty($LoginEvents)) {
        Set-ADFSTkConfiguration -FticsLastRecordId ($LoginEvents.RecordID | Sort | Select -Last 1)
    }
}
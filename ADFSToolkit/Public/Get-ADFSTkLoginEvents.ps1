function Get-ADFSTkLoginEvents {
    param (
        [switch]$LatestRecordsOnly
    )
   
    $LastRecordID = 0
    if ($PSBoundParameters.ContainsKey('LatestRecordsOnly') -and $LatestRecordsOnly -ne $false) {
        if ([string]::IsNullOrEmpty($Global:ADFSTkConfiguration)) {
            $Global:ADFSTkConfiguration = Get-ADFSTkConfiguration
        }
        $LastRecordID = $Global:ADFSTkConfiguration.Ftics.LastRecordId
        if ([string]::IsNullOrEmpty($LastRecordID)) {
            $LastRecordID = 0
        }
    }
    $Query = @"
<QueryList>
    <Query Id="0" Path="Security">
      <Select Path="Security">*[System[((EventID=1200) or (EventID=1201)) and (EventRecordID &gt; $LastRecordID)]]</Select>
    </Query>
</QueryList>   
"@

    # Write-Host "Last RecordID: $LastRecordID"
    # Write-Host "Getting Events..." 
    try {
        $Events = Get-WinEvent -LogName Security -FilterXPath $Query -ErrorAction Stop
    }
    catch {
        $Events = $null
    }
    
    # Write-Host "$($Events.Count) events found!"
    
    $LogonEvents = foreach ($Event in $Events) {
        $xmlEvent = [xml]$Event.ToXml()

        $Logon = [PSCustomObject]@{
            DateTime          = [DateTime]::Parse($xmlEvent.Event.System.TimeCreated.SystemTime)
            UserName          = ""
            RecordID          = $xmlEvent.Event.System.EventRecordID
            IdP               = ($xmlEvent.Event.System.Computer -split '\.')[0]
            SP                = ""
            AuditResult       = ""
            AuthnContextClass = ""
            CorrelationID     = $xmlEvent.Event.EventData.Data[0]
        }
        
        $xmlEvent.LoadXml($xmlEvent.Event.EventData.Data[1])
        $Logon.UserName = ($xmlEvent.AuditBase.ContextComponents.Component.UserId[0] -split '\\')[-1]
        $Logon.SP = ($xmlEvent.AuditBase.ContextComponents.Component | ? type -eq ResourceAuditComponent).RelyingParty
        $Logon.AuditResult = $xmlEvent.AuditBase.AuditResult
        $Logon.AuthnContextClass = ($xmlEvent.AuditBase.ContextComponents.Component | ? type -eq AuthNAuditComponent).PrimaryAuth

        if ($Logon.AuthnContextClass -eq 'http://schemas.microsoft.com/ws/2008/06/identity/authenticationmethod/password') {
            $Logon.AuthnContextClass = 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport'
        }

        if ($Logon.AuditResult -eq "Failure") {
            try {
                $FailQuery = @"
<QueryList>
  <Query Id="0" Path="AD FS/Admin">
    <Select Path="AD FS/Admin">*[System[EventID=364 and Correlation[@ActivityID='{$($Logon.CorrelationID)}']]]</Select>
  </Query>
</QueryList>
"@

                $FailEvent = Get-WinEvent -LogName Security -FilterXPath $FailQuery
                if ($FailEvent -is [Object[]]) {
                    $FailEvent = [xml]$FailEvent[0].ToXml()
                }
                else {
                    $FailEvent = [xml]$FailEvent.ToXml()
                }
                $Logon.SP = $FailEvent.Event.UserData.Event.EventData.Data[1]
            }
            catch {}
        }

        $Logon
    }

    $LogonEvents
    
    #$LogonEvents | Measure -Maximum -Property RecordID | Select -ExpandProperty Maximum | Out-File (Join-Path $LastRecordIDPath $LastRecordIDFile)
}
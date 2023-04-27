function New-ADFSTkFticMessage {
    param (
        $entityID, #The current SP
        $userName, #The UserName of the person logged in
        $IdP, #The entityID of the IdP
        [DateTime]$LoggedTime,
        [ValidateSet('Success', 'Failure')]
        $AuditResult,
        $AuthnContextClass
    )

    if ([string]::IsNullOrEmpty($Global:ADFSTkConfiguration))
    {
        $Global:ADFSTkConfiguration = Get-ADFSTkConfiguration
    }

    $FederationName = $Global:ADFSTkConfiguration.FederationConfig.Federation.FederationName #The name of the federation
    $Salt = $Global:ADFSTkConfiguration.Ftics.Salt

    #Get the timestamp
    $Timestamp = ($LoggedTime).ToUniversalTime()
    $FormattedTimestamp = [System.Math]::Truncate((Get-Date -Date $Timestamp -UFormat %s))

    $hashmaker = [Security.Cryptography.HashAlgorithm]::Create("SHA256");
    $hash = $hashmaker.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Salt + $userName))
 
    $userID = [Convert]::ToBase64String($hash)

    if ($AuditResult -eq "Success")
    {
        $Result = "OK"
    }
    else {
        $Result = "FAIL"
    }

    #OK/FAIL beroende på eventID
    $FTicksMessage = 'ADFS-F-TICKS/{0}/1.0#TS={1}#RP={2}#AP={3}#PN={4}#AM={5}#RESULT={6}#' -f $FederationName, $FormattedTimestamp, $entityID, $IdP, $userID, $AuthnContextClass, $Result
    $FTicksMessage
    

}
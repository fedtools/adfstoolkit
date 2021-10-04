function Get-ADFSTkMFAConfiguration {
    param (

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$EntityId
    )


    if ([string]::IsNullOrEmpty($Global:ADFSTkManualSPSettings)) {
        if ([string]::IsNullOrEmpty($Global:ADFSTkAllTransformRules) -or $Global:ADFSTkAllTransformRules.Count -eq 0) {
            $Global:ADFSTkAllTransformRules = Import-ADFSTkAllTransformRules
            $AllTransformRules = $Global:ADFSTkAllTransformRules #So we don't need to change anything in the Get-ADFSTkManualSPSettings files
        }
        $Global:ADFSTkManualSPSettings = Get-ADFSTkManualSPSettings
    }

    $ApplyMFAConfiguration = $null

    #AllSPs
    if ($Global:ADFSTkManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
            $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
            $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.ContainsKey('ApplyMFAConfiguration')) {
        $ApplyMFAConfiguration = $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.ApplyMFAConfiguration
    }

    #AllEduSPs

    if ($EntityId -ne $null) {
    
        #First remove http:// or https://
        $entityDNS = $EntityId.ToLower().Replace('http://', '').Replace('https://', '')

        #Second get rid of all ending sub paths
        $entityDNS = $entityDNS -split '/' | select -First 1

        #Last fetch the last two words and join them with a .
        #$entityDNS = ($entityDNS -split '\.' | select -Last 2) -join '.'

        $settingsDNS = $null

        foreach ($setting in $Global:ADFSTkManualSPSettings.Keys) {
            if ($setting.StartsWith('urn:adfstk:entityiddnsendswith:')) {
                $settingsDNS = $setting -split ':' | select -Last 1
            }
        }

        if ($entityDNS.EndsWith($settingsDNS) -and `
                $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS" -is [System.Collections.Hashtable] -and `
                $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('ApplyMFAConfiguration')) {
            $ApplyMFAConfiguration = $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ApplyMFAConfiguration
        }

        #Manual SP
        if ($EntityId -ne $null -and `
                $Global:ADFSTkManualSPSettings.ContainsKey($EntityId) -and `
                $Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
                $Global:ADFSTkManualSPSettings.$EntityId.ContainsKey('ApplyMFAConfiguration')) {
            $ApplyMFAConfiguration = $Global:ADFSTkManualSPSettings.$EntityId.ApplyMFAConfiguration
        }
    }

    if ($ApplyMFAConfiguration -ne $null -and $ApplyMFAConfiguration.ContainsKey('azuremfa')) { 
    
        $mfaRules = @()
        $mfaRulesText = @()
        
        if ($ApplyMFAConfiguration.AzureMFA.ContainsKey('otp') -and $ApplyMFAConfiguration.AzureMFA.otp -eq $true)
        {
            $mfaRulesText += "TOTP"
            $mfaRules += @"
@RuleName = "Check RefedsMFA context class after successful Azure MFA with TOTP"
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value == "http://schemas.microsoft.com/ws/2012/12/authmethod/otp"]
=> add(Type = "urn:adfstk:mfalogon", Value = "true");
"@
        }

        if ($ApplyMFAConfiguration.AzureMFA.ContainsKey('smsotp') -and $ApplyMFAConfiguration.AzureMFA.smsotp -eq $true)
        {
            $mfaRulesText += "SMS"
            $mfaRules += @"
@RuleName = "Check RefedsMFA context class after successful Azure MFA with SMS"
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value == "http://schemas.microsoft.com/ws/2012/12/authmethod/smsotp"]
=> add(Type = "urn:adfstk:mfalogon", Value = "true");
"@
        }

        if ($ApplyMFAConfiguration.AzureMFA.ContainsKey('phoneappnotification') -and $ApplyMFAConfiguration.AzureMFA.phoneappnotification -eq $true)
        {
            $mfaRulesText += "Phone App Notification"
            $mfaRules += @"
@RuleName = "Check RefedsMFA context class after successful Azure MFA with Phone App Notification"
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value == "http://schemas.microsoft.com/ws/2012/12/authmethod/phoneappnotification"]
=> add(Type = "urn:adfstk:mfalogon", Value = "true");
"@
        }

        if ($ApplyMFAConfiguration.AzureMFA.ContainsKey('phoneconfirmation') -and $ApplyMFAConfiguration.AzureMFA.phoneconfirmation -eq $true)
        {
            $mfaRulesText += "Phone callback"
            $mfaRules += @"
@RuleName = "Check RefedsMFA context class after successful Azure MFA with Phone callback"
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value == "http://schemas.microsoft.com/ws/2012/12/authmethod/phoneconfirmation"]
=> add(Type = "urn:adfstk:mfalogon", Value = "true");
"@
        }

        if ($ApplyMFAConfiguration.AzureMFA.ContainsKey('phoneotp') -and $ApplyMFAConfiguration.AzureMFA.phoneotp -eq $true)
        {
            $mfaRulesText += "Phone OTP"
            $mfaRules += @"
@RuleName = "Check RefedsMFA context class after successful Azure MFA with Phone OTP"
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value == "http://schemas.microsoft.com/ws/2012/12/authmethod/phoneotp"]
=> add(Type = "urn:adfstk:mfalogon", Value = "true");
"@
        }

        $mfaRules += @"
@RuleName = "Exists RefedsMFA context class after successful Azure MFA with $($mfaRulesText -join '/')"
NOT EXISTS([Type == "urn:adfstk:mfalogon"])
=> issue(Type = "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationmethod", Value = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport");
"@
        
    }
    else {
        # Check if the ADFSTK MFA Adapter is installed and add rules if so
        if ([string]::IsNullOrEmpty($Global:ADFSTKRefedsMFAUsernamePasswordAdapterInstalled))
        {
            $Global:ADFSTKRefedsMFAUsernamePasswordAdapterInstalled = ![string]::IsNullOrEmpty((Get-AdfsAuthenticationProvider -Name RefedsMFAUsernamePasswordAdapter -WarningAction Ignore))
        }

        if ($Global:ADFSTKRefedsMFAUsernamePasswordAdapterInstalled)
        {
            $mfaRules += @"
            @RuleName = "Assert Refeds MFA is compliant with"
            COUNT([Type == "http://schemas.microsoft.com/claims/authnmethodsproviders"]) == 1
            && EXISTS([Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", 
                       Value == "https://refeds.org/profile/mfa"])
            => issue(Type = "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationmethod", 
                     Value = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport");
"@
        }
        else {
            $null
        }
    }

    return $mfaRules
}
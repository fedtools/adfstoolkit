function Get-ADFSTkIssuanceAuthorizationRules
{
param (

    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    [string]$EntityId
)


if ([string]::IsNullOrEmpty($Global:ManualSPSettings))
{
    $Global:ManualSPSettings = Get-ADFSTkManualSPSettings
}

#Default rule if nothing overrides it
$IssuanceAuthorizationRules =
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", 
     Value = "true");
"@

#if ($Global:ManualSPSettings -ne $null)
#{
    #AllSPs
    if ($Global:ManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
        $Global:ManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
        $Global:ManualSPSettings.'urn:adfstk:allsps'.ContainsKey('AuthorizationRules'))
    {
        $IssuanceAuthorizationRules = $Global:ManualSPSettings.'urn:adfstk:allsps'.AuthorizationRules
    }

    #AllEduSPs

    if ($EntityId -ne $null)
    {
    
        #First remove http:// or https://
        $entityDNS = $EntityId.ToLower().Replace('http://','').Replace('https://','')

        #Second get rid of all ending sub paths
        $entityDNS = $entityDNS -split '/' | select -First 1

        #Last fetch the last two words and join them with a .
        #$entityDNS = ($entityDNS -split '\.' | select -Last 2) -join '.'

        $settingsDNS = $null

        foreach($setting in $Global:ManualSPSettings.Keys)
        {
            if ($setting.StartsWith('urn:adfstk:entityiddnsendswith:'))
            {
                $settingsDNS = $setting -split ':' | select -Last 1
            }
        }

        if ($entityDNS.EndsWith($settingsDNS) -and `
            $Global:ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS" -is [System.Collections.Hashtable] -and `
            $Global:ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('AuthorizationRules'))
    {
        $IssuanceAuthorizationRules = $Global:ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".AuthorizationRules
    }

    #Manual SP
    if ($EntityId -ne $null -and `
        $Global:ManualSPSettings.ContainsKey($EntityId) -and `
        $Global:ManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
        $Global:ManualSPSettings.$EntityId.ContainsKey('AuthorizationRules'))
        {
            $IssuanceAuthorizationRules = $Global:ManualSPSettings.$EntityId.AuthorizationRules
        }
    }
#}

$IssuanceAuthorizationRules

}
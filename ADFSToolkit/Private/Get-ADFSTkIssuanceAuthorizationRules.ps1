function Get-ADFSTkIssuanceAuthorizationRules
{
param (

    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    [string]$EntityId
)


if ([string]::IsNullOrEmpty($Global:ADFSTkManualSPSettings))
{
    if ([string]::IsNullOrEmpty($Global:ADFSTkAllTransformRules) -or $Global:ADFSTkAllTransformRules.Count -eq 0)
    {
        $Global:ADFSTkAllTransformRules = Import-ADFSTkAllTransformRules
        $AllTransformRules = $Global:ADFSTkAllTransformRules #So we don't need to change anything in the Get-ADFSTkManualSPSettings files
    }
    $Global:ADFSTkManualSPSettings = Get-ADFSTkManualSPSettings
}

#Default rule if nothing overrides it
$IssuanceAuthorizationRules =
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", 
     Value = "true");
"@

#if ($Global:ADFSTkManualSPSettings -ne $null)
#{
    #AllSPs
    if ($Global:ADFSTkManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
        $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
        $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.ContainsKey('AuthorizationRules'))
    {
        $IssuanceAuthorizationRules = $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.AuthorizationRules
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

        foreach($setting in $Global:ADFSTkManualSPSettings.Keys)
        {
            if ($setting.StartsWith('urn:adfstk:entityiddnsendswith:'))
            {
                $settingsDNS = $setting -split ':' | select -Last 1
            }
        }

        if ($entityDNS.EndsWith($settingsDNS) -and `
            $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS" -is [System.Collections.Hashtable] -and `
            $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('AuthorizationRules'))
    {
        $IssuanceAuthorizationRules = $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".AuthorizationRules
    }

    #Manual SP
    if ($EntityId -ne $null -and `
        $Global:ADFSTkManualSPSettings.ContainsKey($EntityId) -and `
        $Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
        $Global:ADFSTkManualSPSettings.$EntityId.ContainsKey('AuthorizationRules'))
        {
            $IssuanceAuthorizationRules = $Global:ADFSTkManualSPSettings.$EntityId.AuthorizationRules
        }
    }
#}

$IssuanceAuthorizationRules

}
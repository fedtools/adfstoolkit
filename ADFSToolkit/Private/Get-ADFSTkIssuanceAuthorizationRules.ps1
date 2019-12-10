function Get-ADFSTkIssuanceAuthorizationRules
{
param (

    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    [string]$EntityId
)


$ManualSPSettings = get-ADFSTkManualSPSettings

#Default rule if nothing overrides it
$IssuanceAuthorizationRules =
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", 
     Value = "true");
"@

#AllSPs
if ($ManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
    $ManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
    $ManualSPSettings.'urn:adfstk:allsps'.ContainsKey('AuthorizationRules'))
{
    $IssuanceAuthorizationRules = $ManualSPSettings.'urn:adfstk:allsps'.AuthorizationRules
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

    foreach($setting in $ManualSPSettings.Keys)
    {
        if ($setting.StartsWith('urn:adfstk:entityiddnsendswith:'))
        {
            $settingsDNS = $setting -split ':' | select -Last 1
        }
    }

    if ($entityDNS.EndsWith($settingsDNS) -and `
        $ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS" -is [System.Collections.Hashtable] -and `
        $ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('AuthorizationRules'))
{
    $IssuanceAuthorizationRules = $ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".AuthorizationRules
}

#Manual SP
if ($EntityId -ne $null -and `
    $ManualSPSettings.ContainsKey($EntityId) -and `
    $ManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
    $ManualSPSettings.$EntityId.ContainsKey('AuthorizationRules'))
    {
        $IssuanceAuthorizationRules = $ManualSPSettings.$EntityId.AuthorizationRules
    }
}

$IssuanceAuthorizationRules

}
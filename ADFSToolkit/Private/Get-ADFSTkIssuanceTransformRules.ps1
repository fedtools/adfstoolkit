function Get-ADFSTkIssuanceTransformRules
{
param (

    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    [string[]]$EntityCategories,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
    [string]$EntityId,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
    $RequestedAttribute,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
    $RegistrationAuthority
)


$AllAttributes = Import-ADFSTkAllAttributes
$AllTransformRules = Import-ADFSTkAllTransformRules

$IssuanceTransformRuleCategories = Import-ADFSTkIssuanceTransformRuleCategories -RequestedAttribute $RequestedAttribute
$IssuanceTransformRulesManualSP = get-ADFSTkManualSPSettings


### Transform Entity Categories

$TransformedEntityCategories = @()

$AttributesFromStore = @{}
$IssuanceTransformRules = [Ordered]@{}

if ($EntityCategories -eq $null)
{
    $TransformedEntityCategories += "NoEntityCategory"
}
else
{
    if ($EntityCategories.Contains("http://refeds.org/category/research-and-scholarship")) 
    {
        $TransformedEntityCategories += "research-and-scholarship" 
    }

    if ($EntityCategories.Contains("http://www.geant.net/uri/dataprotection-code-of-conduct/v1")) 
    {
        $TransformedEntityCategories += "ReleaseToCoCo" 
    }

    if ($EntityCategories.Contains("http://www.swamid.se/category/research-and-education") -and `
        ($EntityCategories.Contains("http://www.swamid.se/category/eu-adequate-protection") -or `
        $EntityCategories.Contains("http://www.swamid.se/category/nren-service") -or `
        $EntityCategories.Contains("http://www.swamid.se/category/hei-service")))
    {
        $TransformedEntityCategories += "entity-category-research-and-education" 
    }

    if ($EntityCategories.Contains("http://www.swamid.se/category/sfs-1993-1153"))
    {
        $TransformedEntityCategories += "entity-category-sfs-1993-1153" 
    }

    #if ($EntityID.Identifier.Contains("*..se") THEN ADD Entitetskategori

    #if ($EntityCategories.Contains("http://www.swamid.se/category/hei-service"))
    #{
    #    $TransformedEntityCategories += "all-requested-attributes" 
    #}
    #
    #if ($EntityCategories.Contains("http://www.swamid.se/category/nren-service"))
    #{
    #    $TransformedEntityCategories += "all-requested-attributes" 
    #}
    #
    #if ($EntityCategories.Contains("http://www.swamid.se/category/eu-adequate-protection"))
    #{
    #    $TransformedEntityCategories += "all-requested-attributes" 
    #}

    if ($TransformedEntityCategories.Count -eq 0)
    {
        $TransformedEntityCategories += "NoEntityCategory"
    }

###

}

#region Add TransformRules from categories
$TransformedEntityCategories | % { 

    if ($_ -ne $null -and $IssuanceTransformRuleCategories.ContainsKey($_))
    {
        foreach ($Rule in $IssuanceTransformRuleCategories[$_].Keys) { 
            if ($IssuanceTransformRuleCategories[$_][$Rule] -ne $null)
            {
                $IssuanceTransformRules[$Rule] = $IssuanceTransformRuleCategories[$_][$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
                foreach ($Attribute in $IssuanceTransformRuleCategories[$_][$Rule].Attribute) { $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] }
            }
        }
    }
}
#endregion



if ($EntityId -ne $null -and $IssuanceTransformRulesManualSP.ContainsKey($EntityId))
{
    foreach ($Rule in $IssuanceTransformRulesManualSP[$EntityId].Keys) { 
        if ($IssuanceTransformRulesManualSP[$EntityId][$Rule] -ne $null)
        {                
            $IssuanceTransformRules[$Rule] = $IssuanceTransformRulesManualSP[$EntityId][$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
            foreach ($Attribute in $IssuanceTransformRulesManualSP[$EntityId][$Rule].Attribute) { 
                $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] 
            }
        }
    }
}

### This is a good place to remove attributes that shouldn't be sent outside a RegistrationAuthority
$removeRules = @()
foreach ($rule in $IssuanceTransformRules.Keys)
{
    $attribute = $Settings.configuration.storeConfig.attributes.attribute | ? name -eq $rule
    if ($attribute -ne $null -and $attribute.allowedRegistrationAuthorities -ne $null)
    {
        $allowedRegistrationAuthorities = @()
        $allowedRegistrationAuthorities += $attribute.allowedRegistrationAuthorities.registrationAuthority
        if ($allowedRegistrationAuthorities.count -gt 0 -and !$allowedRegistrationAuthorities.contains($RegistrationAuthority))
        {
            $removeRules += $rule
        }
    }
}

$removeRules | % {$IssuanceTransformRules.Remove($_)}

###

#region Create Stores
if ($AttributesFromStore.Count)
{
    $FirstRule = ""
    foreach ($store in ($Settings.configuration.storeConfig.stores.store | sort order))
    {
        #region Active Directory Store
        if ($store.name -eq "Active Directory")
        {
            $currentStoreAttributes = $AttributesFromStore.Values | ? store -eq $store.name
            if ($currentStoreAttributes.Count -gt 0)
            {
                $FirstRule += @"

                @RuleName = "Retrieve Attributes from AD"
                c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                => add(store = "$($store.name)", 
                types = ("$($currentStoreAttributes.type -join '","')"), 
                query = ";$($currentStoreAttributes.name -join ',');{0}", param = c.Value);

"@
            }
        }
        #endregion

        #region SQL Store

        #endregion

        #region LDAP Store

        #endregion

        #region Custom Store
        if ($store.name -eq "Custom Store")
        {
            $currentStoreAttributes = $AttributesFromStore.Values | ? store -eq $store.name
            if ($currentStoreAttributes -ne $null)
            {
                $FirstRule += @"

                @RuleName = "Retrieve Attributes from Custom Store"
                c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                => add(store = "$($store.name)", 
                types = ("$($currentStoreAttributes.type -join '","')"), 
                query = ";$($currentStoreAttributes.name -join ',');{0}", param = "[ReplaceWithSPNameQualifier]", param = c.Value);

"@
            }
        }
        #endregion
    }

    return $FirstRule.Replace("[ReplaceWithSPNameQualifier]",$EntityId) + $IssuanceTransformRules.Values
}
else
{
    return $IssuanceTransformRules.Values
}
#endregion
}
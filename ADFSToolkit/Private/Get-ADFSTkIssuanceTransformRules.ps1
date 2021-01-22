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
    $RegistrationAuthority,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
    $NameIDFormat
)

#Get All paths
if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
{
    $Global:ADFSTkPaths = Get-ADFSTKPaths
}

if ([string]::IsNullOrEmpty($Global:ADFSTkAllAttributes) -or $Global:ADFSTkAllAttributes.Count -eq 0)
{
    $Global:ADFSTkAllAttributes = Import-ADFSTkAllAttributes
}

if ([string]::IsNullOrEmpty($Global:ADFSTkAllTransformRules) -or $Global:ADFSTkAllTransformRules.Count -eq 0)
{
    $Global:ADFSTkAllTransformRules = Import-ADFSTkAllTransformRules

    if (Test-Path $Global:ADFSTkPaths.institutionLocalTransformRulesFile)
    {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFoundFile)
        try {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFile)
            . $Global:ADFSTkPaths.institutionLocalTransformRulesFile
    
            if (Test-Path function:Get-ADFSTkLocalTransformRules)
            {
                $localTransformRules = Get-ADFSTkLocalTransformRules
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFound -f $localTransformRules.Count)
    
                foreach ($transformRule in $localTransformRules.Keys)
                {
                    #Add or replace the standard Entoty Category with the federation one
                    if ($Global:ADFSTkAllTransformRules.ContainsKey($transformRule))
                    {
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesOverwrite -f $transformRule)
                    }
                    else
                    {
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesAdd -f $transformRule)
                    }
    
                    $Global:ADFSTkAllTransformRules.$transformRule = $localTransformRules.$transformRule
                }
            }
            else
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesLoadFail) -EntryType Error
            }
        }
        catch
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesLoadFail) -EntryType Error
        }
    }
    else {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFileNotFound)
    }
}

if ([string]::IsNullOrEmpty($AllTransformRules))
{
    $AllTransformRules = $Global:ADFSTkAllTransformRules #So we don't need to change anything in the Get-ADFSTkManualSPSettings files
}

$RequestedAttributes = @{}

if (![string]::IsNullOrEmpty($RequestedAttribute))
{
    $RequestedAttribute | % {
        $RequestedAttributes.($_.Name.trimEnd()) = $_.friendlyName
    }
}
else
{
    Write-ADFSTkLog (Get-ADFSTkLanguageText rulesNoRequestedAttributesDetected)
}

$IssuanceTransformRuleCategories = Import-ADFSTkIssuanceTransformRuleCategories -RequestedAttributes $RequestedAttributes

$adfstkConfig = Get-ADFSTkConfiguration

$federationDir = Join-Path $Global:ADFSTkPaths.federationDir $adfstkConfig.FederationConfig.Federation.FederationName
$fedEntityCategoryFileName = Join-Path $federationDir "$($adfstkConfig.FederationConfig.Federation.FederationName)_entityCategories.ps1"

if (Test-Path $fedEntityCategoryFileName)
{
    try {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationEntityCategoryFile)
        . $fedEntityCategoryFileName

        if (Test-Path function:Import-ADFSTkIssuanceTransformRuleCategoriesFromFederation)
        {
            $IssuanceTransformRuleCategoriesFromFederation = Import-ADFSTkIssuanceTransformRuleCategoriesFromFederation -RequestedAttributes $RequestedAttributes
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationEntityCategoriesFound -f $IssuanceTransformRuleCategoriesFromFederation.Count)

            foreach ($entityCategory in $IssuanceTransformRuleCategoriesFromFederation.Keys)
            {
                #Add or replace the standard Entoty Category with the federation one
                if ($IssuanceTransformRuleCategories.ContainsKey($entityCategory))
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationEntityCategoryOverwrite -f $entityCategory)
                }
                else
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationEntityCategoryAdd -f $entityCategory)
                }

                $IssuanceTransformRuleCategories.$entityCategory = $IssuanceTransformRuleCategoriesFromFederation.$entityCategory
            }
        }
        else
        {
            #Write Verbose
        }
    }
    catch
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText rulesFederationEntityCategoryLoadFail) -EntryType Error
    }
}
else
{
    #Write Verbose
}


if ([string]::IsNullOrEmpty($Global:ADFSTkManualSPSettings))
{
    $Global:ADFSTkManualSPSettings = Get-ADFSTkManualSPSettings
}

### Transform Entity Categories

$TransformedEntityCategories = @()

$AttributesFromStore = @{}
$IssuanceTransformRules = [Ordered]@{}

$ManualSPTransformRules = $null

#Check version of get-ADFSTkLocalManualSpSettings and retrieve the transform rules
if ($EntityId -ne $null -and $Global:ADFSTkManualSPSettings.ContainsKey($EntityId))
{
    if ($Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
        $Global:ADFSTkManualSPSettings.$EntityId.ContainsKey('TransformRules'))
    {
        $ManualSPTransformRules = $Global:ADFSTkManualSPSettings.$EntityId.TransformRules
    }
    elseif ($Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Specialized.OrderedDictionary])
    {
        $ManualSPTransformRules = $Global:ADFSTkManualSPSettings.$EntityId
    }
    else
    {
        #Shouldn't be here
    }
}

#Add manually added entity categories if any

if ($EntityId -ne $null -and `
    $Global:ADFSTkManualSPSettings.ContainsKey($EntityId) -and `
    $Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
    $Global:ADFSTkManualSPSettings.$EntityId.ContainsKey('EntityCategories'))
{
    $EntityCategories += $Global:ADFSTkManualSPSettings.$EntityId.EntityCategories
}


if ($EntityCategories -eq $null)
{
    $TransformedEntityCategories += "NoEntityCategory"
}
else
{
    foreach ($entityCategory in $IssuanceTransformRuleCategories.Keys)
    {
        if ($entityCategory -eq "http://www.swamid.se/category/research-and-education" -and $EntityCategories.Contains($entityCategory))
        {
            if ($EntityCategories.Contains("http://www.swamid.se/category/eu-adequate-protection") -or `
                $EntityCategories.Contains("http://www.swamid.se/category/nren-service") -or `
                $EntityCategories.Contains("http://www.swamid.se/category/hei-service"))
            {
                $TransformedEntityCategories += $entityCategory
            }
        }
        elseif ($EntityCategories.Contains($entityCategory)) 
        {
            $TransformedEntityCategories += $entityCategory
        }
    }

    if ($TransformedEntityCategories.Count -eq 0)
    {
        $TransformedEntityCategories += "NoEntityCategory"
    }

###

}

#region Add NameID to TransformRules
    if ([string]::IsNullOrEmpty($NameIDFormat))
    {
        $IssuanceTransformRules.'transient-id' = $Global:ADFSTkAllTransformRules.'transient-id'.Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
        foreach ($Attribute in $Global:ADFSTkAllTransformRules.'transient-id'.Attribute) { 
            $AttributesFromStore[$Attribute] = $Global:ADFSTkAllAttributes[$Attribute]
        }
    }
    elseif ($NameIDFormat.Contains('urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'))
    {
        $IssuanceTransformRules.'persistent-id' = $Global:ADFSTkAllTransformRules.'persistent-id'.Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
        foreach ($Attribute in $Global:ADFSTkAllTransformRules.'persistent-id'.Attribute) { 
            $AttributesFromStore[$Attribute] = $Global:ADFSTkAllAttributes[$Attribute]
        }
    }
    # elseif ($NameIDFormat.Contains('urn:oasis:names:tc:SAML:2.0:nameid-format:transient'))
    # {
    #     
    # }
    else
    {
        $IssuanceTransformRules.'transient-id' = $Global:ADFSTkAllTransformRules.'transient-id'.Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
        foreach ($Attribute in $Global:ADFSTkAllTransformRules.'transient-id'.Attribute) { 
            $AttributesFromStore[$Attribute] = $Global:ADFSTkAllAttributes[$Attribute]
        }
    }
#endregion

#region Add TransformRules from categories
$TransformedEntityCategories | % { 

    if ($_ -ne $null -and $IssuanceTransformRuleCategories.ContainsKey($_))
    {
        foreach ($Rule in $IssuanceTransformRuleCategories[$_].Keys) { 
            if ($IssuanceTransformRuleCategories[$_][$Rule] -ne $null)
            {
                $IssuanceTransformRules[$Rule] = $IssuanceTransformRuleCategories[$_][$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
                foreach ($Attribute in $IssuanceTransformRuleCategories[$_][$Rule].Attribute) { 
                    $AttributesFromStore[$Attribute] = $Global:ADFSTkAllAttributes[$Attribute]
                }
            }
        }
    }
}
#endregion

#AllSPs
if ($Global:ADFSTkManualSPSettings.ContainsKey('urn:adfstk:allsps'))
{
    foreach ($Rule in $Global:ADFSTkManualSPSettings['urn:adfstk:allsps'].TransformRules.Keys) { 
        if ($Global:ADFSTkManualSPSettings['urn:adfstk:allsps'].TransformRules[$Rule] -ne $null)
        {                
            $IssuanceTransformRules[$Rule] = $Global:ADFSTkManualSPSettings['urn:adfstk:allsps'].TransformRules[$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
            foreach ($Attribute in $Global:ADFSTkManualSPSettings['urn:adfstk:allsps'].TransformRules[$Rule].Attribute) { 
                $AttributesFromStore[$Attribute] = $Global:ADFSTkAllAttributes[$Attribute]
            }
        }
    }
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
        $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('TransformRules'))
    {
        foreach ($Rule in $Global:ADFSTkManualSPSettings["urn:adfstk:entityiddnsendswith:$settingsDNS"].TransformRules.Keys) { 
            if ($Global:ADFSTkManualSPSettings["urn:adfstk:entityiddnsendswith:$settingsDNS"].TransformRules[$Rule] -ne $null)
            {                
                $IssuanceTransformRules[$Rule] = $Global:ADFSTkManualSPSettings["urn:adfstk:entityiddnsendswith:$settingsDNS"].TransformRules[$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
                foreach ($Attribute in $Global:ADFSTkManualSPSettings["urn:adfstk:entityiddnsendswith:$settingsDNS"].TransformRules[$Rule].Attribute) { 
                    $AttributesFromStore[$Attribute] = $Global:ADFSTkAllAttributes[$Attribute]
                }
            }
        }
    }
}


#Manual SP
if ($ManualSPTransformRules -ne $null)
{
    foreach ($Rule in $ManualSPTransformRules.Keys) { 
        if ($ManualSPTransformRules[$Rule] -ne $null)
        {                
            $IssuanceTransformRules[$Rule] = $ManualSPTransformRules[$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
            foreach ($Attribute in $ManualSPTransformRules[$Rule].Attribute) { 
                $AttributesFromStore[$Attribute] = $Global:ADFSTkAllAttributes[$Attribute]
            }
        }
    }
}

### This is a good place to remove attributes that shouldn't be sent outside a RegistrationAuthority
#$removeRules = @()
#foreach ($rule in $IssuanceTransformRules.Keys)
#{
#    $attribute = $Settings.configuration.attributes.attribute | ? name -eq $rule
#    if ($attribute -ne $null -and $attribute.allowedRegistrationAuthorities -ne $null)
#    {
#        $allowedRegistrationAuthorities = @()
#        $allowedRegistrationAuthorities += $attribute.allowedRegistrationAuthorities.registrationAuthority
#        if ($allowedRegistrationAuthorities.count -gt 0 -and !$allowedRegistrationAuthorities.contains($RegistrationAuthority))
#        {
#            $removeRules += $rule
#        }
#    }
#}
#
#$removeRules | % {$IssuanceTransformRules.Remove($_)}
#


$removeRules = @()
foreach ($attr in $AttributesFromStore.values)
{
    $attribute = $Settings.configuration.attributes.attribute | ? type -eq $attr.type
    if ($attribute -ne $null -and $attribute.allowedRegistrationAuthorities -ne $null)
    {
        $allowedRegistrationAuthorities = @()
        $allowedRegistrationAuthorities += $attribute.allowedRegistrationAuthorities.registrationAuthority
        if ($allowedRegistrationAuthorities.count -gt 0 -and !$allowedRegistrationAuthorities.contains($RegistrationAuthority))
        {
            $removeRules += $attr
        }
    }
}

$removeRules | % {
    
    $AttributesFromStore.Remove($_.type)
    foreach ($key in $Global:ADFSTkAllTransformRules.Keys) 
    {
        if ($Global:ADFSTkAllTransformRules.$key.Attribute -eq $_.type) 
        {
            $IssuanceTransformRules.Remove($key)
            break
        }
    }
}


###

#region Create Stores
if ($AttributesFromStore.Count -ne $null)
{

    $FirstRule = Get-ADFSTkStoreRule -Stores $Settings.configuration.storeConfig.stores.store `
                                     -AttributesFromStore $AttributesFromStore `
                                     -EntityId $EntityId 

    return  $FirstRule + $IssuanceTransformRules.Values
}
else
{
    return $IssuanceTransformRules.Values
}
#endregion
}
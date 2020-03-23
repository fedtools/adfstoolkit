function Import-ADFSTkIssuanceTransformRuleCategories {
param (
    
[Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    $RequestedAttribute,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
    $NameIDFormat

)
    ### Create AttributeStore variables
    $IssuanceTransformRuleCategories = @{}

    $RequestedAttributes = @{}

    if (![string]::IsNullOrEmpty($RequestedAttribute))
    {
        $RequestedAttribute | % {
            $RequestedAttributes.($_.Name.trimEnd()) = $_.friendlyName
        }
    }else
    {
    Write-ADFSTkLog "No Requested attributes detected"

    }

    ### Released to SP:s without Entity Category

    $TransformRules = [Ordered]@{}

    if ([string]::IsNullOrEmpty($NameIDFormat))
    {
        $TransformRules.'transient-id' = $Global:AllTransformRules.'transient-id'
    }
    elseif ($NameIDFormat.Contains('urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'))
    {
        $TransformRules.'persistent-id' = $Global:AllTransformRules.'persistent-id'
    }
    elseif ($NameIDFormat.Contains('urn:oasis:names:tc:SAML:2.0:nameid-format:transient'))
    {
        $TransformRules.'transient-id' = $Global:AllTransformRules.'transient-id'
    }
    else
    {
        $TransformRules.'transient-id' = $Global:AllTransformRules.'transient-id'
    }

    $IssuanceTransformRuleCategories.Add("NoEntityCategory",$TransformRules)
    
    ### research-and-scholarship ###

    $TransformRules = [Ordered]@{}

    #$TransformRules.'transient-id' = $Global:AllTransformRules.'transient-id'
    
    $TransformRules.displayName = $Global:AllTransformRules.displayName
    $TransformRules.eduPersonAssurance = $Global:AllTransformRules.eduPersonAssurance
    $TransformRules.eduPersonPrincipalName = $Global:AllTransformRules.eduPersonPrincipalName
    $TransformRules.eduPersonScopedAffiliation = $Global:AllTransformRules.eduPersonScopedAffiliation
    
    #eduPersonTargetedID should only be released if eduPersonPrincipalName i ressignable
    if (![string]::IsNullOrEmpty($Settings.configuration.eduPersonPrincipalNameRessignable) -and $Settings.configuration.eduPersonPrincipalNameRessignable.ToLower() -eq "true")
    {
        $TransformRules.eduPersonTargetedID = $Global:AllTransformRules.eduPersonTargetedID
    }

    $TransformRules.eduPersonUniqueID = $Global:AllTransformRules.eduPersonUniqueID
    $TransformRules.givenName = $Global:AllTransformRules.givenName
    $TransformRules.mail = $Global:AllTransformRules.mail
    $TransformRules.sn = $Global:AllTransformRules.sn

    $IssuanceTransformRuleCategories.Add("research-and-scholarship",$TransformRules)

    #...
    #$IssuanceTransformRuleCategories.Add("research-and-scholarship-SWAMID",$TransformRules)

    ### GEANT Dataprotection Code of Conduct
    
    $TransformRules = [Ordered]@{}

    if ($RequestedAttributes.Count -gt 0)
    {
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.6")) {
            $TransformRules.c = $Global:AllTransformRules.c
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.3")) {
            $TransformRules.cn = $Global:AllTransformRules.cn
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:0.9.2342.19200300.100.1.43")) {
            $TransformRules.co = $Global:AllTransformRules.co
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.16.840.1.113730.3.1.241")) { 
            $TransformRules.displayName = $Global:AllTransformRules.displayName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.6")) { 
            $TransformRules.countryName = $Global:AllTransformRules.countryName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.1")) {
            $TransformRules.eduPersonAffiliation = $Global:AllTransformRules.eduPersonAffiliation
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.11")) {
            $TransformRules.eduPersonAssurance = $Global:AllTransformRules.eduPersonAssurance
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.16")) {
            $TransformRules.eduPersonOrcid = $Global:AllTransformRules.eduPersonOrcid
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.6")) { 
            $TransformRules.eduPersonPrincipalName = $Global:AllTransformRules.eduPersonPrincipalName
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.9")) {
            $TransformRules.eduPersonScopedAffiliation = $Global:AllTransformRules.eduPersonScopedAffiliation
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.10")) { 
            $TransformRules.eduPersonTargetedID = $Global:AllTransformRules.eduPersonTargetedID
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.13")) { 
            $TransformRules.eduPersonUniqueID = $Global:AllTransformRules.eduPersonUniqueID
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:0.9.2342.19200300.100.1.43")) { 
            $TransformRules.friendlyCountryName = $Global:AllTransformRules.friendlyCountryName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.42")) { 
            $TransformRules.givenName = $Global:AllTransformRules.givenName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:0.9.2342.19200300.100.1.3")) { 
            $TransformRules.mail = $Global:AllTransformRules.mail
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.2428.90.1.6")) { 
            $TransformRules.norEduOrgAcronym = $Global:AllTransformRules.norEduOrgAcronym 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.2428.90.1.5")) {
            $TransformRules.norEduPersonNIN = $Global:AllTransformRules.norEduPersonNIN
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.10")) {
            $TransformRules.o = $Global:AllTransformRules.o
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.10")) { 
            $TransformRules.organizationName = $Global:AllTransformRules.organizationName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.2.752.29.4.13")) {
            $TransformRules.personalIdentityNumber = $Global:AllTransformRules.personalIdentityNumber
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.3")) {
            $TransformRules.schacDateOfBirth = $Global:AllTransformRules.schacDateOfBirth
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.9")) { 
            $TransformRules.schacHomeOrganization = $Global:AllTransformRules.schacHomeOrganization
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.10")) {
            $TransformRules.schacHomeOrganizationType = $Global:AllTransformRules.schacHomeOrganizationType
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.4")) { 
            $TransformRules.sn = $Global:AllTransformRules.sn
        }
    }

    $IssuanceTransformRuleCategories.Add("ReleaseToCoCo",$TransformRules)
    
    ### SWAMID Entity Category Research and Education

    $TransformRules = [Ordered]@{}

    #$TransformRules.'transient-id' = $Global:AllTransformRules.'transient-id'
    $TransformRules.eduPersonPrincipalName = $Global:AllTransformRules.eduPersonPrincipalName
    $TransformRules.eduPersonUniqueID = $Global:AllTransformRules.eduPersonUniqueID
    $TransformRules.mail = $Global:AllTransformRules.mail
    $TransformRules.displayName = $Global:AllTransformRules.displayName
    $TransformRules.cn = $Global:AllTransformRules.cn
    $TransformRules.givenName = $Global:AllTransformRules.givenName
    $TransformRules.sn = $Global:AllTransformRules.sn
    $TransformRules.eduPersonAssurance = $Global:AllTransformRules.eduPersonAssurance
    $TransformRules.eduPersonScopedAffiliation = $Global:AllTransformRules.eduPersonScopedAffiliation
    $TransformRules.o = $Global:AllTransformRules.o
    $TransformRules.norEduOrgAcronym = $Global:AllTransformRules.norEduOrgAcronym
    $TransformRules.c = $Global:AllTransformRules.c
    $TransformRules.co = $Global:AllTransformRules.co
    $TransformRules.schacHomeOrganization = $Global:AllTransformRules.schacHomeOrganization

    $IssuanceTransformRuleCategories.Add("entity-category-research-and-education",$TransformRules)

    ### SWAMID Entity Category SFS 1993:1153

    $TransformRules = [Ordered]@{}

    #$TransformRules.'transient-id' = $Global:AllTransformRules.'transient-id'
    $TransformRules.norEduPersonNIN = $Global:AllTransformRules.norEduPersonNIN
    $TransformRules.eduPersonAssurance = $Global:AllTransformRules.eduPersonAssurance

    $IssuanceTransformRuleCategories.Add("entity-category-sfs-1993-1153",$TransformRules)

    return $IssuanceTransformRuleCategories
}
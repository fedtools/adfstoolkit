function Import-ADFSTkIssuanceTransformRuleCategories {
param (
    $RequestedAttribute
)
    ### Create AttributeStore variables
    $IssuanceTransformRuleCategories = @{}

    $RequestedAttributes = @{}

    if (![string]::IsNullOrEmpty($RequestedAttribute))
    {
        $RequestedAttribute | % {
            $RequestedAttributes.($_.Name) = $_.friendlyName
        }
    }

    ### Released to SP:s without Entity Category

    $TransformRules = [Ordered]@{}

    $TransformRules.'transient-id' = $AllTransformRules.'transient-id'
    #$TransformRules.eduPersonTargetedID = $AllTransformRules.eduPersonTargetedID

    $IssuanceTransformRuleCategories.Add("NoEntityCategory",$TransformRules)
    
    ### research-and-scholarship ###

    $TransformRules = [Ordered]@{}

    $TransformRules.'transient-id' = $AllTransformRules.'transient-id'
    #$TransformRules.eduPersonTargetedID = $AllTransformRules.eduPersonTargetedID
    $TransformRules.eduPersonPrincipalName = $AllTransformRules.eduPersonPrincipalName
    #eduPersonUniqueID
    $TransformRules.mail = $AllTransformRules.mail
    $TransformRules.displayName = $AllTransformRules.displayName
    $TransformRules.givenName = $AllTransformRules.givenName
    $TransformRules.sn = $AllTransformRules.sn
    $TransformRules.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation

    $IssuanceTransformRuleCategories.Add("research-and-scholarship",$TransformRules)

    ### GEANT Dataprotection Code of Conduct
    
    $TransformRules = [Ordered]@{}

    if ($RequestedAttributes.Count -gt 0)
    {
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.10")) { 
            $TransformRules.eduPersonTargetedID = $AllTransformRules.'transient-id'
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.10")) { 
            $TransformRules.eduPersonTargetedID = $AllTransformRules.eduPersonTargetedID
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.6")) { 
            $TransformRules.eduPersonPrincipalName = $AllTransformRules.eduPersonPrincipalName
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:0.9.2342.19200300.100.1.3")) { 
            $TransformRules.mail = $AllTransformRules.mail
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.16.840.1.113730.3.1.241")) { 
            $TransformRules.displayName = $AllTransformRules.displayName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.3")) { 
            $TransformRules.cn = $AllTransformRules.cn
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.42")) { 
            $TransformRules.displayName = $AllTransformRules.givenName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.4")) { 
            $TransformRules.cn = $AllTransformRules.sn
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.9")) {
            $TransformRules.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.1")) {
            $TransformRules.eduPersonScopedAffiliation = $AllTransformRules.eduPersonAffiliation
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.10")) { 
            $TransformRules.displayName = $AllTransformRules.organizationName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.2428.90.1.6")) { 
            $TransformRules.displayName = $AllTransformRules.norEduOrgAcronym 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.6")) { 
            $TransformRules.displayName = $AllTransformRules.countryName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:0.9.2342.19200300.100.1.43")) { 
            $TransformRules.displayName = $AllTransformRules.friendlyCountryName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.9")) { 
            $TransformRules.schacHomeOrganization = $AllTransformRules.schacHomeOrganization
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.10")) {
            $TransformRules.schacHomeOrganizationType = $AllTransformRules.schacHomeOrganizationType
        }
    }

    $IssuanceTransformRuleCategories.Add("ReleaseToCoCo",$TransformRules)
    
    ### SWAMID Entity Category Research and Education

    $TransformRules = [Ordered]@{}

    $TransformRules.'transient-id' = $AllTransformRules.'transient-id'
    #$TransformRules.eduPersonTargetedID = $AllTransformRules.eduPersonTargetedID
    $TransformRules.eduPersonPrincipalName = $AllTransformRules.eduPersonPrincipalName
    #eduPersonUniqueID
    $TransformRules.mail = $AllTransformRules.mail
    $TransformRules.displayName = $AllTransformRules.displayName
    $TransformRules.cn = $AllTransformRules.cn
    $TransformRules.givenName = $AllTransformRules.givenName
    $TransformRules.sn = $AllTransformRules.sn
    $TransformRules.eduPersonAssurance = $AllTransformRules.eduPersonAssurance
    $TransformRules.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation
    $TransformRules.o = $AllTransformRules.o
    $TransformRules.norEduOrgAcronym = $AllTransformRules.norEduOrgAcronym
    $TransformRules.c = $AllTransformRules.c
    $TransformRules.co = $AllTransformRules.co
    $TransformRules.schacHomeOrganization = $AllTransformRules.schacHomeOrganization

    $IssuanceTransformRuleCategories.Add("entity-category-research-and-education",$TransformRules)

    ### SWAMID Entity Category SFS 1993:1153

    $TransformRules = [Ordered]@{}

    $TransformRules.'transient-id' = $AllTransformRules.'transient-id'
    #$TransformRules.eduPersonTargetedID = $AllTransformRules.eduPersonTargetedID
    $TransformRules.norEduPersonNIN = $AllTransformRules.norEduPersonNIN
    $TransformRules.eduPersonAssurance = $AllTransformRules.eduPersonAssurance

    $IssuanceTransformRuleCategories.Add("entity-category-sfs-1993-1153",$TransformRules)

    return $IssuanceTransformRuleCategories
}
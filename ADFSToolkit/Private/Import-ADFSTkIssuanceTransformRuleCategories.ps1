function Import-ADFSTkIssuanceTransformRuleCategories {
    param (
    
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        $RequestedAttributes,
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 1)]
        $SubjectIDReq
    )

    if ($SubjectIDReq -eq 'any') {
        $SubjectIDReq = 'pairwise-id'
    } 

    ### Create AttributeStore variables
    $IssuanceTransformRuleCategories = @{}
    
    ### Released to SP:s without Entity Category
    $TransformRules = [Ordered]@{}
    #We don't want to send anything to SP's without entity categories at this time
    $IssuanceTransformRuleCategories.Add("NoEntityCategory", $TransformRules)
    
    ### research-and-scholarship ###

    $TransformRules = [Ordered]@{}

    $TransformRules.displayName = $Global:ADFSTkAllTransformRules.displayName
    $TransformRules.eduPersonAssurance = $Global:ADFSTkAllTransformRules.eduPersonAssurance
    $TransformRules.eduPersonPrincipalName = $Global:ADFSTkAllTransformRules.eduPersonPrincipalName
    $TransformRules.eduPersonScopedAffiliation = $Global:ADFSTkAllTransformRules.eduPersonScopedAffiliation
    
    #eduPersonTargetedID should only be released if eduPersonPrincipalName i ressignable
    if (![string]::IsNullOrEmpty($Settings.configuration.eduPersonPrincipalNameRessignable) -and $Settings.configuration.eduPersonPrincipalNameRessignable.ToLower() -eq "true") {
        $TransformRules.eduPersonTargetedID = $Global:ADFSTkAllTransformRules.eduPersonTargetedID
    }

    $TransformRules.eduPersonUniqueID = $Global:ADFSTkAllTransformRules.eduPersonUniqueID
    $TransformRules.givenName = $Global:ADFSTkAllTransformRules.givenName
    $TransformRules.mail = $Global:ADFSTkAllTransformRules.mail
    $TransformRules.sn = $Global:ADFSTkAllTransformRules.sn

    $IssuanceTransformRuleCategories.Add("http://refeds.org/category/research-and-scholarship", $TransformRules)

    ### GEANT Dataprotection Code of Conduct
    
    $TransformRules = [Ordered]@{}

    if ($RequestedAttributes.Count -gt 0) {
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.3")) {
            $TransformRules.cn = $Global:ADFSTkAllTransformRules.cn
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.16.840.1.113730.3.1.241")) { 
            $TransformRules.displayName = $Global:ADFSTkAllTransformRules.displayName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.1")) {
            $TransformRules.eduPersonAffiliation = $Global:ADFSTkAllTransformRules.eduPersonAffiliation
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.11")) {
            $TransformRules.eduPersonAssurance = $Global:ADFSTkAllTransformRules.eduPersonAssurance
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.16")) {
            $TransformRules.eduPersonOrcid = $Global:ADFSTkAllTransformRules.eduPersonOrcid
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.6")) { 
            $TransformRules.eduPersonPrincipalName = $Global:ADFSTkAllTransformRules.eduPersonPrincipalName
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.9")) {
            $TransformRules.eduPersonScopedAffiliation = $Global:ADFSTkAllTransformRules.eduPersonScopedAffiliation
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.10")) { 
            #eduPersonTargetedID should only be released if eduPersonPrincipalName i ressignable
            if (![string]::IsNullOrEmpty($Settings.configuration.eduPersonPrincipalNameRessignable) -and $Settings.configuration.eduPersonPrincipalNameRessignable.ToLower() -eq "true") {
                $TransformRules.eduPersonTargetedID = $Global:ADFSTkAllTransformRules.eduPersonTargetedID
            }
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.5923.1.1.1.13")) { 
            $TransformRules.eduPersonUniqueID = $Global:ADFSTkAllTransformRules.eduPersonUniqueID
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.42")) { 
            $TransformRules.givenName = $Global:ADFSTkAllTransformRules.givenName 
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:0.9.2342.19200300.100.1.3")) { 
            $TransformRules.mail = $Global:ADFSTkAllTransformRules.mail
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.2.752.29.4.13")) {
            $TransformRules.personalIdentityNumber = $Global:ADFSTkAllTransformRules.personalIdentityNumber
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.3")) {
            $TransformRules.schacDateOfBirth = $Global:ADFSTkAllTransformRules.schacDateOfBirth
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.9")) { 
            $TransformRules.schacHomeOrganization = $Global:ADFSTkAllTransformRules.schacHomeOrganization
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:1.3.6.1.4.1.25178.1.2.10")) {
            $TransformRules.schacHomeOrganizationType = $Global:ADFSTkAllTransformRules.schacHomeOrganizationType
        }
        if ($RequestedAttributes.ContainsKey("urn:oid:2.5.4.4")) { 
            $TransformRules.sn = $Global:ADFSTkAllTransformRules.sn
        }
    }

    #region Add subject-id/pairwise-id
    switch ($SubjectIDReq) {
        'pairwise-id' { 
            $TransformRules.pairwiseID = $Global:ADFSTkAllTransformRules.pairwiseID 
        }
        'subject-id' { 
            $TransformRules.subjectID = $Global:ADFSTkAllTransformRules.subjectID 
        }
        'none' {  }
        Default {}
    }
    #endregion

    $IssuanceTransformRuleCategories.Add("http://www.geant.net/uri/dataprotection-code-of-conduct/v1", $TransformRules)

    #Anonumous Authorization – REFEDS
    $TransformRules = [Ordered]@{}
    $TransformRules.eduPersonScopedAffiliation = $Global:ADFSTkAllTransformRules.eduPersonScopedAffiliation
    $TransformRules.eduPersonOrgDN = $Global:ADFSTkAllTransformRules.eduPersonOrgDN
    $TransformRules.schacHomeOrganizationType = $Global:ADFSTkAllTransformRules.schacHomeOrganizationType
    
    $TransformRules.eduPersonEntitlement = $Global:ADFSTkAllTransformRules.eduPersonEntitlement
    $IssuanceTransformRuleCategories.Add("http://refeds.org/category/anonymous/", $TransformRules)
    
    #Pseudonymous Authorization – REFEDS
    $TransformRules = [Ordered]@{}
    $TransformRules.eduPersonScopedAffiliation = $Global:ADFSTkAllTransformRules.eduPersonScopedAffiliation
    $TransformRules.eduPersonOrgDN = $Global:ADFSTkAllTransformRules.eduPersonOrgDN 
    $TransformRules.schacHomeOrganizationType = $Global:ADFSTkAllTransformRules.schacHomeOrganizationType
    
    $TransformRules.eduPersonEntitlement = $Global:ADFSTkAllTransformRules.eduPersonEntitlement
    $TransformRules.pairwiseID = $Global:ADFSTkAllTransformRules.pairwiseID #new unique per SP and anonymous https://docs.oasis-open.org/security/saml-subject-id-attr/v1.0/cs01/saml-subject-id-attr-v1.0-cs01.html 3.4
    $IssuanceTransformRuleCategories.Add("http://refeds.org/category/pseudonymous", $TransformRules)
    
    #Personalized Authorization – REFEDS
    $TransformRules = [Ordered]@{}
    $TransformRules.schacHomeOrganizationType = $Global:ADFSTkAllTransformRules.schacHomeOrganizationType
    $TransformRules.subjectID = $Global:ADFSTkAllTransformRules.subjectID #new same as eppn if unique
    $TransformRules.displayName = $Global:ADFSTkAllTransformRules.displayName 
    $TransformRules.givenName = $Global:ADFSTkAllTransformRules.givenName 
    $TransformRules.sn = $Global:ADFSTkAllTransformRules.sn
    $TransformRules.mail = $Global:ADFSTkAllTransformRules.mail
    $TransformRules.eduPersonScopedAffiliation = $Global:ADFSTkAllTransformRules.eduPersonScopedAffiliation
    $IssuanceTransformRuleCategories.Add("http://refeds.org/category/personalized", $TransformRules)
    
    ###
    
    return $IssuanceTransformRuleCategories
}
function Import-ADFSTkAllTransformRules
{
   

    $TransformRules = @{}
 #region Static values from config
    $TransformRules.o = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [o]"
    => issue(type = "urn:oid:2.5.4.10", 
    value = "$($Settings.configuration.StaticValues.o)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.norEduOrgAcronym = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [norEduOrgAcronym]"
    => issue(type = "urn:oid:1.3.6.1.4.1.2428.90.1.6", 
    value = "$($Settings.configuration.StaticValues.norEduOrgAcronym)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.c = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [c]"
    => issue(type = "urn:oid:2.5.4.6", 
    value = "$($Settings.configuration.StaticValues.c)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.co = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [co]"
    => issue(type = "urn:oid:0.9.2342.19200300.100.1.43", 
    value = "$($Settings.configuration.StaticValues.co)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.schacHomeOrganization = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [schacHomeOrganization]"
    => issue(type = "urn:oid:1.3.6.1.4.1.25178.1.2.9", 
    value = "$($Settings.configuration.StaticValues.schacHomeOrganization)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.schacHomeOrganizationType = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [schacHomeOrganizationType]"
    => issue(type = "urn:oid:1.3.6.1.4.1.25178.1.2.10", 
    value = "$($Settings.configuration.StaticValues.schacHomeOrganizationType)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }
    #endregion

    #region ID's
    $TransformRules."transient-id" = [PSCustomObject]@{
    Rule=@"
    @RuleName = "synthesize transient-id"
    c1:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
     && 
     c2:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationinstant"]
     => add(store = "_OpaqueIdStore", 
     types = ("http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"),
     query = "{0};{1};{2};{3};{4}", 
     param = "useEntropy", 
     param = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust![ReplaceWithSPNameQualifier]!" + c1.Value, 
     param = c1.OriginalIssuer, 
     param = "", 
     param = c2.Value);

    @RuleName = "issue transient-id"
    c:[Type == "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"]
     => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
     Value = c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/spnamequalifier"] = "[ReplaceWithSPNameQualifier]", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/namequalifier"] = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust");
"@
    Attribute=""
    AttributeGroup="ID's"
    }

   
   # eduPersonPrincipalName 
   # Calculated based off an ADFSTk configuration rule keyed to ADFSTkExtractSubjectUniqueId, default to the Claim 'upn'
   # 
   # Origin Claim will have only the left hand side being everything prior to the first @ sign
   # Rest of the string will be surpressed and then it is re-assembled with our SAML2 scope.
   #
   

    $TransformRules.eduPersonPrincipalName = [PSCustomObject]@{
    Rule=@"
    @RuleName = "compose eduPersonPrincipalName"
    c:[Type == "$(($Settings.configuration.storeConfig.transformRules.rule | ? name -eq "ADFSTkExtractSubjectUniqueId").originClaim )" ]
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.6", 
     Value = RegexReplace(c.Value, "@.*$", "") +"@$($Settings.configuration.StaticValues.schacHomeOrganization)", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    AttributeGroup="ID's"
    }

    $TransformRules.eduPersonTargetedID = [PSCustomObject]@{
    Rule=@"
    @RuleName = "compose eduPersonTargetedID"
    c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", 
    Value !~ "^.+\\"]
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.10", 
     Value = c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    AttributeGroup="ID's"
    }

    $TransformRules.eduPersonUniqueID = [PSCustomObject]@{
    Rule=@"
    @RuleName = "compose eduPersonUniqueID"
    c:[Type == "urn:mace:dir:attribute-def:norEduPersonLIN"] 
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.13", 
     Value = RegExReplace(c.Value, "-", "") + "@$($Settings.configuration.StaticValues.schacHomeOrganization)",
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="urn:mace:dir:attribute-def:norEduPersonLIN"
    AttributeGroup="ID's"
    }

 $TransformRules["LoginName"] = [PSCustomObject]@{
    Rule=@"

    @RuleName = "Transform LoginName"
    c:[Type == "http://schemas.xmlsoap.org/claims/samaccountname"]
     => issue(Type = "LOGINNAME", 
     Value = c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:assertion");
"@

    Attribute="http://schemas.xmlsoap.org/claims/samaccountname"
    AttributeGroup="ID's"
    }

    #endregion
    #region Personal attributes
    $TransformRules.givenName = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" `
                                                  -Oid "urn:oid:2.5.4.42" `
                                                  -AttributeName givenName `                                                  -AttributeGroup "Personal attributes"

    $TransformRules.sn = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" `
                                           -Oid "urn:oid:2.5.4.4" `
                                           -AttributeName sn `                                           -AttributeGroup "Personal attributes"

    $TransformRules.displayName = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/displayname" `
                                           -Oid "urn:oid:2.16.840.1.113730.3.1.241" `
                                           -AttributeName displayName `                                           -AttributeGroup "Personal attributes"
                                           
    $TransformRules.cn = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/claims/CommonName" `
                                           -Oid "urn:oid:2.5.4.3" `
                                           -AttributeName cn `                                           -AttributeGroup "Personal attributes"

    $TransformRules.mail = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
                                             -Oid "urn:oid:0.9.2342.19200300.100.1.3" `
                                             -AttributeName mail `                                             -AttributeGroup "Personal attributes"

    #endregion

 #region eduPerson Attributes

    $TransformRules.eduPersonScopedAffiliation = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonScopedAffiliation" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.9" `
                                                        -AttributeName eduPersonScopedAffiliation `                                                        -AttributeGroup "eduPerson attributes"

    $TransformRules.eduPersonAffiliation = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonAffiliation" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.1" `
                                                        -AttributeName eduPersonAffiliation `                                                        -AttributeGroup "eduPerson attributes"

    $TransformRules.norEduPersonNIN = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:norEduPersonNIN" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.2428.90.1.5" `
                                                        -AttributeName norEduPersonNIN `                                                        -AttributeGroup "eduPerson attributes"

    $TransformRules.eduPersonEntitlement = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonEntitlement" `
                                                             -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.7" `
                                                             -AttributeName eduPersonEntitlement `                                                             -AttributeGroup "eduPerson attributes"

    $TransformRules.eduPersonAssurance = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonAssurance" `
                                                           -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.11" `
                                                           -AttributeName eduPersonAssurance `                                                           -AttributeGroup "eduPerson attributes"

    $TransformRules.norEduPersonLIN = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:norEduPersonLIN" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.2428.90.1.4" `
                                                        -AttributeName norEduPersonLIN `                                                        -AttributeGroup "norEduPerson attributes"

    #endregion

    $TransformRules
}

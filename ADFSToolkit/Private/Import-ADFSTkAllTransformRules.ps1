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
#    $TransformRules."transient-id" = [PSCustomObject]@{
#    Rule=@"
#    @RuleName = "synthesize transient-id"
#    c1:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
#     && 
#     c2:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationinstant"]
#     => add(store = "_OpaqueIdStore", 
#     types = ("http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"),
#     query = "{0};{1};{2};{3};{4}", 
#     param = "useEntropy", 
#     param = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust![ReplaceWithSPNameQualifier]!" + c1.Value, 
#     param = c1.OriginalIssuer, 
#     param = "", 
#     param = c2.Value);
#
#    @RuleName = "issue transient-id"
#    c:[Type == "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"]
#     => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
#     Value = c.Value, 
#     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient", 
#     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/spnamequalifier"] = "[ReplaceWithSPNameQualifier]", 
#     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/namequalifier"] = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust");
#"@
#    Attribute=""
#    AttributeGroup="ID's"
#    }

#New way to release nameID
$TransformRules."transient-id" = [PSCustomObject]@{
    Rule=@"
    @RuleName = "synthesize transient-id"
    c1:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"] && 
    c2:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationinstant"]
    => add(
            store = "_OpaqueIdStore", 
            types = ("urn:adfstk:transientid"),
            query = "{0};{1};{2};{3};{4}", 
            param = "useEntropy", 
            param = c1.Value, 
            param = c1.OriginalIssuer, 
            param = "", 
            param = c2.Value);

    @RuleName = "issue transient-id"
    c:[Type == "urn:adfstk:transientid"]
    => issue(
            Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
            Value = c.Value, 
            Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient", 
            Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/spnamequalifier"] = "[ReplaceWithSPNameQualifier]", 
            Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/namequalifier"] = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust");
"@
    Attribute=""
    AttributeGroup="ID's"
    }

 $TransformRules."persistent-id" = [PSCustomObject]@{
    Rule=@"
    @RuleName = "synthesize persistent-id"
    c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
    => add(
            store = "_OpaqueIdStore", 
            types = ("urn:adfstk:persistentid"), 
            query = "{0};{1};{2}", 
            param = "ppid", 
            param = c.Value, 
            param = c.OriginalIssuer);

    @RuleName = "issue persistent-id"
    c:[Type == "urn:adfstk:persistentid"]
    => issue(
            Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
            Issuer = c.Issuer, 
            OriginalIssuer = c.OriginalIssuer, 
            Value = c.Value, 
            ValueType = c.ValueType, 
            Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent", 
            Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/spnamequalifier"] = "[ReplaceWithSPNameQualifier]", 
            Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/namequalifier"] = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)");
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
    c:[Type == "$(($Settings.configuration.transformRules.rule | ? name -eq "ADFSTkExtractSubjectUniqueId").originClaim )" ]
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.6", 
     Value = RegexReplace(c.Value, "@.*$", "") +"@$($Settings.configuration.StaticValues.schacHomeOrganization)", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    AttributeGroup="ID's"
    }

#     $TransformRules.eduPersonTargetedID = [PSCustomObject]@{
#     Rule=@"
#     @RuleName = "compose eduPersonTargetedID"
#     c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", 
#     Value !~ "^.+\\"]
#      => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.10", 
#      Value = c.Value, 
#      Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
# "@
#     Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
#     AttributeGroup="ID's"
#     }

    $TransformRules.eduPersonTargetedID = [PSCustomObject]@{
        Rule=@"
        @RuleName = "synthesize eduPersonTargetedID"
        c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
        => add(
                store = "_OpaqueIdStore", 
                types = ("urn:adfstk:edupersontargetedid"), 
                query = "{0};{1};{2}", 
                param = "ppid", 
                param = c.Value, 
                param = c.OriginalIssuer);
    
        @RuleName = "issue eduPersonTargetedID"
        c:[Type == "urn:adfstk:edupersontargetedid"]
        => issue(
                Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
                Issuer = c.Issuer, 
                OriginalIssuer = c.OriginalIssuer, 
                Value = c.Value, 
                ValueType = c.ValueType, 
                Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent", 
                Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/spnamequalifier"] = "[ReplaceWithSPNameQualifier]", 
                Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/namequalifier"] = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)");
"@
        Attribute=""
        AttributeGroup="ID's"
        }

    $TransformRules.eduPersonUniqueID = [PSCustomObject]@{
    Rule=@"
    @RuleName = "compose eduPersonUniqueID"
    c:[Type == "urn:mace:dir:attribute-def:eduPersonUniqueID"] 
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.13", 
     Value = RegExReplace(c.Value, "-", "") + "@$($Settings.configuration.StaticValues.schacHomeOrganization)",
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="urn:mace:dir:attribute-def:eduPersonUniqueID"
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
                                                  -AttributeName givenName `
                                                  -AttributeGroup "Personal attributes"

    $TransformRules.sn = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" `
                                           -Oid "urn:oid:2.5.4.4" `
                                           -AttributeName sn `
                                           -AttributeGroup "Personal attributes"

    $TransformRules.displayName = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/displayname" `
                                           -Oid "urn:oid:2.16.840.1.113730.3.1.241" `
                                           -AttributeName displayName `
                                           -AttributeGroup "Personal attributes"
                                           
    $TransformRules.cn = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/claims/CommonName" `
                                           -Oid "urn:oid:2.5.4.3" `
                                           -AttributeName cn `
                                           -AttributeGroup "Personal attributes"
    
#    $TransformRules.cn = [PSCustomObject]@{
#    Rule=@"
#
#    @RuleName = "Transform CommonName"
#    c1:[Type == "http://schemas.xmlsoap.org/claims/CommonName"] &&
#    c2:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"] &&
#    c3:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"] &&
#     => issue(Type = "urn:oid:2.5.4.3", 
#              Value = c2.Value + " " + c3.Value, 
#              Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
#"@
#
#    Attribute=@("givenName","sn")
#    AttributeGroup="Personal attributes"
#    }

    $TransformRules.mail = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
                                             -Oid "urn:oid:0.9.2342.19200300.100.1.3" `
                                             -AttributeName mail `
                                             -AttributeGroup "Personal attributes"

    $TransformRules.personalIdentityNumber = [PSCustomObject]@{
        Rule=@"

        @RuleName = "Transform personalIdentityNumber"
        c:[Type == "urn:mace:dir:attribute-def:personalIdentityNumber", value =~ "^(18|19|20)?[0-9]{2}((0[0-9])|(10|11|12))((([0-2][0-9])|(3[0-1]))|((6[1-9])|([7-8][0-9])|(9[0-1])))[0-9]{4}$"]
        => issue(Type = "urn:oid:1.2.752.29.4.13", Value = c.Value, 
                 Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@

        Attribute="urn:mace:dir:attribute-def:personalIdentityNumber"
        AttributeGroup="Personal attributes"
    }

#    $TransformRules.schacDateOfBirth = [PSCustomObject]@{
#        Rule=@'
#
#        @RuleName = "Transform schacDateOfBirth"
#        c:[Type == "urn:mace:dir:attribute-def:schacDateOfBirth", 
#           value =~ "^(18|19|20)?[0-9]{2}((0[0-9])|(10|11|12))((([0-2][0-9])|(3[0-1]))|((6[1-9])|([7-8][0-9])|(9[0-1])))[0-9]{4}$"]
#        => issue(Type = "urn:oid:1.3.6.1.4.1.25178.1.2.3", 
#                 Value = regexReplace (c.Value, "(?<start>^.{1,8}).+$", "${start}"), 
#                 Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
#'@
#
#        Attribute="urn:mace:dir:attribute-def:schacDateOfBirth"
#        AttributeGroup="Personal attributes"
#    }


    $TransformRules.schacDateOfBirth = [PSCustomObject]@{
        Rule=@'

        @RuleName = "Compose schacDateOfBirth start"
        c:[Type == "urn:mace:dir:attribute-def:schacDateOfBirth", Value =~ "^(18|19|20)?[0-9]{2}((0[0-9])|(10|11|12))((([0-2][0-9])|(3[0-1]))|((6[1-9])|([7-8][0-9])|(9[0-1])))[0-9]{4}$"]
         => add(Type = "urn:adfstk:schackdateofbirth:start", Value = regexReplace(c.Value, "(?<start>^.{6}).+$", "${start}"));
        
        @RuleName = "Compose schacDateOfBirth middle"
        c:[Type == "urn:mace:dir:attribute-def:schacDateOfBirth", Value =~ "^(18|19|20)?[0-9]{2}((0[0-9])|(10|11|12))((([0-2][0-9])|(3[0-1]))|((6[1-9])|([7-8][0-9])|(9[0-1])))[0-9]{4}$"]
         => add(Type = "urn:adfstk:schackdateofbirth:middle", Value = regexReplace(c.Value, "^.{6}(?<middle>\d{1}).+$", "${middle}"));
        
        @RuleName = "Compose schacDateOfBirth end"
        c:[Type == "urn:mace:dir:attribute-def:schacDateOfBirth", Value =~ "^(18|19|20)?[0-9]{2}((0[0-9])|(10|11|12))((([0-2][0-9])|(3[0-1]))|((6[1-9])|([7-8][0-9])|(9[0-1])))[0-9]{4}$"]
         => add(Type = "urn:adfstk:schackdateofbirth:end", Value = regexReplace(c.Value, "^.{7}(?<end>\d{1}).+$", "${end}"));
        
        @RuleName = "Transform schacDateOfBirth 6x->0x"
        c1:[Type == "urn:adfstk:schackdateofbirth:start"]
         && c2:[Type == "urn:adfstk:schackdateofbirth:middle", Value == "6"]
         && c3:[Type == "urn:adfstk:schackdateofbirth:end"]
         => issue(Type = "urn:oid:1.3.6.1.4.1.25178.1.2.3", Value = c1.Value + "0" + c3.Value, Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
        
        @RuleName = "Transform schacDateOfBirth 7x->1x"
        c1:[Type == "urn:adfstk:schackdateofbirth:start"]
         && c2:[Type == "urn:adfstk:schackdateofbirth:middle", Value == "7"]
         && c3:[Type == "urn:adfstk:schackdateofbirth:end"]
         => issue(Type = "urn:oid:1.3.6.1.4.1.25178.1.2.3", Value = c1.Value + "1" + c3.Value, Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
        
        @RuleName = "Transform schacDateOfBirth 8x->2x"
        c1:[Type == "urn:adfstk:schackdateofbirth:start"]
         && c2:[Type == "urn:adfstk:schackdateofbirth:middle", Value == "8"]
         && c3:[Type == "urn:adfstk:schackdateofbirth:end"]
         => issue(Type = "urn:oid:1.3.6.1.4.1.25178.1.2.3", Value = c1.Value + "2" + c3.Value, Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
        
        @RuleName = "Transform schacDateOfBirth 9x->3x"
        c1:[Type == "urn:adfstk:schackdateofbirth:start"]
         && c2:[Type == "urn:adfstk:schackdateofbirth:middle", Value == "9"]
         && c3:[Type == "urn:adfstk:schackdateofbirth:end"]
         => issue(Type = "urn:oid:1.3.6.1.4.1.25178.1.2.3", Value = c1.Value + "3" + c3.Value, Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
        
        @RuleName = "Transform schacDateOfBirth <=3x"
        c1:[Type == "urn:adfstk:schackdateofbirth:start"]
         && c2:[Type == "urn:adfstk:schackdateofbirth:middle", Value =~ "[0-3]"]
         && c3:[Type == "urn:adfstk:schackdateofbirth:end"]
         => issue(Type = "urn:oid:1.3.6.1.4.1.25178.1.2.3", Value = c1.Value + c2.Value + c3.Value, Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
        
'@

        Attribute="urn:mace:dir:attribute-def:schacDateOfBirth"
        AttributeGroup="Personal attributes"
    }

    #endregion

 #region eduPerson Attributes

    $TransformRules.eduPersonScopedAffiliation = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonScopedAffiliation" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.9" `
                                                        -AttributeName eduPersonScopedAffiliation `
                                                        -AttributeGroup "eduPerson attributes"

    $TransformRules.eduPersonAffiliation = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonAffiliation" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.1" `
                                                        -AttributeName eduPersonAffiliation `
                                                        -AttributeGroup "eduPerson attributes"

    $TransformRules.eduPersonPrimaryAffiliation = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonPrimaryAffiliation" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.5" `
                                                        -AttributeName eduPersonPrimaryAffiliation `
                                                        -AttributeGroup "eduPerson attributes"

    $TransformRules.norEduPersonLIN = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:norEduPersonLIN" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.2428.90.1.4" `
                                                        -AttributeName norEduPersonLIN `
                                                        -AttributeGroup "norEduPerson attributes"

    $TransformRules.norEduPersonNIN = [PSCustomObject]@{
        Rule=@"

        @RuleName = "Transform norEduPersonNIN"
        c:[Type == "urn:mace:dir:attribute-def:norEduPersonNIN", 
           value =~ "^(18|19|20)[0-9]{2}((0[1-9])|(10|11|12))(((0[1-9])|([1-2][0-9])|(3[0-1]))|((6[1-9])|([7-8][0-9])|(9[0-1])))(([PTRSUWXJKLMN]{1}[0-9]{3})|([0-9]{4}))$"]
        => issue(Type = "urn:oid:1.3.6.1.4.1.2428.90.1.5", 
                 Value = c.Value, 
                 Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@

        Attribute="urn:mace:dir:attribute-def:norEduPersonNIN"
        AttributeGroup="eduPerson attributes"
    }

    $TransformRules.eduPersonEntitlement = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonEntitlement" `
                                                             -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.7" `
                                                             -AttributeName eduPersonEntitlement `
                                                             -AttributeGroup "eduPerson attributes"

    $TransformRules.eduPersonAssurance = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonAssurance" `
                                                           -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.11" `
                                                           -AttributeName eduPersonAssurance `
                                                           -AttributeGroup "eduPerson attributes"

    $TransformRules.eduPersonOrcid = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonOrcid" `
                                                  -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.16" `
                                                  -AttributeName eduPersonOrcid `
                                                  -AttributeGroup "norEduPerson attributes"

    #endregion

    #region Load local institution transform rules if they exists
    if (Test-Path $Global:ADFSTkPaths.institutionLocalTransformRulesFile) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFoundFile)
        try {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFile)
            . $Global:ADFSTkPaths.institutionLocalTransformRulesFile
    
            if (Test-Path function:Get-ADFSTkLocalTransformRules) {
                $localTransformRules = Get-ADFSTkLocalTransformRules
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFound -f $localTransformRules.Count)
    
                foreach ($transformRule in $localTransformRules.Keys) {
                    #Add or replace the standard Entoty Category with the federation one
                    if ($TransformRules.ContainsKey($transformRule)) {
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesOverwrite -f $transformRule)
                    }
                    else {
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesAdd -f $transformRule)
                    }
    
                    $TransformRules.$transformRule = $localTransformRules.$transformRule
                }
            }
            else {
                Write-ADFSTkLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesLoadFail) -EntryType Error
            }
        }
        catch {
            Write-ADFSTkLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesLoadFail) -EntryType Error
        }
    }
    else {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText rulesFederationLocalTransformRulesFileNotFound)
    }
    #endregion


    $TransformRules
}

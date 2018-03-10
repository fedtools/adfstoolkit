

function get-ADFSTkManualSPSettings
{

    # This function contains all  specific overrides for attribute release for given entity
    #
    # Entities with Entity Category Designation like Research and Scholarship, are handled elsewhere.
    #
    # How this works
    #
    # For a given entity, we:
    #   create an empty TransformRules Hashtable
    #   assign specific transform rules that have a corelating TransformRules Object
    #   when complete, we insert the Ordered Hashtable transform into the Hashtable we return

    #  We can also get clever and inject a transform rule into the hashtable rather than reference an existing one
    # examples of this are included below


    # Hashtable that we will return at the end of the function
    $IssuanceTransformRuleManualSP = @{}

# uncomment an entity Rule to use it or copy and emulate it.

    ### Lynda.com attribute release
    
        # $TransformRules = [Ordered]@{}
        # $TransformRules.givenName = $AllTransformRules.givenName
        # $TransformRules.sn = $AllTransformRules.sn
        # $TransformRules.cn = $AllTransformRules.cn
        # $TransformRules.eduPersonPrincipalName = $AllTransformRules.eduPersonPrincipalName
        # $TransformRules.mail = $AllTransformRules.mail
        # $TransformRules.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation
        
        # $IssuanceTransformRuleManualSP["https://shib.lynda.com/shibboleth-sp"] = $TransformRules
        


    ### advanced ADFS Transform rule #1 'from AD'    

#         $TransformRules = [Ordered]@{}
#         $TransformRules."From AD" = @"
# c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", 
# Issuer == "AD AUTHORITY"]
#  => issue(store = "Active Directory", 
# types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn", 
# "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", 
# "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress", 
# "http://liu.se/claims/eduPersonScopedAffiliation", 
# "http://liu.se/claims/Department"), 
# query = ";userPrincipalName,displayName,mail,eduPersonScopedAffiliation,department;{0}", param = c.Value);
# "@
        
#         $IssuanceTransformRuleManualSP."advanced.entity.id.org" = $TransformRules

   

    ### advanced ADFS Transform rule #2 

#         $TransformRules = [Ordered]@{}
#         $TransformRules.mail = [PSCustomObject]@{
#     Rule=@"
#     @RuleName = "compose mail address as name@schacHomeOrganization"
#     c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name", Value !~ "^.+\\"]
#  => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", Value = c.Value + "@$($Settings.configuration.StaticValues.schacHomeOrganization)");
# "@
#     Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
#     }
        
#         $IssuanceTransformRuleManualSP["https://advanced.rule.two.org"] = $TransformRules
#    

    ### verify-i.myunidays.com

    #     $TransformRules = [Ordered]@{}
    #     $TransformRules["eduPersonScopedAffiliation"] = $AllTransformRules["eduPersonScopedAffiliation"]
    #     $TransformRules["eduPersonTargetedID"] = $AllTransformRules["eduPersonTargetedID"]
    #     $IssuanceTransformRuleManualSP["https://verify-i.myunidays.com/shibboleth"] = $TransformRules
    # ###

    ### Just transient-id

        # $TransformRules = [Ordered]@{}
        # $TransformRules.'transient-id' = $AllTransformRules.'transient-id'
                
        # $IssuanceTransformRuleManualSP["https://just-transientid.org"] = $TransformRules
    ###

    # this returns the hashtable of hashtables.
    
    $IssuanceTransformRuleManualSP
}

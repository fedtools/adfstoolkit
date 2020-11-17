function Get-ADFSTkLocalTransformRules
{
#Helper object, do not remove!
    $TransformRules = @{}

# This example will release upn as eduPersonPrincipalName without changing it.
# This is good if the institution has more than one scope for their users
<#
$TransformRules.eduPersonPrincipalName = [PSCustomObject]@{
    Rule=@"
    @RuleName = "compose eduPersonPrincipalName"
    c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn" ]
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.6", 
     Value = c.value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
    AttributeGroup="Local rules"
    } 
#>

    #Helper objects, do not remove!
    $TransformRules
}

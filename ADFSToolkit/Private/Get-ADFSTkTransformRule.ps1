function Get-ADFSTkTransformRule {
param (
    $Type,
    $Oid,
    $AttributeName,
    $AttributeGroup
    
)
    $currentAttribute = $Settings.configuration.storeConfig.attributes.attribute | ? type -eq $Type
    
    if ($currentAttribute.store -eq "Static")
    {
        $rule = ""
        $currentAttribute.value | % {
            $rule += @"

            @RuleName = "Send static $AttributeName = $_"
            c:[]
             => issue(Type = "$Oid", 
             Value = "$_", 
             Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
            }
        $transformRule = [PSCustomObject]@{
            Rule=$rule
            Attribute=""
            AttributeGroup=$AttributeGroup
        }
    }
    else
    {
         
        if ($currentAttribute -ne $null -and $currentAttribute.HasAttribute('useGroups') -and $currentAttribute.useGroups.ToLower() -eq 'true' -and $currentAttribute.HasAttribute('claimOrigin') ) 
        {
            $useAttributeGroup = $true
        }
        else
        {
            $useAttributeGroup = $false
        }

        if ($useAttributeGroup)
        {
            # Claim origin is not consistent or may want to be flexible here:
            # "http://schemas.xmlsoap.org/claims/Group" was the old one, but we want what the config says it is.
            $groupClaimOrigin=$currentAttribute.claimOrigin

            $rules = ""
            foreach ($group in $currentAttribute.group)
            {
                $rules += @"

                @RuleName = "Transform $AttributeName from group $($group.name)"
                c:[Type == "$($groupClaimOrigin)", value == "$($group.name)"]
                 => issue(Type = "$Oid", 
                 Value = "$($group.value)", 
                 Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
            }
            $transformRule = [PSCustomObject]@{
                Rule=$rules
                Attribute="$($groupClaimOrigin)"
                AttributeGroup=$AttributeGroup
            }
        }
        else
        {
            if ($currentAttribute.restrictedvalue.count -gt 0)
            {
                $rules = ""
                foreach ($restrictedvalue in $currentAttribute.restrictedvalue)
                {
                    $rules += @"

                    @RuleName = "Transform $($currentAttribute.name) = $restrictedvalue"
                    c:[Type == "$Type", value == "$restrictedvalue"] 
                    => issue(Type = "$Oid", Value = c.Value, 
                    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
                }
                $transformRule = [PSCustomObject]@{
                    Rule=$rules
                    Attribute="$Type"
                    AttributeGroup=$AttributeGroup
                }
            }
            else
            {
                $transformRule = [PSCustomObject]@{
                Rule=@"

                @RuleName = "Transform $AttributeName"
                c:[Type == "$Type"]
                 => issue(Type = "$Oid", 
                 Value = c.Value, 
                 Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
                Attribute="$Type"
                AttributeGroup=$AttributeGroup
            }
            }
        }
    }

    return $transformRule
}
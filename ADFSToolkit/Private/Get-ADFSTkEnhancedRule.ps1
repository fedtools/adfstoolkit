function Get-ADFSTkEnhancedRule {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        $Rule,
        [Parameter(Mandatory = $true, Position = 1)]
        $EntityId
    )

    $enhancedRule = $Rule.Rule.Replace("[ReplaceWithSPNameQualifier]", $EntityId)

    $currentAttribute = $Settings.configuration.attributes.attribute | ? type -eq $Rule.Attribute

    if (-not [string]::IsNullOrEmpty($currentAttribute) `
            -and -not [string]::IsNullOrEmpty($currentAttribute.transform)) {
            
            $prepend = ""
            $append = ""
            $replace = ""
            foreach ($transform in $currentAttribute.transform) {
                if ($transform.HasAttribute('prepend') `
                        -and -not [string]::IsNullOrEmpty($transform.prepend)) {
                    $prepend += $transform.prepend
                }
                if ($transform.HasAttribute('append') `
                        -and -not [string]::IsNullOrEmpty($transform.append)) {
                            $append += $transform.append
                }

                if ($transform.HasAttribute('replacetext') `
                        -and -not [string]::IsNullOrEmpty($transform.replacetext)) {
                    if ($transform.HasAttribute('replacewith')) {
                        if ([string]::IsNullOrEmpty($replace))
                        {
                            $replace =  "RegexReplace(c.Value, `"{0}`", `"{1}`")" -f $transform.replacetext, $transform.replacewith
                        }
                        else {
                            $replace = $replace.replace("c.Value", ("RegexReplace(c.Value, `"{0}`", `"{1}`")" -f $transform.replacetext, $transform.replacewith))
                        }
                    }
                    else {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText rulesReplaceWithAttributeIsMissing -f $currentAttribute.Type)
                    }
                }
            }
            if ([string]::IsNullOrEmpty($replace))
            {
                $replace = "c.Value"
            }
            $enhancedRule = $enhancedRule.replace("c.Value", ("`"{0}`" + $replace + `"{1}`"" -f $prepend,$append))
    }

    return $enhancedRule
}
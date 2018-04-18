function Get-ADFSTkTransformRuleObjects
{
    $allTransformRules = Import-ADFSTkAllTransformRules
    $transformRuleTypes = foreach ($transformRuleObject in $allTransformRules.Keys)
    {
        [PSCustomObject]@{
            name = $transformRuleObject
            attributeGroup = $allTransformRules.$transformRuleObject.AttributeGroup
        }
    }

    foreach ($type in ($transformRuleTypes | Sort attributeGroup | Group attributeGroup))
    {
        Write-Host $type.Name -ForegroundColor Yellow
        $type.Group.name | Sort | % {Write-host "  $_"}
    }
}
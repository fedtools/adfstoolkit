function Get-ADFSTkToolsIssuanceTransformRules {
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        $entityId,
        [switch]$SelectAttributes
    )

    $configFiles = Get-ADFSTkConfiguration -ConfigFilesOnly

    if ([string]::IsNullOrEmpty($configFiles)) {
        Write-ADFSTkHost confNoInstConfFiles -Style Attention
    }
    elseif ($configFiles -is [Object[]]) {
        $configFile = $configFiles | Out-GridView -Title (Get-ADFSTkLanguageText confSelectInstConfFileToHandle) -OutputMode Single
    }
    else {
        $configFile = $configFiles
    }

    [xml]$settings = Get-Content $configFile.ConfigFile
    
    $rpParams = @{}

    if ($PSBoundParameters.ContainsKey('SelectAttributes') -and $SelectAttributes -ne $false) {
        $AllAttributes = Import-ADFSTkAllAttributes
        $AllTransformRules = Import-ADFSTkAllTransformRules

        if (Test-Path $Global:ADFSTkPaths.institutionLocalTransformRulesFile) {
            try {
                . $Global:ADFSTkPaths.institutionLocalTransformRulesFile
        
                if (Test-Path function:Get-ADFSTkLocalTransformRules) {
                    $localTransformRules = Get-ADFSTkLocalTransformRules
        
                    foreach ($transformRule in $localTransformRules.Keys) {
                        $AllTransformRules.$transformRule = $localTransformRules.$transformRule
                    }
                }
            }
            catch {
            }
        }
        $Attributes = $AllTransformRules.Keys | `
            Select @{Label = "Attribute"; Expression = { $_ } },
        @{Label = "Example"; Expression = {
                if ($AllTransformRules.$_.AttributeGroup -eq 'Static attributes') {
                    $Settings.configuration.staticValues.$_
                }
            }
        } | Sort Attribute | `
            Out-GridView -Title "Select one or more attributes to build rules from" -OutputMode Multiple | `
            Select -ExpandProperty Attribute

        $Attributes | % {
            $TransformRules = [Ordered]@{}
        } {
            if ($AllTransformRules.ContainsKey($_)) {
                $TransformRules.$_ = $AllTransformRules.$_
            }
        }

        $IssuanceTransformRulesManualSP = @{}
        $IssuanceTransformRulesManualSP[$EntityId] = $TransformRules
        
        $AttributesFromStore = @{}
        $IssuanceTransformRules = [Ordered]@{}
        
        if ($EntityId -ne $null -and $IssuanceTransformRulesManualSP.ContainsKey($EntityId)) {
            foreach ($Rule in $IssuanceTransformRulesManualSP[$EntityId].Keys) { 
                if ($IssuanceTransformRulesManualSP[$EntityId][$Rule] -ne $null) {                
                    $IssuanceTransformRules[$Rule] = $IssuanceTransformRulesManualSP[$EntityId][$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]", $EntityId)
                    foreach ($Attribute in $IssuanceTransformRulesManualSP[$EntityId][$Rule].Attribute) { 
                        $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] 
                    }
                }
            }
        }

        $IssuanceTransformRuleObject = @{
            Stores   = $null
            MFARules = $null
            Rules    = $IssuanceTransformRules.Values
        }
        if ($AttributesFromStore.Count -ne $null) {
            $IssuanceTransformRuleObject.Stores = Get-ADFSTkStoreRule -Stores $Settings.configuration.storeConfig.stores.store `
                -AttributesFromStore $AttributesFromStore `
                -EntityId $EntityId 
        }
    }
    else {
        $MetadataCacheFile = (Join-Path $Global:ADFSTkPaths.cacheDir $settings.configuration.MetadataCacheFile)
        $metadataURL = $settings.configuration.metadataURL

        if ([string]::IsNullOrEmpty($Global:ADFSTkToolMetadata)) {
            $Global:ADFSTkToolMetadata = @{
                $MetadataCacheFile = Get-ADFSTkMetadata -CacheTime 60 -CachedMetadataFile $MetadataCacheFile -metadataURL $metadataURL
            }
        }
        elseif (!$Global:ADFSTkToolMetadata.ContainsKey($MetadataCacheFile)) {
            $Global:ADFSTkToolMetadata = @{
                $MetadataCacheFile = Get-ADFSTkMetadata -CacheTime 60 -CachedMetadataFile $MetadataCacheFile -metadataURL $metadataURL
            }
        }

        $sp = ($Global:ADFSTkToolMetadata.$MetadataCacheFile).EntitiesDescriptor.EntityDescriptor | ? { $_.entityId -eq $entityId }

        $EntityCategories = @()
        $EntityCategories += $sp.Extensions.EntityAttributes.Attribute | ? Name -eq "http://macedir.org/entity-category" | select -ExpandProperty AttributeValue | % {
            if ($_ -is [string]) {
                $_
            }
            elseif ($_ -is [System.Xml.XmlElement]) {
                $_."#text"
            }
        }

        # Filter Entity Categories that shouldn't be released together
        $filteredEntityCategories = @()
        $filteredEntityCategories += foreach ($entityCategory in $EntityCategories) {
            if ($entityCategory -eq 'https://refeds.org/category/personalized') {
                if (-not ($EntityCategories.Contains('https://refeds.org/category/pseudonymous') -or `
                            $EntityCategories.Contains('https://refeds.org/category/anonymous'))) {
                    $entityCategory
                }
            }
            elseif ($entityCategory -eq 'https://refeds.org/category/pseudonymous') {
                if (-not $EntityCategories.Contains('https://refeds.org/category/anonymous')) {
                    $entityCategory
                }
            }
            else {
                $entityCategory
            }
        }

        $EntityCategories = $filteredEntityCategories
    
        $subjectIDReq = $sp.Extensions.EntityAttributes.Attribute | ? Name -eq "urn:oasis:names:tc:SAML:profiles:subject-id:req" | Select -First 1 -ExpandProperty AttributeValue

        $IssuanceTransformRuleObject = Get-ADFSTkIssuanceTransformRules $EntityCategories -EntityId $entityID `
            -RequestedAttribute $sp.SPSSODescriptor.AttributeConsumingService.RequestedAttribute `
            -RegistrationAuthority $sp.Extensions.RegistrationInfo.registrationAuthority `
            -NameIdFormat $sp.SPSSODescriptor.NameIDFormat `
            -SubjectIDReq $subjectIDReq
    }

    $IssuanceTransformRuleObject.MFARules = Get-ADFSTkMFAConfiguration -EntityId $entityID

    if ([string]::IsNullOrEmpty($IssuanceTransformRuleObject.MFARules)) {
        $rpParams.IssuanceAuthorizationRules = Get-ADFSTkIssuanceAuthorizationRules -EntityId $entityID
        $rpParams.IssuanceTransformRules = $IssuanceTransformRuleObject.Stores + $IssuanceTransformRuleObject.Rules
    }
    else {
        $rpParams.AccessControlPolicyName = 'ADFSTk:Permit everyone and force MFA'
        $rpParams.IssuanceTransformRules = $IssuanceTransformRuleObject.Stores + $IssuanceTransformRuleObject.MFARules + $IssuanceTransformRuleObject.Rules
    }

    #region Custom Access Control Policy
    $CustomACPName = Get-ADFSTkCustomACPConfiguration -EntityId $entityID
    if (![string]::IsNullOrEmpty($CustomACPName))
    {
        $rpParams.AccessControlPolicyName = $CustomACPName
    }
    #endregion

    return $rpParams
}
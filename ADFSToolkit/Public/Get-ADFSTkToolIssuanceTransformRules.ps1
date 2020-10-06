function Get-ADFSTkToolsIssuanceTransformRules {
param (
    [Parameter(Mandatory=$true,
               Position=0)]
    $entityId,
    [switch]$SelectAttributes
)

    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    $configFiles = Get-ADFSTkConfiguration -ConfigFilesOnly

    if ([string]::IsNullOrEmpty($configFiles))
    {
        Write-ADFSTkHost confNoInstConfFiles -Style Attention
    }
    elseif ($configFiles -is [Object[]])
    {
        $configFile = $configFiles | Out-GridView -Title (Get-ADFSTkLanguageText confSelectInstConfFileToHandle) -OutputMode Single
    }
    else
    {
        $configFile = $configFiles
    }

    [xml]$settings = Get-Content $configFile.ConfigFile
    
    
    if ($PSBoundParameters.ContainsKey('SelectAttributes') -and $SelectAttributes -ne $false)
    {
        $AllAttributes = Import-ADFSTkAllAttributes
        $AllTransformRules = Import-ADFSTkAllTransformRules

        $Attributes = $AllTransformRules.Keys | `
                      Select @{Label = "Attribute";Expression={$_}},
                              @{Label = "Example";Expression={
                                  if ($AllTransformRules.$_.AttributeGroup -eq 'Static attributes')
                                      {
                                          $Settings.configuration.staticValues.$_
                                      }
                                  }
                              } | Sort Attribute | `
                                  Out-GridView -Title "Select one or more attributes to build rules from" -OutputMode Multiple | `
                                  Select -ExpandProperty Attribute

        $Attributes | % {
            $TransformRules = [Ordered]@{}
        }{
            if ($AllTransformRules.ContainsKey($_)){
                $TransformRules.$_ = $AllTransformRules.$_
            }
        }

        $IssuanceTransformRulesManualSP = @{}
        $IssuanceTransformRulesManualSP[$EntityId] = $TransformRules
        
        $AttributesFromStore = @{}
        $IssuanceTransformRules = [Ordered]@{}
        
        if ($EntityId -ne $null -and $IssuanceTransformRulesManualSP.ContainsKey($EntityId))
        {
            foreach ($Rule in $IssuanceTransformRulesManualSP[$EntityId].Keys) { 
                if ($IssuanceTransformRulesManualSP[$EntityId][$Rule] -ne $null)
                {                
                    $IssuanceTransformRules[$Rule] = $IssuanceTransformRulesManualSP[$EntityId][$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
                    foreach ($Attribute in $IssuanceTransformRulesManualSP[$EntityId][$Rule].Attribute) { 
                        $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] 
                    }
                }
            }
        }

        if ($AttributesFromStore.Count)
        {
            $FirstRule = Get-ADFSTkStoreRule -Stores $Settings.configuration.storeConfig.stores.store `
                                             -AttributesFromStore $AttributesFromStore `
                                             -EntityId $EntityId 

            return  $FirstRule + $IssuanceTransformRules.Values
        }
        else
        {
            return $IssuanceTransformRules.Values
        }
    }
    else
    {
        $MetadataCacheFile = (Join-Path $Global:ADFSTkPaths.cacheDir $settings.configuration.MetadataCacheFile)
        $metadataURL = $settings.configuration.metadataURL

        if ([string]::IsNullOrEmpty($Global:ADFSTkToolMetadata))
        {
            $Global:ADFSTkToolMetadata = @{
                $MetadataCacheFile = Get-ADFSTkMetadata -CacheTime 60 -CachedMetadataFile $MetadataCacheFile -metadataURL $metadataURL
            }
        }
        elseif(!$Global:ADFSTkToolMetadata.ContainsKey($MetadataCacheFile))
        {
            $Global:ADFSTkToolMetadata = @{
                $MetadataCacheFile = Get-ADFSTkMetadata -CacheTime 60 -CachedMetadataFile $MetadataCacheFile -metadataURL $metadataURL
            }
        }

        $sp = ($Global:ADFSTkToolMetadata.$MetadataCacheFile).EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $entityId}

        $EntityCategories = @()
            $EntityCategories += $sp.Extensions.EntityAttributes.Attribute | ? Name -eq "http://macedir.org/entity-category" | select -ExpandProperty AttributeValue | % {
                if ($_ -is [string])
                {
                    $_
                }
                elseif ($_ -is [System.Xml.XmlElement])
                {
                    $_."#text"
                }
            }
    
        Get-ADFSTkIssuanceTransformRules $EntityCategories -EntityId $entityID `
                                                           -RequestedAttribute $sp.SPSSODescriptor.AttributeConsumingService.RequestedAttribute `
                                                           -RegistrationAuthority $sp.Extensions.RegistrationInfo.registrationAuthority `
                                                           -NameIdFormat $sp.SPSSODescriptor.NameIDFormat
    }
}
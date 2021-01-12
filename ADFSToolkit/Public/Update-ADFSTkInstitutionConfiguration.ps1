function Update-ADFSTkInstitutionConfiguration 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        $ConfigurationFile
    )

    #This is ther version we can upgrade to
    $currentConfigVersion = '1.3'

    #Get All paths
    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    #Create main dirs
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainDir               -PathName "ADFSTk install directory" #C:\ADFSToolkit
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainConfigDir         -PathName "Main configuration" #C:\ADFSToolkit\config
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainBackupDir         -PathName "Main backup" #C:\ADFSToolkit\config\backup
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.cacheDir              -PathName "Cache directory" #C:\ADFSToolkit\cache
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.institutionDir        -PathName "Institution config directory" #C:\ADFSToolkit\config\institution
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.institutionBackupDir  -PathName "Institution backup directory" #C:\ADFSToolkit\config\institution\backup
    ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.federationDir         -PathName "Federation config directory" #C:\ADFSToolkit\config\federation   

    try {
        $mainConfiguration = Get-ADFSTkConfiguration
    }
    catch {
        #inform that we need a main config and that we will call that now
        Write-ADFSTkHost confNeedMainConfigurationMessage -Style Info
        $mainConfiguration = New-ADFSTkConfiguration -Passthru
    }
    
    $defaultConfigFile = $Global:ADFSTkPaths.defaultConfigFile

    $federationName = $mainConfiguration.FederationConfig.Federation.FederationName
    
    if (![string]::IsNullOrEmpty($federationName))
    {
        $defaultFederationConfigDir = Join-Path $Global:ADFSTkPaths.federationDir $federationName
        
        #Check if the federation dir exists and if not, create it
        ADFSTk-TestAndCreateDir -Path $defaultFederationConfigDir -PathName "$federationName config directory"

        #Check if we already have any Federation defaults file(s)
        $allDefaultFederationConfigFiles = Get-ChildItem -Path $defaultFederationConfigDir -Filter "*_defaultConfigFile.xml"
        
        if ([string]::IsNullOrEmpty($allDefaultFederationConfigFiles))
        {
            Write-ADFSTkHost -WriteLine -AddSpaceAfter
            Write-ADFSTkHost confCopyFederationDefaultFolderMessage -Style Info -AddSpaceAfter -f $defaultFederationConfigDir
        
            Read-Host (Get-ADFSTkLanguageText cPressEnterKey) | Out-Null

            $allDefaultFederationConfigFiles = Get-ChildItem -Path $defaultFederationConfigDir -Filter "*_defaultConfigFile.xml" -Recurse
        }
        
        if ($allDefaultFederationConfigFiles -eq $null)
        {
            $defaultFederationConfigFile = $null
        }
        elseif ($allDefaultFederationConfigFiles -is [System.IO.FileSystemInfo])
        {
            $defaultFederationConfigFile = $allDefaultFederationConfigFiles.FullName
        }
        elseif ($allDefaultFederationConfigFiles -is [System.Array])
        {
            $defaultFederationConfigFile = $allDefaultFederationConfigFiles | Out-GridView -Title (Get-ADFSTkLanguageText confSelectDefaultFedConfigFile) -OutputMode Single | Select -ExpandProperty Fullname
        }
        else
        {
            #We should never be here...
        }

        if ([string]::IsNullOrEmpty($defaultFederationConfigFile))
        {
            if (!(Get-ADFSTkAnswer (Get-ADFSTkLanguageText confFederationDefaultConfigNotFoundQuestion -f $federationName) -DefaultYes))
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confFederationDefaultConfigNotFound) -MajorFault
            }
        }
        else
        {
            try {
                [xml]$defaultFederationConfig = Get-Content $defaultFederationConfigFile

                if ($defaultFederationConfig.configuration.ConfigVersion -ne $currentConfigVersion)
                {
                    Write-ADFSTkHost confNotAValidVersionWarning -Style Attention
                }
            }
            catch {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confCouldNotOpenFederationDefaultConfig -f $defaultFederationConfig,$_) -MajorFault
            }
        }
    }

    #Try to open default config
    try {
        [xml]$defaultConfig = Get-Content $defaultConfigFile
    }
    catch {
        Write-ADFSTkLog (Get-ADFSTkLanguageText confCouldNotOpenDefaultConfig -f $defaultConfigFile,$_) -MajorFault
    }

#region Copy Local Transform Rule File
if (!(Test-path $Global:ADFSTkPaths.institutionLocalTransformRulesFile)) 
{
    Write-ADFSTkHost confLocalTransformRulesMessage -Style Info -AddLinesOverAndUnder -f $Global:ADFSTkPaths.institutionLocalTransformRulesFile
    Copy-item -Path $Global:ADFSTkPaths.defaultInstitutionLocalTransformRulesFile -Destination $Global:ADFSTkPaths.institutionLocalTransformRulesFile
}
#endregion

#region Select Institution config(s)
    
    $selectedConfigs = @()

    if ($PSBoundParameters.ContainsKey('ConfigurationFile'))
    {
        if (!(Test-Path $ConfigurationFile))
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText cFileDontExist -f $ConfigurationFile) -MajorFault
        }

        $ConfigurationFilePath = Get-ChildItem $ConfigurationFile

        #Check if it's an old file that neds to be copied to the institution dir
        if ($ConfigurationFilePath.Directory.FullName -ne $Global:ADFSTkPaths.institutionDir)
        {
            #Copy the configuration file to new location
            $newFileName = Join-Path $Global:ADFSTkPaths.institutionDir $ConfigurationFilePath.Name
            if (Test-Path $newFileName)
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confInstConfFileAlreadyUpgraded -f (Join-Path $ConfigurationFilePath.Directory $ConfigurationFilePath.name), $newFileName) -MajorFault
            }
            else
            {
                Copy-Item $ConfigurationFilePath.FullName $newFileName
            }
        }

        #Copy the ManualSP file to new location
        [xml]$selectedConfigSettings = Get-Content $ConfigurationFile
        $selectedConfigManualSP = $selectedConfigSettings.configuration.LocalRelyingPartyFile
        
        $oldManualSPFile = Join-Path $ConfigurationFilePath.Directory.FullName $selectedConfigManualSP
        $newManualSPFile = Join-Path $Global:ADFSTkPaths.institutionDir $selectedConfigManualSP

        if (Test-Path $oldManualSPFile)
        {
            if (Test-Path $newManualSPFile)
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confManualSPFileAlreadyExists -f $oldManualSPFile, $Global:ADFSTkPaths.institutionDir) -EntryType Warning
            }
            else
            {
                Copy-Item $oldManualSPFile $newManualSPFile
                Write-ADFSTkLog (Get-ADFSTkLanguageText confManualSPFileCopied -f $oldManualSPFile, $Global:ADFSTkPaths.institutionDir) -EntryType Information
            }
        }
        else {
            Write-ADFSTkHost confLocalManualSettingsMessage -Style Info -AddLinesOverAndUnder
            Copy-item -Path $Global:ADFSTkPaths.defaultInstitutionLocalSPFile -Destination $newManualSPFile
        }

        $selectedConfigs += Add-ADFSTkConfigurationItem -ConfigurationItem $newFileName -PassThru 
    }
    else
    {
        $allCurrentConfigs = Get-ADFSTkConfiguration -ConfigFilesOnly

        if ([string]::IsNullOrEmpty($allCurrentConfigs))
        {
            $currentConfigs = @()
            $currentConfigs += Get-ChildItem $Global:ADFSTkPaths.mainDir -Filter '*.xml' `
                                                         -Recurse | ? {$_.Directory.Name -notcontains 'cache' -and `
                                                                       $_.Directory.Name -notcontains 'federation' -and`
                                                                       $_.Name -ne 'config.ADFSTk.xml' -and -not`
                                                                       $_.Name.EndsWith('_defaultConfigFile.xml') -and `
                                                                       $_.Directory.Name -notcontains 'backup'} | `
                                                                    Select Directory, Name, LastWriteTime | `
                                                                    Sort Directory,Name
            
            if ($currentConfigs.Count -eq 0)
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confNoInstConfFiles) -MajorFault
            }

            #Add all selected federation config files to ADFSTk configuration
            $selectedConfigsTemp = $currentConfigs | Out-GridView -Title (Get-ADFSTkLanguageText confSelectInstConfFileToHandle) -PassThru

            foreach ($selectedConfig in $selectedConfigsTemp)
            {
                #Check if it's an old file that neds to be copied to the institution dir
                if ($selectedConfig.Directory -ne $Global:ADFSTkPaths.institutionDir)
                {
                    #Copy the configuration file to new location
                    $newFileName = Join-Path $Global:ADFSTkPaths.institutionDir $selectedConfig.Name
                    if (Test-Path $newFileName)
                    {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText confInstConfFileAlreadyUpgraded -f (Join-Path $selectedConfig.Directory $selectedConfig.name), $newFileName) -MajorFault
                    }
                    else
                    {
                        Copy-Item (Join-Path $selectedConfig.Directory $selectedConfig.name) $newFileName
                        $selectedConfig.Directory = $Global:ADFSTkPaths.institutionDir
                    }

                    #Copy the ManualSP file to new location
                    [xml]$selectedConfigSettings = Get-Content (Join-Path $selectedConfig.Directory $selectedConfig.name)
                    $selectedConfigManualSP = $selectedConfigSettings.configuration.LocalRelyingPartyFile
                    
                    $oldManualSPFile = Join-Path $selectedConfig.Directory $selectedConfigManualSP
                    $newManualSPFile = Join-Path $Global:ADFSTkPaths.institutionDir $selectedConfigManualSP

                    if (Test-Path $oldManualSPFile)
                    {
                        if (Test-Path $newManualSPFile)
                        {
                            Write-ADFSTkLog (Get-ADFSTkLanguageText confManualSPFileAlreadyExists -f $oldManualSPFile, $Global:ADFSTkPaths.institutionDir) -EntryType Warning
                        }
                        else
                        {
                            Copy-Item $oldManualSPFile $newManualSPFile
                            Write-ADFSTkLog (Get-ADFSTkLanguageText confManualSPFileCopied -f $oldManualSPFile, $Global:ADFSTkPaths.institutionDir) -EntryType Information
                        }
                    }
                }

                $selectedConfigs += Add-ADFSTkConfigurationItem -ConfigurationItem (Join-Path $selectedConfig.Directory $selectedConfig.Name) -PassThru
            }
        }
        else
        {
            $selectedConfigs += $allCurrentConfigs | Out-GridView -Title (Get-ADFSTkLanguageText confSelectInstConfFileToHandle) -PassThru
        }
    }

    if ($selectedConfigs.Count -eq 0)
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText confNoInstConfigFileSelectedborting) -MajorFault
    }

#endregion

#region Handle each institution config file
    foreach ($configFile in $selectedConfigs)
    {
        Write-ADFSTkHost confProcessingInstConfig -f $configFile.configFile -AddLinesOverAndUnder -Style Info
        
        $continue = $true
        try 
        {
            [xml]$config = Get-Content $configFile.ConfigFile
        }
        catch
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText confCouldNotOpenInstConfigFile -f $_) -EntryType Error
            $continue = $false
        }

        if ($continue)
        {

            if ([string]::IsNullOrEmpty($config.configuration.ConfigVersion))
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confCouldNotRetrieveVersion) -EntryType Error
            }
            elseif ($config.configuration.ConfigVersion -eq $currentConfigVersion)
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confInstConfAlreadyCorrectVersion -f $currentConfigVersion) -EntryType Information
            }
            else
            {
                $oldConfigVersion = $config.configuration.ConfigVersion
                $configFileObject = Get-ChildItem $configFile.configFile

                #Check if the config is enabled and disable it if so
                if ($configFile.Enabled)
                {
                    Write-ADFSTkHost confInstitutionConfigEnabledWarning -Style Attention
                    Set-ADFSTkInstitutionConfiguration -ConfigurationItem $configFile.configFile -Status Disabled
                }

                #First take a backup of the current file
                if (!(Test-Path $Global:ADFSTkPaths.institutionBackupDir))
                {
                    Write-ADFSTkVerboseLog -Message (Get-ADFSTkLanguageText cFileDontExist -f $Global:ADFSTkPaths.institutionBackupDir)

                    New-Item -ItemType Directory -Path $Global:ADFSTkPaths.institutionBackupDir | Out-Null
                
                    Write-ADFSTkVerboseLog -Message (Get-ADFSTkLanguageText cCreated)
                }
                
                $backupFilename = "{0}_backup_v{3}_{1}{2}" -f $configFileObject.BaseName, (Get-Date).tostring("yyyyMMdd_HHmmss"), $configFile.Extension, $config.configuration.ConfigVersion
                $backupFile = Join-Path $Global:ADFSTkPaths.institutionBackupDir $backupFilename
                Copy-Item -Path $configFile.configFile -Destination $backupFile | Out-Null

                Write-ADFSTkLog (Get-ADFSTkLanguageText confOldConfBackedUpTo -f $backupFile) -ForegroundColor Green

                ###Now lets upgrade in steps!###
                
                $RemoveCache = $false

                #v0.9 --> v1.0
                $currentVersion = '0.9'
                $newVersion     = '1.0'
                if ($config.configuration.ConfigVersion -eq $currentVersion)
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText confUpdatingInstConfigFromTo -f $currentVersion, $newVersion)
                    
                    if ($config.configuration.LocalRelyingPartyFile -eq $null)
                    {
                        Add-ADFSTkXML -XPathParentNode "configuration" -NodeName "LocalRelyingPartyFile" -RefNodeName "MetadataCacheFile"
                    }
                   
                    Update-ADFSTkXML -XPath "configuration/LocalRelyingPartyFile" -ExampleValue 'get-ADFSTkLocalManualSPSettings.ps1'

                    $config.configuration.ConfigVersion = $newVersion
                    $config.Save($configFile.configFile);
                 
                }
                #v1.0 --> v1.1
                $currentVersion = '1.0'
                $newVersion     = '1.1'
                if ($config.configuration.ConfigVersion -eq $currentVersion)
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText confUpdatingInstConfigFromTo -f $currentVersion, $newVersion)
                    
                    if ($config.configuration.eduPersonPrincipalNameRessignable -eq $null)
                    {
                        Add-ADFSTkXML -XPathParentNode "configuration" -NodeName "eduPersonPrincipalNameRessignable" -RefNodeName "MetadataPrefixSeparator"
                    }
                   
                    Update-ADFSTkXML -XPath "configuration/eduPersonPrincipalNameRessignable" -ExampleValue 'true/false'

                    $config.configuration.ConfigVersion = $newVersion
                    $config.Save($configFile.configFile);

                    if ($RemoveCache -eq $false)
                    {
                        $RemoveCache = $true
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText confCacheNeedsToBeRemoved)
                    }
                }

                #v1.1 --> v1.2
                $currentVersion = '1.1'
                $newVersion     = '1.2'
                if ($config.configuration.ConfigVersion -eq $currentVersion)
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText confUpdatingInstConfigFromTo -f $currentVersion, $newVersion)
                    
                    Remove-ADFSTkXML -XPath 'configuration/WorkingPath'
                    Remove-ADFSTkXML -XPath 'configuration/ConfigDir'
                    Remove-ADFSTkXML -XPath 'configuration/CacheDir'

                    foreach ($store in $config.configuration.storeConfig.stores.store)
                    {
                        if ([string]::IsNullOrEmpty($store.storetype))
                        {
                            $store.SetAttribute('storetype', $store.name)

                            'issuer', 'type', 'order' | % {
                                $attributeValue = $store.$_
                                if (![string]::IsNullOrEmpty($attributeValue))
                                {
                                    $store.RemoveAttribute($_)
                                    $store.SetAttribute($_,$attributeValue)
                                }
                            }
                        }
                    }

                    $config.configuration.ConfigVersion = $newVersion
                    $config.Save($configFile.configFile);
                }

                #v1.2 --> v1.3
                $currentVersion = '1.2'
                $newVersion     = '1.3'
                if ($config.configuration.ConfigVersion -eq $currentVersion)
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText confUpdatingInstConfigFromTo -f $currentVersion, $newVersion)

                    if (![string]::IsNullOrEmpty($config.configuration.storeConfig.transformRules))
                    {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText confMoveNodeFromStoreConfigToConfig -f 'transformRules')
                        $config.configuration.AppendChild($config.configuration.storeConfig.transformRules) | Out-Null
                    }

                    if (![string]::IsNullOrEmpty($config.configuration.storeConfig.attributes))
                    {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText confMoveNodeFromStoreConfigToConfig -f 'attributes')
                        $config.configuration.AppendChild($config.configuration.storeConfig.attributes) | Out-Null
                    }



                    $config.configuration.ConfigVersion = $newVersion
                    $config.Save($configFile.configFile);
                }

                Write-ADFSTkLog (Get-ADFSTkLanguageText confUpdatedInstConfigDone -f $configFile.configFile, $oldConfigVersion, $currentConfigVersion) -EntryType Information
            }
        }
    }

    Write-ADFSTkLog (Get-ADFSTkLanguageText confUpdatedInstConfigAllDone) -EntryType Information
    if ($RemoveCache)
    {
        Write-ADFSTkHost confDeleteCacheWarning -Style Attention
        if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText confDeleteCacheQuestion) -DefaultYes)
        {
            Get-ChildItem $Global:ADFSTkPaths.cacheDir | Remove-Item -Confirm:$false
        }
    }
#endregion
}
#endregion


function Add-ADFSTkXML {
param (
    $NodeName,
    $XPathParentNode,
    $RefNodeName,
    $Value = [string]::Empty
)

    $configurationNode = Select-Xml -Xml $config -XPath $XPathParentNode
    $configurationNodeChild = $config.CreateNode("element",$NodeName,$null)
    $configurationNodeChild.InnerText = $Value

    #$configurationNode.Node.AppendChild($configurationNodeChild) | Out-Null
    $refNode = Select-Xml -Xml $config -XPath "$XPathParentNode/$RefNodeName"
    $configurationNode.Node.InsertAfter($configurationNodeChild, $refNode.Node) | Out-Null

}

function Update-ADFSTkXML {
param (
    $XPath,
    $ExampleValue
)

    $params = @{
        XPath = $XPath
        ExampleValue = $ExampleValue 
        NewConfig = $config
    }
    
    $defaultFederationConfigNode = $null

    if (![string]::IsNullOrEmpty($defaultFederationConfig))
    {
        $defaultFederationConfigNode = Select-Xml -Xml $defaultFederationConfig -XPath $XPath
    }

    if ([string]::IsNullOrEmpty($defaultFederationConfigNode))
    {
        $params.DefaultConfig = $defaultConfig
    }
    else
    {
        $params.DefaultConfig = $defaultFederationConfig
    }

    Set-ADFSTkConfigItem @params
}

function Remove-ADFSTkXML {
param (
    $XPath
)

    $node = $config.SelectSingleNode($XPath)
    if (![string]::IsNullOrEmpty($node))
    {
        $node.ParentNode.RemoveChild($node) | Out-Null
    }
}
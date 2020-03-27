function Update-ADFSTkInstitutionConfiguration 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        $ConfigurationFile
    )

    #This is ther version we can upgrade to
    $currentConfigVersion = '1.2'

    #Get All paths
    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    try {
        $mainConfiguration = Get-ADFSTkConfiguration
    }
    catch {
        #inform that we need a main config and that we will call that now
        Write-ADFSTkHost confNeedMainConfigurationMessage -Style Info
        $mainConfiguration = New-ADFSTkConfiguration
    }
    
    $defaultConfigFile = $Global:ADFSTkPaths.defaultConfigFile

    $federationName = $mainConfiguration.FederationConfig.Federation.FederationName
    
    if (![string]::IsNullOrEmpty($federationName))
    {
        Write-ADFSTkHost -WriteLine -AddSpaceAfter
        Write-ADFSTkHost confCopyFederationDefaultFolderMessage -Style Info -AddSpaceAfter -f $Global:ADFSTkPaths.federationDir
        
    
        if (Test-Path variable:global:psISE)
        {
            Read-Host (Get-ADFSTkLanguageText cPressEnterKey) | Out-Null
        }
        else
        {
            Write-ADFSTkHost cPressAnyKey -Style Attention            
            [System.Console]::ReadKey() | Out-Null
        }

        $defaultFederationConfigDir = Join-Path $Global:ADFSTkPaths.federationDir $federationName
        $allDefaultFederationConfigFiles = Get-ChildItem -Path $defaultFederationConfigDir -Filter "*_defaultConfigFile.xml" -Recurse
        
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
            $defaultFederationConfigFile = $allDefaultFederationConfigFiles | Out-GridView -Title (Get-ADFSTkLanguageText confSelectDefaultFedConfigFile) -OutputMode Single
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
    }

    #Try to open default config
    try {
        [xml]$defaultConfig = Get-Content $defaultConfigFile
    }
    catch {
        Write-ADFSTkLog (Get-ADFSTkLanguageText confCouldNotOpenDefaultConfig -f $defaultConfigFile,$_) -MajorFault
    }

    #Try to open federation config (if any)
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

#region Select Institution config(s)
    
    $selectedConfigs = @()

    if ($PSBoundParameters.ContainsKey('ConfigurationFile'))
    {
        if (!(Test-Path $ConfigurationFile))
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText cFileDontExist -f $ConfigurationFile) -MajorFault
        }

        $selectedConfigs += Add-ADFSTkConfigurationItem -ConfigurationItem $ConfigurationFile -PassThru 
    }
    else
    {
        $allCurrentConfigs = Get-ADFSTkConfiguration -ConfigFilesOnly

        if ([string]::IsNullOrEmpty($allCurrentConfigs))
        {
            $currentConfigs = @()
            $currentConfigs += Get-ChildItem $Global:ADFSTkPaths.mainDir -Filter '*.xml' `
                                                         -Recurse | ? {$_.Directory.Name -notcontains 'cache' -and `
                                                                       $_.Directory.Name -notcontains 'federation' -and `
                                                                       $_.Directory.Name -notcontains 'backup'} | `
                                                                    Select Directory, Name, LastWriteTime | `
                                                                    Sort Directory,Name
            
            if ($currentConfigs -lt 1)
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confNoInstConfFiles) -MajorFault
            }

            #Add all selected federation config files to ADFSTk configuration
            $selectedConfigs += $currentConfigs | Out-GridView -Title (Get-ADFSTkLanguageText confSelectInstConfFileToHandle) -PassThru | % {
                Add-ADFSTkConfigurationItem -ConfigurationItem (Join-Path $_.Directory $_.Name) -PassThru
            }
        }
        else
        {
            $selectedConfigs += $allCurrentConfigs | Out-GridView -Title (Get-ADFSTkLanguageText confSelectInstConfFileToHandle) -PassThru
        }
    }

    if ($selectedConfigs.Count -lt 1)
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

                    $RemoveCache = $true
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

                    #$RemoveCache = $true
                    
                    $config.configuration.ConfigVersion = $newVersion
                    $config.Save($configFile.configFile);
                }

                Write-ADFSTkLog (Get-ADFSTkLanguageText confUpdatedInstConfigDone -f $configFile.configFile, $oldConfigVersion, $currentConfigVersion) -EntryType Information

            }
        }
    }

    Write-ADFSTkLog (Get-ADFSTkLanguageText confUpdatedInstConfigAllDone) -EntryType Information

    #if ($RemoveCache -and Get-ADFSTkAnswer "We recommend you start over without cache OK?")
    #{

    #}
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
                    
    $defaultFederationConfigNode = Select-Xml -Xml $defaultFederationConfig -XPath $XPath

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
   $node.ParentNode.RemoveChild($node) | Out-Null
}
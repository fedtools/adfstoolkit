#Requires -Version 5.1

function New-ADFSTkInstitutionConfiguration {
[cmdletbinding()]
    Param (
    )


    #Get All paths
    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    #$ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1
    
    if (!(Test-Path "Function:\Write-ADFSTkLog"))
    {
        . (Join-Path $Global:ADFSTkPaths.modulePath 'Private\Write-ADFSTkLog.ps1')
    }

    if (!(Test-Path "Function:\Get-ADFSTkAnswer"))
    {
        . (Join-Path $Global:ADFSTkPaths.modulePath 'Private\Get-ADFSTkAnswer.ps1')
    }

    if (!(Test-Path "Function:\Compare-ADFSTkObject"))
    {
        . (Join-Path $Global:ADFSTkPaths.modulePath 'Private\Compare-ADFSTkObject.ps1')
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
        Write-ADFSTkHost -WriteLine -AddSpaceAfter
        Write-ADFSTkHost confNeedMainConfigurationMessage -Style Info -AddSpaceAfter
        $mainConfiguration = New-ADFSTkConfiguration -Passthru
    }

    Write-ADFSTkHost confCreateNewConfigurationFile -Style Info -AddLinesOverAndUnder

    # Detect and prep previousConfig to source values for defaults from it
    #[xml]$previousConfig = ""
    #
    #
    #if ([string]::IsNullOrEmpty($MigrationConfig))
    #{
    #    Write-Verbose (Get-ADFSTkLanguageText confNoPreviousFile)
    #}
    #else
    #{
    #    if (Test-Path -Path $MigrationConfig)
    #    {
    #        $previousConfig = Get-Content $MigrationConfig
    #        Write-ADFSTkHost confUsingPreviousFileForDefaulValues -f $MigrationConfig -ForegroundColor Red -AddSpaceAfter
    #    }
    #    else 
    #    {
    #        Throw (Get-ADFSTkLanguageText confPreviousFileNotExist -f $MigrationConfig)
    #    }
    #}
 
    # Use a default template from to start with
    #$mainConfiguration.FederationConfig.Federation

    $federationName = $mainConfiguration.FederationConfig.Federation.FederationName
    if ([string]::IsNullOrEmpty($federationName))
    {
        $defaultConfigFile = $Global:ADFSTkPaths.defaultConfigFile
        #[xml]$config = Get-Content $Global:ADFSTkPaths.defaultConfigFile
    }
    else
    {
        Write-ADFSTkHost confCopyFederationDefaultFolderMessage -Style Info -AddSpaceAfter -f $Global:ADFSTkPaths.federationDir
        Read-Host (Get-ADFSTkLanguageText cPressEnterKey) | Out-Null

        $defaultFederationConfigDir = Join-Path $Global:ADFSTkPaths.federationDir $federationName
        $defaultFederationConfigFiles = Get-ChildItem -Path $defaultFederationConfigDir -Filter "*_defaultConfigFile.xml"
        
        if ($defaultFederationConfigFiles -eq $null)
        {
            $defaultConfigFile = $null
        }
        elseif ($defaultFederationConfigFiles -is [System.IO.FileSystemInfo])
        {
            $defaultConfigFile = $defaultFederationConfigFiles.FullName
            #[xml]$config = Get-Content $defaultFederationConfigFiles.FullName
        }
        elseif ($defaultFederationConfigFiles -is [System.Array])
        {
            $defaultConfigFile = $defaultFederationConfigFiles | Out-GridView -Title "Select the default federation configuration file you want to use" -OutputMode Single | Select -ExpandProperty FullName
        }
        else
        {
            #We should never be here...
        }

        if ([string]::IsNullOrEmpty($defaultConfigFile))
        {
            if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText confFederationDefaultConfigNotFoundQuestion -f $federationName) -DefaultYes)
            {
                $defaultConfigFile = $Global:ADFSTkPaths.defaultConfigFile
                #[xml]$config = Get-Content $Global:ADFSTkPaths.defaultConfigFile
            }
            else
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText confFederationDefaultConfigNotFound) -MajorFault
            }
        }

    }

    try {
        [xml]$defaultConfig = Get-Content $defaultConfigFile

        if ($defaultConfig.configuration.ConfigVersion -ne '1.2')
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText confDefaultConfigIncorrectVersion -f $defaultConfigFile,$config.configuration.ConfigVersion,'1.2') -MajorFault
        }
    }
    catch {
        Write-ADFSTkLog (Get-ADFSTkLanguageText confCouldNotOpenFederationDefaultConfig -f $defaultConfigFile,$_) -MajorFault
    }

    [xml]$newConfig = $defaultConfig.Clone()


    Write-ADFSTkHost confStartMessage -Style Info -AddSpaceAfter
    Write-ADFSTkHost -WriteLine
    
    
       
    #Just set the value...
    #(Select-Xml -Xml $config -XPath "configuration/Federation").Node.'#text' = $chosenFed
    
    #Set-ADFSTkConfigItem -XPath "configuration/metadataURL" `
    #                     -ExampleValue 'https://metadata.federationOperator.org/path/to/metadata.xml' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #                   
    #Set-ADFSTkConfigItem -XPath "configuration/signCertFingerprint" `
    #                     -ExampleValue '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #
    #Set-ADFSTkConfigItem -XPath "configuration/MetadataPrefix" `
    #                     -ExampleValue 'ADFSTk/SWAMID/CANARIE/INCOMMON' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #              
    #Set-ADFSTkConfigItem -XPath "configuration/staticValues/o" `
    #                     -ExampleValue 'ABC University' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #
    #Set-ADFSTkConfigItem -XPath "configuration/staticValues/co" `
    #                     -ExampleValue 'Canada, Sweden' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #
    #Set-ADFSTkConfigItem -XPath "configuration/staticValues/c" `
    #                     -ExampleValue 'CA, SE' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #
    #Set-ADFSTkConfigItem -XPath "configuration/staticValues/schacHomeOrganization" `
    #                     -ExampleValue 'institution.edu' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #
    #Set-ADFSTkConfigItem -XPath "configuration/staticValues/norEduOrgAcronym" `
    #                     -ExampleValue 'CA' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #
    #Set-ADFSTkConfigItem -XPath "configuration/staticValues/ADFSExternalDNS" `
    #                     -ExampleValue 'adfs.institution.edu' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig
    #
    #Set-ADFSTkConfigItem -XPath "configuration/eduPersonPrincipalNameRessignable" `
    #                     -ExampleValue 'false' `
    #                     -Config $config `
    #                     -DefaultConfig $previousConfig

    Set-ADFSTkConfigItem -XPath "configuration/metadataURL" `
                         -ExampleValue 'https://metadata.federationOperator.org/path/to/metadata.xml' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig
                       
    Set-ADFSTkConfigItem -XPath "configuration/signCertFingerprint" `
                         -ExampleValue '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    Set-ADFSTkConfigItem -XPath "configuration/MetadataPrefix" `
                         -ExampleValue 'ADFSTk/CANARIE/INCOMMON/SWAMID' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig
                  
    Set-ADFSTkConfigItem -XPath "configuration/staticValues/o" `
                         -ExampleValue 'University Of Example' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/co" `
                         -ExampleValue 'Canada, Sweden, USA' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/c" `
                         -ExampleValue 'CA, SE, US' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/schacHomeOrganization" `
                         -ExampleValue 'universityofexample.edu' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/norEduOrgAcronym" `
                         -ExampleValue 'UoE' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/ADFSExternalDNS" `
                         -ExampleValue 'adfs.universityofexample.edu' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    Set-ADFSTkConfigItem -XPath "configuration/eduPersonPrincipalNameRessignable" `
                         -ExampleValue 'false' `
                         -DefaultConfig $defaultConfig `
                         -NewConfig $newConfig

    
    #Adding eduPersonScopedAffiliation based on eduPersonAffiliation added with @schackHomeOrganization
    $epa = $newConfig.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonAffiliation" 
    $epsa = $newConfig.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonScopedAffiliation"
    

    $epa.ChildNodes | % {
        $node = $_.Clone()    
        $node.InnerText += "@$($newConfig.configuration.staticValues.schacHomeOrganization)"

        $epsa.AppendChild($node) | Out-Null
    }

    # various useful items for minting our configuration 

    # user entered
    $myPrefix = (Select-Xml -Xml $newConfig -XPath "configuration/MetadataPrefix").Node.InnerText

    # For the ADFSTk functionality, we desire to associate certain cache files to certain things and bake a certain default location
 
    #(Select-Xml -Xml $config -XPath "configuration/WorkingPath").Node.'#text' = "$myADFSTkInstallDir" #Do we really need this?
    (Select-Xml -Xml $newConfig -XPath "configuration/SPHashFile").Node.InnerText = "$myPrefix-SPHashfile.xml"
    (Select-Xml -Xml $newConfig -XPath "configuration/MetadataCacheFile").Node.InnerText = "$myPrefix-metadata.cached.xml"

    $newConfigFile = Join-Path $Global:ADFSTkPaths.institutionDir "config.$myPrefix.xml"

    if (Test-path $newConfigFile)
    {
        #Should we recommend to do an upgrade instead?
        if (Get-ADFSTkAnswer -Caption (Get-ADFSTkLanguageText confConfigurationAlreadyExistsCaption) `
                             -Message (Get-ADFSTkLanguageText confOverwriteConfiguration) `
                             -DefaultYes)
        {
            $newConfigFileObject = Get-ChildItem $newConfigFile
            $myConfigFileBkpName = Join-Path $Global:ADFSTkPaths.institutionBackupDir ("{0}.{1}{2}" -f $newConfigFileObject.BaseName, (get-date -Format o).Replace(':','.'), $newConfigFileObject.Extension)

            Write-ADFSTkHost confCreatingNewConfigHere -f $newConfigFile -Style Value
            Write-ADFSTkHost confOldConfigurationFile -f $myConfigFileBkpName -Style Value

            Move-Item -Path $newConfigFile -Destination $myConfigFileBkpName

            $newConfig.Save($newConfigFile)
        } 
        else 
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText confDontOverwriteFileExit) -MajorFault
        }
    }
    else
    {
        Write-ADFSTkHost confInstConfigCreated -f $newConfigFile -Style Value
        $newConfig.Save($newConfigFile)
    }


    
    #Add $configFile to Main Config File

    Write-ADFSTkHost confAddFileToMainConfigMessage -Style Info -AddLinesOverAndUnder

    Add-ADFSTkConfigurationItem -ConfigurationItem $newConfigFile

    Write-ADFSTkHost -WriteLine -AddSpaceAfter

    Write-ADFSTkHost confConfigurationFileSavedHere -f $newConfigFile -Style Value
    
#region get-ADFSTkLocalManualSpSettings.ps1

    Write-ADFSTkHost confLocalManualSettingsMessage -Style Info -AddLinesOverAndUnder

    # Prepare our template for ADFSTkManualSPSettings to be copied into place, safely of course, after directories are confirmed to be there.

    #$myADFSTkManualSpSettingsDistroTemplateFile =  Join-Path $Global:ADFSTkPaths.modulePath     -ChildPath "config\default\en-US\get-ADFSTkLocalManualSpSettings-dist.ps1"
    $myADFSTkManualSpSettingsInstallTemplateFile = Join-Path $Global:ADFSTkPaths.institutionDir -ChildPath "get-ADFSTkLocalManualSpSettings.ps1"

    if (Test-path $myADFSTkManualSpSettingsInstallTemplateFile ) 
    {
        if (Get-ADFSTkAnswer -Caption (Get-ADFSTkLanguageText confInstLocalSPFileExistsCaption) `
                             -Message (Get-ADFSTkLanguageText confOverwriteInstLocalSPFileMessage -f $myADFSTkManualSpSettingsInstallTemplateFile))
        {
            Write-ADFSTkHost confOverwriteInstLocalSPFileConfirmed -f $myADFSTkManualSpSettingsInstallTemplateFile -Style Value

            $mySPFileBkpName = "$myADFSTkManualSpSettingsInstallTemplateFile.$myConfigFileBkpExt"

            Write-ADFSTkHost confCreateNewInstLocalSPFile -f $Global:ADFSTkPaths.defaultInstitutionLocalSPFile -Style Value
            Write-ADFSTkHost confOldInstLocalSPFile -f $mySPFileBkpName -Style Value

            # Make backup
            Move-Item -Path $myADFSTkManualSpSettingsInstallTemplateFile -Destination $mySPFileBkpName

            Copy-item -Path $Global:ADFSTkPaths.defaultInstitutionLocalSPFile -Destination $myADFSTkManualSpSettingsInstallTemplateFile


            # Detect and strip signature from file we ship
            #$myFileContent = Get-Content $Global:ADFSTkPaths.defaultInstitutionLocalSPFile
            #$mySigLine = ($myFileContent | Select-String "SIG # Begin signature block").LineNumber
            #$sigOffset = 2
            #$mySigLocation = $mySigLine-$sigOffset
            #
            ## detection is anything greater than zero with offset as the signature block will be big.
            #if ($mySigLocation -gt 0 )
            #{
            #    $myFileContent = $myFileContent[0..$mySigLocation]
            #    Write-ADFSTkHost confFileSignedWillRemoveSignature -Style Info
            #}
            #else
            #{
            #    Write-ADFSTkHost confFileNotSignedWillCopy -Style Info
            #}
            #
            #$myFileContent | Set-Content $myADFSTkManualSpSettingsInstallTemplateFile
        } 
        else 
        {
            Write-ADFSTkHost confDontOverwriteFileJustProceed -Style Info -AddSpaceAfter
        }
    }
    else
    {
        Write-ADFSTkHost confNoExistingFileSaveTo -f $myADFSTkManualSpSettingsInstallTemplateFile -Style Value -AddSpaceAfter
        Copy-item -Path $Global:ADFSTkPaths.defaultInstitutionLocalSPFile -Destination $myADFSTkManualSpSettingsInstallTemplateFile
    }

#endregion
    
    Write-ADFSTkHost confHowToRunMetadataImport -Style Info -AddLinesOverAndUnder

    if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText confCreateScheduledTask))
    {
        $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
                                            -Argument "-NoProfile -WindowStyle Hidden -command 'Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1 | Import-Module;Sync-ADFSTkAggregates'"

        $stTrigger =  New-ScheduledTaskTrigger -Daily -DaysInterval 1 -At (Get-Date)
        $stSettings = New-ScheduledTaskSettingsSet -Disable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromHours(12))

        Register-ScheduledTask -Action $stAction `
                               -Trigger $stTrigger `
                               -TaskName (Get-ADFSTkLanguageText confImportMetadata) `
                               -Description (Get-ADFSTkLanguageText confTHisSchedTaskWillDoTheImport) `
                               -RunLevel Highest `
                               -Settings $stSettings `
                               -TaskPath "\ADFSToolkit\"
    }

    Write-ADFSTkHost -WriteLine -AddSpaceAfter
    Write-ADFSTkHost cAllDone -Style Done

<#
.SYNOPSIS
Create or migrats an ADFSToolkit configuration file per aggregate.

.DESCRIPTION

This command creates a new or migrates an older configuration to a newer one when invoked.

How this Powershell Cmdlet works:
 
When loaded we:
   -  seek out a template configuration in $Module-home/config/default/en/config.ADFSTk.default*.xml 
   -- where * is the language designation, usually 'en'
   -  if invoked with -MigrateConfig, the configuration attempts to detect the previous answers as defaults to the new ones where possible

   
.INPUTS

zero or more inputs of an array of string to command

.OUTPUTS

configuration file(s) for use with current ADFSToolkit that this command is associated with

.EXAMPLE
new-ADFSTkConfiguration

.EXAMPLE

"C:\ADFSToolkit\0.0.0.0\config\config.file.xml" | new-ADFSTkConfiguration

.EXAMPLE

"C:\ADFSToolkit\0.0.0.0\config\config.file.xml","C:\ADFSToolkit\0.0.0.0\config\config.file2.xml" | new-ADFSTkConfiguration

#>

}



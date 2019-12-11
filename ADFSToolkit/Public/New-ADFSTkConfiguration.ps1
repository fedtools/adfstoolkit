#Requires -Version 5.1

function New-ADFSTkConfiguration {
[cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True)]
        [string[]]$MigrationConfig
    )

    Begin {
        #$ADFSTkModule = Get-Module ADFSToolkit
        $ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1
        
        if (!(Test-Path "Function:\Write-ADFSTkLog"))
        {
            . (Join-Path $ADFSTkModule.ModuleBase 'Private\Write-ADFSTkLog.ps1')
        }

        if (!(Test-Path "Function:\Get-ADFSTkAnswer"))
        {
            . (Join-Path $ADFSTkModule.ModuleBase 'Private\Get-ADFSTkAnswer.ps1')
        }

        if (!(Test-Path "Function:\Compare-ADFSTkObject"))
        {
            . (Join-Path $ADFSTkModule.ModuleBase 'Private\Compare-ADFSTkObject.ps1')
        }
        
        #ADFSTk-TestAndCreateDir
        #
        #Set-ADFSTkConfigItem

        $AllFederations = @()
                
        $configPath = Join-Path $ADFSTkModule.ModuleBase "config"

        if (Test-Path $configPath)
        {
            $configDefaultPath = Join-Path $configPath "default"
            if (Test-Path $configDefaultPath)
            {
                $dirs = Get-ChildItem -Path $configDefaultPath -Directory
                $configFoundLanguages = (Compare-ADFSTkObject -FirstSet $dirs.Name `
                                                              -SecondSet ([System.Globalization.CultureInfo]::GetCultures("SpecificCultures").Name) `
                                                              -CompareType Intersection).CompareSet
    
                $configFoundLanguages | % {
                    $choices = @()
                    $caption = "Select language"
                    $message = "Please select which language you want help text in."
                    $defaultChoice = 0
                    $i = 0
                }{
                    $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&$([System.Globalization.CultureInfo]::GetCultureInfo($_).DisplayName)","" #if we want more than one language with the same starting letter we need to redo this (number the languages)
                    if ($_ -eq "en-US") {
                        $defaultChoice = $i
                    }
                    $i++
                }{
            
                    $result = $Host.UI.PromptForChoice($caption,$message,[System.Management.Automation.Host.ChoiceDescription[]]$choices,$defaultChoice) 
                }
        
                $configChosenLanguagePath = Join-Path $configDefaultPath ([string[]]$configFoundLanguages)[$result]

                if (Test-Path $configChosenLanguagePath)
                {
                    $defaultConfigFile = Get-ChildItem -Path $configChosenLanguagePath -File -Filter "config.ADFSTk.default*.xml" | Select -First 1 #Just to be sure
                }
                else
                {
                    #This should'nt happen
                }
            }
            else
            {
                #no default configs :(
            }
        }
        else
        {
            #Yeh what to do?
        }

}

# for each configuration we want to handle, we do these steps
# if given a configuration, we use it to load and set them as defaults and continue with the questions
# allowing them to hit enter to accept the default to save time and previous responses.
#
# if an empty configuration file is entered, we will ask the questions, with no defaults set.

process 
{
    Write-ADFSTkHost "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan
    
    Write-ADFSTkHost -En "You are about to create a new configuration file for ADFSToolkit." -ForegroundColor Cyan
    Write-ADFSTkHost " "

 # Detect and prep previousConfig to source values for defaults from it
    [xml]$previousConfig = ""
    

    if ([string]::IsNullOrEmpty($MigrationConfig))
    {
        Write-Verbose "No Previous Configuration detected"
    }
    else
    {
        if (Test-Path -Path $MigrationConfig)
        {
            $previousConfig = Get-Content $MigrationConfig
            Write-ADFSTkHost -En "Using previous configuration for defaults (file: $MigrationConfig)`nPLEASE NOTE: Previous hand edits to config must be manually applied again`n" -ForegroundColor Red
            Write-ADFSTkHost " "
        }
        else 
        {
            Throw "Error:Migration file $MigrationConfig does not exist, exiting"
        }
    }
 
    # Use our template from the Module to start with

    [xml]$config = Get-Content $defaultConfigFile.FullName

    Write-ADFSTkHost -En "You will be prompted with questions about metadata, signature fingerprint" -ForegroundColor Cyan
    Write-ADFSTkHost -En "and other question about your institution." -ForegroundColor Cyan
    Write-ADFSTkHost " "
    Write-ADFSTkHost -En "Hit enter to accept the defaults in round brackets" -ForegroundColor Cyan
    Write-ADFSTkHost " "
    Write-ADFSTkHost -En "If you make a mistake or want to change a value after this cmdlet is run" -ForegroundColor Cyan
    Write-ADFSTkHost -En "you can manually open the config file or re-run this command." -ForegroundColor Cyan
    
    #if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
    #{
    #    Write-ADFSTkHost "You are about to create a new configuration file for ADFSToolkit." -ForegroundColor Cyan
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "$previousMsg" -ForegroundColor Red
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "You will be prompted with questions about metadata, signature fingerprint" -ForegroundColor Cyan
    #    Write-ADFSTkHost "and other question about your institution." -ForegroundColor Cyan
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "Hit enter to accept the defaults in round brackets" -ForegroundColor Cyan
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "If you make a mistake or want to change a value after this cmdlet is run" -ForegroundColor Cyan
    #    Write-ADFSTkHost "you can manually open the config file or re-run this command." -ForegroundColor Cyan
    #}
    #elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
    #{
    #    Write-ADFSTkHost "Skapar ny konfigurationsfil för ADFSToolkit." -ForegroundColor Cyan
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "$previousMsg" -ForegroundColor Red
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "Du kommer att få svara på frågor kring metadata" -ForegroundColor Cyan
    #    Write-ADFSTkHost "och andra frågor om ditt lärosäte." -ForegroundColor Cyan
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "Tryck enter för att acceptera de förvalda värdena inom hakparenteser" -ForegroundColor Cyan
    #    Write-ADFSTkHost " "
    #    Write-ADFSTkHost "Om något blir fel eller om du vill ändra något i efterhand efter du kört klart det här kommandot" -ForegroundColor Cyan
    #    Write-ADFSTkHost "kan du öppna konfigurationsfilen och ändra i den manuellt eller köra det här kommandot igen." -ForegroundColor Cyan
    #
    #}
    
    Write-ADFSTkHost "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan
       
    Set-ADFSTkConfigItem -XPath "configuration/metadataURL" `
                         -ExampleValue 'https://metadata.federationOperator.org/path/to/metadata.xml'
                       
    Set-ADFSTkConfigItem -XPath "configuration/signCertFingerprint" `
                         -ExampleValue '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF'

    Set-ADFSTkConfigItem -XPath "configuration/MetadataPrefix" `
                         -ExampleValue 'ADFSTk/SWAMID/CANARIE/INCOMMON' `
                  
    Set-ADFSTkConfigItem -XPath "configuration/staticValues/o" `
                         -ExampleValue 'ABC University'

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/co" `
                         -ExampleValue 'Canada, Sweden'

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/c" `
                         -ExampleValue 'CA, SE'

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/schacHomeOrganization" `
                         -ExampleValue 'institution.edu'

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/norEduOrgAcronym" `
                         -ExampleValue 'CA'

    Set-ADFSTkConfigItem -XPath "configuration/staticValues/ADFSExternalDNS" `
                         -ExampleValue 'adfs.institution.edu'

    Set-ADFSTkConfigItem -XPath "configuration/eduPersonPrincipalNameRessignable" `
                         -ExampleValue 'false'

    $epsa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonScopedAffiliation"
    $epa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonAffiliation" 

    $epa.ChildNodes | % {
        $node = $_.Clone()    
        $node.'#text' += "@$($config.configuration.staticValues.schacHomeOrganization)"

        $epsa.AppendChild($node) | Out-Null
    }

    # Post processing to apply some business logic to enhance things

    # Module specific info
    #$myWorkingPath = (Get-Module -Name ADFSToolkit).ModuleBase
    $myWorkingPath = $ADFSTkModule.ModuleBase
    #$myVersion = (Get-Module -Name ADFSToolkit).Version.ToString()
    $myVersion = "{0}.{1}" -f $ADFSTkModule.Version.Major.ToString(),$ADFSTkModule.Version.Minor.ToString()

    # set workingpath for base:
    $myInstallDir = "c:\ADFSToolkit"
    $myMainConfigDir = Join-Path $myInstallDir 'config'

    $myADFSTkInstallDir = Join-path $myInstallDir $myVersion

    # various useful items for minting our configuration 

    # user entered
    $myPrefix = (Select-Xml -Xml $config -XPath "configuration/MetadataPrefix").Node.'#text'

    # sourced from config template
    $myCacheDir =  (Select-Xml -Xml $config -XPath "configuration/CacheDir").Node.'#text'
    $myConfigDir = (Select-Xml -Xml $config -XPath "configuration/ConfigDir").Node.'#text'
    
    # derived paths 
    $myTargetInstallCacheDir = Join-path $myADFSTkInstallDir $myCacheDir
    $myTargetInstallConfigDir = Join-path $myADFSTkInstallDir $myConfigDir

    #verify directories for cache and config exist or create if they do not

    # we need an install directory

    ADFSTk-TestAndCreateDir -Path $myADFSTkInstallDir       -PathName "ADFSTk install directory"
    ADFSTk-TestAndCreateDir -Path $myMainConfigDir          -PathName "Main configuration"
    ADFSTk-TestAndCreateDir -Path $myTargetInstallCacheDir  -PathName "Cache directory"
    ADFSTk-TestAndCreateDir -Path $myTargetInstallConfigDir -PathName "Config directory"
    
    # For the ADFSTk functionality, we desire to associate certain cache files to certain things and bake a certain default location
 
    (Select-Xml -Xml $config -XPath "configuration/WorkingPath").Node.'#text' = "$myADFSTkInstallDir" #Do we really need this?
    (Select-Xml -Xml $config -XPath "configuration/SPHashFile").Node.'#text' = "$myPrefix-SPHashfile.xml"
    (Select-Xml -Xml $config -XPath "configuration/MetadataCacheFile").Node.'#text' = "$myPrefix-metadata.cached.xml"

    $configFile = Join-Path $myTargetInstallConfigDir "config.$myPrefix.xml"

    #
    # Prepare our template for ADFSTkManualSPSettings to be copied into place, safely of course, after directories are confirmed to be there.

    $myADFSTkManualSpSettingsDistroTemplateFile =  Join-Path $myWorkingPath            -ChildPath "config\default\en-US\get-ADFSTkLocalManualSpSettings-dist.ps1"
    $myADFSTkManualSpSettingsInstallTemplateFile = Join-Path $myTargetInstallConfigDir -ChildPath "get-ADFSTkLocalManualSpSettings.ps1"

    # create a new file using timestamp removing illegal file characters 
    $myConfigFileBkpExt = (get-date -Format o).Replace(':','.')

    if (Test-path $configFile)
    {
        if (Get-ADFSTkAnswer -Caption "ADFSToolkit:Configuration Exists." `
                             -Message "Overwrite $configFile with this new configuration?`n(Backup will be created)")
        {
            $myConfigFileBkpName = "$configFile.$myConfigFileBkpExt"

            Write-ADFSTkHost "Creating new config in: $configFile"
            Write-ADFSTkHost "Old configuration: $myConfigFileBkpName"

            Move-Item -Path $configFile -Destination $myConfigFileBkpName

            $config.Save($configFile)
        } 
        else 
        {
            throw "Safe exit: User decided to not overwrite file, stopping"
        }
    }
    else
    {
        Write-ADFSTkHost "No existing file, saving new ADFSTk configuration to: $configFile"
        $config.Save($configFile)
    }

    if (Test-path $myADFSTkManualSpSettingsInstallTemplateFile ) 
    {
        if (Get-ADFSTkAnswer -Caption "Local Relying Party Settings Exist" `
                             -Message "Overwrite $myADFSTkManualSpSettingsInstallTemplateFile with new blank configuration?`n(Backup will be created)")
        {
            Write-ADFSTkHost "Confirmed, saving new Relying Part/Service Provider customizations to: $myADFSTkManualSpSettingsInstallTemplateFile"

            $mySPFileBkpName = "$myADFSTkManualSpSettingsInstallTemplateFile.$myConfigFileBkpExt"

            Write-ADFSTkHost "Creating new config in: $myADFSTkManualSpSettingsDistroTemplateFile"
            Write-ADFSTkHost "Old configuration: $mySPFileBkpName"

            # Make backup
            Move-Item -Path $myADFSTkManualSpSettingsInstallTemplateFile -Destination $mySPFileBkpName

            # Detect and strip signature from file we ship
            $myFileContent = Get-Content $($myADFSTkManualSpSettingsDistroTemplateFile)
            $mySigLine = ($myFileContent | Select-String "SIG # Begin signature block").LineNumber
            $sigOffset = 2
            $mySigLocation = $mySigLine-$sigOffset

            # detection is anything greater than zero with offset as the signature block will be big.
            if ($mySigLocation -gt 0 )
            {
                $myFileContent = $myFileContent[0..$mySigLocation]
                Write-ADFSTkHost "File signed, stripping signature and putting in place for you to customize"
            }
            else
            {
                Write-ADFSTkHost "File was not signed, simple copy being made"
            }
            
            $myFileContent | Set-Content $myADFSTkManualSpSettingsInstallTemplateFile
        } 
        else 
        {
            Write-ADFSTkHost "User decided to not overwrite existing SP settings file, proceeding to next steps" 
        }
    }
    else
    {
        Write-ADFSTkHost "No existing file, saving new configuration to: $($myADFSTkManualSpSettingsInstallTemplateFile)"
        Copy-item -Path $myADFSTkManualSpSettingsDistroTemplateFile -Destination $myADFSTkManualSpSettingsInstallTemplateFile
    }


    #Add $configFile to Main Config File

    Write-ADFSTkHost "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

    Write-ADFSTkHost -En "To be able to (automatically) run Sync-ADFSTkAggregates the configuration file" -ForegroundColor Cyan
    Write-ADFSTkHost -En "needs to be added to a ADFSTk main configuration file." -ForegroundColor Cyan
    Write-ADFSTkHost -En "This will be done now." -ForegroundColor Cyan

    #if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
    #{
    #    Write-ADFSTkHost "To be able to (automatically) run Sync-ADFSTkAggregates the configuration file" -ForegroundColor Cyan -NoNewline
    #    Write-ADFSTkHost "needs to be added to a ADFSTk main configuration file." -ForegroundColor Cyan
    #    Write-ADFSTkHost "This will be done now." -ForegroundColor Cyan
    #}
    #elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
    #{
    #    Write-ADFSTkHost "För att kunna köra Sync-ADFSTkAggregates måste konfigurationsfilen" -ForegroundColor Cyan -NoNewline
    #    Write-ADFSTkHost "läggas till i en huvudkonfiguration i ADFSTk." -ForegroundColor Cyan
    #    Write-ADFSTkHost "Detta kommer att göras nu." -ForegroundColor Cyan
    #}

    if (Test-Path (Get-ADFSTkMainConfigurationPath))
    {
        Add-ADFSTkMainConfigurationItem -ConfigurationItem $configFile
    }
    else
    {
        New-ADFSTkMainConfiguration -ConfigurationFile $configFile
    }

    Write-ADFSTkHost "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

    Write-ADFSTkHost -En "The configuration file has been saved here:" -ForegroundColor Cyan
    Write-ADFSTkHost $configFile -ForegroundColor Yellow
    Write-ADFSTkHost -En "To run the metadata import use the following command:" -ForegroundColor Cyan
    Write-ADFSTkHost "Sync-ADFSTkAggregates"
    Write-ADFSTkHost -En "Do you want to create a scheduled task that executes this command every hour?" -ForegroundColor Cyan
    Write-ADFSTkHost -En "The scheduled task will be disabled when created and you can change triggers as you like." -ForegroundColor Cyan
    
    $scheduledTaskQuestion = Write-ADFSTkHost -En "Create ADFSToolkit scheduled task?" -PassThru
    $scheduledTaskName = Write-ADFSTkHost -En "Import Federated Metadata with ADFSToolkit" -PassThru
    $scheduledTaskDescription = Write-ADFSTkHost -En "This scheduled task imports the Federated Metadata with ADFSToolkit" -PassThru
    
    #if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
    #{
    #    Write-ADFSTkHost "The configuration file has been saved here:" -ForegroundColor Cyan
    #    Write-ADFSTkHost $configFile -ForegroundColor Yellow
    #    Write-ADFSTkHost "To run the metadata import use the following command:" -ForegroundColor Cyan
    #    Write-ADFSTkHost 'Sync-ADFSTkAggregates' -ForegroundColor Yellow
    #    Write-ADFSTkHost "Do you want to create a scheduled task that executes this command every hour?" -ForegroundColor Cyan
    #    Write-ADFSTkHost "The scheduled task will be disabled when created and you can change triggers as you like." -ForegroundColor Cyan
    #    
    #    $scheduledTaskQuestion = "Create ADFSToolkit scheduled task?"
    #    
    #    $scheduledTaskName = "Import Federated Metadata with ADFSToolkit"
    #    $scheduledTaskDescription = "This scheduled task imports the Federated Metadata with ADFSToolkit"
    #}
    #elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
    #{
    #    Write-ADFSTkHost "Konfigurationsfilen har sparats här:" -ForegroundColor Cyan
    #    Write-ADFSTkHost $configFile -ForegroundColor Yellow
    #    Write-ADFSTkHost "För att starta metadataimporten kör du följande kommando:" -ForegroundColor Cyan
    #    Write-ADFSTkHost 'Sync-ADFSTkAggregates' -ForegroundColor Yellow
    #    Write-ADFSTkHost "Vill du skapa ett schemalagt jobb som kör kommandot varje timme?" -ForegroundColor Cyan
    #    Write-ADFSTkHost "Det schemalagda jobbet kommer att skapas avstängt (disabled) och du kan gå in och ändra inställningar på det om du vill." -ForegroundColor Cyan
    #    
    #    $scheduledTaskQuestion = "Skapa ADFSToolkit schemalagt jobb?"
    #
    #    $scheduledTaskName = "Import Federated Metadata with ADFSToolkit"
    #    $scheduledTaskDescription = "This scheduled task imports the Federated Metadata with ADFSToolkit"
    #}

    if (Get-ADFSTkAnswer $scheduledTaskQuestion)
    {
        $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
                                            -Argument "-NoProfile -WindowStyle Hidden -command 'Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1 | Import-Module;Sync-ADFSTkAggregates'"

        $stTrigger =  New-ScheduledTaskTrigger -Daily -DaysInterval 1 -At (Get-Date)
        $stSettings = New-ScheduledTaskSettingsSet -Disable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromHours(12))

        Register-ScheduledTask -Action $stAction `
                               -Trigger $stTrigger `
                               -TaskName $scheduledTaskName `
                               -Description $scheduledTaskDescription `
                               -RunLevel Highest `
                               -Settings $stSettings `
                               -TaskPath "\ADFSToolkit\"
    }

    Write-ADFSTkHost "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

    Write-ADFSTkHost -En "All done!" -ForegroundColor Green
    
    #if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
    #{
    #    Write-ADFSTkHost "All done!" -ForegroundColor Green
    #}
    #elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
    #{
    #    Write-ADFSTkHost "Allt klart!" -ForegroundColor Green
    #}
}

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


function Write-ADFSTkHost {
[CmdletBinding(DefaultParameterSetName='Text')]
param (
    [Parameter(ParameterSetName='PassThru')]
    [switch]$PassThru,
    [Parameter(ParameterSetName='PassThru', Mandatory=$false, Position=1)]
    [Parameter(ParameterSetName='Text', Mandatory=$false, Position=1)]
    $Sv,
    [Parameter(ParameterSetName='PassThru', Mandatory=$false, Position=0)]
    [Parameter(ParameterSetName='Text', Mandatory=$true, Position=0)]
    $En,
    [Parameter(ParameterSetName='Text', Position=2)]
    [ValidateSet('Black','DarkBlue','DarkGreen','DarkCyan','DarkRed','DarkMagenta','DarkYellow','Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow','White')]
    $ForegroundColor,
    [Parameter(ParameterSetName='Write-ADFSTkHost')]
    $NoNewLine
)

    if ([string]::IsNullOrEmpty($Sv))
    {
        $Sv = $En
    }

    if (!$PSBoundParameters.ContainsKey('PassThru'))
    {
        $params = @{}
        if ($PSBoundParameters.ContainsKey('ForegroundColor'))
        {
            $params.ForegroundColor = $ForegroundColor
        }

        if ($PSBoundParameters.ContainsKey('NoNewLine'))
        {
            $params.NoNewLine = $null
        }
    }

    if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
    {
        if ($PSBoundParameters.ContainsKey('PassThru'))
        {
            $En
        }
        else
        {
            Write-ADFSTkLog $En @params
        }
    }
    elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
    {
        if ($PSBoundParameters.ContainsKey('PassThru'))
        {
            $Sv
        }
        else
        {
            Write-ADFSTkLog $Sv @params
        }
    }
}

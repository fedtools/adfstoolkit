#Requires -Version 5.1


#New-ADFSTkConfiguration -WhatIf
#Set-ADFSTkConfiguration -Identity -Aggregate -fingerPrint -MetadataPrefix -ADFSExternalDNS -o -c -co
#Get-ADFSTkConfiguration 


#Do you have a current config file?



function New-ADFSTkConfiguration {

$myModule = Get-Module ADFSToolkit
$configPath = Join-Path $myModule.ModuleBase "config"
if (Test-Path $configPath)
{
    $configDefaultPath = Join-Path $configPath "default"
    if (Test-Path $configDefaultPath)
    {
        $dirs = Get-ChildItem -Path $configDefaultPath -Directory
        $configFoundLanguages = (Compare-ADFSTkObject -FirstSet $dirs.Name -SecondSet ([System.Globalization.CultureInfo]::GetCultures("SpecificCultures").Name) -CompareType Intersection).CompareSet
    
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

    Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan
if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
{
    Write-Host "You are about to create a new configuration file for ADFSToolkit." -ForegroundColor Cyan
    Write-Host "You will be prompted with questions about metadata, signature fingerprint" -ForegroundColor Cyan
    Write-Host "and other question about your institution." -ForegroundColor Cyan
    Write-Host " "
    Write-Host "If you make a mistake or want to change a value after this cmdlet is run" -ForegroundColor Cyan
    Write-Host "you can manually open the config file or re-run this command." -ForegroundColor Cyan
}
elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
{
    Write-Host "This is actually in Swedish! ;)" -ForegrosundColor Cyan
    Write-Host "You are about to create a new configuration file for ADFSToolkit." -ForegroundColor Cyan
    Write-Host "You will be prompted with questions about your Institution, where the federated metadata is located" -ForegroundColor Cyan
    Write-Host "and other question regarding where you have data stored." -ForegroundColor Cyan
    Write-Host " "
    Write-Host "Please read the questions carefully! If you make a mistake or want to change a value after this cmdlet is run" -ForegroundColor Cyan
    Write-Host "you can manually open the config file or use Set-ADFSTkConfiguration to change it." -ForegroundColor Cyan
}
    Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

[xml]$config = Get-Content $defaultConfigFile.FullName


Set-ADFSTkConfigItem -XPath "configuration/metadataURL" `
               -ExampleValue 'https://metadata.federationOperator.org/path/to/metadata.xml'

Set-ADFSTkConfigItem -XPath "configuration/signCertFingerprint" `
               -ExampleValue '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF'

Set-ADFSTkConfigItem -XPath "configuration/MetadataPrefix" `
               -ExampleValue 'ADFSTk/SWAMID/CANARIE/INCOMMON' `
               -DefaultValue 'ADFSTk'

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


$epsa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonScopedAffiliation"
$epa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonAffiliation" 

$epa.ChildNodes | % {
    $node = $_.Clone()    
    $node.'#text' += "@$($config.configuration.staticValues.schacHomeOrganization)"

    $epsa.AppendChild($node) | Out-Null

}

# Post processing to apply some business logic to enhance things

# Module specific info
    $myWorkingPath= (Get-Module -Name ADFSToolkit).ModuleBase
    $myVersion= (Get-Module -Name ADFSToolkit).Version.ToString()


# set workingpath for base:
    $myInstallDir= "c:\ADFSToolkit"
    $myADFSTkInstallDir= Join-path $myInstallDir $myVersion



# various useful items for minting our configuration 
 

# user entered
    $myPrefix=     (Select-Xml -Xml $config -XPath "configuration/MetadataPrefix").Node.'#text'
# sourced from config template
    $myCacheDir =  (Select-Xml -Xml $config -XPath "configuration/CacheDir").Node.'#text'
    $myConfigDir = (Select-Xml -Xml $config -XPath "configuration/ConfigDir").Node.'#text'
    
# derived paths 
    $myTargetInstallCacheDir = Join-path $myADFSTkInstallDir $myCacheDir
    $myTargetInstallConfigDir = Join-path $myADFSTkInstallDir $myConfigDir

   

#verify directories for cache and config exist or create if they do not

# we need an install directory

If(!(test-path $myADFSTkInstallDir))
{
      New-Item -ItemType Directory -Force -Path $myADFSTkInstallDir
      Write-Host "ADFSToolkit directory did not exist, creating it here: $myADFSTkInstallDir"
}else
{
    Write-Host "Cache directory exists at $myADFSTkInstallDir"
}

    If(!(test-path $myTargetInstallCacheDir))
{
      New-Item -ItemType Directory -Force -Path $myTargetInstallCacheDir
      Write-Host "Cache directory did not exist, creating it here: $myTargetInstallCacheDir"
}else
{
    Write-Host "Cache directory exists at $myTargetInstallCacheDir"
}

    If(!(test-path $myTargetInstallConfigDir))
{
      New-Item -ItemType Directory -Force -Path $myTargetInstallConfigDir
      Write-Host "Config directory did not exist, creating it here: $myTargetInstallConfigDir"
}else
{
    Write-Host "Config directory exists at $myTargetInstallConfigDir"
}




# For the ADFSTk functionality, we desire to associate certain cache files to certain things and bake a certain default location
 
     (Select-Xml -Xml $config -XPath "configuration/WorkingPath").Node.'#text' = $myADFSTkInstallDir
     (Select-Xml -Xml $config -XPath "configuration/SPHashFile").Node.'#text' = "$myPrefix-SPHashfile.xml"
     (Select-Xml -Xml $config -XPath "configuration/MetadataCacheFile").Node.'#text' = "$myPrefix-metadata.cached.xml"



$configFile = Join-Path $myTargetInstallConfigDir "config.$myPrefix.xml"
$configJobName="sync-ADFSTkAggregates.ps1"
$configJob = Join-Path $myADFSTkInstallDir $configJobName

#
# Prepare our template for ADFSTkManualSPSettings to be copied into place, safely of course, after directories are confirmed to be there.

    $myADFSTkManualSpSettingsFileNamePrefix="get-ADFSTkManualSpSettings"
    $myADFSTkManualSpSettingsFileNameDistroPostfix="-dist.ps1"
    $myADFSTkManualSpSettingsFileNameInstallDistroName="$($myADFSTkManualSpSettingsFileNamePrefix)$($myADFSTkManualSpSettingsFileNameDistroPostfix)"
    $myADFSTkManualSpSettingsFileNameInstallPostfix=".ps1"
    $myADFSTkManualSpSettingsFileNameInstallInstallName="$($myADFSTkManualSpSettingsFileNamePrefix)$($myADFSTkManualSpSettingsFileNameInstallPostfix)"

    $myADFSTkManualSpSettingsDistroTemplateFile= Join-path $myWorking (Join-Path "config" (Join-Path "default" ( Join-Path "en-US" "$($myADFSTkManualSpSettingsFileNameInstallDistroName)")))
    
    $myADFSTkManualSpSettingsInstallTemplateFile= Join-path $myADFSTkInstallDir (Join-Path "config"  "$($myADFSTkManualSpSettingsFileNameInstallInstallName)")
    
    


if (Test-path $configFile) 
{
        $message  = 'Configuration Already exists.'
        $question = 'Overwrite with this new configuration?'

        $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

        $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
        if ($decision -eq 0) {
            Write-Host "Confirmed, saving new configuration to: $configFile"

            $config.Save($configFile)


        } else {
         
          
            throw "User decided to not overwrite file - exiting"
        
        }


}else
{
        Write-Host "No existing file, saving new configuration to: $configFile"
        $config.Save($configFile)
        




}

if (Test-path $myADFSTkManualSpSettingsInstallTemplateFile) 
{
        $message  = 'Local site Relying Party/Service provider Configuration Already exists at: $($myADFSTkManualSpSettingsInstallTemplateFile)'
        $question = 'Overwrite with a blank configuration? '

        $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

        $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
        if ($decision -eq 0) {
            Write-Host "Confirmed, saving new configuration to: $myADFSTkManualSpSettingsInstallTemplateFile"

            Copy-item -Path $($myADFSTkManualSpSettingsDistroTemplateFile) -Destination $myADFSTkManualSpSettingsInstallTemplateFile


        } else {
          
            throw "User decided to not overwrite file SP settings file - exiting"
        
        }

}else
{
        Write-Host "No existing file, saving new configuration to: $($myADFSTkManualSpSettingsInstallTemplateFile)"
       Copy-item -Path $($myADFSTkManualSpSettingsDistroTemplateFile) -Destination $myADFSTkManualSpSettingsInstallTemplateFile

        }


$ADFSTkRunCommand = "Import-ADFSTkMetadata -ProcessWholeMetadata -ForceUpdate -ConfigFile '$configFile'"
$ADFSTkImportCommand =" `$md=get-module -ListAvailable adfstoolkit; Import-module `$md" 
$ADFSTKManualSPCommand ="`$ADFSTkSiteSPSettings=$($myADFSTkManualSpSettingsInstallTemplateFile)"
#$ADFSTkImportCommand ="Get-Module -ListAvailable ADFSToolkit |Import-Module"
$ADFSTkModuleBase=(Get-Module -ListAvailable ADFSToolkit).ModuleBase

$myDateFileUpdated= Get-Date


if (Test-path $configJob) 
{
        $message  = 'Job for loading aggregate exists.'
        $question = "Append this configuration in ADFSTk job $configJobName ? (recommended approach is yes)"

        $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

        $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
        if ($decision -eq 0) {
            Write-Host "Confirmed, appending command to: $configJob"

            # We want to write only the job to schedule on a newline to be run
            # Other steps for the first time the file is written is in a nother section of the testing for existence of this file
            Add-Content $configJob "`n$ADFSTkRunCommand"
            Add-Content $configJob "`n#Updated as of: $myDateFileUpdated"


        } else {
         
           Write-host "User selected to NOT add this configuration to $configJob"
         

        }


}else
{
        Write-Host "No existing file, creating new Powershell job to schedule: $configJob"
         # This is the first time the file is written so we need:
         # the import command
         # the run command
         # the Manual SP Settings Command

          
             Write-Host "$configJob does not exist, we will create it and then add your settings to it."
        
             Add-Content $configJob "`n$ADFSTkImportCommand"
             Add-Content $configJob "`n$ADFSTkRunCommand"

             Add-Content $configJob "`n$ADFSTKManualSPCommand"
             
             $myDateFileUpdated= Get-Date
             Add-Content $configJob "`n#Updated as of: $myDateFileUpdated"
        
}



Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
{
    Write-Host "The configuration file has been saved here:" -ForegroundColor Cyan
    Write-Host $configFile -ForegroundColor Yellow
    Write-Host "To run the metadata import use the following command:" -ForegroundColor Cyan
    Write-Host $ADFSTkRunCommand -ForegroundColor Yellow
    Write-Host "Do you want to create a scheduled task that executes this command every hour?" -ForegroundColor Cyan
    Write-Host "The scheduled task will be disabled when created and you can change triggers as you like." -ForegroundColor Cyan
    $scheduledTaskQuestion = "Create scheduled task?"
    $scheduledTaskName = "Import Federated Metadata with ADFSToolkit"
    $scheduledTaskDescription = "This scheduled task imports the Federated Metadata with ADFSToolkit"
}
elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
{
    Write-Host "This is actually in Swedish! ;)" -ForegroundColor Cyan
    Write-Host "The configuration file has been saved here:" -ForegroundColor Cyan
    Write-Host $configFile -ForegroundColor Yellow
    Write-Host "To run the metadata import use the following command:" -ForegroundColor Cyan
    Write-Host $ADFSTkRunCommand -ForegroundColor Yellow
    Write-Host "Do you want to create a scheduled task that executes this command every hour?" -ForegroundColor Cyan
    Write-Host "The scheduled task will be disabled when created and you can change triggers as you like." -ForegroundColor Cyan
    $scheduledTaskQuestion = "Create scheduled task?"
    $scheduledTaskName = "Import Federated Metadata with ADFSToolkit"
    $scheduledTaskDescription = "This scheduled task imports the Federated Metadata with ADFSToolkit"
}

if (Get-ADFSTkAnswer $scheduledTaskQuestion)
{
    $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
                                      -Argument "-NoProfile -WindowStyle Hidden -command '& $configJob'"

    $stTrigger =  New-ScheduledTaskTrigger -Daily -DaysInterval 1 -At (Get-Date)
    $stSettings = New-ScheduledTaskSettingsSet -Disable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromHours(12))

    Register-ScheduledTask -Action $stAction -Trigger $stTrigger -TaskName $scheduledTaskName -Description $scheduledTaskDescription -RunLevel Highest -Settings $stSettings -TaskPath "\ADFSToolkit\"
    
}

Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
{
    Write-Host "All done!" -ForegroundColor Green
}
elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
{
    Write-Host "This is actually in Swedish! ;)" -ForegroundColor Cyan
    Write-Host "All done!" -ForegroundColor Green
}

}
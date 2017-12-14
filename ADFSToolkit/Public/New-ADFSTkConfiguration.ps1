


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
    Write-Host "You will be prompted with questions about your Institution, where the federated metadata is located" -ForegroundColor Cyan
    Write-Host "and other question regarding where you have data stored." -ForegroundColor Cyan
    Write-Host " "
    Write-Host "Please read the questions carefully! If you make a mistake or want to change a value after this cmdlet is run" -ForegroundColor Cyan
    Write-Host "you can manually open the config file or use Set-ADFSTkConfiguration to change it." -ForegroundColor Cyan
}
elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
{
    Write-Host "This is actually in Swedish! ;)" -ForegroundColor Cyan
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
               -ExampleValue 'https://federationurl.edu/metadata.xml'

Set-ADFSTkConfigItem -XPath "configuration/signCertFingerprint" `
               -ExampleValue '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF'

Set-ADFSTkConfigItem -XPath "configuration/MetadataPrefix" `
               -ExampleValue 'ADFSTk/SWAMID/CANARIE/INCOMMON' `
               -DefaultValue 'ADFSTk'

Set-ADFSTkConfigItem -XPath "configuration/staticValues/o" `
               -ExampleValue 'University of Exelance'

Set-ADFSTkConfigItem -XPath "configuration/staticValues/co" `
               -ExampleValue 'Narnia'

Set-ADFSTkConfigItem -XPath "configuration/staticValues/c" `
               -ExampleValue 'NA'

Set-ADFSTkConfigItem -XPath "configuration/staticValues/schacHomeOrganization" `
               -ExampleValue 'institution.edu'

Set-ADFSTkConfigItem -XPath "configuration/staticValues/norEduOrgAcronym" `
               -ExampleValue 'UE'

Set-ADFSTkConfigItem -XPath "configuration/staticValues/ADFSExternalDNS" `
               -ExampleValue 'login.ue.edu'


$epsa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonScopedAffiliation"
$epa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonAffiliation" 

$epa.ChildNodes | % {
    $node = $_.Clone()    
    $node.'#text' += "@$($config.configuration.staticValues.schacHomeOrganization)"

    $epsa.AppendChild($node) | Out-Null

}

$configFile = Join-Path $configPath "config.ADFSTk.xml"

$config.Save($configFile)

$ADFSTkRunCommand = "Import-ADFSTkMetadata -ProcessWholeMetadata -ForceUpdate -ConfigFile '$configFile'"

Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
{
    Write-Host "The configuration file has been saved here:" -ForegroundColor Cyan
    Write-Host $configFile -ForegroundColor Yellow
    Write-Host "To run the metadata import use the following command:" -ForegroundColor Cyan
    Write-Host $ADFSTkRunCommand -ForegroundColor Yellow
    Write-Host "Do you want to create a scheduled task that executes this command every 15 minutes?" -ForegroundColor Cyan
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
    Write-Host "Do you want to create a scheduled task that executes this command every 15 minutes?" -ForegroundColor Cyan
    Write-Host "The scheduled task will be disabled when created and you can change triggers as you like." -ForegroundColor Cyan
    $scheduledTaskQuestion = "Create scheduled task?"
    $scheduledTaskName = "Import Federated Metadata with ADFSToolkit"
    $scheduledTaskDescription = "This scheduled task imports the Federated Metadata with ADFSToolkit"
}

if (Get-ADFSTkAnswer $scheduledTaskQuestion)
{
    $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
                                      -Argument '-NoProfile -WindowStyle Hidden -command "& {$ADFSTkRunCommand}"'

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
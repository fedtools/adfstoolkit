function Update-ADFSTkConfiguration 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        $ConfigurationFile
    )


    #Get All paths
    $ADFSTKPaths = Get-ADFSTKPaths

    #$configFile = $ADFSTKPaths.mainConfigFile

    #$ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1
        
    if (!(Test-Path "Function:\Get-ADFSTkAnswer"))
    {
        . (Join-Path $ADFSTKPaths.modulePath 'Private\Get-ADFSTkAnswer.ps1')
    }
    
    if (!(Test-Path "Function:\Write-ADFSTkLog"))
    {
        . (Join-Path $ADFSTKPaths.modulePath 'Private\Write-ADFSTkLog.ps1')
    }

    #$defaultConfigFile = Join-Path $ADFSTkModule.ModuleBase "config\default\en-US\config.ADFSTk.default_en.xml"
    if (Test-Path $ADFSTKPaths.defaultConfigFile)
    {
        try
        {
            [xml]$defaultConfig = Get-Content $ADFSTKPaths.defaultConfigFile
        }
        catch        {
            Write-ADFSTkLog "Could not parse default config file '$($ADFSTKPaths.defaultConfigFile)'!" -MajorFault
        }
    }
    else
    {
        Write-ADFSTkLog "Could not find default config file '$($ADFSTKPaths.defaultConfigFile)'!" -MajorFault
    }

#region Select Config
    
    $selectedConfigs = $null

    if ($PSBoundParameters.ContainsKey('ConfigurationFile'))
    {
        if (!(Test-Path $ConfigurationFile))
        {
            Write-ADFSTkLog "$ConfigurationFile does not exist!" -MajorFault
        }

        $selectedConfigs = Get-ChildItem $ConfigurationFile
    }
    else
    {
        #Check if a ADFSTk main configuration file exists
        if (Test-Path $ADFSTKPaths.mainConfigFile)
        {
            Write-ADFSTkVerboseLog -Message "A configuration file found!"
        
            #Fetch all institution configuration files from ADFSTk main config

            $currentConfigs = Get-ADFSTkMainConfiguration | Out-GridView -Title "Select the configuration file(s) you want to upgrade..." -PassThru 
            
            $selectedConfigs = foreach ($currentConfig in $currentConfigs) 
            {
                if (!(Test-Path $currentConfig.ConfigFile))
                {
                    Write-ADFSTkLog "Could not find '$($currentConfig.ConfigFile)'!" -EntryType Error
                }
                else
                {
                    Get-ChildItem $currentConfig.ConfigFile
                }
            }
        }
        else
        {
            $currentConfigs = Get-ChildItem $ADFSTKPaths.mainDir -Filter '*.xml' `
                                                         -Recurse | ? {$_.Directory.Name -notcontains 'cache'} | `
                                                                    Select Directory, Name, LastWriteTime | `
                                                                    Sort Directory,Name
            
            if ([string]::IsNullOrEmpty($currentConfigs))
            {
                Write-ADFSTkLog "Could not find any institution configuration files. Have you run New-ADFSTkConfiguration?" -MajorFault
            }

            $selectedConfigs = $currentConfigs | Out-GridView -Title "Select institution configuration file(s) to handle..." -PassThru 
        }
        
        if ([string]::IsNullOrEmpty($selectedConfigs))
        {
            Write-ADFSTkLog "No institution configuration file(s) selected. Aborting!" -MajorFault
        }
    }

#endregion

    foreach ($configFile in $selectedConfigs)
    {
        $continue = $true
        try 
        {
            [xml]$config = Get-Content $configFile.FullName
        }
        catch
        {
            Write-ADFSTkLog "Could not open or parse the institution configuration file!`r`n$_" -EntryType Warning
            $continue = $false
        }

        if ($continue)
        {

            if ([string]::IsNullOrEmpty($config.configuration.ConfigVersion))
            {
                Write-ADFSTkLog "Could not retrieve version from selected configuration file..." -EntryType Error
            }
            else
            {
                #First take a backup of the current file
                $backupDir = Join-Path $configFile.Directory "backup"

                if (!(Test-Path $backupDir))
                {
                    Write-ADFSTkVerboseLog -Message "Backup directory not existing."

                    New-Item -ItemType Directory -Path $backupDir | Out-Null
                
                    Write-ADFSTkVerboseLog -Message "Backup directory created here: '$backupDir'"
                }
                
                $backupFilename = "{0}_backup_v{3}_{1}{2}" -f $configFile.BaseName, (Get-Date).tostring("yyyyMMdd_HHmmss"), $configFile.Extension, $config.configuration.ConfigVersion
                $backupFile = Join-Path $backupDir $backupFilename
                Copy-Item -Path $configFile -Destination $backupFile | Out-Null

                Write-ADFSTkLog "Old configuration file backed up to: '$backupFile'" -ForegroundColor Green

                $RemoveCache = $false

                #Now lets upgrade in steps!

                
                if ($config.configuration.ConfigVersion -eq "1.0")
                {
                    Write-ADFSTkVerboseLog "Updating institution config from v1.0 to v1.1" 
                    Update-ADFSTkXML -NodeName "eduPersonPrincipalNameRessignable" -XPathParentNode "configuration" -RefNodeName "MetadataPrefixSeparator"

                    Set-ADFSTkConfigItem -XPath "configuration/eduPersonPrincipalNameRessignable" `
                             -ExampleValue 'true/false' `
                             -DefaultValue 'false' `
                             -Config $config `
                             -DefaultConfig $defaultConfig

                    #$RemoveCache = $true
                    
                    $config.configuration.ConfigVersion = '1.1'
                    $config.Save($configFile.FullName);
                }

                if ($config.configuration.ConfigVersion -eq "1.1")
                {
                    Write-ADFSTkVerboseLog "Updating institution config from v1.1 to v1.2" 
                    

                    $feds = Get-ADFSTkFederations

                    $chosenFed = $feds.Federations.Federation | Out-GridView -Title "Choose your federation" -PassThru
                    
                    Update-ADFSTkXML -NodeName "Federation" -XPathParentNode "configuration" -RefNodeName "ConfigVersion" -Value $chosenFed.Id

                    #Set-ADFSTkConfigItem -XPath "configuration/Federation" `
                    #         -ExampleValue 'SWAMID/CAF' `
                    #         -DefaultValue $chosenFed.Id `
                    #         -Config $config `
                    #         -DefaultConfig $defaultConfig

                    #$RemoveCache = $true
                    
                    $config.configuration.ConfigVersion = '1.2'
                    $config.Save($configFile.FullName);
                }

                #if ($RemoveCache -and Get-ADFSTkAnswer "We recommend you start over without cache OK?")
                #{

                #}

            }
        }
    }
}

function Update-ADFSTkXML {
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

function New-ADFSTkMainConfiguration 
{
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    $ConfigurationFile
)

    $configDir = 'C:\ADFSToolkit\config'
    $configFile = Join-Path $configDir 'config.ADFSTk.xml'
    $backupDir = Join-Path $configDir 'backup'

    $ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1
        
    if (!(Test-Path "Function:\Get-ADFSTkAnswer"))
    {
        . (Join-Path $ADFSTkModule.ModuleBase 'Private\Get-ADFSTkAnswer.ps1')
    }

    if (!(Test-Path "Function:\Write-ADFSTkLog"))
    {
        . (Join-Path $ADFSTkModule.ModuleBase 'Private\Write-ADFSTkLog.ps1')
    }

    #Check if the config directory exists
    if (!(Test-Path $configDir))
    {
        Write-ADFSTkVerboseLog -Message "Configuration directory not existing."
    
        New-Item -ItemType Directory -Path $configDir | Out-Null
        
        Write-ADFSTkVerboseLog -Message "Configuration directory created here: '$configDir'"
    }

    if (Test-Path $configFile)
    {
        Write-ADFSTkLog -Message "A configuration file already exists!" -EntryType Warning
        
        if (Get-ADFSTkAnswer "Do you want to create a new configuration file?`n(the old one will be backed up)" -Caption "File already exists!")
        {
            if (!(Test-Path $backupDir))
            {
                Write-ADFSTkVerboseLog -Message "Backup directory not existing."

                New-Item -ItemType Directory -Path $backupDir | Out-Null
                
                Write-ADFSTkVerboseLog -Message "Backup directory created here: '$backupDir'"
            }

            $file = Get-ChildItem $configFile
            $backupFilename = "{0}_backup_{1}{2}" -f $file.BaseName, (Get-Date).tostring("yyyyMMdd_HHmmss"), $file.Extension

            $backupFile = Move-Item -Path $configFile -Destination (Join-Path $backupDir $backupFilename) -PassThru
            Write-Host "Old configuration file backed up to: '$($backupFile.FullName)'"
        }
        else
        {
            throw "A configuration file already exists!"
        }
    }

    if ($PSBoundParameters.ContainsKey('ConfigurationFile'))
    {
        if (!(Test-Path $ConfigurationFile))
        {
            throw "$ConfigurationFile does not exist!"
        }
        $selectedConfigs = Get-ChildItem $ConfigurationFile
    }
    else
    {
        $currentConfigs = Get-ChildItem 'C:\ADFSToolkit' -Filter '*.xml' `
                                                         -Recurse | ? {$_.Directory.Name -notcontains 'cache'} | `
                                                                    Select Directory, Name, LastWriteTime | `
                                                                    Sort Directory,Name
        if ([string]::IsNullOrEmpty($currentConfigs))
        {
            throw "Could not find any institution configuration files. Have you run New-ADFSTkConfiguration?"
        }

        $selectedConfigs = $currentConfigs | Out-GridView -Title "Select institution configuration file(s) to handle..." -PassThru

        if ([string]::IsNullOrEmpty($selectedConfigs))
        {
            throw "No institution configuration file(s) selected. Aborting!"
        }
    }

    [xml]$config = New-Object System.Xml.XmlDocument
    $config.AppendChild($config.CreateXmlDeclaration("1.0",$null,$null)) | Out-Null
        
    $configurationNode = $config.CreateNode("element","Configuration",$null)
        
    $configVersionNode = $config.CreateNode("element","ConfigVersion",$null)
    $configVersionNode.InnerText = "1.0"

    $configurationNode.AppendChild($configVersionNode) | Out-Null

    $config.AppendChild($configurationNode) | Out-Null

    $configFiles = $config.CreateNode("element","ConfigFiles",$null)

    foreach ($selectedConfig in $selectedConfigs)
    {
        $node = $config.CreateNode("element","ConfigFile",$null)
        $node.InnerText = Join-Path $selectedConfig.Directory $selectedConfig.Name
        $node.SetAttribute("enabled","false")
        $configFiles.AppendChild($node) | Out-Null
    }

    $config.Configuration.AppendChild($configFiles) | Out-Null
        
    #Don't save the configuration file if -WhatIf is present
    if($PSCmdlet.ShouldProcess($configFile,"Create"))
    {
        try 
        {
            $config.Save($configFile)
            Write-Host "New configuration file created: '$configFile'" -ForegroundColor Green
        }
        catch
        {
            throw $_
        }
    }
}
function Sync-ADFSTkAggregates {
[CmdletBinding(SupportsShouldProcess=$true)]
param()

    $configFile = 'C:\ADFSToolkit\config\config.ADFSTk.xml'

    $ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1
    Import-module $ADFSTkModule

    . (Join-Path $ADFSTkModule.ModuleBase 'Private\Write-ADFSTkLog.ps1')

#region Checking configfile
    Write-ADFSTkVerboseLog "Looking in default location for '$configFile'..."
    try
    {
        [xml]$config = Get-Content $configFile -ErrorAction Stop
    }
    catch
    {
        throw "No main configuration file found!`nRun New-ADFSTkMainConfiguration to create it."
    }

    Write-ADFSTkVerboseLog  "Config file found!"

    Write-ADFSTkVerboseLog  "Checking file for correct XML syntax..."

    if([string]::IsNullOrEmpty($config.Configuration))
    {
        throw "Missing Configuration node in ADFS Toolkit configuration file!"
    }
    elseif([string]::IsNullOrEmpty($config.Configuration.ConfigFiles))
    {
        throw "Missing ConfigFiles node in ADFS Toolkit configuration file!"
    }
    elseif([string]::IsNullOrEmpty($config.Configuration.ConfigFiles.ConfigFile))
    {
        throw "Missing ConfigFile node in ADFS Toolkit configuration file!"
    }

    Write-ADFSTkVerboseLog "Check done successfully!"
#endregion

    #Looping through institution configurations 
    #and invoking Import-ADFSTkMetadata for each
    #configuration file

    Write-ADFSTkLog "$($config.Configuration.ConfigFiles.ChildNodes.Count) configurationfile(s) found!" -ForegroundColor Green

    foreach ($configFile in $config.Configuration.ConfigFiles.ConfigFile)
    {
        Write-ADFSTkLog "---"
        Write-ADFSTkLog "Working with $($configFile.'#text')..."

        if (Test-Path ($configFile.'#text'))
        {
            if ($configFile.enabled -eq "true")
            {
                Write-ADFSTkVerboseLog "Invoking 'Import-ADFSTkMetadata -ProcessWholeMetadata -ForceUpdate -ConfigFile $($configFile.'#text')'"

                #Don't invoke Import-ADFSTkMetadata if -WhatIf is present
                if($PSCmdlet.ShouldProcess($configFile.'#text',"Import-ADFSTkMetadata -ProcessWholeMetadata -ForceUpdate -ConfigFile"))
                {
                    $params = @{
                        ProcessWholeMetadata = $null
                        ForceUpdate = $null
                        ConfigFile = $configFile.'#text'
                    }

                    Import-ADFSTkMetadata @params
                }

                Write-ADFSTkLog "Done!" -ForegroundColor Green
            }
            else
            {
                Write-ADFSTkLog "Config file not enabled, skipping..." -ForegroundColor Yellow
            }
        }
        else
        {
            Write-Warning "File could not be found on disk! Skipping..."
        }
    }
}
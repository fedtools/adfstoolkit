function Sync-ADFSTkAggregates {
[CmdletBinding(SupportsShouldProcess=$true)]
param()

    $configFile = 'C:\ADFSToolkit\config\config.ADFSTk.xml'

    $ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1
    Import-module $ADFSTkModule

    . (Join-Path $ADFSTkModule.ModuleBase 'Private\Write-ADFSTkLog.ps1')

#region Checking configfile
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText syncLookingDefaulLocationFor -f $configFile)
    try
    {
        [xml]$config = Get-Content $configFile -ErrorAction Stop
    }
    catch
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText syncNoADFSTkConfigFile) -MajorFault
    }

    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText syncConfigFound)

    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText syncCheckingXML)

    if([string]::IsNullOrEmpty($config.Configuration))
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText syncMissingNode -f 'Configuration') -MajorFault
    }
    elseif([string]::IsNullOrEmpty($config.Configuration.ConfigFiles))
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText syncMissingNode -f 'ConfigFiles') -MajorFault
    }
    elseif([string]::IsNullOrEmpty($config.Configuration.ConfigFiles.ConfigFile))
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText syncMissingNode -f 'ConfigFile') -MajorFault
    }

    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText syncCheckDoneSuccessfully)
#endregion

    #Looping through institution configurations 
    #and invoking Import-ADFSTkMetadata for each
    #configuration file

    Write-ADFSTkLog (Get-ADFSTkLanguageText syncFoundConfigFiles -f $config.Configuration.ConfigFiles.ChildNodes.Count) -ForegroundColor Green

    foreach ($configFile in $config.Configuration.ConfigFiles.ConfigFile)
    {
        $Global:CurrentInstitutionConfig = $configFile

        Write-ADFSTkHost -WriteLine
        Write-ADFSTkLog (Get-ADFSTkLanguageText cWorkingWith -f $configFile.'#text')

        if (Test-Path ($configFile.'#text'))
        {
            if ($configFile.enabled -eq "true")
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText syncInvokingImportADFSTKMetadata -f $configFile.'#text')

                #Don't invoke Import-ADFSTkMetadata if -WhatIf is present
                if($PSCmdlet.ShouldProcess($configFile.'#text',"Import-ADFSTkMetadata -ProcessWholeMetadata -ForceUpdate -ConfigFile"))
                {
                    $params = @{
                        ProcessWholeMetadata = $true
                        ForceUpdate = $true
                        ConfigFile = $configFile.'#text'
                    }

                    Import-ADFSTkMetadata @params
                }

                Write-ADFSTkLog (Get-ADFSTkLanguageText cDone) -ForegroundColor Green
            }
            else
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText syncConfigNotEnabledSkipping) -ForegroundColor Yellow
            }
        }
        else
        {
            Write-Warning (Get-ADFSTkLanguageText syncFileNotFoundSkipping)
        }
    }
}
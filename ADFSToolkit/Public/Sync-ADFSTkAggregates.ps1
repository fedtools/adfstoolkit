function Sync-ADFSTkAggregates {
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Silent,
    [switch]$criticalHealthChecksOnly
)

#region Check and setup Event Log
    # set appropriate logging via EventLog mechanisms

    $LogName = 'ADFSToolkit'
    $Source = 'Sync-ADFSTkAggregates'
    if (Verify-ADFSTkEventLogUsage -LogName $LogName -Source $Source)
    {
        #If we evaluated as true, the eventlog is now set up and we link the WriteADFSTklog to it
        Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $Source
    }
    else 
    {
        # No Event logging is enabled, just this one to a file
        Write-ADFSTkLog (Get-ADFSTkLanguageText importEventLogMissingInSettings) -MajorFault            
    }
#endregion

    Write-ADFSTkLog (Get-ADFSTkLanguageText syncStart) -EventID 35

#region Checking configfile
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText syncLookingDefaulLocationFor -f $Global:ADFSTkPaths.mainConfigFile)
    try
    {
        [xml]$config = Get-Content $Global:ADFSTkPaths.mainConfigFile -ErrorAction Stop
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
        $Global:ADFSTkCurrentInstitutionConfig = $configFile.'#text'

        # set appropriate logging via EventLog mechanisms
        [xml]$Settings = Get-Content $configFile.'#text'

        $LogName = $Settings.configuration.logging.LogName
        $Source = $Settings.configuration.logging.Source

        if (Verify-ADFSTkEventLogUsage -LogName $LogName -Source $Source)
        {
            #If we evaluated as true, the eventlog is now set up and we link the WriteADFSTklog to it
            Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $Source
        }
        else 
        {
            # No Event logging is enabled, just this one to a file
            Write-ADFSTkLog (Get-ADFSTkLanguageText importEventLogMissingInSettings) -MajorFault            
        }

        Write-ADFSTkHost -WriteLine
        Write-ADFSTkLog (Get-ADFSTkLanguageText cWorkingWith -f $configFile.'#text') -EventID 31

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
                        PreserveMemoryCache = $true
                    }

                    if ($PSBoundParameters.ContainsKey('Silent') -and $Silent -ne $false)
                    {
                        $params.Silent = $true
                    }

                    if ($PSBoundParameters.ContainsKey('criticalHealthChecksOnly') -and $criticalHealthChecksOnly -ne $false)
                    {
                        $params.criticalHealthChecksOnly = $true
                    }

                    try 
                    {
                        Import-ADFSTkMetadata @params
                    }
                    catch 
                    {
                        $_
                    }
                }

                Write-ADFSTkLog (Get-ADFSTkLanguageText syncProcesseDone -f $configFile.'#text') -ForegroundColor Green -EventID 32
            }
            else
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText syncConfigNotEnabledSkipping) -ForegroundColor Yellow -EventID 33
            }
        }
        else
        {
            Write-Warning (Get-ADFSTkLanguageText syncFileNotFoundSkipping)
        }
    }
    # set appropriate logging via EventLog mechanisms

    $LogName = 'ADFSToolkit'
    $Source = 'Sync-ADFSTkAggregates'
    Write-ADFSTkLog -SetEventLogName $LogName -SetEventLogSource $Source

    Write-ADFSTkLog (Get-ADFSTkLanguageText syncFinished) -EventID 34
}
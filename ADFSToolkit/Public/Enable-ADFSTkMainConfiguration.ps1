function Enable-ADFSTkMainConfiguration {
[CmdletBinding(SupportsShouldProcess=$true)]
param()

    $configDir = 'C:\ADFSToolkit\config'
    $configFile = Join-Path $configDir 'config.ADFSTk.xml'

    $ADFSTkModule = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1
        
    if (!(Test-Path "Function:\Get-ADFSTkAnswer"))
    {
        . (Join-Path $ADFSTkModule.ModuleBase 'Private\Get-ADFSTkAnswer.ps1')
    }

    if (!(Test-Path "Function:\Write-ADFSTkLog"))
    {
        . (Join-Path $ADFSTkModule.ModuleBase 'Private\Write-ADFSTkLog.ps1')
    }

    if (Test-Path $configFile)
    {
        [xml]$config = Get-Content $configFile
        
        foreach ($configItem in $config.Configuration.ConfigFiles.ConfigFile)
        {
            $configItem.enabled = "false"
        }

        $enabledConfigFiles = $config.Configuration.ConfigFiles.ConfigFile | Out-GridView -Title "Select the configuration file(s) you want to enable..." -OutputMode Multiple
        $enabledConfigFiles | % {$_.enabled = "true"}
    }
    else
    {
        Write-ADFSTkLog -Message "Configuration file '$configFile' cound not be found!" -MajorFault
    }
        
    #Don't save the configuration file if -WhatIf is present
    if($PSCmdlet.ShouldProcess($configFile,"Save"))
    {
        try 
        {
            $config.Save($configFile)
            Write-ADFSTkLog "Configuration changed successfully!" -ForegroundColor Green


            if ($enabledConfigFiles -ne $null)
            {
                Write-ADFSTkLog -Message "The following configuration file(s) are now active:"

                $enabledConfigFiles | Select -ExpandProperty '#text'
                
                Write-ADFSTkLog -Message "Please note that this configuration will now be picked up and run if the scheduled task is configured!" -ForegroundColor Yellow
            }
            else
            {
                Write-ADFSTkLog -Message "No active configuration file(s)!" -ForegroundColor Yellow
            }
        }
        catch
        {
            throw $_
        }
    }
}
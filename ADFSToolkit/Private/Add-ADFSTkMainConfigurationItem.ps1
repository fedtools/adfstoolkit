function Add-ADFSTkMainConfigurationItem {
[CmdletBinding(SupportsShouldProcess=$true)]
param 
(
    $ConfigurationItem
)

    $mainConfigPath = Get-ADFSTkMainConfigurationPath

    if (!(Test-Path "Function:\Write-ADFSTkLog"))
    {
        . (Join-Path $ADFSTkModule.ModuleBase 'Private\Write-ADFSTkLog.ps1')
    }

    if (!(Test-Path $mainConfigPath))
    {
        Write-ADFSTkLog "ADFS main configuration file does not exist! Run New-ADFSTkMainConfiguration first!" -MajorFault
    }

    [xml]$config = Get-Content $mainConfigPath

    if (($config.Configuration.ConfigFiles.ConfigFile.'#text').Contains($ConfigurationItem))
    {
        Write-ADFSTkLog "The configuration item already added," -EntryType Warning
        Write-ADFSTkLog "The status of the configuration item is: $(($config.Configuration.ConfigFiles.ConfigFile | ? {$_.'#text' -eq $ConfigurationItem}).enabled)"
    }
    else
    {
        $node = $config.CreateNode("element","ConfigFile",$null)
        $node.InnerText = $ConfigurationItem
        $node.SetAttribute("enabled","false")
        $config.Configuration.ConfigFiles.AppendChild($node) | Out-Null
        
        
        #Don't save the configuration file if -WhatIf is present
        if($PSCmdlet.ShouldProcess($mainConfigPath,"Save"))
        {
            try 
            {
                $config.Save($mainConfigPath)
                Write-ADFSTkLog "Configuration item added!" -ForegroundColor Green
                Write-ADFSTkLog "The configuration item is default disabled. To enable it, run Enable-ADFSTkMainConfiguration."
            }
            catch
            {
                throw $_
            }
        }
    }
}
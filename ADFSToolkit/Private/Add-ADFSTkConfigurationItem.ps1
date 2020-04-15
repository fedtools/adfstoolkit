function Add-ADFSTkConfigurationItem {
[CmdletBinding(SupportsShouldProcess=$true)]
param 
(
    $ConfigurationItem,
    [switch]$PassThru
)

    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    [xml]$config = Get-Content $Global:ADFSTkPaths.mainConfigFile

    if (![string]::IsNullOrEmpty($config.Configuration.ConfigFiles.HasChildNodes) -and ($config.Configuration.ConfigFiles.ConfigFile.InnerText).Contains($ConfigurationItem))
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfConfigFileAlreadyAdded) -EntryType Warning
        Write-ADFSTkHost mainconfConfigFileStatus -f ($config.Configuration.ConfigFiles.ConfigFile | ? {$_.InnerText -eq $ConfigurationItem}).enabled
    }
    else
    {
        $node = $config.CreateNode("element","ConfigFile",$null)
        $node.InnerText = $ConfigurationItem
        $node.SetAttribute("enabled","false")
        $config.SelectSingleNode('/Configuration/ConfigFiles').AppendChild($node) | Out-Null
        
        
        #Don't save the configuration file if -WhatIf is present
        if($PSCmdlet.ShouldProcess($Global:ADFSTkPaths.mainConfigFile,"Save"))
        {
            try 
            {
                $config.Save($Global:ADFSTkPaths.mainConfigFile)
                Write-ADFSTkLog (Get-ADFSTkLanguageText  mainconfConfigItemAdded) -ForegroundColor Green
                Write-Host " "
                Write-ADFSTkHost mainconfConfigItemDefaultDisabledMessage -AddSpaceAfter
            }
            catch
            {
                throw $_
            }
        }
    }

    if ($PassThru)
    {
        New-Object -TypeName PSCustomObject -Property @{
            ConfigFile = $ConfigurationItem
            Enabled = "false"
        }
    }
}
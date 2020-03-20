function Set-ADFSTkInstitutionConfiguration {
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    $ConfigurationItem,
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateSet('Enabled', 'Disabled')]
    $Status
)

    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }
        
    if (Test-Path $ADFSTkPaths.mainConfigFile)
    {
        [xml]$config = Get-Content $ADFSTkPaths.mainConfigFile
        
        if ([string]::IsNullOrEmpty($config.Configuration.ConfigFiles))
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText cFileDontExist -f $ADFSTkPaths.mainConfigFile) -MajorFault
        }

        $selectedConfigItem = $config.Configuration.ConfigFiles.ConfigFile | ? InnerText -eq $ConfigurationItem
        
        if ([string]::IsNullOrEmpty($selectedConfigItem))
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfConfItemNotFound -f $ADFSTkPaths.mainConfigFile) -MajorFault
        }
        else
        {
            if ($Status -eq 'Enabled')
            {
                $selectedConfigItem.enabled = 'true'
            }
            else
            {
                $selectedConfigItem.enabled = 'false'
            }
        }
    }
    else
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfADFSTkConfigFileNotFound -f $ADFSTkPaths.mainConfigFile) -MajorFault
    }
        
    #Don't save the configuration file if -WhatIf is present
    if($PSCmdlet.ShouldProcess($ADFSTkPaths.mainConfigFile,"Save"))
    {
        try 
        {
            $config.Save($ADFSTkPaths.mainConfigFile)
            Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfChangedSuccessfully -f $ADFSTkPaths.mainConfigFile)
        }
        catch
        {
            throw $_
        }
    }
}
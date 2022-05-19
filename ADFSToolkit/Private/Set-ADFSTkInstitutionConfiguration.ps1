function Set-ADFSTkInstitutionConfiguration {
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    $ConfigurationItem,
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateSet('Enabled', 'Disabled')]
    $Status
)

    if (Test-Path $Global:ADFSTkPaths.mainConfigFile)
    {
        [xml]$config = Get-Content $Global:ADFSTkPaths.mainConfigFile
        
        if ([string]::IsNullOrEmpty($config.Configuration.ConfigFiles))
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText cFileDontExist -f $Global:ADFSTkPaths.mainConfigFile) -MajorFault
        }

        $selectedConfigItem = $config.Configuration.ConfigFiles.ConfigFile | ? InnerText -eq $ConfigurationItem
        
        if ([string]::IsNullOrEmpty($selectedConfigItem))
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfConfItemNotFound -f $Global:ADFSTkPaths.mainConfigFile) -MajorFault
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
        Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfADFSTkConfigFileNotFound -f $Global:ADFSTkPaths.mainConfigFile) -MajorFault
    }
        
    #Don't save the configuration file if -WhatIf is present
    if($PSCmdlet.ShouldProcess($Global:ADFSTkPaths.mainConfigFile,"Save"))
    {
        try 
        {
            $config.Save($Global:ADFSTkPaths.mainConfigFile)
            Write-ADFSTkLog (Get-ADFSTkLanguageText mainconfChangedSuccessfully -f $ConfigurationItem, $Status)
        }
        catch
        {
            throw $_
        }
    }
}
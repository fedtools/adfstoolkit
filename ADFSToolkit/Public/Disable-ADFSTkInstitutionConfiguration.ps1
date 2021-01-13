function Disable-ADFSTkInstitutionConfiguration {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$All
    )

    #Get all config items and set the enabled to false    
    $configItems = Get-ADFSTkConfiguration -ConfigFilesOnly 

    if ($PSBoundParameters.ContainsKey('All') -and $All -ne $false) {
        $selectedConfigFiles = $configItems | ? Enabled -eq 'true'
    }
    else {
        $selectedConfigFiles = $configItems | Out-GridView -Title (Get-ADFSTkLanguageText confSelectInstitutionConfigToDisable) -OutputMode Multiple | ? Enabled -eq 'true'
    }
    
    
    if ([string]::IsNullOrEmpty($selectedConfigFiles)) {
        Write-ADFSTkHost confNoInstitutionConfigFileSelected
    }
    else {
        foreach ($configItem in $selectedConfigFiles) {
            #Don't update the configuration file if -WhatIf is present
            if ($PSCmdlet.ShouldProcess("ADFSToolkit configuration file", "Save")) {
                try {
                    Set-ADFSTkInstitutionConfiguration -ConfigurationItem $configItem.ConfigFile -Status 'Disabled'
                }
                catch {
                    throw $_
                }
            }
        }
    }
}
function Enable-ADFSTkInstitutionConfiguration {
[CmdletBinding(SupportsShouldProcess=$true)]
param()

    #Get all config items and set the enabled to false    
    $configItems = Get-ADFSTkConfiguration -ConfigFilesOnly 

    $enabledConfigFiles = $configItems | Out-GridView -Title "Select the configuration file(s) you want to have enabled. All others will be disabled (press cancel to disable all)..." -OutputMode Multiple
    
    #First disable all items
    $configItems | % {$_.enabled = 'false'}

    #Second enable select items (referenced to $configItems)
    $enabledConfigFiles | % {$_.enabled = "true"}
    
    
    foreach ($configItem in $configItems)
    {
        #Don't update the configuration file if -WhatIf is present
        if($PSCmdlet.ShouldProcess("ADFSToolkit configuration file","Save"))
        {
            try 
            {
                $param = @{
                    ConfigurationItem = $configItem.ConfigFile
                    Status = 'Disabled'
                }

                if ($configItem.Enabled -eq 'true')
                {
                    $param.Status = 'Enabled'
                }

                Set-ADFSTkInstitutionConfiguration @param
            }
            catch
            {
                throw $_
            }
        }
    }
}
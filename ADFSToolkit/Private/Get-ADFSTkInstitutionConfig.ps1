function Get-ADFSTkInstitutionConfig {
    param (
        #The full path to the configuration file
        $ConfigFile,
        #Return only the path, not the content
        [switch]
        $PathOnly
    )
    
    if (!$PSBoundParameters.ContainsKey('ConfigFile')) {
        if ([string]::IsNullOrEmpty($Global:ADFSTkCurrentInstitutionConfig)) {
            $ConfigFiles = Get-ADFSTkConfiguration -ConfigFilesOnly | ? Enabled -eq $true | Select -ExpandProperty ConfigFile

            if ($ConfigFiles -is [Object[]]) {
                $ConfigFile = $ConfigFiles | Out-GridView -Title (Get-ADFSTkLanguageText confChoosenConfigFile) -OutputMode Single

                if ([string]::IsNullOrEmpty($ConfigFile)) {
                    Write-ADFSTkLog -Message (Get-ADFSTkLanguageText confNoConfigFileChosen) -EventID 40 -MajorFault
                }
            }
            elseif ($ConfigFiles -is [PSCustomObject]) {
                $ConfigFile = $ConfigFiles
            }
            elseif ([string]::IsNullOrEmpty($ConfigFiles)) {
                Write-ADFSTkLog -Message (Get-ADFSTkLanguageText confNoConfigFile) -EventID 43 -MajorFault
            }
        }
        else {
            $ConfigFile = $Global:ADFSTkCurrentInstitutionConfig
        }
    }

    if (!(Test-Path $ConfigFile)) {
        Write-ADFSTkLog -Message (Get-ADFSTkLanguageText confChoosenConfigFileNotFound) -EventID 44 -MajorFault
    }

    if ($PSBoundParameters.ContainsKey('PathOnly') -and $PathOnly -ne $false) {
        return $ConfigFile
    }
    else {
        try {
            [xml]$Config = Get-Content $ConfigFile
            return $Config
        }
        catch {}
    }
}
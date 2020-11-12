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
                #Replace with Write-ADFSTLog
                $ConfigFile = $ConfigFiles | Out-GridView -Title "Choose which Config file" -OutputMode Single

                if ([string]::IsNullOrEmpty($ConfigFile)) {
                    #Replace with Write-ADFSTLog
                    throw "No Institution Config File chosen!"
                }
            }
            elseif ($ConfigFiles -is [PSCustomObject]) {
                $ConfigFile = $ConfigFiles
            }
            elseif ([string]::IsNullOrEmpty($ConfigFiles)) {
                #Replace with Write-ADFSTLog
                throw "No Institution Config File found!"
            }
        }
        else {
            $ConfigFile = $Global:ADFSTkCurrentInstitutionConfig
        }
    }

    if (!(Test-Path $ConfigFile)) {
        throw "Chosen config not found on disk!"
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
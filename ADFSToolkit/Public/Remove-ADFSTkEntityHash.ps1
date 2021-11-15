function Remove-ADFSTkEntityHash {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Default")]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "List")]
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "File")]
        $EntityIDs,
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "List")]
        [Hashtable]
        $SPHashList,
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "File")]
        $SPHashFile
    )

    #Make pipable
 
    if ($PSCmdlet.ParameterSetName -eq 'File') {
        if (Test-Path $SPHashFile) {
            try {
                $SPHashList = Import-Clixml $SPHashFile
            }
            catch {
                Throw (Get-ADFSTkLanguageText importCouldNotImportSPHashFile)
            }
        }
        else {
            Throw (Get-ADFSTkLanguageText cFileNotFound)
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Default') {
        if ([string]::IsNullOrEmpty($SPHashList)) {
            #Import the SPHash List from the File from the configuration
            $instConfig = Get-ADFSTkInstitutionConfig
            
            $SPHashFile = Join-Path $Global:ADFSTkPaths.cacheDir $instConfig.configuration.SPHashFile

            if (Test-Path $SPHashFile) {
                try {
                    $SPHashList = Import-Clixml $SPHashFile
                }
                catch {
                    Throw (Get-ADFSTkLanguageText importCouldNotImportSPHashFile)
                }
            }
            else {
                Throw (Get-ADFSTkLanguageText cFileNotFound)
            }
        }
    }

    if (![string]::IsNullOrEmpty($SPHashList)) {
        foreach ($EntityID in $EntityIDs) {
            if ($SPHashList.ContainsKey($EntityID)) {
                $SPHashList.Remove($EntityID)
                $SPHashList | Export-Clixml $SPHashFile
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText sphashSPSuccessfullyRemoved -f $EntityID)
            }
            else {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText sphashSPAlreadyRemoved -f $EntityID)
            }
        }
    }
    else {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText sphashListEmpty -f $EntityID)
    }
}

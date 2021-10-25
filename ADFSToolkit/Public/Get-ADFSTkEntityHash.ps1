function Get-ADFSTkEntityHash {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    param (
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "Default")]    
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "List")]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "File")]
        $EntityID,
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "List")]
        [Hashtable]
        $SPHashList,
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "Default")]
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "File")]
        $SPHashFile,
        [Switch]
        $Raw
    )
 
    if ($PSBoundParameters.ContainsKey('SPHashFile')) {
        if (Test-Path $SPHashFile) {
            try {
                $SPHashList = Import-Clixml $SPHashFile
            }
            catch {
                Throw (Get-ADFSTkLanguageText importCouldNotImportSPHashFile)
            }
        }
        else {
            Throw "File not found!"
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
                $SPHashList = @{}
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('EntityID')) {
        if ($SPHashList.ContainsKey($EntityID)) {
            $SPHashList.$EntityID
        }
        else {
            return $null
        }
    }
    else {
        if ($PSBoundParameters.ContainsKey('Raw') -and $Raw -ne $false) {
            return $SPHashList
        }
        else {
            foreach ($entityID in $SPHashList.Keys) {
                [PSCustomObject]@{
                    EntityID = $entityID
                    Hash     = $SPHashList.$entityID
                }
            }
        }
    }
}
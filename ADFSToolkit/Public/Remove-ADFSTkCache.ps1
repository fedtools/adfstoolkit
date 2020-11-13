function Remove-ADFSTkCache {
    param (
        #Removes Attributes and SP Settings from the Memory Cache
        [switch]
        $AttributeMemoryCache,
        #Removes everything from the Memory Cache
        [switch]
        $FullMemoryCache,
        #Removes the Metadata Cache file
        [switch]
        $MetadataCache,
        #Removes the SP Hash file. Attention! This will force ADFS Toolkit to re-import ALL SP's again
        [switch]
        $SPHashFile,
        #Reloads the language tables and chosen language
        [switch]
        $LanguageTables
    )

    #We don't want to use the memory cache in here in case of deletion ;)
    $ADFSTkPaths = Get-ADFSTKPaths

    if ($PSBoundParameters.ContainsKey('AttributeMemoryCache') -and $AttributeMemoryCache -ne $false) {
        $Global:ADFSTkManualSPSettings = $null
        $Global:ADFSTkAllAttributes = $null
        $Global:ADFSTkAllTransformRules = $null
    }

    if ($PSBoundParameters.ContainsKey('LanguageTables') -and $LanguageTables -ne $false) {
        $Global:ADFSTkLanguageTables = $null
        $Global:ADFSTkSelectedLanguage = $null
    }

    if ($PSBoundParameters.ContainsKey('FullMemoryCache') -and $FullMemoryCache -ne $false) {
        $Global:ADFSTkToolMetadata = $null
        $Global:ADFSTkManualSPSettings = $null
        $Global:ADFSTkAllAttributes = $null
        $Global:ADFSTkAllTransformRules = $null
        $Global:ADFSTkLanguageTables = $null
        $Global:ADFSTkSelectedLanguage = $null
        $Global:ADFSTkCurrentInstitutionConfig = $null
    }

    if ($PSBoundParameters.ContainsKey('MetadataCache') -and $MetadataCache -ne $false) {
        $Config = Get-ADFSTkInstitutionConfig
        
        $MetadataCacheFile = Join-Path $ADFSTkPaths.cacheDir $Config.configuration.MetadataCacheFile
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cacheSelectedMetadataFile -f $MetadataCacheFile)
        if (![string]::IsNullOrEmpty($MetadataCacheFile) -and (Test-Path $MetadataCacheFile)) {
            try {
                Remove-Item $MetadataCacheFile -Force -Confirm:$false -ErrorAction Stop
                Write-ADFSTkLog (Get-ADFSTkLanguageText cacheSelectedMetadataFileRemoved -f $MetadataCacheFile) -EventID 36 -EntryType Information
            }
            catch {
                Write-ADFSTkLog (Get-ADFSTkLanguageText cacheSelectedMetadataFileNotRemoved -f $MetadataCacheFile, $_) -EventID 37 -MajorFault
            }
        }
    }

    if ($PSBoundParameters.ContainsKey('SPHashFile') -and $SPHashFile -ne $false) {
        $Config = Get-ADFSTkInstitutionConfig
        $SPHashFilePath = Join-Path $ADFSTkPaths.cacheDir $Config.configuration.SPHashFile
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cacheSelectedSPHashFile -f $MetadataCacheFile)
        Write-ADFSTkHost -TextID cacheSelectedSPHashFileMessage -f $SPHashFilePath -Style Attention
        if (![string]::IsNullOrEmpty($SPHashFilePath) -and `
            (Test-Path $SPHashFilePath) -and `
                (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cacheSelectedSPHashFileAreYouSure)) `
        ) {
            try {
                Remove-Item $SPHashFilePath -Force -Confirm:$false -ErrorAction Stop
                Write-ADFSTkLog (Get-ADFSTkLanguageText cacheSelectedSPHashFileRemoved -f $MetadataCacheFile) -EventID 38 -EntryType Information
            }
            catch {
                Write-ADFSTkLog (Get-ADFSTkLanguageText cacheSelectedSPHashFileNotRemoved -f $MetadataCacheFile, $_) -EventID 39 -MajorFault
            }
        }
    }
}
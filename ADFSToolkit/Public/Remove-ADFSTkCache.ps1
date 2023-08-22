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
        #Removes ALL SP Hash files for ALL configurations. Attention! This will force ADFS Toolkit to re-import ALL SP's again
        [switch]
        $SPHashFileForALLConfigurations,
        #Reloads the language tables and chosen language
        [switch]
        $LanguageTables,
        #Forces the deletion of (SP Hash file) without asking
        [switch]
        $Force
    )

    #We don't want to use the memory cache in here in case of deletion ;)
    $ADFSTkPaths = Get-ADFSTKPaths

    $anyCacheCleared = $false
   

    if ($PSBoundParameters.ContainsKey('LanguageTables') -and $LanguageTables -ne $false) {
        $Global:ADFSTkLanguageTables = $null
        $Global:ADFSTkSelectedLanguage = $null
        $anyCacheCleared = $true
        Write-ADFSTkHost cacheCleared -f "Language Tables" -Style Info -ForegroundColor Green
    }

    if ($PSBoundParameters.ContainsKey('FullMemoryCache') -and $FullMemoryCache -ne $false) {
        $Global:ADFSTkToolMetadata = $null
        $Global:ADFSTkManualSPSettings = $null
        $Global:ADFSTkAllAttributes = $null
        $Global:ADFSTkAllTransformRules = $null
        $Global:ADFSTkLanguageTables = $null
        $Global:ADFSTkSelectedLanguage = $null
        $Global:ADFSTkCurrentInstitutionConfig = $null
        $Global:ADFSTkConfiguration = $null
        $anyCacheCleared = $true
        
        Write-ADFSTkHost cacheCleared -f "Full Memory Cache" -Style Info -ForegroundColor Green
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
        $anyCacheCleared = $true
    }

    if ($PSBoundParameters.ContainsKey('SPHashFile') -and $SPHashFile -ne $false) {
        $Config = Get-ADFSTkInstitutionConfig
        Handle-SPHashFile -Config $Config
        $anyCacheCleared = $true
    }

    if ($PSBoundParameters.ContainsKey('SPHashFileForALLConfigurations') -and $SPHashFileForALLConfigurations -ne $false) {
        #Get all configs (even the disabled ones)
        $ConfigFiles = Get-ADFSTkConfiguration -ConfigFilesOnly | Select -ExpandProperty ConfigFile
        
        foreach ($ConfigFile in $ConfigFiles) {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cacheSelectedSPHashFile -f $ConfigFile)
            #Test if the config actually exists on disk
            if (Test-Path $ConfigFile) {
                #Try to open the config file, silenty fail
                try {
                    [xml]$Config = Get-Content $ConfigFile
                }
                catch {}
            
                #Continue only if the config file could be opened
                if (![string]::IsNullOrEmpty($Config)) {
                    Handle-SPHashFile -Config $Config
                    $anyCacheCleared = $true
                }
            }
        }
    }

    if (!$anyCacheCleared -or ($PSBoundParameters.ContainsKey('AttributeMemoryCache') -and $AttributeMemoryCache -ne $false)) {
        $Global:ADFSTkManualSPSettings = $null
        $Global:ADFSTkAllAttributes = $null
        $Global:ADFSTkAllTransformRules = $null

        Write-ADFSTkHost cacheCleared -f "Attribute Memory Cache" -Style Info -ForegroundColor Green
    }
}

function Handle-SPHashFile {
    param (
        $Config
    )
    $SPHashFilePath = Join-Path $ADFSTkPaths.cacheDir $Config.configuration.SPHashFile
    Write-ADFSTkHost -TextID cacheSelectedSPHashFileMessage -f $SPHashFilePath -Style Attention
    if (![string]::IsNullOrEmpty($SPHashFilePath) -and `
        (Test-Path $SPHashFilePath) -and `
        ($Force -or (Get-ADFSTkAnswer (Get-ADFSTkLanguageText cacheSelectedSPHashFileAreYouSure))) `
    ) {
        
        
        try {
            Remove-Item $SPHashFilePath -Force -Confirm:$false -ErrorAction Stop
            Write-ADFSTkLog (Get-ADFSTkLanguageText cacheSelectedSPHashFileRemoved -f $SPHashFilePath) -EventID 38 -EntryType Information
        }
        catch {
            Write-ADFSTkLog (Get-ADFSTkLanguageText cacheSelectedSPHashFileNotRemoved -f $SPHashFilePath, $_) -EventID 39 -MajorFault
        }
    }
}
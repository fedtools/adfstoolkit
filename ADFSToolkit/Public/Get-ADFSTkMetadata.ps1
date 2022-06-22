function Get-ADFSTkMetadata {
    param (
        #The time in minutes the chached metadatafile live
        [Parameter(Mandatory = $false, Position = 0)]
        [int]
        $CacheTime = 15,
        [Parameter(Mandatory = $false, Position = 1)]
        $CachedMetadataFile,
        [Parameter(Mandatory = $false, Position = 2)]
        $metadataURL

    )
    
    if (!$PSBoundParameters.ContainsKey('CachedMetadataFile')) {
        #Get the CachedMetadataFile from the File from the configuration
        $instConfig = Get-ADFSTkInstitutionConfig
        $CachedMetadataFile = Join-Path $Global:ADFSTkPaths.cacheDir $instConfig.configuration.MetadataCacheFile
    }

    if (!$PSBoundParameters.ContainsKey('metadataURL')) {
        #Get the CachedMetadataFile from the File from the configuration
        if ([string]::IsNullOrEmpty($instConfig)) {
            $instConfig = Get-ADFSTkInstitutionConfig
        }
        $metadataURL = $instConfig.configuration.metadataURL
    }

    $UseCachedMetadata = $false
    if (($CacheTime -eq -1 -or $CacheTime -gt 0) -and (Test-Path $CachedMetadataFile)) {
        #CacheTime = -1 allways use cached metadata if exists
        if ($CacheTime -eq -1 -or (Get-ChildItem $CachedMetadataFile).LastWriteTime.AddMinutes($CacheTime) -ge (Get-Date)) {
            $UseCachedMetadata = $true
            try {
                #[xml]$MetadataXML = Get-Content $CachedMetadataFile
                $MetadataXML = new-object Xml.XmlDocument
                $MetadataXML.PreserveWhitespace = $true
                $MetadataXML.Load($CachedMetadataFile)
                    
                if ([string]::IsNullOrEmpty($MetadataXML)) {
                    Write-ADFSTkLog (Get-ADFSTkLanguageText importCachedMetadataEmptyDownloading) -EntryType Error -EventID 5
                    $UseCachedMetadata = $false
                }
            }
            catch {
                Write-ADFSTkLog (Get-ADFSTkLanguageText importCachedMetadataCorruptDownloading) -EntryType Error -EventID 6
                $UseCachedMetadata = $false
            }
        }
        else {
            $UseCachedMetadata = $false
            Remove-Item $CachedMetadataFile -Confirm:$false
        }
    }

    if (!$UseCachedMetadata) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importDownloadingMetadataFrom) -EntryType Information
            
        try {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importDownloadingFromTo -f $metadataURL, $CachedMetadataFile) -EntryType Information
               
            $webClient = New-Object System.Net.WebClient 
            $webClient.Headers.Add("user-agent", "ADFSToolkit-v2")
            $webClient.DownloadFile($metadataURL, $CachedMetadataFile)
                
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSuccesfullyDownloadedMetadataFrom -f $metadataURL) -EntryType Information
        }
        catch {
            Write-ADFSTkLog (Get-ADFSTkLanguageText importCouldNotDownloadMetadataFrom -f $metadataURL) -MajorFault -EventID 7
        }
        
        try {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importParsingMetadataXML) -EntryType Information
            $MetadataXML = new-object Xml.XmlDocument
            $MetadataXML.PreserveWhitespace = $true
            $MetadataXML.Load($CachedMetadataFile)            
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSuccessfullyParsedMetadataXMLFrom -f $metadataURL) -EntryType Information
        }
        catch {
            Write-ADFSTkLog (Get-ADFSTkLanguageText importCouldNotParseMetadataFrom -f $metadataURL) -MajorFault -EventID 8
        }
    }

    return $MetadataXML
}
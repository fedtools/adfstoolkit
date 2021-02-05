function Get-ADFSTkFederationDefaults {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [string]
        $URL,
        [Parameter(ParameterSetName = 'Default')]    
        [switch]$InstallDefaults,
        [Parameter(ParameterSetName = 'ClearCache')]
        [switch]$ClearCache,
        [Parameter(ParameterSetName = 'Default')]
        [Parameter(ParameterSetName = 'ClearCache')]
        [switch]$Silent
    )

    process {
        #Prepare to be able to use zip files 
        Add-Type -assembly "System.IO.Compression.FileSystem"

        #Get All paths  and assert they exist 
       
        if ([string]::IsNullOrEmpty($Global:ADFSTkPaths)) {
            $Global:ADFSTkPaths = Get-ADFSTKPaths
        }   

        # setup our files
        $nowStamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
        $fedCacheFile = "federationdefaults.zip"
        $unzippedFullNameDir = Join-path $Global:ADFSTkPaths.cacheDir "federationdefaults"
        $federationConfigCacheFile = Join-Path $Global:ADFSTkPaths.cacheDir $fedCacheFile
        $adfstkConfig = Get-ADFSTkConfiguration
        $federationName = $adfstkConfig.FederationConfig.Federation.FederationName
        $federationTargetDir = Join-Path $Global:ADFSTkPaths.federationDir $federationName
 
        # Begin processing the various states for default handling

        if ($PSBoundParameters.ContainsKey('ClearCache') -and ($ClearCache -ne $null) ) {
            #Write-Output ("ADFSToolkit: Removing cache file $federationConfigCacheFile")
            Write-ADFSTkHost feddefaultsErrorFlagsElse -f $federationConfigCacheFile -Style Info

            Remove-Item  $federationConfigCacheFile
            return
        }

        #region Get defaults file from URL
        if ($PSBoundParameters.ContainsKey('URL')) {
            #Write-Output ("ADFSToolkit: Updating federation defaults on disk from: $URL")
            Write-ADFSTkHost feddefaultsCaseNoURLConfigCacheYesHeaderURLOK -f $URL -Style info

            # Begin fetch file  
            $start_time = Get-Date

            #Write-Output ("ADFSToolkit: Fetching $URL to $federationConfigCacheFile")
            Write-ADFSTkHost feddefaultsFetchBegin -f $URL, $federationConfigCacheFile -Style info
            try {
                [System.Net.WebClient]::New().DownloadFile($URL, $federationConfigCacheFile)
            }
            catch {
                Write-ADFSTkLog (Get-ADFSTkLanguageText feddefaultsCouldNotDownloadFile -f $URL) -MajorFault
            }

            #Write-Output "ADFSToolkit: Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
            Write-ADFSTkHost feddefaultsTimeTaken -f $((Get-Date).Subtract($start_time).Seconds) -Style info

            Get-ChildItem $federationConfigCacheFile -Force | Select-Object FullName, CreationTime, LastAccessTime, LastWriteTime, Mode, Length

            #  interrogate the file we just fetched
            #Write-Output ("ADFSToolkit: contents of Federation Cache file: $federationConfigCacheFile :")
            Write-ADFSTkHost feddefaultsContents  -f $federationName, $federationConfigCacheFile -Style Info
    
            $zip = [IO.Compression.ZipFile]::OpenRead($federationConfigCacheFile)
    
            $zip.Entries | Where-Object { $_.Name.StartsWith($federationName) } | Select -ExpandProperty "FullName"
            $zip.Dispose()

            # persist url in ADFSTkFederationSettings
            # verify URL exists, then persist
            if ($Global:ADFSTkPaths.mainConfigFile -ne $null) {

                [xml]$config = Get-Content $Global:ADFSTkPaths.mainConfigFile
                $config.Configuration.FederationConfig.Federation.URL = $URL
                $config.Save($Global:ADFSTkPaths.mainConfigFile)
            }
        }
        #endregion

        #region Install Defaults
        # deploy configuration that's on disk
        if (($PSBoundParameters.ContainsKey('InstallDefaults') -and ($InstallDefaults -ne $false)) -and (Test-Path ($federationConfigCacheFile))) {

            #Write-Output ("ADFSToolkit: Installing federation defaults from: $federationConfigCacheFile ...")
            Write-ADFSTkHost feddefaultsInstalling -f $federationConfigCacheFile -Style info

            $zip = [IO.Compression.ZipFile]::OpenRead($federationConfigCacheFile)

            if (Test-Path $unzippedFullNameDir) {
                Remove-Item $unzippedFullNameDir -Force -Confirm:$false -Recurse
            }

            if (!(Test-Path $unzippedFullNameDir)) {
                New-Item -ItemType Directory -Force -Path $unzippedFullNameDir | Out-Null
            }
            
            Expand-Archive -Path $federationConfigCacheFile -DestinationPath $unzippedFullNameDir -Force
            $zip.Dispose()

            if (!(Test-Path $federationTargetDir)) {
                New-Item -ItemType Directory -Force -Path $federationTargetDir | Out-Null
            }
            
            $backupDir = Join-Path $Global:ADFSTkPaths.federationBackupDir ("{0}_{1}" -f $federationName, [DateTime]::Now.ToString("yyyyMMdd-HHmmss"))
            foreach ($file in (Get-ChildItem $unzippedFullNameDir -Filter "$federationName*" -Recurse -File)) {
                $targetFile = Join-Path $federationTargetDir $file.Name
                if (Test-Path $targetFile) {
                    if (!(Test-Path $backupDir))
                    {
                        New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
                    }
                    $backupFile = Join-Path $backupDir $file.Name
                    Move-Item $targetFile $backupFile -Confirm:$false
                }
                
                Copy-Item $file.FullName $federationTargetDir -Confirm:$false
            }

            #Write-Output ("ADFSToolkit: Done. Next time a new aggregate is configured, defaults will be used. Existing configurations should remain unchanged")
            Write-ADFSTkHost feddefaultsUnchanged -Style Info
        }
        else {
            Write-Output " "
            #Write-Output "ADFSToolkit: Federation defaults not installed into ADFSToolkit. Specify -InstallDefaults to apply them."
            Write-ADFSTkHost feddefaultsNotInstalled -Style Info
        }
        Write-ADFSTkHost feddefaultsAllDone -Style Info
    }
    #endregion
}

<#
.SYNOPSIS
   show,fetch, and install federation defaults zip bundle to augment ADFSToolkit behaviour
   
.DESCRIPTION
   show,fetch, and install federation defaults zip bundle.
   ADFSToolkit will use default behaviour otherwise
.EXAMPLE
get-ADFSTkFederationDefaults
.EXAMPLE
get-ADFSTkFederationDefaults -URL https://someurl/fed.zip
.EXAMPLE
get-ADFSTkFederationDefaults -InstallDefaults -URL https://someurl/fed.zip

#>
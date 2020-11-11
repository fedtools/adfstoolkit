function get-ADFSTkFederationDefaults
{
 [CmdletBinding()]
    param (
        $URL,
        [switch]$InstallDefaults,
        $ExtractionFilter ="ADFSToolkit/config/federation",
        [switch]$ClearCache,
        [switch]$Silent
    )

process 
{
    #Prepare to be able to use zip files 
    Add-Type -assembly "system.io.compression.filesystem"

    #Get All paths  and assert they exist 
       
    $Global:ADFSTkPaths = Get-ADFSTKPaths
        

    # setup our files
    $nowStamp=[DateTime]::Now.ToString("yyyyMMdd-HHmmss")
    $fedCacheFile="federationdefaults.zip"
    $fedCacheFileBackup="federationdefaults" +$nowStamp +".zip"
    $federationDirNameBackup="federation"+$nowStamp
 
    $federationConfigCacheFile=         Join-Path $Global:ADFSTkPaths.cacheDir $fedCacheFile
    $federationConfigCacheFileBackup=   Join-Path $Global:ADFSTkPaths.cacheDir $fedCacheFileBackup
    $federationConfigDirFullBackupPath= Join-Path $Global:ADFSTkPaths.mainBackupDir $federationDirNameBackup

# Begin processing the various states for default handling
#
#

if  ($ClearCache )
{
    If  ( ( $InstallDefaults) -or !( $URL -eq  $null)  )
    {
        Write-Output ("ADFSToolkit: When used, ClearCache flag must be the only flag used. Nothing done, exiting ")
        return

    }else
    {
        Write-Output ("ADFSToolkit: Removing cache file $federationConfigCacheFile")
        remove-item  $federationConfigCacheFile
        return

    }
}

# Use case A: no url, no config cache available
if ( ($URL -eq $null) -and !(Test-Path ( $federationConfigCacheFile )  ) )
   
    {
        
            Write-Output ("ADFSToolkit: Federation default behaviour expected with no extra federation settings.")
        
            if ($InstallDefaults)
            {
             Write-Output ("ADFSToolkit: InstallDefaults flag  found  but no defaults to apply, nothing changed, exiting.")
            }


            return
        }
# Use case B: no url, config cache detected, tell user about it
elseif ( ($URL -eq $null) -and (Test-Path ( $federationConfigCacheFile )  ) )
     {
        Write-Output ("ADFSToolkit: Federation defaults in the cache are:")

        Get-ChildItem $federationConfigCacheFile -Force | Select-Object FullName, CreationTime, LastAccessTime, LastWriteTime, Mode, Length

    }
#Use case C:  URL is not null, and  we have a file. If InstallDefaults specified make backup and deploy.
#
# Note that we  are  now using  if statements for presence as the defaults could be on disk if fetched  but not installed
# 

if ( !($URL -eq $null)  )
{

    Write-Output ("ADFSToolkit: Updating federation defaults on disk from: $URL")

    # make backup
    If (Test-Path ( $federationConfigCacheFile ) )
    {
        Write-Output ("ADFSToolkit: Backing up $fedConfigCacheFile to $fedConfigCacheFileBackup")
        Copy-item $federationConfigCacheFile -Destination $federationConfigCacheFileBackup
    }

    # Begin fetch file  
    $start_time = Get-Date

    Write-Output ("ADFSToolkit: Fetching $URL to $federationConfigCacheFile")
    (New-Object System.Net.WebClient).DownloadFile($URL, $federationConfigCacheFile)

    Write-Output "ADFSToolkit: Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

    Get-ChildItem $federationConfigCacheFile -Force | Select-Object FullName, CreationTime, LastAccessTime, LastWriteTime, Mode, Length

    #  interrogate the file we just fetched
    Write-Output ("ADFSToolkit: contents of Federation Cache file: $federationConfigCacheFile :")

    

    $zip = [io.compression.zipfile]::OpenRead($federationConfigCacheFile)
    
    $zip.Entries|where-object {$_.FullName -match $ExtractionFilter }|Select-object FullName |Select -ExpandProperty "FullName"
    $zip.Dispose()

}

    # deploy configuration that's on disk
    if ($InstallDefaults -and (Test-Path ( $federationConfigCacheFile ) )  )
    {

        Write-Output ("ADFSToolkit: Installing federation defaults from: $federationConfigCacheFile ...")
    
        $zip = [io.compression.zipfile]::OpenRead($federationConfigCacheFile)
        $unzippedDirName=($zip.Entries[0]).FullName
        $unzippedFullNameDir=Join-Path (Join-path $Global:ADFSTkPaths.cacheDir $unzippedDirName) $ExtractionFilter

        #backup previous federation-settings
        move-item  -Path $Global:ADFSTkPaths.federationDir -Destination $federationConfigDirFullBackupPath

        Expand-Archive -Path $federationConfigCacheFile -DestinationPath $Global:ADFSTkPaths.cacheDir -Force

        copy-item $unzippedFullNameDir  $Global:ADFSTkPaths.federationDir -Recurse

        $zip.Dispose()

        # persist url in ADFSTkFederationSettings
        # verify URL exists, then persist
        if ( !($URL -eq $null) -and !($Global:ADFSTkPaths.mainConfigFile -eq $null) )
        {

            [xml]$config = Get-Content $Global:ADFSTkPaths.mainConfigFile
            $config.Configuration.FederationConfig.Federation.URL= $URL
            $config.Save( $Global:ADFSTkPaths.mainConfigFile)
        }


        Write-Output ("ADFSToolkit: Done. Next time a new aggregate is configured, defaults will be used. Existing configurations should remain unchanged")
    }
     else
    {
        Write-Output " "
        Write-Output "ADFSToolkit: Federation defaults not installed into ADFSToolkit. Specify -InstallDefaults to apply them."

    }


    return

    

Write-Output  ("ADFSToolkit: Federation Defaults done.")

}


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
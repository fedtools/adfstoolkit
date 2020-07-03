#Requires -Version 5.1
#Requires -RunAsAdministrator

function Import-ADFSTkMetadata 
{

    [CmdletBinding(DefaultParameterSetName='AllSPs',
                    SupportsShouldProcess=$true)]
    param (
        [Parameter(ParameterSetName='SingleSP',
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $EntityId,
        [Parameter(ParameterSetName='SingleSP',
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            Position=1)]
        $EntityBase,
        [string]$ConfigFile,
        [string]$LocalMetadataFile,
        [string[]]$ForcedEntityCategories,
        [Parameter(ParameterSetName='AllSPs')]
        [switch]
        $ProcessWholeMetadata,
        [switch]$ForceUpdate,
        [Parameter(ParameterSetName='AllSPs')]
        [switch]
        $AddRemoveOnly,
        #The time in minutes the chached metadatafile live
        [int]
        $CacheTime = 15,
        #The maximum SPs to add in one run (to prevent throttling). Is used when the script recusrive calls itself
        [int]
        $MaxSPAdditions = 80,
        [switch]$Silent,
        [switch]$criticalHealthChecksOnly
    )


process 
{
    #$CompatibleConfigVersion = "1.3"

    #Get All paths
    if ([string]::IsNullOrEmpty($Global:ADFSTkPaths))
    {
        $Global:ADFSTkPaths = Get-ADFSTKPaths
    }

    try {
        # Add some variables
        $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
        $utf8 = new-object -TypeName System.Text.UTF8Encoding

        # load configuration file
        if (!(Test-Path ( $ConfigFile )))
        {
            throw (Get-ADFSTkLanguageText cFileDontExist -f $ConfigFile)
        }
        else
        {
            [xml]$Settings = Get-Content ($ConfigFile)
        }

        # set appropriate logging via EventLog mechanisms

        if (Verify-ADFSTkEventLogUsage)
        {
            #If we evaluated as true, the eventlog is now set up and we link the WriteADFSTklog to it
            Write-ADFSTkLog -SetEventLogName $Settings.configuration.logging.LogName -SetEventLogSource $Settings.configuration.logging.Source

        }
        else 
        {
            # No Event logging is enabled, just this one to a file
            Write-ADFSTkLog (Get-ADFSTkLanguageText importEventLogMissingInSettings) -MajorFault            
        }

        #Check against compatible version
        #if ([float]$Settings.configuration.ConfigVersion -lt [float]$CompatibleConfigVersion)
        #{
        #    Write-ADFSTkLog (Get-ADFSTkLanguageText importIncompatibleInstitutionConfigVersion -f $Settings.configuration.ConfigVersion, $CompatibleConfigVersion) -MajorFault
        #}
        if ($PSBoundParameters.ContainsKey('criticalHealthChecksOnly') -and $criticalHealthChecksOnly -ne $false)
        {
            $healthCheckResult = Get-ADFSTkHealth -ConfigFile $ConfigFile -HealthCheckMode CriticalOnly
        }
        else
        {
            $healthCheckResult = Get-ADFSTkHealth -ConfigFile $ConfigFile -HealthCheckMode Full
        }

        if ($healthCheckResult -eq $false)
        {
            Write-ADFSTkLog "The Health Check of ADFS Toolkit did not pass! Check earlier log entries to see what's wrong." -MajorFault
        }

    #region Get static values from configuration file
    $mypath= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')

    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importStarted) -EntryType Information
    Write-ADFSTkLog (Get-ADFSTkLanguageText importCurrentPath -f $Global:ADFSTkPaths.modulePath) -EventID 1

    #endregion


    #region Get SP Hash
    if ([string]::IsNullOrEmpty($Settings.configuration.SPHashFile))
    {
        Write-ADFSTkLog  (Get-ADFSTkLanguageText importMissingSPHashFileInConfig -f $ConfigFile) -MajorFault
    }
    else
    {
        $SPHashFile = Join-Path $Global:ADFSTkPaths.cacheDir $Settings.configuration.SPHashFile
        Write-ADFSTkLog (Get-ADFSTkLanguageText importSettingSPHashFileTo -f $SPHashFile) -EventID 2
    }

    if (Test-Path $SPHashFile)
    {
        try 
        {
            $SPHashList = Import-Clixml $SPHashFile
        }
        catch
        {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importCouldNotImportSPHashFile)
            $SPHashFileItem  = Get-ChildItem $SPHashFile
            Rename-Item -Path $SPHashFile -NewName ("{0}_{1}.{2}" -f $SPHashFileItem.BaseName, ([guid]::NewGuid()).Guid, $SPHashFileItem.Extension)
            $SPHashList = @{}
        }
    }
    else
    {
        $SPHashList = @{}
    }

    #endregion



    #region Getting Metadata

    #Cached Metadata file
    #$CachedMetadataFile = Join-Path $Settings.configuration.WorkingPath -ChildPath $Settings.configuration.CacheDir | Join-Path -ChildPath $Settings.configuration.MetadataCacheFile
    $CachedMetadataFile = Join-Path $Global:ADFSTkPaths.cacheDir $Settings.configuration.MetadataCacheFile
    
    Write-ADFSTkLog (Get-ADFSTkLanguageText importSettingCachedMetadataFile -f $CachedMetadataFile) -EventID 3


    if ($LocalMetadataFile)
    {
        try
        {
            $MetadataXML = new-object Xml.XmlDocument
            $MetadataXML.PreserveWhitespace = $true
            $MetadataXML.Load($LocalMetadataFile)
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSuccessfullyLoadedLocalMetadataFile) -EntryType Information
        }
        catch
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText importCouldNotLoadLocalMetadataFile) -MajorFault -EventID 4
        }
    }

    if ($MetadataXML -eq $null)
    {
#        $UseCachedMetadata = $false
#        if (($CacheTime -eq -1 -or $CacheTime -gt 0) -and (Test-Path $CachedMetadataFile)) #CacheTime = -1 allways use cached metadata if exists
#        {
#            if ($CacheTime -eq -1 -or (Get-ChildItem $CachedMetadataFile).LastWriteTime.AddMinutes($CacheTime) -ge (Get-Date))
#            {
#                $UseCachedMetadata =  $true
#                try 
#                {
#                    #[xml]$MetadataXML = Get-Content $CachedMetadataFile
#                    $MetadataXML = new-object Xml.XmlDocument
#                    $MetadataXML.PreserveWhitespace = $true
#                    $MetadataXML.Load($CachedMetadataFile)
#                    
#                    if ([string]::IsNullOrEmpty($MetadataXML))
#                    {
#                        Write-ADFSTkLog (Get-ADFSTkLanguageText importCachedMetadataEmptyDownloading) -EntryType Error -EventID 5
#                        $UseCachedMetadata =  $false
#                    }
#                }
#                catch
#                {
#                    Write-ADFSTkLog (Get-ADFSTkLanguageText importCachedMetadataCorruptDownloading) -EntryType Error -EventID 6
#                    $UseCachedMetadata =  $false
#                }
#            }
#            else
#            {
#                $UseCachedMetadata = $false
#                Remove-Item $CachedMetadataFile -Confirm:$false
#            }
#        }
#
#        if (!$UseCachedMetadata)
#        {
#            
#            #Get Metadata URL from config
#            if ([string]::IsNullOrEmpty($Settings.configuration.metadataURL))
#            {
#                $metadataURL = 'https://localhost/metadata.xml' #Just for fallback
#            }
#            else
#            {
#                $metadataURL = $Settings.configuration.metadataURL
#            }
#
#            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importDownloadingMetadataFrom) -EntryType Information
#            
#            try
#            {
#                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importDownloadingFromTo -f $metadataURL, $CachedMetadataFile) -EntryType Information
#               
#                $webClient = New-Object System.Net.WebClient 
#                $webClient.Headers.Add("user-agent", "ADFSToolkit")
#                $webClient.DownloadFile($metadataURL, $CachedMetadataFile)
#                
#                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSuccesfullyDownloadedMetadataFrom -f $metadataURL) -EntryType Information
#            }
#            catch
#            {
#                Write-ADFSTkLog (Get-ADFSTkLanguageText importCouldNotDownloadMetadataFrom -f $metadataURL) -MajorFault -EventID 7
#            }
#        
#            try
#            {
#                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importParsingMetadataXML) -EntryType Information
#                $MetadataXML = new-object Xml.XmlDocument
#                $MetadataXML.PreserveWhitespace = $true
#                $MetadataXML.Load($CachedMetadataFile)            
#                #$MetadataXML = [xml]$Metadata.Content
#                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSuccessfullyParsedMetadataXMLFrom -f $metadataURL) -EntryType Information
#            }
#            catch
#            {
#                Write-ADFSTkLog (Get-ADFSTkLanguageText importCouldNotParseMetadataFrom -f $metadataURL) -MajorFault -EventID 8
#            }
#        }
        $MetadataXML = Get-ADFSTkMetadata -CacheTime $CacheTime -CachedMetadataFile $CachedMetadataFile -metadataURL $Settings.configuration.metadataURL
    }

    # Assert that the metadata we are about to process is not zero bytes after all this


    if (Test-Path $CachedMetadataFile) 
    {
        $MyFileSize=(Get-Item $CachedMetadataFile).length 
    
        if ((Get-Item $CachedMetadataFile).length -gt 0kb) 
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText importMetadataFileSize -f $MyFileSize) -EventID 9
        } 
        else 
        {
            Write-ADFSTkLog (Get-ADFSTkLanguageText importCachedMetadataFileIsZeroBytes -f $CachedMetadataFile) -EventID 10
        }
    }
    #endregion

    #Verify Metadata Signing Cert
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importVerifyingSigningCert) -EntryType Information
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importEnsuringSHA256) -EntryType Information
  
    Update-SHA256AlgXmlDSigSupport

    if (Verify-ADFSTkSigningCert $MetadataXML.EntitiesDescriptor.Signature.KeyInfo.X509Data.X509Certificate)
    {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSuccessfullyVerifiedMetadataCert) -EntryType Information
    }
    else
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText importMetadataCertIncorrect) -MajorFault -EventID 11
    }

    #Verify Metadata Signature
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importVerifyingMetadataSignature) -EntryType Information
    if (Verify-ADFSTkMetadataSignature $MetadataXML)
    {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSuccessfullyVerifiedMetadataSignature) -EntryType Information
    }
    else
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText importMetadataSignatureFailed) -MajorFault -EventID 12
    }

    #region Read/Create file with 


    $RawAllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null}
    $myRawAllSPsCount= $RawALLSps.count
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importTotalNumberOfSPs -f $myRawAllSPsCount)


    if ($ProcessWholeMetadata)
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText importProcessingWholeMetadata) -EntryType Information -EventID 13
   
        $AllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null}

        $myAllSPsCount= $ALLSPs.count
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importNumberOfSPsAfterFilter -f $myAllSPsCount)

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importCalculatingChanges)
        $AllSPs | % {
            $SwamidSPs = @()
            $SwamidSPsToProcess = @()
        }{
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cWorkingWith -f $_.EntityID)

            $SwamidSPs += $_.EntityId
            if (Check-ADFSTkSPHasChanged $_)
            {
                $SwamidSPsToProcess += $_
            }
            #else
            #{
            #    Write-ADFSTkVerboseLog "Skipped due to no changes in metadata..."
            #}

        }{
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
            $n = $SwamidSPsToProcess.Count
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importFoundXNewChangedSPs -f $n)
            $batches = [Math]::Ceiling($n/$MaxSPAdditions)
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importBatchCount -f $batches)

            if ($n -gt 0)
            {
                if ($batches -gt 1)
                {
                    for ($i = 1; $i -le $batches; $i++)
                    {
                        $ADFSTkModuleBase = Join-Path $Global:ADFSTkPaths.modulePath ADFSToolkit.psm1
                        Write-ADFSTkLog (Get-ADFSTkLanguageText importWorkingWithBatch -f $i, $batches, $ADFSTkModuleBase) -EventID 14
                       
                        $runCommand = "-Command & {"

                        if ($Global:ADFSTkSkipNotSignedHealthCheck -eq $true)
                        {
                            $runCommand += "$Global:ADFSTkSkipNotSignedHealthCheck = $true;"
                        }
                        
                        $runCommand += "Import-ADFSTkMetadata -MaxSPAdditions $MaxSPAdditions -CacheTime -1 -ConfigFile '$ConfigFile'"
                        
                        if ($PSBoundParameters.ContainsKey("Silent") -and $Silent -ne $false)
                        {
                            $runCommand += " -Silent"
                        }

                        if ($PSBoundParameters.ContainsKey("criticalHealthChecksOnly") -and $criticalHealthChecksOnly -ne $false)
                        {
                            $runCommand += " -criticalHealthChecksOnly"
                        }
                        
                        if ($PSBoundParameters.ContainsKey("ForceUpdate") -and $ForceUpdate -ne $false)
                        {
                            $runCommand += " -ForceUpdate"
                        }
                        
                        if ($PSBoundParameters.ContainsKey("WhatIf") -and $WhatIf -ne $false)
                        {
                            $runCommand += " -WhatIf"
                        }
                        
                        $runCommand += " ;Exit}"

                        Start-Process -WorkingDirectory $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') -FilePath "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoExit", $runCommand -Wait -NoNewWindow
                        Write-ADFSTkLog (Get-ADFSTkLanguageText cDone) -EventID 15
                    }
                }
                else
                {
                    $SwamidSPsToProcess | % {
                        Processes-ADFSTkRelyingPartyTrust $_
                    }
                }
            }

            # Checking if any Relying Party Trusts show be removed
            
           

        $NamePrefix = $Settings.configuration.MetadataPrefix 
        $Sep= $Settings.configuration.MetadataPrefixSeparator      
        $FilterString="$NamePrefix$Sep"

            Write-ADFSTkLog (Get-ADFSTkLanguageText importCheckingForRemovedRPsUsingFilter -f $FilterString) -EventID 16

            $CurrentSwamidSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "$FilterString*"} | select -ExpandProperty Identifier
            if ($CurrentSwamidSPs -eq $null)
            {
                $CurrentSwamidSPs = @()
            }

            #$RemoveSPs = Compare-ADFSTkObject $CurrentSwamidSPs $SwamidSPs | ? SideIndicator -eq "<=" | select -ExpandProperty InputObject
            $CompareSets = Compare-ADFSTkObject -FirstSet $CurrentSwamidSPs -SecondSet $SwamidSPs -CompareType InFirstSetOnly

            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importFoundRPsToRemove -f $CompareSets.MembersInCompareSet)

            if ($ForceUpdate)
            {
                foreach ($rp in $CompareSets.CompareSet)
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cRemoving -f $rp)
                    try 
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
                    }
                    catch
                    {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText cCouldNotRemove -f $rp, $_) -EntryType Error -EventID 17
                    }
                }
            }
            else
            {
                foreach ($rp in ($CompareSets.CompareSet | Get-ADFSTkAnswer -Caption (Get-ADFSTkLanguageText importDoYouWantToRemoveRPsNotInMetadata)))
                {
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cRemoving -f $rp)
                    try 
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cDone)
                    }
                    catch
                    {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText importCouldNotRemove -f $rp, $_) -EntryType Error -EventID 18
                    }
                }
            }
        }
    }
    elseif($PSBoundParameters.ContainsKey('MaxSPAdditions') -and $MaxSPAdditions -gt 0)
    {
        Write-ADFSTkLog (Get-ADFSTkLanguageText importProcessingXRPs -f $MaxSPAdditions) -EntryType Information -EventID 19
       
        $AllSPsInMetadata = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null }

        $i = 0
        $n = 0
        $m = $AllSPsInMetadata.Count - 1
        $SPsToProcess = @()
        do
        {
            if (Check-ADFSTkSPHasChanged $AllSPsInMetadata[$i])
            {
                $SPsToProcess += $AllSPsInMetadata[$i]
                $n++
            }
            else
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importSkippedNoChanges)
            }
            $i++
        }
        until ($n -ge $MaxSPAdditions -or $i -ge $m)

        $SPsToProcess | % {
            Processes-ADFSTkRelyingPartyTrust $_
        }
    }
    elseif(! ([string]::IsNullOrEmpty($EntityID) ) )
    {
    #Enter so that SP: N is checked against the can and ask if you want to force update. Insert the hash!

        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cWorkingWith -f $EntityID)
        if ([string]::IsNullOrEmpty($EntityBase)) {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId}
        }
        else {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId -and $_.base -eq $EntityBase}
        }

        if ($sp.count -gt 1) { 
            $sp = $sp[0]
            Write-ADFSTkLog (Get-ADFSTkLanguageText importMoreThanOneRPWithEntityID -f $EntityId) -EntryType Warning -EventID 29
        }

        if ([string]::IsNullOrEmpty($sp)){
            Write-ADFSTkLog (Get-ADFSTkLanguageText importNoSPsFound) -MajorFault -EventID 20
        }
        else {
            Processes-ADFSTkRelyingPartyTrust $sp
        }
    }
    else 
    {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importNothingToDo)
    }

    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText importScriptEnded)

    }
        Catch
        {
            Throw $_
        }
    }
}
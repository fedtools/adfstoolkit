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
        $CacheTime = 60,
        #The maximum SPs to add in one run (to prevent throttling). Is used when the script recusrive calls itself
        [int]
        $MaxSPAdditions = 80
    )


    process 
    {


    try {


    # Add some variables
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding

    # load configuration file
    if (!(Test-Path ( $ConfigFile )))
    {
   
        Write-Error -message "Msg: Path:$mypath configFile: $ConfigFile" 
        throw "throwing. Path:$mypath configfile:$ConfigFile" 
    }
    else
    {
        [xml]$Settings=Get-Content ($ConfigFile)
    }


    # set appropriate logging via EventLog mechanisms

        if (Verify-ADFSTkEventLogUsage)
        {
            #If we evaluated as true, the eventlog is now set up and we link the WriteADFSTklog to it
            Write-ADFSTkLog   -SetEventLogName $Settings.configuration.logging.LogName -SetEventLogSource $Settings.configuration.logging.Source

        }
        else {

            # No Event logging is enabled, just this one to a file
            Throw "Missing eventlog settings in config,"   
    
    }

    #region Get static values from configuration file
    $mypath= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')

    $myVersion=(get-module ADFSToolkit).version.ToString()

    Write-ADFSTkVerboseLog "Import-ADFSTkMetadata $myVersion started" -EntryType Information
    Write-ADFSTkLog "Import-ADFSTkMetadata path: $mypath"

    #endregion


    #region Get SP Hash
    if ([string]::IsNullOrEmpty($Settings.configuration.SPHashFile))
    {
         Write-Error -message "Halting: Missing SPHashFile setting from  $ConfigFile" 
        throw "SPHashFile missing from configfile"
    }
    else
    {
        $SPHashFile = Join-Path $Settings.configuration.WorkingPath -ChildPath $Settings.configuration.CacheDir | Join-Path -ChildPath $Settings.configuration.SPHashFile
            Write-ADFSTkLog "Setting SPHashFile to: $SPHashFile"
    }

    if (Test-Path $SPHashFile)
    {
        try 
        {
            $SPHashList = Import-Clixml $SPHashFile
        }
        catch
        {
            Write-ADFSTkVerboseLog "Could not import SP Hash File!"
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
    $CachedMetadataFile = Join-Path $Settings.configuration.WorkingPath -ChildPath $Settings.configuration.CacheDir | Join-Path -ChildPath $Settings.configuration.MetadataCacheFile
    #Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\cache\') SwamidMetadata.cache.xml
Write-ADFSTkLog "Setting CachedMetadataFile to: $CachedMetadataFile"


    if ($LocalMetadataFile)
    {
        try
        {
            $MetadataXML = new-object Xml.XmlDocument
            $MetadataXML.PreserveWhitespace = $true
            $MetadataXML.Load($LocalMetadataFile)
            Write-ADFSTkVerboseLog "Successfully loaded local MetadataFile..." -EntryType Information
        }
        catch
        {
            Write-ADFSTkLog "Could not load LocalMetadataFile!" -MajorFault
        }
    }

    if ($MetadataXML -eq $null)
    {
        $UseCachedMetadata = $false
        if (($CacheTime -eq -1 -or $CacheTime -gt 0) -and (Test-Path $CachedMetadataFile)) #CacheTime = -1 allways use cached metadata if exists
        {
            if ($CacheTime -eq -1 -or (Get-ChildItem $CachedMetadataFile).LastWriteTime.AddMinutes($CacheTime) -ge (Get-Date))
            {
                $UseCachedMetadata =  $true
                try 
                {
                    #[xml]$MetadataXML = Get-Content $CachedMetadataFile
                    $MetadataXML = new-object Xml.XmlDocument
                    $MetadataXML.PreserveWhitespace = $true
                    $MetadataXML.Load($CachedMetadataFile)
                    
                    if ([string]::IsNullOrEmpty($MetadataXML))
                    {
                        Write-ADFSTkLog "Cached Metadata file was empty. Downloading instead!" -EntryType Error
                        $UseCachedMetadata =  $false
                    }
                }
                catch
                {
                    Write-ADFSTkLog "Could not parse cached Metadata file. Downloading instead!" -EntryType Error
                    $UseCachedMetadata =  $false
                }
            }
            else
            {
                $UseCachedMetadata = $false
                Remove-Item $CachedMetadataFile -Confirm:$false
            }
        }

        if (!$UseCachedMetadata)
        {
            
            #Get Metadata URL from config
            if ([string]::IsNullOrEmpty($Settings.configuration.metadataURL))
            {
                $metadataURL = 'https://localhost/metadata.xml' #Just for fallback
            }
            else
            {
                $metadataURL = $Settings.configuration.metadataURL
            }

            Write-ADFSTkVerboseLog "Downloading Metadata from $metadataURL " -EntryType Information
            
            try
            {
               


            Write-ADFSTkVerboseLog "Downloading From: $metadataURL to file $CachedMetadataFile" -EntryType Information
               
                #$Metadata = Invoke-WebRequest $metadataURL -OutFile $CachedMetadataFile -PassThru
                $myUserAgent = "ADFSToolkit/"+(get-module ADFSToolkit).Version.toString()
 
                $webClient = New-Object System.Net.WebClient 
                $webClient.Headers.Add("user-agent", "$myUserAgent")
                $webClient.DownloadFile($metadataURL, $CachedMetadataFile) 
                
                Write-ADFSTkVerboseLog "Successfully downloaded Metadata from $metadataURL" -EntryType Information
            }
            catch
            {
                Write-ADFSTkLog "Could not download Metadata from $metadataURL" -MajorFault
            }
        
            try
            {
                Write-ADFSTkVerboseLog "Parsing downloaded Metadata XML..." -EntryType Information
                $MetadataXML = new-object Xml.XmlDocument
                $MetadataXML.PreserveWhitespace = $true
                $MetadataXML.Load($CachedMetadataFile)            
                #$MetadataXML = [xml]$Metadata.Content
                Write-ADFSTkVerboseLog "Successfully parsed downloaded Metadata from $metadataURL" -EntryType Information
            }
            catch
            {
                Write-ADFSTkLog "Could not parse downloaded Metadata from $metadataURL" -MajorFault
            }
        }
    }

    # Assert that the metadata we are about to process is not zero bytes after all this


    if (Test-Path $CachedMetadataFile) {

            $MyFileSize=(Get-Item $CachedMetadataFile).length 
            if ((Get-Item $CachedMetadataFile).length -gt 0kb) {
            Write-ADFSTkLog "Metadata file size is $MyFileSize"
            } else {
    
            Write-ADFSTkLog "Note: $CachedMetadataFile  is 0 bytes" 
        
         }
    }
    #endregion

    #Verify Metadata Signing Cert
    Write-ADFSTkVerboseLog "Verifying metadata signing cert..." -EntryType Information
  
    Write-ADFSTkVerboseLog "Ensuring SHA256 Signature validation is present..." -EntryType Information
    Update-SHA256AlgXmlDSigSupport


    if (Verify-ADFSTkSigningCert $MetadataXML.EntitiesDescriptor.Signature.KeyInfo.X509Data.X509Certificate)
    {
        Write-ADFSTkVerboseLog "Successfully verified metadata signing cert!" -EntryType Information
    }
    else
    {
        Write-ADFSTkLog "Metadata signing cert is incorrect! Please check metadata URL or signature fingerprint in config." -MajorFault
    }

    #Verify Metadata Signature
    Write-ADFSTkVerboseLog "Verifying metadata signature..." -EntryType Information
    if (Verify-ADFSTkMetadataSignature $MetadataXML)
    {
        Write-ADFSTkVerboseLog "Successfully verified metadata signature!" -EntryType Information
    }
    else
    {
        Write-ADFSTkLog "Metadata signature test did not pass. Aborting!" -MajorFault
    }

    #region Read/Create file with 


     $RawAllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null}
        $myRawAllSPsCount= $RawALLSps.count
        Write-ADFSTkVerboseLog "Total number of Sps observed: $myRawAllSPsCount"


    if ($ProcessWholeMetadata)
    {
        Write-ADFSTkLog "Processing whole Metadata file..." -EntryType Information
   
        $AllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null}
#        $AllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null -and $_.Extensions -ne $null}

        $myAllSPsCount= $ALLSPs.count
        Write-ADFSTkVerboseLog "Total number of Sps observed post filter selection: $myAllSPsCount"

        Write-ADFSTkVerboseLog "Calculating changes..."
        $AllSPs | % {
            $SwamidSPs = @()
            $SwamidSPsToProcess = @()
        }{
            Write-ADFSTkVerboseLog "Working with `'$($_.EntityID)`'..."

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
            Write-ADFSTkVerboseLog "Done!"
            $n = $SwamidSPsToProcess.Count
            Write-ADFSTkVerboseLog "Found $n new/changed SPs."
            $batches = [Math]::Ceiling($n/$MaxSPAdditions)
            Write-ADFSTkVerboseLog "Batches count: $batches"

            if ($n -gt 0)
            {
                if ($batches -gt 1)
                {
                    for ($i = 1; $i -le $batches; $i++)
                    {
                        $ADFSTkModuleBase= Join-Path (get-module ADFSToolkit).ModuleBase ADFSToolkit.psm1
                        Write-ADFSTkLog "Working with batch $($i)/$batches with $ADFSTkModuleBase"
                       
                        Start-Process -WorkingDirectory $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') -FilePath "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoExit", "-Command & {Get-Module -ListAvailable ADFSToolkit |Import-Module ; Import-ADFSTkMetadata -MaxSPAdditions $MaxSPAdditions -CacheTime -1 -ForceUpdate -ConfigFile '$ConfigFile' ;Exit}" -Wait -NoNewWindow
                        Write-ADFSTkLog "Done!"
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

            Write-ADFSTkLog "Checking for Relying Parties removed from Metadata using Filter:$FilterString* ..." 

            $CurrentSwamidSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "$FilterString*"} | select -ExpandProperty Identifier

            #$RemoveSPs = Compare-ADFSTkObject $CurrentSwamidSPs $SwamidSPs | ? SideIndicator -eq "<=" | select -ExpandProperty InputObject
            $CompareSets = Compare-ADFSTkObject -FirstSet $CurrentSwamidSPs -SecondSet $SwamidSPs -CompareType InFirstSetOnly

            Write-ADFSTkVerboseLog "Found $($CompareSets.MembersInCompareSet) RPs that should be removed."

            if ($ForceUpdate)
            {
                foreach ($rp in $CompareSets.CompareSet)
                {
                    Write-ADFSTkVerboseLog "Removing `'$($rp)`'..."
                    try 
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                        Write-ADFSTkVerboseLog "Done!"
                    }
                    catch
                    {
                        Write-ADFSTkLog "Could not remove `'$($rp)`'! Error: $_" -EntryType Error
                    }
                }
            }
            else
            {
                # $RemoveSPs | Get-ADFSTkAnswer -Caption "Do you want to remove Relying Party trust that are not in Swamid metadata?" | Remove-ADFSRelyingPartyTrust -Confirm:$false 
                foreach ($rp in ($CompareSets.CompareSet | Get-ADFSTkAnswer -Caption "Do you want to remove Relying Party trust that are not in Swamid metadata?"))
                {
                    Write-ADFSTkVerboseLog "Removing `'$($rp)`'..."
                    try 
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                        Write-ADFSTkVerboseLog "Done!"
                    }
                    catch
                    {
                        Write-ADFSTkLog "Could not remove `'$($rp)`'! Error: $_" -EntryType Error
                    }
                }
            }
        }
    }
    elseif($PSBoundParameters.ContainsKey('MaxSPAdditions') -and $MaxSPAdditions -gt 0)
    {
        Write-ADFSTkLog "Processing $MaxSPAdditions SPs..." -EntryType Information
       
        $AllSPsInMetadata = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null }
#        $AllSPsInMetadata = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null -and $_.Extensions -ne $null}

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
                Write-ADFSTkVerboseLog "Skipped due to no changes in metadata..."
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

        Write-ADFSTkVerboseLog "Working with `'$EntityID`'..."
        if ([string]::IsNullOrEmpty($EntityBase)) {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId}
        }
        else {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId -and $_.base -eq $EntityBase}
        }

        if ($sp.count -gt 1) {
            $tmpSP = $null
            $sp | % {
                if (![string]::IsNullOrEmpty($_.Extensions.RegistrationInfo))
                {
                    $tmpSP = $_
                }
            }

            if ($tmpSP -ne $null)
            {
                $sp = $tmpSP
            }
            else
            {
                $sp = $sp[0]
            }
        }

        if ([string]::IsNullOrEmpty($sp)){
            Write-ADFSTkLog "No SP found!" -MajorFault
        }
        else {
            Processes-ADFSTkRelyingPartyTrust $sp
        }
    }else {
        Write-ADFSTkVerboseLog "Invoked without -ProcessWholeMetadata <no args> , -EntityID <with quoted URL>, nothing to do, exiting"
    }

    Write-ADFSTkVerboseLog "Script ended!"

    }
        Catch
        {
            Throw $_
        }
    }
}
function Import-FedMetadata 
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
        [string]$LocalMetadataFile,
        [string[]]$ForcedEntityCategories,
        [Parameter(ParameterSetName='AllSPs')]
        [switch]
        $ProcessWholeMetadata,
        [switch]$ForceUpdate,
        [Parameter(ParameterSetName='AllSPs')]
        [switch]
        $AddRemoveOnly,
        [string]$LogToPath,
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

     
    $CmdLet =  Load-CmdLet Write-Log
    . $CmdLet
    $CmdLet =  Load-CmdLet Get-Answer
    . $CmdLet
    $CmdLet =  Load-CmdLet Compare-Object
    . $CmdLet
    $CmdLet =  Load-CmdLet Split-Collection
    . $CmdLet


    if (Test-Path 'C:\Powershell Scripts\ADFS\Import-SWAMIDEntityCategoryBuilder.ps1')
    {
    . 'C:\Powershell Scripts\ADFS\Import-SWAMIDEntityCategoryBuilder.ps1'
    }
    elseif (Test-Path 'C:\Powershell Scripts\Import-SWAMIDEntityCategoryBuilder.ps1')
    {
    . 'C:\Powershell Scripts\Import-SWAMIDEntityCategoryBuilder.ps1'
    }
    elseif(Test-Path (Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') Import-SWAMIDEntityCategoryBuilder.ps1))
    {
    . (Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') Import-SWAMIDEntityCategoryBuilder.ps1)
    }
    else
    {
        Write-Log "Could not import Import-SWAMIDEntityCategoryBuilder.ps1! Is it missing?" -Majorfault
    }

    # Add some variables
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding


    if (![string]::IsNullOrEmpty($LogToPath)) {
        Write-Log -SetLogFilePath $LogToPath
    }

    Write-VerboseLog "Script started" -EntryType Information

    #region Get static values from configuration file

    if (!(Test-Path (Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') Import-SWAMIDMetadata.config.xml)))
    {
        throw "Could not find 'Import-SWAMIDMetadata.config.xml'. Please put the file in the same directory as Import-SWAMIDMetadata.ps1"
    }
    else
    {
        [xml]$Settings=Get-Content (Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') Import-SWAMIDMetadata.config.xml)
    }

    #endregion

    #region Get SP Hash
    if ([string]::IsNullOrEmpty($Settings.configuration.SPHashFile))
    {
        $SPHashFile = $Settings.configuration.SPHashFile
    }
    else
    {
        $SPHashFile = (Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') SPHashFile.xml) #Just a fallback
    }

    if (Test-Path $SPHashFile)
    {
        try 
        {
            $SPHashList = Import-Clixml $SPHashFile
        }
        catch
        {
            Write-VerboseLog "Could not import SP Hash File!"
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
    $CachedMetadataFile = Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') SwamidMetadata.cache.xml
    #$CachedMetadataXML = $null

    #Load the cached Metadata if it exists
    #if (Test-Path $CachedMetadataFile)
    #{
    #    try 
    #    {
    #        Write-VerboseLog "Parsing cached Metadata XML..." -EntryType Information
    #        [xml]$CachedMetadataXML = Get-Content $CachedMetadataFile
    #        Write-VerboseLog "Successfully parsed cached Metadata XML!" -EntryType Information
    #    }
    #    catch 
    #    {
    #        Write-Log "Could not parse cached Metadata!" 
    #    }
    #}

    if ($LocalMetadataFile)
    {
        try
        {
            #[xml]$MetadataXML = Get-Content $LocalMetadataFile
            $MetadataXML = new-object Xml.XmlDocument
            $MetadataXML.PreserveWhitespace = $true
            $MetadataXML.Load($LocalMetadataFile)
            Write-VerboseLog "Successfully loaded local MetadataFile..." -EntryType Information
        }
        catch
        {
            Write-Log "Could not load LocalMetadataFile!" -MajorFault
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
                        Write-Log "Cached Metadata file was empty. Downloading instead!" -EntryType Error
                        $UseCachedMetadata =  $false
                    }
                }
                catch
                {
                    Write-Log "Could not parse cached Metadata file. Downloading instead!" -EntryType Error
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
            Write-VerboseLog "Downloading Metadata from SWAMID..." -EntryType Information
            
            #Get Metadata URL from config
            if ([string]::IsNullOrEmpty($Settings.configuration.metadataURL))
            {
                $metadataURL = 'https://mds.swamid.se/md/swamid-2.0.xml' #Just for fallback
            }
            else
            {
                $metadataURL = $Settings.configuration.metadataURL
            }

            try
            {
                #$Metadata = Invoke-WebRequest $metadataURL -OutFile $CachedMetadataFile -PassThru
                $webClient = New-Object System.Net.WebClient 
                $webClient.DownloadFile($metadataURL, $CachedMetadataFile) 
                
                Write-VerboseLog "Successfully downloaded Metadata from SWAMID!" -EntryType Information
            }
            catch
            {
                Write-Log "Could not download Metadata from SWAMID!" -MajorFault
            }
        
            try
            {
                Write-VerboseLog "Parsing downloaded Metadata XML..." -EntryType Information
                $MetadataXML = new-object Xml.XmlDocument
                $MetadataXML.PreserveWhitespace = $true
                $MetadataXML.Load($CachedMetadataFile)            
                #$MetadataXML = [xml]$Metadata.Content
                Write-VerboseLog "Successfully parsed downloaded Metadata XML!" -EntryType Information
            }
            catch
            {
                Write-Log "Could not parse downloaded Metadata from SWAMID!" -MajorFault
            }
        }
    }

    #endregion

    #Verify Metadata Signing Cert
    Write-VerboseLog "Verifying metadata signing cert..." -EntryType Information
    if (Verify-SigningCert $MetadataXML.EntitiesDescriptor.Signature.KeyInfo.X509Data.X509Certificate)
    {
        Write-VerboseLog "Successfully verified metadata signing cert!" -EntryType Information
    }
    else
    {
        Write-Log "Metadata signing cert is incorrect! Please check metadata URL or signtaure fingerprint in config." -MajorFault
    }

    #Verify Metadata Signature
    Write-VerboseLog "Verifying metadata signature..." -EntryType Information
    if (Verify-MetadataSignature $MetadataXML)
    {
        Write-VerboseLog "Successfully verified metadata signature!" -EntryType Information
    }
    else
    {
        Write-Log "Metadata signature test did not pass. Aborting!" -MajorFault
    }

    #region Read/Create file with 


    if ($ProcessWholeMetadata)
    {
        Write-Log "Processing whole Metadata file..." -EntryType Information

        $AllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null -and $_.Extensions -ne $null}

        Write-VerboseLog "Calculating changes..."
        $AllSPs | % {
            $SwamidSPs = @()
            $SwamidSPsToProcess = @()
        }{
            Write-VerboseLog "Working with `'$($_.EntityID)`'..."

            $SwamidSPs += $_.EntityId
            if (Check-SPHasChanged $_)
            {
                $SwamidSPsToProcess += $_
            }
            #else
            #{
            #    Write-VerboseLog "Skipped due to no changes in metadata..."
            #}

        }{
            Write-VerboseLog "Done!"
            $n = $SwamidSPsToProcess.Count
            Write-VerboseLog "Found $n new/changed SPs."
            $batches = [Math]::Ceiling($n/$MaxSPAdditions)
            Write-VerboseLog "Batches count: $batches"

            if ($n -gt 0)
            {
                if ($batches -gt 1)
                {
                    for ($i = 1; $i -le $batches; $i++)
                    {
                        Write-Log "Working with batch $($i)/$batches"
                        Start-Process -WorkingDirectory $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') -FilePath "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoExit", "-Command & {.\Import-SWAMIDMetadata.ps1 -MaxSPAdditions 50 -CacheTime -1 -ForceUpdate -LogToPath '$LogToPath';Exit}" -Wait -NoNewWindow
                        Write-Log "Done!"
                    }
                }
                else
                {
                    $SwamidSPsToProcess | % {
                        Processes-RelyingPartyTrust $_
                    }
                }
            }

            # Checking if any Swamid Relying Party Trusts show be removed
            
            Write-Log "Checking for Relying Parties removed from Swamid Metadata..."

            $CurrentSwamidSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "Swamid: *"} | select -ExpandProperty Identifier

            #$RemoveSPs = Compare-Object $CurrentSwamidSPs $SwamidSPs | ? SideIndicator -eq "<=" | select -ExpandProperty InputObject
            $CompareSets = Compare-Object -FirstSet $CurrentSwamidSPs -SecondSet $SwamidSPs -CompareType InFirstSetOnly

            Write-VerboseLog "Found $($CompareSets.MembersInCompareSet) RPs that should be removed."

            if ($ForceUpdate)
            {
                foreach ($rp in $CompareSets.CompareSet)
                {
                    Write-VerboseLog "Removing `'$($rp)`'..."
                    try 
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                        Write-VerboseLog "Done!"
                    }
                    catch
                    {
                        Write-Log "Could not remove `'$($rp)`'! Error: $_" -EntryType Error
                    }
                }
            }
            else
            {
                # $RemoveSPs | Get-Answer -Caption "Do you want to remove Relying Party trust that are not in Swamid metadata?" | Remove-ADFSRelyingPartyTrust -Confirm:$false 
                foreach ($rp in ($CompareSets.CompareSet | Get-Answer -Caption "Do you want to remove Relying Party trust that are not in Swamid metadata?"))
                {
                    Write-VerboseLog "Removing `'$($rp)`'..."
                    try 
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                        Write-VerboseLog "Done!"
                    }
                    catch
                    {
                        Write-Log "Could not remove `'$($rp)`'! Error: $_" -EntryType Error
                    }
                }
            }
        }
    }
    elseif($PSBoundParameters.ContainsKey('MaxSPAdditions') -and $MaxSPAdditions -gt 0)
    {
        Write-Log "Processing $MaxSPAdditions SPs..." -EntryType Information
        
        $AllSPsInMetadata = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null -and $_.Extensions -ne $null}

        $i = 0
        $n = 0
        $m = $AllSPsInMetadata.Count - 1
        $SPsToProcess = @()
        do
        {
            if (Check-SPHasChanged $AllSPsInMetadata[$i])
            {
                $SPsToProcess += $AllSPsInMetadata[$i]
                $n++
            }
            else
            {
                Write-VerboseLog "Skipped due to no changes in metadata..."
            }
            $i++
        }
        until ($n -ge $MaxSPAdditions -or $i -ge $m)

        $SPsToProcess | % {
            Processes-RelyingPartyTrust $_
        }
    }
    else
    {
    #Lägg in så att SP:N kollas mot hashen och frågar om man vill tvinga uppdatering. Lägg in i hashen!
        Write-VerboseLog "Working with `'$EntityID`'..."
        if ([string]::IsNullOrEmpty($EntityBase)) {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId}
        }
        else {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId -and $_.base -eq $EntityBase}
        }

        if ($sp.count -gt 1) {
            $sp = $sp[0] #Fult som fan, jag vet, men vad ska jag göra?!?!
        }

        if ([string]::IsNullOrEmpty($sp)){
            Write-Log "No SP found!" -MajorFault
        }
        else {
            Processes-RelyingPartyTrust $sp
        }
    }

    Write-VerboseLog "Script ended!"

    }
        Catch
        {
            Throw $_
        }
    }
}
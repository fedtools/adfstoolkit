#========================================================================== 
# NAME: Import-SWAMIDMetadata.ps1
#
# DESCRIPTION: Creates ADFS Relying Parties from the SWAMID Metadata
#
# 
# AUTHOR: Johan Peterson (Linköping University)
# DATE  : 2014-03-18
#
# PUBLISH LOCATION: C:\Published Powershell Scripts\ADFS
#
#=========================================================================
#  Version     Date      	Author              	Note 
#  ----------------------------------------------------------------- 
#   1.0        2014-03-18	Johan Peterson (Linköping University)	Initial Release
#   1.1        2014-03-18	Johan Peterson (adm)	First Publish
#   1.2        2014-03-19	Johan Peterson (adm)	Fixed a bug with SamlEndpoint not setting Binding to Artifact correct
#   1.3        2014-03-19	Johan Peterson (adm)	Only releasing TransformsRule Group Base to everyone, not Static Group as before
#   1.4        2014-03-20	Johan Peterson (adm)	Now removes swamid RPs that are not in metadata anymore
#   1.5        2014-03-20	Johan Peterson (adm)	Changed AddOnly to AddRemoveOnly
#   1.6        2014-05-26	Johan Peterson (adm)	Added SupportsShouldProcess and ErrorAction Stop for ADFS cmdlets
#   1.7        2015-05-28	Andreas Karlsson (adm)	Added load-cmdlet function and changed paths of the functions to load
#   1.8        2015-08-06	Andreas Karlsson (adm)	Removed the Snapin-Check for ADFS
#   1.9        2016-04-08	Johan Peterson (adm)	Removed an incorrect row (69) wich didn't do anything :)
#   1.10        2016-04-12	Johan Peterson (adm)	Added support for having PS sciprts in /ADFS or in root folder
#   1.11        2016-04-28	Johan Peterson (adm)	EntityBase not required anymore for manual imports from metadata
#=========================================================================


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

#region internal functions
function Check-SPHasChanged {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $SP
)
 
    #Try to get the cached Entity
    try
    {
        if ($SPHashList.ContainsKey($SP.EntityID))
        {
            $currentSPHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($SP)))
            return $currentSPHash -ne $SPHashList.($SP.EntityID)
        }
        else
        {
            return $true #Can't find the cached entity so it has changed
        }
    }
    catch
    {
        Write-VerboseLog "Could not get cached entity or compute the hash for it..."
    }
    
    #if (![string]::IsNullOrEmpty($SP))
    #{
    #    $currentSPHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($SP)))
    #}
    #
    #if ($SPHashList.ContainsKey($SP.EntityID))
    #{
    #    if ($currentSPHash -eq $SPHashList.($SP.EntityID))
    #    {
    #        return $false
    #    }
    #    else
    #    {
    #        Add-EntityHash $SP -spHash $currentSPHash
    #        return $true
    #    }
    #
    #    #return ($currentSPHash -ne $SPHash.($SP.EntityID))
    #}
    #else
    #{
    #    Add-EntityHash $SP -spHash $currentSPHash
    #    return $true #EntityID didn't exist ie it has changed
    #}
}

function Add-EntityHash {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $EntityID,
    [Parameter(Mandatory=$false, Position=1)]
    $spHash = $null
)
    if (![string]::IsNullOrEmpty($SP))
    {
        if ([string]::IsNullOrEmpty($spHash))
        {
            $spHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($sp)))
        }
    
        $SPHashList.$EntityID = $spHash
        $SPHashList | Export-Clixml $SPHashFile
    }
}

function Verify-SigningCert {
param (
    [string]$signingCertString
)
    [void][reflection.assembly]::LoadWithPartialName("System.IO")
    $memoryStream = new-object System.IO.MemoryStream

    $signCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    try {
        $signCertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($signingCertString)
        $signCertificate.Import($signCertificateBytes)
    }
    catch {
        throw "Could not convert signingCertString to X509 certificate"
    }
        
    $signCertificateHash = Get-FileHash -InputStream ([System.IO.MemoryStream]$signCertificate.RawData)

    
    #Get Signing Certificate Hash from config
    if ([string]::IsNullOrEmpty($Settings.configuration.signCertFingerprint))
    {
        $signCertificateHashCompare = 'A6785A37C9C90C25AD5F1F6922EF767BC97867673AAF4F8BEAA1A76DA3A8E585' #Just for fallback
    }
    else
    {
        $signCertificateHashCompare = $Settings.configuration.signCertFingerprint
    }

    return ($signCertificateHash.Hash -eq $signCertificateHashCompare)
    
}

function Verify-MetadataSignature {
param (
    [xml]$xmlMetadata
)
# check metadata signature
        # from http://msdn.microsoft.com/en-us/library/system.security.cryptography.xml.signedxml.aspx
        Add-Type -AssemblyName System.Security
    
        $signatureNode = $xmlMetadata.EntitiesDescriptor.Signature
        $signedXml = New-Object System.Security.Cryptography.Xml.SignedXml($xmlMetadata)
        $signedXml.LoadXml($signatureNode)
        return $signedXml.CheckSignature()
}

function Add-SPRelyingPartyTrust {
    param (
        [Parameter(Mandatory=$true,
                   Position=0)]
        $sp
    )
    
    $Continue = $true

    ### EntityId
    $entityID = $sp.entityID

    Write-Log "Adding $entityId as SP..." -EntryType Information

    ### Name, DisplayName
    $Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1


    ### SwamID 2.0
    #$Swamid2 = ($sp.base | Split-Path -Parent) -eq "swamid-2.0"

    ### Token Encryption Certificate 
    Write-VerboseLog "Getting Token Encryption Certificate..."
    $EncryptionCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    if ($CertificateString -eq $null)
    {
        Write-VerboseLog "Certificate with description `'encryption`' not found. Using default certificate..."
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | select -ExpandProperty KeyInfo -First 1).X509Data.X509Certificate
    }
    
    try
    {
        #Kan finnas flera certifikat! Se till att kolla det och kör foreach. Välj det giltiga cert som har längst giltighetstid
        Write-VerboseLog "Converting Token Encryption Certificate string to Certificate..."
        $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($CertificateString)
        $EncryptionCertificate.Import($CertificateBytes)
        Write-VerboseLog "Convertion of Token Encryption Certificate string to Certificate done!"
    }
    catch
    {
        Write-Log "Could not import Token Encryption Certificate!" -EntryType Error
        $Continue = $false
    }

    ### Token Signing Certificate 
    Write-VerboseLog "Getting Token Signing Certificate..."
    $SigningCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    if ($CertificateString -eq $null)
    {
        Write-VerboseLog "Certificate with description `'signing`' not found. Using Token Decryption certificate..."
        $SigningCertificate = $EncryptionCertificate
    }
    else
    {
        try
        {
            Write-VerboseLog "Converting Token Signing Certificate string to Certificate..."
            $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($CertificateString)
            $SigningCertificate.Import($CertificateBytes)
            Write-VerboseLog "Convertion of Token Signing Certificate string to Certificate done!"
        }
        catch
        {
            Write-Log "Could not import Token Signing Certificate!" -EntryType Error
            $Continue = $false
        }
    }

    ### Bindings
    Write-VerboseLog "Getting SamlEndpoints..."
    $SamlEndpoints = $sp.SPSSODescriptor.AssertionConsumerService |  % {
        if ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST")
        {  
            Write-VerboseLog "HTTP-POST SamlEndpoint found!"
            New-ADFSSamlEndpoint -Binding POST -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
        elseif ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact")
        {
            Write-VerboseLog "HTTP-Artifact SamlEndpoint found!"
            New-ADFSSamlEndpoint -Binding Artifact -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
    } 

    if ($SamlEndpoints -eq $null) 
    {
        Write-Log "No SamlEndpoints found!" -EntryType Error
        $Continue = $false
    }
    

    ### Get Category
    Write-VerboseLog "Getting Entity Categories..."
    $EntityCategories = @()
    $EntityCategories += $sp.Extensions.EntityAttributes.Attribute | ? Name -eq "http://macedir.org/entity-category" | select -ExpandProperty AttributeValue | % {
        if ($_ -is [string])
        {
            $_
        }
        elseif ($_ -is [System.Xml.XmlElement])
        {
            $_."#text"
        }
    }
    
    Write-VerboseLog "The following Entity Categories found: $($EntityCategories -join ',')"

    if ($ForcedEntityCategories)
    {
        $EntityCategories += $ForcedEntityCategories
        Write-VerboseLog "Added Forced Entity Categories: $($ForcedEntityCategories -join ',')"
    }

    $IssuanceTransformRules = Get-IssuanceTransformRules $EntityCategories -EntityId $entityID -RequestedAttribute $sp.SPSSODescriptor.AttributeConsumingService.RequestedAttribute

    $IssuanceAuthorityRule =
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", 
     Value = "true");
"@

    if ((Get-ADFSRelyingPartyTrust -Identifier $entityID) -eq $null)
    {
        ### Lägg till swamid: före namnet.
        ### Om namn finns utan swamid, låt det vara
        ### Om namn finns med swamid, lägg till siffra

        $NamePrefix = "Swamid:"        
        $NameWithPrefix = "$NamePrefix $Name"

        if ((Get-ADFSRelyingPartyTrust -Name $NameWithPrefix) -ne $null)
        {
            $n=1
            Do
            {
                $n++
                $NewName = "$Name ($n)"
            }
            Until ((Get-ADFSRelyingPartyTrust -Name "$NamePrefix $NewName") -eq $null)

            $Name = $NewName
            $NameWithPrefix = "$NamePrefix $Name"
            Write-VerboseLog "A RelyingPartyTrust already exist with the same name. Changing name to `'$NameWithPrefix`'..."
        }
        
        if ($Continue)
        {
            try 
            {
                Write-VerboseLog "Adding ADFSRelyingPartyTrust `'$entityID`'..."
                
                Add-ADFSRelyingPartyTrust -Identifier $entityID `
                                    -RequestSigningCertificate $SigningCertificate `
                                    -Name $NameWithPrefix `
                                    -EncryptionCertificate $EncryptionCertificate  `
                                    -IssuanceTransformRules $IssuanceTransformRules `
                                    -IssuanceAuthorizationRules $IssuanceAuthorityRule `
                                    -SamlEndpoint $SamlEndpoints `
                                    -ClaimsProviderName @("Active Directory") `
                                    -ErrorAction Stop

                Write-Log "Successfully added `'$entityId`'!" -EntryType Information
                Add-EntityHash -EntityID $entityId
            }
            catch
            {
                Write-Log "Could not add $entityId as SP! Error: $_" -EntryType Error
                Add-EntityHash -EntityID $entityId
            }
        }
        else
        {
            #There were some error with certificate or endpoints with this SP. Let's only try again if it changes... 
            Add-EntityHash -EntityID $entityId
        }
    }
    else
    {
        Write-Log "$entityId already exists as SP!" -EntryType Warning
    }                
}

function Processes-RelyingPartyTrust {
param (
    $sp
)

    if ((Get-ADFSRelyingPartyTrust -Identifier $sp.EntityID) -eq $null)
    {
        Write-VerboseLog "'$($sp.EntityID)' not in ADFS database."
        Add-SPRelyingPartyTrust $sp
    }
    else
    {
        $Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1

        if ($ForceUpdate)
        {
            if ((Get-ADFSRelyingPartyTrust -Name $Name) -ne $null)
            {
                Write-Log "'$($sp.EntityID)' added manual in ADFS database, aborting force update!" -EntryType Warning
                Add-EntityHash -EntityID $sp.EntityID
            }
            else
            {
                Write-VerboseLog "'$($sp.EntityID)' in ADFS database, forcing update!"
                #Update-SPRelyingPartyTrust $_
                Write-VerboseLog "Deleting '$($sp.EntityID)'..."
                try
                {
                    Remove-ADFSRelyingPartyTrust -TargetIdentifier $sp.EntityID -Confirm:$false -ErrorAction Stop
                    Write-VerboseLog "Deleting $($sp.EntityID) done!"
                    Add-SPRelyingPartyTrust $sp
                }
                catch
                {
                    Write-Log "Could not delete '$($sp.EntityID)'... Error: $_" -EntryType Error
                }
            }
        }
        else
        {
            if ($AddRemoveOnly -eq $true)
            {
                Write-VerboseLog "Skipping RP due to -AddRemoveOnly switch..."
            }
            elseif (Get-Answer "'$($sp.EntityID)' already exists. Do you want to update it?")
            {
                if ((Get-ADFSRelyingPartyTrust -Name $Name) -ne $null)
                {
                    $Continue = Get-Answer "'$($sp.EntityID)' added manual in ADFS database, still forcing update?"
                }
                else
                {
                    $Continue = $true
                }

                if ($Continue)
                {
                        
                    Write-VerboseLog "'$($sp.EntityID)' in ADFS database, updating!"
                
                    #Update-SPRelyingPartyTrust $_
                    Write-VerboseLog "Deleting '$($sp.EntityID)'..."
                    try
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $sp.EntityID -Confirm:$false -ErrorAction Stop
                        Write-VerboseLog "Deleting '$($sp.EntityID)' done!"
                        Add-SPRelyingPartyTrust $sp
                    }
                    catch
                    {
                        Write-Log "Could not delete '$($sp.EntityID)'... Error: $_" -EntryType Error
                    }
                }
            }
        }
    }
}

# Load  CmdLets
function Load-CmdLet($CmdLetName)
{
    # set the script loading path to be relative to where the code is
    # making no presumptions on where it is.
    $ScriptsPath = @()
    $ScriptsPath += "."
    $ScriptsPath += $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')
    $ScriptsPath += $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\lib')
#    $ScriptsPath += "C:\Published Powershell Scripts\ADFS"
#    $ScriptsPath += "C:\Published Powershell Scripts\Functions"
    

    if (!$CmdLetName.EndsWith('.ps1')) { $CmdLetName += ".ps1" }

    $ScriptsPath | % { 
        $ReturnObj = $null 
    }{ 
        if (Test-Path "$_\$CmdLetName") { $ReturnObj = "$_\$CmdLetName" }
    }{ 
        if ($ReturnObj -ne $null) { $ReturnObj }  else { throw "$CmdLetName cmdlet missing!" }
    }
}
#endregion

#Not needed for ADFS 3.0
#if ((Get-PSSnapin | ? name -eq "Microsoft.Adfs.PowerShell") -eq $null)
#{
#    Add-PSSnapin "Microsoft.Adfs.PowerShell"
#}

# Import commandlets
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

function Add-ADFSTkSPRelyingPartyTrust {
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        $sp
    )
    
    $Continue = $true
    
    ### EntityId
    $entityID = $sp.entityID

    $rpParams = @{
        Identifier                           = $sp.entityID
        EncryptionCertificateRevocationCheck = 'None'
        SigningCertificateRevocationCheck    = 'None'
        ClaimsProviderName                   = @("Active Directory")
        ErrorAction                          = 'Stop'
        SignatureAlgorithm                   = Get-ADFSTkSecureHashAlgorithm -sp $sp
        SamlResponseSignature                = Get-ADFSTkSamlResponseSignature -EntityId $entityID
    }

    Write-ADFSTkLog (Get-ADFSTkLanguageText addRPAddingRP -f $entityId) -EntryType Information -EventID 41
     
    ### Name, DisplayName
    $Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1


    #region Token Encryption Certificate 
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPGettingEncryptionert)
    
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    
    if ($CertificateString -eq $null) {
        #Check if any certificates without 'use'. Should we use this?
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPEncryptionCertNotFound)
        
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -ne "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate #or shoud 'use' not be present?
    }
    
    if ($CertificateString -ne $null) {
        $rpParams.EncryptionCertificate = $null
        try {
            #May be more certificates! 
            #If more than one, choose the one with furthest end date.

            $CertificateString | % {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPConvertingEncrytionCert)
                $EncryptionCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    
                $CertificateBytes = [system.Text.Encoding]::UTF8.GetBytes($_)
                $EncryptionCertificate.Import($CertificateBytes)
                
                
                if ($rpParams.EncryptionCertificate -eq $null) {
                    $rpParams.EncryptionCertificate = $EncryptionCertificate
                }
                elseif ($rpParams.EncryptionCertificate.NotAfter -lt $EncryptionCertificate.NotAfter) {
                    $rpParams.EncryptionCertificate = $EncryptionCertificate
                }
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPConvertionEncryptionCertDone)
            }

            if ($CertificateString -is [Object[]]) {
                #Just for logging!
                Write-ADFSTkLog (Get-ADFSTkLanguageText addRPMultipleEncryptionCertsFound -f $EncryptionCertificate.Thumbprint)  -EntryType Warning -EventID 30
            }
        }
        catch {
            Write-ADFSTkLog (Get-ADFSTkLanguageText addRPCouldNotImportEncrytionCert) -EntryType Error -EventID 21
            $Continue = $false
        }
    }
    #endregion

    #region Token Signing Certificate 

    #Add all signing certificates if there are more than one
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPGetSigningCert)
    
    #$rpParams.SignatureAlgorithm = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
    
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    if ($CertificateString -eq $null) {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPSigningCertNotFound)
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -ne "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate #or shoud 'use' not be present?
    }
    
    if ($CertificateString -ne $null) {
        #foreach insted create $SigningCertificates array
        try {
            $rpParams.RequestSigningCertificate = @()

            $CertificateString | % {

                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPConvertingSigningCert)

                $CertificateBytes = [system.Text.Encoding]::UTF8.GetBytes($_)
                
                $SigningCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2                
                $SigningCertificate.Import($CertificateBytes)

                $rpParams.RequestSigningCertificate += $SigningCertificate

                #if ($SigningCertificate.SignatureAlgorithm.Value -eq '1.2.840.113549.1.1.11') #Check if Signature Algorithm is SHA256
                #{
                #    $rpParams.SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
                #}
            }
            
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPConvertionSigningCertDone)
        }
        catch {
            Write-ADFSTkLog (Get-ADFSTkLanguageText addRPCouldNotImportSigningCert) -EntryType Error -EventID 22
            $Continue = $false
        }
    }
    #endregion

    #region Get SamlEndpoints
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPGetSamlEndpoints)
    $rpParams.SamlEndpoint = @()
    $rpParams.SamlEndpoint += $sp.SPSSODescriptor.AssertionConsumerService | % {
        if ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST") {  
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPHTTPPostFound)
            New-ADFSSamlEndpoint -Binding POST -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
        elseif ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact") {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPHTTPArtifactFound)
            New-ADFSSamlEndpoint -Binding Artifact -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
        elseif ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect") {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPHTTPRedirectFound)
            New-ADFSSamlEndpoint -Binding Redirect -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index
        }
        else {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPUnhandledEndpointFound -f $_.Binding, $entityID)
        }
    } 

    if ($rpParams.SamlEndpoint.Count -eq 0) {
        Write-ADFSTkLog (Get-ADFSTkLanguageText addRPNoSamlEndpointsFound) -EntryType Error -EventID 23
        $Continue = $false
    }
    #endregion

    #region Get LogoutEndpoints
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPGetLogoutEndpoints) 
    $rpParams.SamlEndpoint += $sp.SPSSODescriptor.SingleLogoutService | % {
        if ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST") {  
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPLogoutPostFound)
            New-ADFSSamlEndpoint -Binding POST -Protocol SAMLLogout -ResponseUri $_.Location -Uri ("https://{0}/adfs/ls/?wa=wsignout1.0" -f $Settings.configuration.staticValues.ADFSExternalDNS)
        }
        elseif ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect") {
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPLogoutRedirectFound)
            New-ADFSSamlEndpoint -Binding Redirect -Protocol SAMLLogout -ResponseUri $_.Location -Uri ("https://{0}/adfs/ls/?wa=wsignout1.0" -f $Settings.configuration.staticValues.ADFSExternalDNS)
        }
    } 
    #endregion

    #region Get Issuance Transform Rules from Entity Categories
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPGetEntityCategories)
    $EntityCategories = @()
    $EntityCategories += $sp.Extensions.EntityAttributes.Attribute | ? Name -eq "http://macedir.org/entity-category" | select -ExpandProperty AttributeValue | % {
        if ($_ -is [string]) {
            $_
        }
        elseif ($_ -is [System.Xml.XmlElement]) {
            $_."#text"
        }
    }
    
    # Filter Entity Categories that shouldn't be released together
    $filteredEntityCategories = @()
    $filteredEntityCategories += foreach ($entityCategory in $EntityCategories) {
        if ($entityCategory -eq 'https://refeds.org/category/personalized') {
            if (-not ($EntityCategories.Contains('https://refeds.org/category/pseudonymous') -or `
                        $EntityCategories.Contains('https://refeds.org/category/anonymous'))) {
                $entityCategory
            }
        }
        elseif ($entityCategory -eq 'https://refeds.org/category/pseudonymous') {
            if (-not $EntityCategories.Contains('https://refeds.org/category/anonymous')) {
                $entityCategory
            }
        }
        else {
            $entityCategory
        }
    }

    $EntityCategories = $filteredEntityCategories

    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPFollowingECFound -f ($EntityCategories -join ','))

    if ($ForcedEntityCategories) {
        $EntityCategories += $ForcedEntityCategories
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPAddedForcedEC -f ($ForcedEntityCategories -join ','))
    }



    $subjectIDReq = $sp.Extensions.EntityAttributes.Attribute | ? Name -eq "urn:oasis:names:tc:SAML:profiles:subject-id:req" | Select -First 1 -ExpandProperty AttributeValue

    $IssuanceTransformRuleObject = Get-ADFSTkIssuanceTransformRules $EntityCategories -EntityId $entityID `
        -RequestedAttribute $sp.SPSSODescriptor.AttributeConsumingService.RequestedAttribute `
        -RegistrationAuthority $sp.Extensions.RegistrationInfo.registrationAuthority `
        -NameIdFormat $sp.SPSSODescriptor.NameIDFormat `
        -SubjectIDReq $subjectIDReq
    #endregion

    #region Add MFA Access Policy and extra rules if needed

    $IssuanceTransformRuleObject.MFARules = Get-ADFSTkMFAConfiguration -EntityId $entityID

    if ([string]::IsNullOrEmpty($IssuanceTransformRuleObject.MFARules)) {
        $rpParams.IssuanceAuthorizationRules = Get-ADFSTkIssuanceAuthorizationRules -EntityId $entityID
        $rpParams.IssuanceTransformRules = $IssuanceTransformRuleObject.Stores + $IssuanceTransformRuleObject.Rules
    }
    else {
        $rpParams.AccessControlPolicyName = 'ADFSTk:Permit everyone and force MFA'
        $rpParams.IssuanceTransformRules = $IssuanceTransformRuleObject.Stores + $IssuanceTransformRuleObject.MFARules + $IssuanceTransformRuleObject.Rules
    }
    #endregion

    #region Custom Access Control Policy
    $CustomACPName = Get-ADFSTkCustomACPConfiguration -EntityId $entityID
    if (![string]::IsNullOrEmpty($CustomACPName))
    {
        $rpParams.AccessControlPolicyName = $CustomACPName
    }
    #endregion

    if ((Get-ADFSRelyingPartyTrust -Identifier $entityID) -eq $null) {
        $NamePrefix = $Settings.configuration.MetadataPrefix 
        $Sep = $Settings.configuration.MetadataPrefixSeparator      
        $NameWithPrefix = "$NamePrefix$Sep$Name"

        if ((Get-ADFSRelyingPartyTrust -Name $NameWithPrefix) -ne $null) {
            $n = 1
            Do {
                $n++
                $NameWithPrefix = "$NamePrefix$Sep$Name ($n)"
            }
            Until ((Get-ADFSRelyingPartyTrust -Name $NameWithPrefix) -eq $null)

            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPRPAlreadyExistsChangingNameTo -f $NameWithPrefix)
        }

        $rpParams.Name = $NameWithPrefix
        
        if ($Continue) {
            try {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText addRPAddingRP -f $entityID)
                
                # Invoking the following command leverages 'splatting' for passing the switches for commands
                # for details, see: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-6
                # (that's what it's @rpParams and not $rpParams)

                Add-ADFSRelyingPartyTrust @rpParams

                Write-ADFSTkLog (Get-ADFSTkLanguageText addRPSuccefullyAddedRP -f $entityId) -EntryType Information -EventID 42
                Add-ADFSTkEntityHash -EntityID $entityId
            }
            catch {
                Write-ADFSTkLog (Get-ADFSTkLanguageText addRPCouldNotAddRP -f $entityId, $_) -EntryType Error -EventID 24
                Add-ADFSTkEntityHash -EntityID $entityId
            }
        }
        else {
            #There were some error with certificate or endpoints with this SP. Let's only try again if it changes... 
            Add-ADFSTkEntityHash -EntityID $entityId
        }
    }
    else {
        Write-ADFSTkLog (Get-ADFSTkLanguageText addRPRPAlreadyExists -f $entityId) -EntryType Warning -EventID 25
    }                
}
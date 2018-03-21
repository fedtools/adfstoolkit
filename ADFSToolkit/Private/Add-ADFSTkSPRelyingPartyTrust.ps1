function Add-ADFSTkSPRelyingPartyTrust {
    param (
        [Parameter(Mandatory=$true,
                   Position=0)]
        $sp
    )
    
    $Continue = $true

    ### EntityId
    $entityID = $sp.entityID

    Write-ADFSTkLog "Adding $entityId as SP..." -EntryType Information

    ### Name, DisplayName
    $Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1

    ### Token Encryption Certificate 
    Write-ADFSTkVerboseLog "Getting Token Encryption Certificate..."
    $EncryptionCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    if ($CertificateString -eq $null)
    {
        Write-ADFSTkVerboseLog "Certificate with description `'encryption`' not found. Using default certificate..."
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | select -ExpandProperty KeyInfo -First 1).X509Data.X509Certificate
    }
    
    try
    {
        #May be more certificates! Be sure to check it out and drive foreach. 
        # 1. If any cert is invalid, choose the valid one
        # 2. If more than one is valid, select certificate with the lowest validity period
        Write-ADFSTkVerboseLog "Converting Token Encryption Certificate string to Certificate..."
        $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($CertificateString)
        $EncryptionCertificate.Import($CertificateBytes)
        Write-ADFSTkVerboseLog "Convertion of Token Encryption Certificate string to Certificate done!"
    }
    catch
    {
        Write-ADFSTkLog "Could not import Token Encryption Certificate!" -EntryType Error
        $Continue = $false
    }

    ### Token Signing Certificate 

    #Add all signing certificates if there are more than one
    Write-ADFSTkVerboseLog "Getting Token Signing Certificate..."
    
    $SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" 
    
    $SigningCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    if ($CertificateString -eq $null)
    {
        Write-ADFSTkVerboseLog "Certificate with description `'signing`' not found. Using Token Decryption certificate..."
        $SigningCertificate = $EncryptionCertificate
    }
    else
    {
        try
        {
            Write-ADFSTkVerboseLog "Converting Token Signing Certificate string to Certificate..."
            $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($CertificateString)
            $SigningCertificate.Import($CertificateBytes)

            if ($SigningCertificate.SignatureAlgorithm.Value -eq '1.2.840.113549.1.1.5') #Check if Signature Algorithm is SHA1
            {
                $SignatureAlgorithm = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
            }
            Write-ADFSTkVerboseLog "Convertion of Token Signing Certificate string to Certificate done!"
        }
        catch
        {
            Write-ADFSTkLog "Could not import Token Signing Certificate!" -EntryType Error
            $Continue = $false
        }
    }

    ### Bindings
    Write-ADFSTkVerboseLog "Getting SamlEndpoints..."
    $SamlEndpoints = $sp.SPSSODescriptor.AssertionConsumerService |  % {
        if ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST")
        {  
            Write-ADFSTkVerboseLog "HTTP-POST SamlEndpoint found!"
            New-ADFSSamlEndpoint -Binding POST -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
        elseif ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact")
        {
            Write-ADFSTkVerboseLog "HTTP-Artifact SamlEndpoint found!"
            New-ADFSSamlEndpoint -Binding Artifact -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
    } 

    if ($SamlEndpoints -eq $null) 
    {
        Write-ADFSTkLog "No SamlEndpoints found!" -EntryType Error
        $Continue = $false
    }
    

    ### Get Category
    Write-ADFSTkVerboseLog "Getting Entity Categories..."
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
    
    Write-ADFSTkVerboseLog "The following Entity Categories found: $($EntityCategories -join ',')"

    if ($ForcedEntityCategories)
    {
        $EntityCategories += $ForcedEntityCategories
        Write-ADFSTkVerboseLog "Added Forced Entity Categories: $($ForcedEntityCategories -join ',')"
    }

    $IssuanceTransformRules = Get-ADFSTkIssuanceTransformRules $EntityCategories -EntityId $entityID `
                                                                                 -RequestedAttribute $sp.SPSSODescriptor.AttributeConsumingService.RequestedAttribute `
                                                                                 -RegistrationAuthority $sp.extensions.RegistrationInfo.registrationAuthority

    $IssuanceAuthorityRule =
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", 
     Value = "true");
"@

    if ((Get-ADFSRelyingPartyTrust -Identifier $entityID) -eq $null)
    {
        

        $NamePrefix = $Settings.configuration.MetadataPrefix 
        $Sep= $Settings.configuration.MetadataPrefixSeparator      
        $NameWithPrefix = "$NamePrefix$Sep$Name"

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
            Write-ADFSTkVerboseLog "A RelyingPartyTrust already exist with the same name. Changing name to `'$NameWithPrefix`'..."
        }
        
        if ($Continue)
        {
            try 
            {
                Write-ADFSTkVerboseLog "Adding ADFSRelyingPartyTrust `'$entityID`'..."
                
                Add-ADFSRelyingPartyTrust -Identifier $entityID `
                                    -SignatureAlgorithm $SignatureAlgorithm `
                                    -EncryptionCertificateRevocationCheck None `
                                    -SigningCertificateRevocationCheck None `
                                    -RequestSigningCertificate $SigningCertificate `
                                    -Name $NameWithPrefix `
                                    -EncryptionCertificate $EncryptionCertificate  `
                                    -IssuanceTransformRules $IssuanceTransformRules `
                                    -IssuanceAuthorizationRules $IssuanceAuthorityRule `
                                    -SamlEndpoint $SamlEndpoints `
                                    -ClaimsProviderName @("Active Directory") `
                                    -ErrorAction Stop

                Write-ADFSTkLog "Successfully added `'$entityId`'!" -EntryType Information
                Add-ADFSTkEntityHash -EntityID $entityId
            }
            catch
            {
                Write-ADFSTkLog "Could not add $entityId as SP! Error: $_" -EntryType Error
                Add-ADFSTkEntityHash -EntityID $entityId
            }
        }
        else
        {
            #There were some error with certificate or endpoints with this SP. Let's only try again if it changes... 
            Add-ADFSTkEntityHash -EntityID $entityId
        }
    }
    else
    {
        Write-ADFSTkLog "$entityId already exists as SP!" -EntryType Warning
    }                
}
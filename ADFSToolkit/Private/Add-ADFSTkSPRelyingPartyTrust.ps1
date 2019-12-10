function Add-ADFSTkSPRelyingPartyTrust {
    param (
        [Parameter(Mandatory=$true,
                   Position=0)]
        $sp
    )
    
    $Continue = $true
    
    ### EntityId
    $entityID = $sp.entityID

    $rpParams = @{
        Identifier = $entityID
        EncryptionCertificateRevocationCheck = 'None'
        SigningCertificateRevocationCheck = 'None'
        ClaimsProviderName = @("Active Directory")
        IssuanceAuthorizationRules =
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", 
     Value = "true");
"@
        ErrorAction = 'Stop'
    }

    Write-ADFSTkLog "Adding $entityId as SP..." -EntryType Information -EventID 41
     
    ### Name, DisplayName
    $Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1


#region Token Encryption Certificate 
    Write-ADFSTkVerboseLog "Getting Token Encryption Certificate..."
    
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    
    if ($CertificateString -eq $null)
    {
        #Check if any certificates without 'use'. Should we use this?
        Write-ADFSTkVerboseLog "Certificate with description `'encryption`' not found. Using default certificate..."
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -ne "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate #or shoud 'use' not be present?
    }
    
    if ($CertificateString -ne $null)
    {
        $rpParams.EncryptionCertificate = $null
        try
        {
            #May be more certificates! 
            #If more than one, choose the one with furthest end date.

            $CertificateString | % {
                Write-ADFSTkVerboseLog "Converting Token Encryption Certificate string to Certificate..."
                $EncryptionCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    
                $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($_)
                $EncryptionCertificate.Import($CertificateBytes)
                
                
                if ($rpParams.EncryptionCertificate -eq $null) 
                {
                    $rpParams.EncryptionCertificate = $EncryptionCertificate
                }
                elseif($rpParams.EncryptionCertificate.NotAfter -lt $EncryptionCertificate.NotAfter)
                {
                    $rpParams.EncryptionCertificate = $EncryptionCertificate
                }
                Write-ADFSTkVerboseLog "Convertion of Token Encryption Certificate string to Certificate done!"
            }

            if ($CertificateString -is [Object[]]) #Just for logging!
            {
                Write-ADFSTkLog "Multiple encryption certificates found! Chose certificate with thumbprint '$($EncryptionCertificate.Thumbprint)' as encryption certificate." -EntryType Warning -EventID 30
            }
        }
        catch
        {
            Write-ADFSTkLog "Could not import Token Encryption Certificate!" -EntryType Error -EventID 21
            $Continue = $false
        }
    }
#endregion

#region Token Signing Certificate 

    #Add all signing certificates if there are more than one
    Write-ADFSTkVerboseLog "Getting Token Signing Certificate..."
    
    $rpParams.SignatureAlgorithm = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
    
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    if ($CertificateString -eq $null)
    {
        Write-ADFSTkVerboseLog "Certificate with description `'signing`' not found. Using Token Decryption certificate..."
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -ne "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate #or shoud 'use' not be present?
    }
    
    if ($CertificateString -ne $null) #foreach insted create $SigningCertificates array
    {
        try
        {
            $rpParams.RequestSigningCertificate = @()

            $CertificateString | % {

                Write-ADFSTkVerboseLog "Converting Token Signing Certificate string to Certificate..."

                $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($_)
                
                $SigningCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2                
                $SigningCertificate.Import($CertificateBytes)

                $rpParams.RequestSigningCertificate += $SigningCertificate

                if ($SigningCertificate.SignatureAlgorithm.Value -eq '1.2.840.113549.1.1.11') #Check if Signature Algorithm is SHA256
                {
                    $rpParams.SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
                }
            }
            
            Write-ADFSTkVerboseLog "Convertion of Token Signing Certificate string to Certificate done!"
        }
        catch
        {
            Write-ADFSTkLog "Could not import Token Signing Certificate!" -EntryType Error -EventID 22
            $Continue = $false
        }
    }
#endregion

#region Get SamlEndpoints
    Write-ADFSTkVerboseLog "Getting SamlEndpoints..."
    $rpParams.SamlEndpoint = $sp.SPSSODescriptor.AssertionConsumerService |  % {
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

    if ($rpParams.SamlEndpoint -eq $null) 
    {
        Write-ADFSTkLog "No SamlEndpoints found!" -EntryType Error -EventID 23
        $Continue = $false
    }
#endregion

#region Get Issuance Transform Rules from Entity Categories
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

    $rpParams.IssuanceTransformRules = Get-ADFSTkIssuanceTransformRules $EntityCategories -EntityId $entityID `
                                                                                 -RequestedAttribute $sp.SPSSODescriptor.AttributeConsumingService.RequestedAttribute `
                                                                                 -RegistrationAuthority $sp.Extensions.RegistrationInfo.registrationAuthority `
                                                                                 -NameIdFormat $sp.SPSSODescriptor.NameIDFormat
#endregion

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

        $rpParams.Name = $NameWithPrefix
        
        if ($Continue)
        {
            try 
            {
                Write-ADFSTkVerboseLog "Adding ADFSRelyingPartyTrust `'$entityID`'..."
                
                # Invoking the following command leverages 'splatting' for passing the switches for commands
                # for details, see: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-6
                # (that's what it's @rpParams and not $rpParams)

                Add-ADFSRelyingPartyTrust @rpParams

                Write-ADFSTkLog "Successfully added `'$entityId`'!" -EntryType Information -EventID 42
                Add-ADFSTkEntityHash -EntityID $entityId
            }
            catch
            {
                Write-ADFSTkLog "Could not add $entityId as SP! Error: $_" -EntryType Error -EventID 24
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
        Write-ADFSTkLog "$entityId already exists as SP!" -EntryType Warning -EventID 25
    }                
}
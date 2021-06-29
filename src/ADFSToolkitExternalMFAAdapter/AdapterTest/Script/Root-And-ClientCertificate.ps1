# Provide the name for fake certificate authority
$selfSignedCertAuthorityName = "EduIdApiRoot"
$selfSignedCertClientName="EduIdApiClient"
# Provide the name of the fake subdomain that will be used in order to generate wildcard certs
# If you are not using subdomains - you need to go specify the name of the cert DNS for each Sitecore role
# Note: it is recommended to have xConnect services in the same domain so that generating client certificate will be much easier

# Let's assume I have my Sitecore roles with the hostnames in this subdomain, e.g. xcollection.sc1.internal, cm.sc1.internal etc.
$domainName = "EduIDApiMFAAdapter" 

# In this hashtable I define which certificates I want to generate, you can add more or remove those which you dont need
$rolesToGenerateCertificatesFor = @{
#    CM                  =   "cm.$domainName"
#    IdentityServer      =   "identityserver.$domainName"
#    PRC                 =   "prc.$domainName"
#    REP                 =   "rep.$domainName"
#    XCollection         =   "xcollection.$domainName"
#    XCollectionSearch   =   "xcollsearch.$domainName"
#    MARep               =   "marep.$domainName"
#    MAOps               =   "maops.$domainName"
#    RefData             =   "xrefdata.$domainName"
#    CortexPrc           =   "cortexprc.$domainName"
#    CortexRep           =   "cortexrep.$domainName"
    xConnectClientCert  =   "*.$domainName"
}


# Path where certificates will be exported to
$certificateFolderPath = "C:\Temp\"

# Certificate password
$password = ConvertTo-SecureString -AsPlainText -Force -String "secret"

# Create root certificate
# Please install the certificate created below to the Trusted Certificate Root of local machine, 
# so that you all other certificates will be trusted automatically since they comes from this fake authority
$params = @{
    Subject = $selfSignedCertAuthorityName
    DnsName = $selfSignedCertAuthorityName
    KeyLength = 2048
    KeyAlgorithm = 'RSA'
    HashAlgorithm = 'SHA256'
    KeyExportPolicy = 'Exportable'
    NotAfter = (Get-Date).AddYears(5)
    CertStoreLocation = 'Cert:\LocalMachine\My'
    KeyUsage = 'CertSign','CRLSign' #fixes invalid cert error
  }
$rootCA = New-SelfSignedCertificate @params
$rootCAThumbprint = $rootCA.Thumbprint
  
Export-PfxCertificate -cert Cert:\LocalMachine\My\$rootCAThumbprint -FilePath "$certificateFolderPath\$selfSignedCertAuthorityName-CA.pfx" -Password $password

# Create all other certificates from the root above

foreach($role in $rolesToGenerateCertificatesFor.Keys)
{    
    $params = @{
        Subject = $selfSignedCertClientName
        DnsName = $rolesToGenerateCertificatesFor[$role]
        Signer = $rootCA
        KeyLength = 2048
        KeyAlgorithm = 'RSA'
        HashAlgorithm = 'SHA256'
        KeyExportPolicy = 'Exportable'
        NotAfter = (Get-date).AddYears(2)
        CertStoreLocation = 'Cert:\LocalMachine\My'
      }
    
    $cmCert = New-SelfSignedCertificate @params
    $cmCertThumbprint = $cmCert.Thumbprint
    
    Export-PfxCertificate -cert Cert:\LocalMachine\My\$cmCertThumbprint -FilePath "$certificateFolderPath\$selfSignedCertClientName-$role.pfx" -Password $password
}
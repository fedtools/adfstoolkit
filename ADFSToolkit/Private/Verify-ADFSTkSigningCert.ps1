function Verify-ADFSTkSigningCert {
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
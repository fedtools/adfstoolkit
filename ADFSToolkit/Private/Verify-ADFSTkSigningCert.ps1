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
        Write-ADFSTkVerboseLog "Could not convert signingCertString to X509 certificate" -MajorFault
    }
        
   
    $signCertificateHash = Get-FileHash -InputStream ([System.IO.MemoryStream]$signCertificate.RawData)

    #Get Signing Certificate Hash from config
    if ([string]::IsNullOrEmpty($Settings.configuration.signCertFingerprint))
    {

        Write-ADFSTkVerboseLog "Certificate Fingerprint from configuration was null" -MajorFault

    }
    else
    {
        # This string may contain colons from other output like openssl and if it does, we will strip them as the comparison below requires them to be absent
        $signCertificateHashCompare = $Settings.configuration.signCertFingerprint -replace ":"
    }
    
    Write-ADFSTkLog "Comparing aggregate certificate hash of: $signCertificateHash.Hash to $signCertificateHashCompare" -EntryType Information

    return ($signCertificateHash.Hash -eq $signCertificateHashCompare)
    
}
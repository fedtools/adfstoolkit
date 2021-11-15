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
        Write-ADFSTkLog (Get-ADFSTkLanguageText importCouldNotConvertSigningSert) -MajorFault
    }
        
   
    $signCertificateHash = Get-FileHash -InputStream ([System.IO.MemoryStream]$signCertificate.RawData)

    #Get Signing Certificate Hash from config
    if ([string]::IsNullOrEmpty($Settings.configuration.signCertFingerprint))
    {

        Write-ADFSTkLog (Get-ADFSTkLanguageText importNoCertFingerprintInConfig) -MajorFault

    }
    else
    {
        # This string may contain colons from other output like openssl and if it does, we will strip them as the comparison below requires them to be absent
        $signCertificateHashCompare = $Settings.configuration.signCertFingerprint -replace ":"
    }
    
    Write-ADFSTkLog (Get-ADFSTkLanguageText importComparingCertHashes -f $signCertificateHash.Hash, $signCertificateHashCompare) -EntryType Information

    return ($signCertificateHash.Hash -eq $signCertificateHashCompare)
    
}
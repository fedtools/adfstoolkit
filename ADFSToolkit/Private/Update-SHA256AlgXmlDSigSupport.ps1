function Update-SHA256AlgXmlDSigSupport
{

try
{

Add-Type @'
        public class RSAPKCS1SHA256SignatureDescription : System.Security.Cryptography.SignatureDescription
            {
                public RSAPKCS1SHA256SignatureDescription()
                {
                    base.KeyAlgorithm = "System.Security.Cryptography.RSACryptoServiceProvider";
                    base.DigestAlgorithm = "System.Security.Cryptography.SHA256Managed";
                    base.FormatterAlgorithm = "System.Security.Cryptography.RSAPKCS1SignatureFormatter";
                    base.DeformatterAlgorithm = "System.Security.Cryptography.RSAPKCS1SignatureDeformatter";
                }

                public override System.Security.Cryptography.AsymmetricSignatureDeformatter CreateDeformatter(System.Security.Cryptography.AsymmetricAlgorithm key)
                {
                    System.Security.Cryptography.AsymmetricSignatureDeformatter asymmetricSignatureDeformatter = (System.Security.Cryptography.AsymmetricSignatureDeformatter)
                        System.Security.Cryptography.CryptoConfig.CreateFromName(base.DeformatterAlgorithm);
                    asymmetricSignatureDeformatter.SetKey(key);
                    asymmetricSignatureDeformatter.SetHashAlgorithm("SHA256");
                    return asymmetricSignatureDeformatter;
                }
            }
'@
    $RSAPKCS1SHA256SignatureDescription = New-Object RSAPKCS1SHA256SignatureDescription
    [System.Security.Cryptography.CryptoConfig]::AddAlgorithm($RSAPKCS1SHA256SignatureDescription.GetType(), "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")

}
catch {
    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPCouldNotAddSHA256AsValidSignatureAlgorithm) -MajorFault
}

}

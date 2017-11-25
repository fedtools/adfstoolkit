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

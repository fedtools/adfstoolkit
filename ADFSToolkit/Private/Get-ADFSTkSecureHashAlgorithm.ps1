function Get-ADFSTkSecureHashAlgorithm
{
param (

    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    [string]$EntityId,
    $CertificateSignatureAlgorithm
)


if ([string]::IsNullOrEmpty($Global:ManualSPSettings))
{
    $Global:ManualSPSettings = Get-ADFSTkManualSPSettings
}

#Default hash algorithm if nothing overrides it
$SignatureAlgorithm = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"

#Check if signing cerificate Signature Algorithm is SHA256
if ($SignatureAlgorithm -eq '1.2.840.113549.1.1.11') 
{
    $SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
}

#AllSPs
if ($Global:ManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
    $Global:ManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
    $Global:ManualSPSettings.'urn:adfstk:allsps'.ContainsKey('HashAlgorithm'))
{
    $SignatureAlgorithm = $Global:ManualSPSettings.'urn:adfstk:allsps'.HashAlgorithm
}

#AllEduSPs

if ($EntityId -ne $null)
{
    
    #First remove http:// or https://
    $entityDNS = $EntityId.ToLower().Replace('http://','').Replace('https://','')

    #Second get rid of all ending sub paths
    $entityDNS = $entityDNS -split '/' | select -First 1

    #Last fetch the last two words and join them with a .
    #$entityDNS = ($entityDNS -split '\.' | select -Last 2) -join '.'

    $settingsDNS = $null

    foreach($setting in $Global:ManualSPSettings.Keys)
    {
        if ($setting.StartsWith('urn:adfstk:entityiddnsendswith:'))
        {
            $settingsDNS = $setting -split ':' | select -Last 1
        }
    }

    if ($entityDNS.EndsWith($settingsDNS) -and `
        $Global:ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS" -is [System.Collections.Hashtable] -and `
        $Global:ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('HashAlgorithm'))
{
    $SignatureAlgorithm = $Global:ManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".HashAlgorithm
}

#Manual SP
if ($EntityId -ne $null -and `
    $Global:ManualSPSettings.ContainsKey($EntityId) -and `
    $Global:ManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
    $Global:ManualSPSettings.$EntityId.ContainsKey('HashAlgorithm'))
    {
        $SignatureAlgorithm = $Global:ManualSPSettings.$EntityId.HashAlgorithm
    }
}

$SignatureAlgorithm

}
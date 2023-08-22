function Get-ADFSTkSecureHashAlgorithm
{
param (

    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    $sp
)
#Default hash algorithm if nothing overrides it
$SignatureAlgorithm = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"

#check if md:extentions is not null
if(![string]::IsNullOrEmpty($sp.Extension) -and [string]::IsNullOrEmpty($sp.Extensions.SigningMethod)){
    $SigningMethods = $sp.Extension.SigningMethod
    if(($SigningMethods -is [string]) -and $SigningMethods -eq "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" ){
        $SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    }
    elseif($SigningMethods -is [Object[]]){
        if($SigningMethods.Algorithm.Contains("http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")){
            $SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
        }
    }
}


if ([string]::IsNullOrEmpty($Global:ADFSTkManualSPSettings))
{
    if ([string]::IsNullOrEmpty($Global:ADFSTkAllTransformRules) -or $Global:ADFSTkAllTransformRules.Count -eq 0)
    {
        $Global:ADFSTkAllTransformRules = Import-ADFSTkAllTransformRules
        $AllTransformRules = $Global:ADFSTkAllTransformRules #So we don't need to change anything in the Get-ADFSTkManualSPSettings files
    }
    $Global:ADFSTkManualSPSettings = Get-ADFSTkManualSPSettings
}



#Check if signing cerificate Signature Algorithm is SHA256
#if ($SignatureAlgorithm -eq '1.2.840.113549.1.1.11') 
#{
#    $SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
#}

#AllSPs
if ($Global:ADFSTkManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
    $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
    $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.ContainsKey('HashAlgorithm'))
{
    $SignatureAlgorithm = $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.HashAlgorithm
}

#AllEduSPs

if ($sp.EntityId -ne $null)
{
    
    #First remove http:// or https://
    $entityDNS = $sp.EntityId.ToLower().Replace('http://','').Replace('https://','')

    #Second get rid of all ending sub paths
    $entityDNS = $entityDNS -split '/' | select -First 1

    #Last fetch the last two words and join them with a .
    #$entityDNS = ($entityDNS -split '\.' | select -Last 2) -join '.'

    $settingsDNS = $null

    foreach($setting in $Global:ADFSTkManualSPSettings.Keys)
    {
        if ($setting.StartsWith('urn:adfstk:entityiddnsendswith:'))
        {
            $settingsDNS = $setting -split ':' | select -Last 1
        }
    }

    if ($entityDNS.EndsWith($settingsDNS) -and `
        $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS" -is [System.Collections.Hashtable] -and `
        $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('HashAlgorithm'))
{
    $SignatureAlgorithm = $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".HashAlgorithm
}

#Manual SP
if ($EntityId -ne $null -and `
    $Global:ADFSTkManualSPSettings.ContainsKey($sp.EntityID) -and `
    $Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
    $Global:ADFSTkManualSPSettings.$EntityId.ContainsKey('HashAlgorithm'))
    {
        $SignatureAlgorithm = $Global:ADFSTkManualSPSettings.$EntityId.HashAlgorithm
    }
}

$SignatureAlgorithm

}
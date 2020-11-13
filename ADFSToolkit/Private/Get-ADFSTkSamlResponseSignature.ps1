function Get-ADFSTkSamlResponseSignature {
    param (

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$EntityId
    )


    if ([string]::IsNullOrEmpty($Global:ADFSTkManualSPSettings)) {
        $Global:ADFSTkManualSPSettings = Get-ADFSTkManualSPSettings
    }

    #Default SamlResponseSignature  if nothing overrides it
    #Valid SamlResponseSignatures: AssertionOnly, MessageAndAssertion, MessageOnly
    $SamlResponseSignature = "AssertionOnly"

    #AllSPs
    if ($Global:ADFSTkManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
            $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
            $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.ContainsKey('SamlResponseSignature')) {
        $SamlResponseSignature = $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.SamlResponseSignature
    }

    #AllEduSPs

    if ($EntityId -ne $null) {
    
        #First remove http:// or https://
        $entityDNS = $EntityId.ToLower().Replace('http://', '').Replace('https://', '')

        #Second get rid of all ending sub paths
        $entityDNS = $entityDNS -split '/' | select -First 1

        #Last fetch the last two words and join them with a .
        #$entityDNS = ($entityDNS -split '\.' | select -Last 2) -join '.'

        $settingsDNS = $null

        foreach ($setting in $Global:ADFSTkManualSPSettings.Keys) {
            if ($setting.StartsWith('urn:adfstk:entityiddnsendswith:')) {
                $settingsDNS = $setting -split ':' | select -Last 1
            }
        }

        if ($entityDNS.EndsWith($settingsDNS) -and `
                $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS" -is [System.Collections.Hashtable] -and `
                $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('SamlResponseSignature')) {
            $SamlResponseSignature = $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".SamlResponseSignature
        }

        #Manual SP
        if ($EntityId -ne $null -and `
                $Global:ADFSTkManualSPSettings.ContainsKey($EntityId) -and `
                $Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
                $Global:ADFSTkManualSPSettings.$EntityId.ContainsKey('SamlResponseSignature')) {
            $SamlResponseSignature = $Global:ADFSTkManualSPSettings.$EntityId.SamlResponseSignature
        }
    }

    $SamlResponseSignature
}
function Get-ADFSTkCustomACPConfiguration {
    param (

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            Position = 0)]
        [string]$EntityId
    )


    if ([string]::IsNullOrEmpty($Global:ADFSTkManualSPSettings)) {
        $Global:ADFSTkManualSPSettings = Get-ADFSTkManualSPSettings
    }

    $CustomAccessControlPolicyName = $null

    #AllSPs
    if ($Global:ADFSTkManualSPSettings.ContainsKey('urn:adfstk:allsps') -and `
            $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps' -is [System.Collections.Hashtable] -and `
            $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.ContainsKey('CustomAccessControlPolicyName')) {
        $CustomAccessControlPolicyName = $Global:ADFSTkManualSPSettings.'urn:adfstk:allsps'.CustomAccessControlPolicyName
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
                $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".ContainsKey('CustomAccessControlPolicyName')) {
            $CustomAccessControlPolicyName = $Global:ADFSTkManualSPSettings."urn:adfstk:entityiddnsendswith:$settingsDNS".CustomAccessControlPolicyName
        }

        #Manual SP
        if ($EntityId -ne $null -and `
                $Global:ADFSTkManualSPSettings.ContainsKey($EntityId) -and `
                $Global:ADFSTkManualSPSettings.$EntityId -is [System.Collections.Hashtable] -and `
                $Global:ADFSTkManualSPSettings.$EntityId.ContainsKey('CustomAccessControlPolicyName')) {
            $CustomAccessControlPolicyName = $Global:ADFSTkManualSPSettings.$EntityId.CustomAccessControlPolicyName
        }
    }

    if ($CustomAccessControlPolicyName -ne $null) {
        if (![string]::IsNullOrEmpty($Global:ADFSTkCustomAccessControlPolicyName) -and `
                $Global:ADFSTkCustomAccessControlPolicyName -is [System.Collections.Hashtable] -and `
                $Global:ADFSTkCustomAccessControlPolicyName.ContainsKey($CustomAccessControlPolicyName)) {
            $UseCustomACP = $Global:ADFSTkCustomAccessControlPolicyName.$CustomAccessControlPolicyName
        }
        else {
            $CustomACP = Get-AdfsAccessControlPolicy -Name $CustomAccessControlPolicyName
            $UseCustomACP = ![string]::IsNullOrEmpty($CustomACP)

            if ([string]::IsNullOrEmpty($Global:ADFSTkCustomAccessControlPolicyName)) {
                $Global:ADFSTkCustomAccessControlPolicyName = @{}
            }

            $Global:ADFSTkCustomAccessControlPolicyName.$CustomAccessControlPolicyName = $UseCustomACP
        }

        if ($UseCustomACP -eq $false) {
            Write-ADFSTkLog (Get-ADFSTkLanguageText addCustomAccessControlPolicyNameMissing -f $CustomAccessControlPolicyName) -EntryType Error -EventID 46
            $CustomAccessControlPolicyName = $null #We want to return null if non existing ACP
        }   
    }
    
    return $CustomAccessControlPolicyName
}
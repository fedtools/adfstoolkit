function Get-ADFSTkStoreRule {
    param (
        $Stores,
        $AttributesFromStore,
        $EntityId
    )

    $FirstRule = ""

    # First check if ADFSTkStore is installed and transform attributes if needed
    $ADFSTkStore = ![string]::IsNullOrEmpty((Get-AdfsAttributeStore -Name ADFSTkStore))
    
    if ($ADFSTkStore) {
        #ADFSTkStore is installed
        $fixedAttributes = foreach ($attrib in $AttributesFromStore.Values) {
            if (![string]::IsNullOrEmpty($attrib.transformvalue) -and $attrib.transformvalue.HasAttribute('adfstkstorefunction')) {
                $newAttrib = $attrib.Clone()
                $newAttrib.type += ':beforetransform'
                $newAttrib
            }
            else {
                $attrib
            }
        }
    }
    else {
        #ADFSTkStore is not installed
        $fixedAttributes = $AttributesFromStore.Values
        if (![string]::IsNullOrEmpty($AttributesFromStore.Values.transformvalue.adfstkstorefunction)) {
            Write-ADFSTkLog @"
ADFSTk Store is not intalled but attributes in the Institution configuration file is configured for it. 
Please run Install-ADFSTkStore on all ADFS servers or remove the transformvalue attribute adfstkstorefunction.
"@
        }
    }

    foreach ($store in ($Stores | Sort order)) {
        #region Active Directory Store
        if ($store.storetype -eq "Active Directory") {
            $currentStoreAttributes = $fixedAttributes | ? store -eq $store.name
            if ($currentStoreAttributes -ne $null) {
               
                $FirstRule += @"

                @RuleName = "Retrieve Attributes from AD"
                c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                => add(store = "$($store.name)", 
                types = ("$($currentStoreAttributes.type -join '","')"), 
                query = ";$($currentStoreAttributes.name -join ',');{0}", param = c.Value);

"@
            }
        }
        #endregion

        #region SQL Store
        if ($store.storetype -eq "SQL") {
            $currentStoreAttributes = $fixedAttributes | ? store -eq $store.name
            if ($currentStoreAttributes -ne $null) {
                if ($store.query.Trim().ToLower().StartsWith("select")) {
                    $FirstRule += @"

            @RuleName = "Retrieve Attributes from $($store.name)"
            c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                => add(store = "$($store.name)", 
                types = ("$($currentStoreAttributes.type -join '","')"), 
                query = "$($store.query)", param = c.Value);
                
"@
                }
                else {
                    $FirstRule += @"

            @RuleName = "Retrieve Attributes from $($store.name)"
            c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                => add(store = "$($store.name)", 
                types = ("$($currentStoreAttributes.type -join '","')"), 
                query = "SELECT $($currentStoreAttributes.name -join ',') $($store.query)", param = c.Value);

"@
                }
            }
        }
        #endregion

        #region LDAP Store

        #endregion

        #region Custom Store
        if ($store.storetype -eq "Custom Store") {
            $currentStoreAttributes = $fixedAttributes | ? store -eq $store.name
            if ($currentStoreAttributes -ne $null) {
                $FirstRule += @"

                @RuleName = "Retrieve Attributes from Custom Store"
                c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                    => add(store = "$($store.name)", 
                    types = ("$($currentStoreAttributes.type -join '","')"), 
                    query = ";$($currentStoreAttributes.name -join ',');{0}", param = "[ReplaceWithSPNameQualifier]", param = c.Value);

"@
            }
        }
        #endregion
    }
    #region ADFSTkStore
    if ($ADFSTkStore) {
            
        foreach ($attrib in $AttributesFromStore.Values) {
            if (![string]::IsNullOrEmpty($attrib.transformvalue) -and $attrib.transformvalue.HasAttribute('adfstkstorefunction')) {
                $transformvalue = $attrib.transformvalue | ? {$_.adfstkstorefunction -ne $null} | Select -First 1 -ExpandProperty adfstkstorefunction
                $FirstRule += @"

                @RuleName = "Transform $($attrib.name) through ADFSTkStore"
                c:[Type == "$($attrib.type):beforetransform"]
                => add(store = "ADFSTkStore", 
                types = ("$($attrib.type)"), 
                query = ";$transformvalue;{0}", param = "[ReplaceWithSPNameQualifier]", param = c.Value, param = "$($settings.configuration.staticValues.schacHomeOrganization)");
                
"@
                # c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"]
                #=> issue(store = "ADFSTkStore", types = ("urn:oasis:names:tc:SAML:attribute:pairwise-id"), query = ";pairwiseid;{0}", param = "https://release-check.swamid.se/shibboleth", param = RegexReplace(c.Value, "@.*$", ""), param = "umu.se");
            }
        }
    }

    #         if ($store.storetype -eq "Custom Store") {
    #             $currentStoreAttributes = $fixedAttributes | ? store -eq $store.name
    #             if ($currentStoreAttributes -ne $null) {
    #                 $FirstRule += @"

    #                 @RuleName = "Retrieve Attributes from Custom Store"
    #                 c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
    #                 => add(store = "$($store.name)", 
    #                 types = ("$($currentStoreAttributes.type -join '","')"), 
    #                 query = ";$($currentStoreAttributes.name -join ',');{0}", param = "[ReplaceWithSPNameQualifier]", param = c.Value);

    # "@
    #             }
    #         }
    #endregion
    

    return $FirstRule.Replace("[ReplaceWithSPNameQualifier]", $EntityId) 
}
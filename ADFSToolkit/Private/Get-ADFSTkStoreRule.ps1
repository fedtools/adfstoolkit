function Get-ADFSTkStoreRule {
    param (
        $Stores,
        $AttributesFromStore,
        $EntityId
    )

    $FirstRule = ""

    # First check if ADFSTkStore is installed and transform attributes if needed
    $ADFSTkStoreInstalled = [string]::IsNullOrEmpty((Get-AdfsAttributeStore -Name ADFSTkStore))
    if ($ADFSTkStoreInstalled) {
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
        $fixedAttributes = $AttributesFromStore.Values
        if (![string]::IsNullOrEmpty($AttributesFromStore.Values.transformvalue.adfstkstorefunction))
        {
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

        #region ADFSTkStore
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

    return $FirstRule.Replace("[ReplaceWithSPNameQualifier]", $EntityId) 
}
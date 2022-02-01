function Get-ADFSTkStoreRule {
    param (
        $Stores,
        $AttributesFromStore,
        $EntityId
    )

    $FirstRule = ""

    foreach ($store in ($Stores | Sort order)) {
        #region Active Directory Store
        if ($store.storetype -eq "Active Directory") {
            $currentStoreAttributes = $AttributesFromStore.Values | ? store -eq $store.name
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
            $currentStoreAttributes = $AttributesFromStore.Values | ? store -eq $store.name
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
            $currentStoreAttributes = $AttributesFromStore.Values | ? store -eq $store.name
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
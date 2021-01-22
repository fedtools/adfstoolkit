function Get-ADFSTkToolEntityId {
    param (
        [switch]
        $All,
        $Search
    )

    #Figure out the connection string to SQL server
    $adfsWMI = gwmi -Namespace root/ADFS -Class SecurityTokenService
    $SQLConnectionString = $adfsWMI.ConfigurationDatabaseConnectionString

    #Make a String builder to get the initial catalog
    $sb = New-Object System.Data.Common.DbConnectionStringBuilder
    $sb.set_ConnectionString($SQLConnectionString)

    if ($PSBoundParameters.ContainsKey('Search')) {
        $sqlCommand = @"
SELECT s.Name AS DisplayName, si.[IdentityData] AS Identifier
  FROM [$($sb.'initial catalog')].[IdentityServerPolicy].[Scopes] as s
INNER JOIN [$($sb.'initial catalog')].[IdentityServerPolicy].[ScopeIdentities] AS si
    ON si.[ScopeId] = s.ScopeId
WHERE s.Name LIKE '%$Search%' OR si.[IdentityData] LIKE '%$Search%'
ORDER BY s.Name
"@
    }
    else {
        $sqlCommand = @"
SELECT s.Name AS DisplayName, si.[IdentityData] AS Identifier
    FROM [$($sb.'initial catalog')].[IdentityServerPolicy].[Scopes] as s
INNER JOIN [$($sb.'initial catalog')].[IdentityServerPolicy].[ScopeIdentities] AS si
    ON si.[ScopeId] = s.ScopeId
ORDER BY s.Name
"@
    }
    
    $rps = Get-ADFSTkSQL -ConnectionString $SQLConnectionString -Query $sqlCommand 

    if ($PSBoundParameters.ContainsKey('Search')) {
        return $rps.Rows
    }
    else {
        if ($PSBoundParameters.ContainsKey('All') -and $All -ne $false) {
            return $rps.Rows
        }
        else {
            $rps.Rows | Out-GridView -Title "Select entityID" -OutputMode Single | select -ExpandProperty Identifier
        }
    }
}
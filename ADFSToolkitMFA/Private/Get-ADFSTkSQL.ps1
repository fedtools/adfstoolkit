function Get-ADFSTkSQL {
    param (
        [parameter(Mandatory = $true)]
        [string]$Query,
        [parameter(Mandatory = $true)]
        [string]$ConnectionString,
        [switch]$KeepConnectionAlive
    ) 

    if ([string]::IsNullOrEmpty($SQLConnection)) {
        $SQLConnection = (New-Object System.Data.SQLClient.SQLConnection)
    }

    if ($PSBoundParameters.ContainsKey('ConnectionString')) {

        if ($ConnectionString -match '"*"') {
            $ConnectionString = $ConnectionString.TrimStart('"')
            $ConnectionString = $ConnectionString.TrimEnd('"')
        }
    }
    else {
    }

    if ($SQLConnection.State -ne 'Open') {
        $SQLConnection.ConnectionString = $ConnectionString
        $SQLConnection.Open()
    }

    $Command = New-Object System.Data.SQLClient.SQLCommand
    $Command.Connection = $SQLConnection
    $Command.CommandText = $Query

    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $Command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    $dataset.Tables

    if (!$PSBoundParameters.ContainsKey('KeepConnectionAlive') -or ($PSBoundParameters.ContainsKey('KeepConnectionAlive') -and $KeepConnectionAlive -eq $false)) {
        $SQLConnection.Close()
    }
}
function Add-ADFSTkEntityHash {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $EntityID,
    [Parameter(Mandatory=$false, Position=1)]
    $spHash = $null
)
    if (![string]::IsNullOrEmpty($SP))
    {
        if ([string]::IsNullOrEmpty($spHash))
        {
            $spHash = Get-ADFSTkEntityHash $SP
        }
    
        $SPHashList.$EntityID = $spHash
        $SPHashList | Export-Clixml $SPHashFile
    }
}
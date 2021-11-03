function Add-ADFSTkEntityHash {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $EntityID,
    [Parameter(Mandatory=$false, Position=1)]
    $spHash = $null
)
    if (![string]::IsNullOrEmpty($EntityID))
    {
        if ([string]::IsNullOrEmpty($spHash))
        {
            $spHash = New-ADFSTkEntityHash -SP $sp #$SP should exist in memory
        } 
    
        $SPHashList.$EntityID = $spHash
        $SPHashList | Export-Clixml $SPHashFile
    }
}
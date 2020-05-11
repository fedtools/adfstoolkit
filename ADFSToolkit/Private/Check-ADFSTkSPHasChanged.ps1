function Check-ADFSTkSPHasChanged {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $SP
)
 
    #Try to get the cached Entity
    try
    {
        if ($SPHashList.ContainsKey($SP.EntityID))
        {
            $currentSPHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($SP.InnerXML)))
            return $currentSPHash -ne $SPHashList.($SP.EntityID)
        }
        else
        {
            return $true #Can't find the cached entity so it has changed
        }
    }
    catch
    {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPCouldNotGetChachedEntity)

    }
    
    #if (![string]::IsNullOrEmpty($SP))
    #{
    #    $currentSPHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($SP)))
    #}
    #
    #if ($SPHashList.ContainsKey($SP.EntityID))
    #{
    #    if ($currentSPHash -eq $SPHashList.($SP.EntityID))
    #    {
    #        return $false
    #    }
    #    else
    #    {
    #        Add-ADFSTkEntityHash $SP -spHash $currentSPHash
    #        return $true
    #    }
    #
    #    #return ($currentSPHash -ne $SPHash.($SP.EntityID))
    #}
    #else
    #{
    #    Add-ADFSTkEntityHash $SP -spHash $currentSPHash
    #    return $true #EntityID didn't exist ie it has changed
    #}
}

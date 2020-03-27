function Processes-ADFSTkRelyingPartyTrust {
param (
    $sp
)

    if ((Get-ADFSRelyingPartyTrust -Identifier $sp.EntityID) -eq $null)
    {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPEntityNotInADFS -f $sp.EntityID)
        Add-ADFSTkSPRelyingPartyTrust $sp
    }
    else
    {
        $Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1

        if ($ForceUpdate)
        {
            if ((Get-ADFSRelyingPartyTrust -Name $Name) -ne $null)
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText processRPRPAddedManualAbortingForce -f $sp.EntityID) -EntryType Warning -EventID 26
                Add-ADFSTkEntityHash -EntityID $sp.EntityID
            }
            else
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPRPInADFSForcingUpdate -f $sp.EntityID)
                #Update-SPRelyingPartyTrust $_
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPDeletingRP -f $sp.EntityID)
                try
                {
                    Remove-ADFSRelyingPartyTrust -TargetIdentifier $sp.EntityID -Confirm:$false -ErrorAction Stop
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPDeletingRPDone -f $sp.EntityID)
                    Add-ADFSTkSPRelyingPartyTrust $sp
                }
                catch
                {
                    Write-ADFSTkLog (Get-ADFSTkLanguageText processRPCouldNotDeleteRP -f $sp.EntityID, $_) -EntryType Error -EventID 27
                }
            }
        }
        else
        {
            if ($AddRemoveOnly -eq $true)
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPSkippingDueToAddRemoveOnlySwitch)
            }
            elseif (Get-ADFSTkAnswer (Get-ADFSTkLanguageText processRPEntityAlreadyExistsDoUpdate -f $sp.EntityID))
            {
                if ((Get-ADFSRelyingPartyTrust -Name $Name) -ne $null)
                {
                    $Continue = Get-ADFSTkAnswer (Get-ADFSTkLanguageText processRPEntityAddedManuallyStillUpdate -f $sp.EntityID)
                }
                else
                {
                    $Continue = $true
                }

                if ($Continue)
                {
                        
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPEntityInADFSWillUpdate -f $sp.EntityID)
                
                    #Update-SPRelyingPartyTrust $_
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPDeletingRP -f $sp.EntityID)
                    try
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $sp.EntityID -Confirm:$false -ErrorAction Stop
                        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPDeletingRPDone -f $sp.EntityID)
                        Add-ADFSTkSPRelyingPartyTrust $sp
                    }
                    catch
                    {
                        Write-ADFSTkLog (Get-ADFSTkLanguageText processRPCouldNotDeleteRP -f $sp.EntityID, $_) -EntryType Error -EventID 28
                    }
                }
            }
        }
    }
}
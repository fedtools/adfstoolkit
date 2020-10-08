function Processes-ADFSTkRelyingPartyTrust {
param (
    $sp
)

    $Prefix = $Settings.configuration.MetadataPrefix 
    $Sep = $Settings.configuration.MetadataPrefixSeparator      
    $PrefixWithSeparator = "$Prefix$Sep"
    
    $adfsSP = Get-ADFSRelyingPartyTrust -Identifier $sp.EntityID

    $SPGotPrefix = $false
    if ($adfsSP -ne $null)
    {
        $SPGotPrefix = $adfsSP.Name.StartsWith($PrefixWithSeparator)
    }
    
    if ($adfsSP -eq $null)
    {
        Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText processRPEntityNotInADFS -f $sp.EntityID)
        Add-ADFSTkSPRelyingPartyTrust $sp
    }
    else
    {
        if ($ForceUpdate)
        {
            if ($SPGotPrefix) 
            {
                #ADFSTk added this and can take actions with it
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
            else
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText processRPRPAddedManualAbortingForce -f $sp.EntityID) -EntryType Warning -EventID 26
                #Add-ADFSTkEntityHash -EntityID $sp.EntityID
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
                if ($SPGotPrefix)
                {
                    #ADFSTk added this and can take actions with it
                    $Continue = $true
                }
                else
                {
                    $Continue = Get-ADFSTkAnswer (Get-ADFSTkLanguageText processRPEntityAddedManuallyStillUpdate -f $sp.EntityID)
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
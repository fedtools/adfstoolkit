function Unpublish-ADFSTkAggregate

{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]

    param (
            [string]$FilterString = 'ADFStk:'
    )


    $CurrentSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "$FilterString*"} | select -ExpandProperty Identifier

            
    foreach ($rp in $CurrentSPs)
    {
        Write-ADFSTkVerboseLog "Removing `'$($rp)`'..."
        try 
        {
            Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
            Write-ADFSTkVerboseLog "Deleted $rp"
        }
        catch
        {
            Write-ADFSTkLog "Could not remove `'$($rp)`'! Error: $_" -EntryType Error
        }

    }

}
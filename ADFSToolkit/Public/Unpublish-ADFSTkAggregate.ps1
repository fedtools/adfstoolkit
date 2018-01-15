function Unpublish-ADFSTkAggregate

{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]

    param (
            [string]$FilterString = "ADFStk:"
    )

    if ($PSCmdlet.ShouldProcess($FilterString)) {

            Write-ADFSTkVerboseLog "Searching ADFS for SPs with Name starting with $FilterString"

            $CurrentSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "$FilterString*"} | select -ExpandProperty Identifier

            $numSPs=$CurrentSPs.count

            Write-ADFSTkVerboseLog "SPs detected: $numSPs"
            
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
            Write-ADFSTkVerboseLog "job completed"
      }

}
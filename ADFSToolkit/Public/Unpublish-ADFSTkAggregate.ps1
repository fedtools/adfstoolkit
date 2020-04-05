function Unpublish-ADFSTkAggregate

{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]

    param (
            [string]$FilterString = "ADFStk:"
    )

    ### ToDo: User Get-ADFSTkAnswer to veiw which SPs that will be deleted.

    if ($PSCmdlet.ShouldProcess($FilterString)) {

            Write-ADFSTkLog (Get-ADFSTkLanguageText unpubSearchingRPsWithFilter -f $FilterString)

            $CurrentSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "$FilterString*"} | select -ExpandProperty Identifier

            $numSPs=$CurrentSPs.count

            Write-ADFSTkLog (Get-ADFSTkLanguageText unpubRPsFound -f $numSPs)
            
            foreach ($rp in $CurrentSPs)
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cRemoving -f $rp)
                try 
                {
                    Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                    Write-ADFSTkLog (Get-ADFSTkLanguageText unpubRPDeleted -f $rp)
                }
                catch
                {
                    Write-ADFSTkLog (Get-ADFSTkLanguageText cCouldNotRemove -f $rp, $_) -EntryType Error
                    
                }

            }
            Write-ADFSTkLog (Get-ADFSTkLanguageText unpubJobCompleated)
      }

}
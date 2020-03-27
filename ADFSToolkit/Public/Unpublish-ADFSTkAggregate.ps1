function Unpublish-ADFSTkAggregate

{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]

    param (
            [string]$FilterString = "ADFStk:"
    )

    if ($PSCmdlet.ShouldProcess($FilterString)) {

            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText unpubSearchingRPsWithFilter -f $FilterString)

            $CurrentSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "$FilterString*"} | select -ExpandProperty Identifier

            $numSPs=$CurrentSPs.count

            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText unpubRPsFound -f $numSPs)
            
            foreach ($rp in $CurrentSPs)
            {
                Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText cRemoving -f $rp)
                try 
                {
                    Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                    Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText unpubRPDeleted -f $rp)
                }
                catch
                {
                    Write-ADFSTkLog (Get-ADFSTkLanguageText cCouldNotRemove -f $rp, $_) -EntryType Error
                    
                }

            }
            Write-ADFSTkVerboseLog (Get-ADFSTkLanguageText unpubJobCompleated)
      }

}
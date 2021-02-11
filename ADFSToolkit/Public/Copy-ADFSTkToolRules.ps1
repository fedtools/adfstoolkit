function Copy-ADFSTkToolRules {
    [CmdletBinding(DefaultParameterSetName = 'CustomTarget')]
    param (
        #[Parameter(ParameterSetName = 'AllCustom')]
        $sourceEntityID,
        [Parameter(ParameterSetName = 'CustomTarget')]
        $targetEntityID,
        [Parameter(ParameterSetName = 'ClaimsXRay')]
        [switch]
        $ClaimsXRay
    )


    if (!$PSBoundParameters.ContainsKey("sourceEntityID")) {
        $allSPs = Get-ADFSTkToolEntityId -All
        $sourceEntityID = $allSPs | Out-GridView -Title (Get-ADFSTkLanguageText toolSelectSource) -PassThru
        if ([string]::IsNullOrEmpty($sourceEntityID)) {
            Write-ADFSTkLog -Message (Get-ADFSTkLanguageText toolNoSourceSelected) -MajorFault
        }
        else {
            $sourceEntityID = $sourceEntityID.Identifier
        }
    }

    if ($PSCmdlet.ParameterSetName -eq 'ClaimsXRay') {
        $targetEntityID = 'urn:microsoft:adfs:claimsxray'
    }
    else {
        if (!$PSBoundParameters.ContainsKey("targetEntityID")) {
            if ([string]::IsNullOrEmpty($allSPs)) {
                $allSPs = Get-ADFSTkToolEntityId -All
            }
            $targetEntityID = $allSPs | Out-GridView -Title (Get-ADFSTkLanguageText toolSelectTarget) -PassThru
            if ([string]::IsNullOrEmpty($targetEntityID)) {
                Write-ADFSTkLog -Message (Get-ADFSTkLanguageText toolNoSourceSelected) -MajorFault
            }
            else {
                $targetEntityID = $targetEntityID.Identifier
            }
        }
    }

    $oldIssuanceTransformRules = Get-AdfsRelyingPartyTrust -Identifier $targetEntityID | select -ExpandProperty IssuanceTransformRules
    $newIssuanceTransformRules = Get-AdfsRelyingPartyTrust -Identifier $sourceEntityID | select -ExpandProperty IssuanceTransformRules

    if (Get-ADFSTkAnswer (Get-ADFSTkLanguageText toolAreYouSure -f $sourceEntityID,$targetEntityID))
    {
        Get-AdfsRelyingPartyTrust -Identifier $targetEntityID | Set-AdfsRelyingPartyTrust -IssuanceTransformRules $newIssuanceTransformRules
        Write-ADFSTkLog -Message (Get-ADFSTkLanguageText toolRulesCopiedFromTo -f $targetEntityID, $sourceEntityID, $oldIssuanceTransformRules, $newIssuanceTransformRules) -EventID 45 -EntryType Information
        Write-ADFSTkHost cAllDone -ForegroundColor Green
    }

    
}
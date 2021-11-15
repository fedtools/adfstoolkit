function New-ADFSTKAccessControlPolicy {
    $ACPMetadata = @"
    <PolicyMetadata xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.datacontract.org/2012/04/ADFS">
      <RequireFreshAuthentication>false</RequireFreshAuthentication>
      <IssuanceAuthorizationRules>
        <Rule>
          <Conditions>
            <Condition i:type="SpecificClaimCondition">
              <ClaimType>http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationmethod</ClaimType>
              <Operator>Equals</Operator>
              <Values>
                <Value>https://refeds.org/profile/mfa</Value>
              </Values>
            </Condition>
            <Condition i:type="MultiFactorAuthenticationCondition">
              <Operator>IsPresent</Operator>
              <Values />
            </Condition>
          </Conditions>
        </Rule>
        <Rule>
          <Conditions>
            <Condition i:type="AlwaysCondition">
              <Operator>IsPresent</Operator>
              <Values />
            </Condition>
          </Conditions>
        </Rule>
      </IssuanceAuthorizationRules>
    </PolicyMetadata>
"@
    New-AdfsAccessControlPolicy -Name "ADFSTk:Permit everyone and force MFA" `
        -Identifier ADFSToolkitPermitEveryoneAndRequireMFA `
        -Description "Grant access to everyone and require MFA for everyone." `
        -PolicyMetadata $ACPMetadata | Out-Null
}
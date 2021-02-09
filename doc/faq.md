# FAQ
## How can I search for a specific SP?
```Powershell
Get-ADFSTkToolEntityId
```
## How can I copy rules from one SP to another?
```Powershell
Copy-ADFSTkToolRules
```
## How can I test that the rules on a SP works as expected?
```Powershell
Copy-ADFSTkToolRules -ClaimsXRay
```
## How can I use ADFS Toolkit to set rules on SP's that are not part of the federation?
```Powershell
$entityID = "entityid.of.the.sp"
$rules = Get-ADFSTkToolsIssuanceTransformRules -entityId $entityID -SelectAttributes
Get-AdfsRelyingPartyTrust -Identifier $entityID | Set-AdfsRelyingPartyTrust -IssuanceTransformRules $rules
```
## How can I allow only members in a specific group to logon to a SP?
```Powershell
$entityID = "entityid.of.the.sp"
$authRules = @"
@RuleName = "Allow users in [Group]"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid", Value == "[GroupSID]", Issuer == "AD AUTHORITY"]
  => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");
"@
Get-AdfsRelyingPartyTrust -Identifier $entityID | Set-AdfsRelyingPartyTrust -IssuanceAuthorizationRules $authRules
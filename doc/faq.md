# FAQ
## How can I search for a specific SP?
We have a cmdlet for that in ADFS Toolkit.
|:heavy_check_mark: The cmdlet connects directly to the ADFS database and reads from it. To be able to use this cmdlet you need access to that database. |
|-----------------------------------------------------------------------------|
If run without parameters a GridView will show up and you can use it to scroll through all SP's or search for a specific SP. You can also search for all SP's ending with a specific domain.
```Powershell
Get-ADFSTkToolEntityId
```
The cmdlet will return the entityID of the selected SP.

You can also use the parameter ``-All`` to get all entityID's of the ADFS or ``-Search`` to retrieve all SP's whos name contains the search word.
## How can I copy rules from one SP to another?
Sometimes it's convenient to copy all rules from one SP to another. ADFS Toolkit has a cmdlet for it.
```Powershell
Copy-ADFSTkToolRules -sourceEntityID "source.etity.id" -targetEntityID "target.entity.id"
```
The result will be logged on screen and in the Event Log.

|:heavy_check_mark: If sourceEntityID or targetEntityID is omitted, the cmdlet Get-ADFSTkToolEntityId will be used to show you all SP's in the database. You will then need to have access to the ADFS database.|
|-----------------------------------------------------------------------------|
## How can I test that the rules on a SP works as expected?
There are many ways you can test the rules on a SP. 
- Some SP's has a 'test page' where you can see all the provided claims
- Press F12 and use the browser's "developer tools' to look at the SAML data
    - If the claims are encrypted you can *temporary delete* the encryption certificate on the SP so see the claims. ATTENTION! Only do this in your test environment or when/if you know it's OK to do so.
- Use an addin for your browser to show the SAML data
    - For FireFox, UNINETT has made SAML-tracer which works great
    - If the claims are encrypted you can *temporary delete* the encryption certificate on the SP so see the claims. ATTENTION! Only do this in your test environment or when/if you know it's OK to do so.
- Copy the rules from the SP you want to test to a specific Test-SP that will show you the claims provided
    - Some federations provides these kind of SP's to the members
    - Microsoft provides [Claims X-Ray](https://adfshelp.microsoft.com/ClaimsXray/) to do this. [Claims X-Ray](https://adfshelp.microsoft.com/ClaimsXray/) is easy to add to ADFS and will also give you the posibility to test different logon methods and protocols. 

You can easily copy rules from a SP to Claims X-Ray with the following command:
```Powershell
Copy-ADFSTkToolRules -sourceEntityID "source.etity.id" -ClaimsXRay
```
## How can I use ADFS Toolkit to set rules on SP's that are not part of the federation?
Yes, ADFS Toolkit can be used to create manual rules for any SP.
Use the cmdlet ``Get-ADFSTkToolsIssuanceTransformRules`` to take advantage of ADFS Toolkit's attibute release engine and create rules for any SP. When the parameter ``-SelectAttributes`` is used a GridView will show where you can select all attributes you need for the SP.
```Powershell
$entityID = "entityid.of.the.sp"
$rules = Get-ADFSTkToolsIssuanceTransformRules -entityId $entityID -SelectAttributes
Get-AdfsRelyingPartyTrust -Identifier $entityID | Set-AdfsRelyingPartyTrust -IssuanceTransformRules $rules
```
## How can I allow only members in a specific group to logon to a SP?
If you want to restrict who can logon to a specific SP you need to create a manual SP Setting in the file ``Get-ADFSTkLocalManualSPSettings.ps1``. The file is located here:
`` "C:\ADFSToolkit\config\institution\get-ADFSTkLocalManualSPSettings.ps1"``

Add a section in the file that lookes like below. Replace the values in [] to relevant values for you:
```Powershell
### The name of the SP

    $ManualSPSettings = @{
        #TransformRules = [Ordered]@{}
        AuthorizationRules = @{}
        #HashAlgorithm = $SecureHashAlgorithm.SHA256
        #EntityCategories = @("http://www.geant.net/uri/dataprotection-code-of-conduct/v1")
    }

    $ManualSPSettings.AuthorizationRules = @"
@RuleName = "Allow users in [Group]"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid", Value == "[GroupSID]", Issuer == "AD AUTHORITY"]
  => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");
"@
$IssuanceTransformRuleManualSP["entityid.of.the.sp"] = $ManualSPSettings 

###
```

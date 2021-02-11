# FAQ
## How can I search for a specific SP?

ADFSToolkit bundles a cmdlet for this:
```Powershell
Get-ADFSTkToolEntityId
```
### Synopsis: ###

A cmdlet that connects directly to the ADFS database and reads from it. To be able to use this cmdlet you need access and sufficient privileges; local Administrator on the target AD FS server will be required. 

If run without parameters a GridView will show up and you can use it to scroll through all SP's or search for a specific SP. You can also search for all SP's ending with a specific domain.
The cmdlet will return the entityID of the selected SP.

**Examples:**
- get all entityID's from AD FS:

```Powershell
Get-ADFSTkToolEntityId -All
```

- keyword search entityID's from AD FS:

```Powershell
Get-ADFSTkToolEntityId -Search key_word
```

## How can I copy rules from one SP to another?
Sometimes it's convenient to copy all rules from one SP to another. ADFS Toolkit has a cmdlet for it.
```Powershell
Copy-ADFSTkToolRules -sourceEntityID "source.etity.id" -targetEntityID "target.entity.id"
```
The result will be logged on screen and in the Event Log.

If sourceEntityID or targetEntityID is omitted, the cmdlet Get-ADFSTkToolEntityId will be used to show you all SP's in the database as long as you are in a Administrator level Powershell session

## How do I copy rules from and SP to Claims X-Ray?
Claims X-Ray is a common test target and ADFSToolkit has a special switch once you have configured Claims X-Ray in your ADFS. 

You can easily copy rules from a SP to Claims X-Ray with the following command:
```Powershell
Copy-ADFSTkToolRules -sourceEntityID "source.etity.id" -ClaimsXRay
```
|:exclamation: Be mindful using Claims X-Ray and use test accounts where possible as this will send data outside your organization |
|-----------------------------------------------------------------------------|


## How can I test that the rules on a SP works as expected?
There are many ways you can test the rules on a SP:
- The SP's may have a 'test page' that reveals your attributes (e.g. for Shibboleth sites, session info is at https://site.domain/Shibboleth.sso/Session)
- Use the 'developer tools' options in modern browsers to look at the SAML data
- Use a browser plugin such as SAML-tracer by UNINETT to show the SAML data flow
- Copy the rules from the SP you want to test to a specific Test-SP that will show you the claims provided
  - Check with your federation operator for an appropriate test SP 
  - Microsoft hosts  [Claims X-Ray](https://adfshelp.microsoft.com/ClaimsXray/) open to all.  [Claims X-Ray](https://adfshelp.microsoft.com/ClaimsXray/) is easy to add to ADFS and will also give you the posibility to test different logon methods and protocols. 

|:exclamation: In all cases during testing be mindful that the test cases and data you are working with are suitable for the purpose
|-----------------------------------------------------------------------------|
### I can't read the attributes even if I use SAML-tracer, now what?

If the claims are encrypted you can *temporary delete* the encryption certificate on the SP so see the claims. 




## Can ADFSToolkit be used to set rules on SP's that are not part of the federation?
Yes, ADFSToolkit can be used to create manual rules for any SP.

to take advantage of ADFS Toolkit's attibute release engine and create rules for any SP use the cmdlet ``Get-ADFSTkToolsIssuanceTransformRules`` . 

**Examples**
To invoke a GridView interface  add in the parameter ``-SelectAttributes``. This will allow you to select one or more attribute transforms you need for the SP.
The exammple below shows the rules being appropriately structured to be used with the pipelined command ``Set-AdfsRelyingPartyTrust``:

```Powershell
$entityID = "entityid.of.the.sp"
$rules = Get-ADFSTkToolsIssuanceTransformRules -entityId $entityID -SelectAttributes
Get-AdfsRelyingPartyTrust -Identifier $entityID | Set-AdfsRelyingPartyTrust -IssuanceTransformRules $rules
```
## Can I restrict access to an SP to members of a specific group?
Yes, if you want to restrict who can logon to a specific SP you need to create a manual SP Setting in the file ``Get-ADFSTkLocalManualSPSettings.ps1``. 

To do this, edit the localized SP settings file here:
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
@RuleName = "Allow users in [Replace_with_Friendly_Group_Name]"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid", Value == "[Specific_GroupSID_no_square_brackets]", Issuer == "AD AUTHORITY"]
  => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");
"@
$IssuanceTransformRuleManualSP["entityid.of.the.sp"] = $ManualSPSettings 

###
```

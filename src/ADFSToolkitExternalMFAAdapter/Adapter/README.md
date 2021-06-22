#### Powershell for installing and uninstalling the External IDP MFA Adapter ####
```

#Prerequisites 
[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
$publish = New-Object System.EnterpriseServices.Internal.Publish
$publish.GacInstall("C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\System.DirectoryServices.dll")
$publish.GacInstall("C:\admin\install\ADFSEduIDAdapter\Newtonsoft.json.dll")

##Enable third party, one time operation
Set-AdfsGlobalAuthenticationPolicy -AllowAdditionalAuthenticationAsPrimary $true -Force

## EventLogSource, one time operation
New-EventLog -Source "AD FS" -LogName Application

# Install
Set-Location "C:\admin\install"
$name = "ExternalIdpMFAAdapter";

[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
$publish = New-Object System.EnterpriseServices.Internal.Publish

$publish.GacInstall("C:\admin\install\ADFSToolkitExternalMFA\ADFSTK.ExternalMFA.AdapterMerged.dll")

$fn = ([System.Reflection.Assembly]::LoadFile("C:\admin\install\ADFSToolkitExternalMFA\ADFSTK.ExternalMFA.AdapterMerged.dll")).FullName

$typeName = "ADFSTK.ExternalMFA.ExternalRefedsMFAAdapter, " + $fn.ToString() + ", processorArchitecture=MSIL"
Register-AdfsAuthenticationProvider -TypeName $typeName -Name $name -ConfigurationFilePath 'C:\admin\install\ADFSToolkitExternalMFA\ExternalMFASettings.json'

restart-service adfssrv



# Uninstall
$name = "ExternalIdpMFAAdapter"
[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
$publish = New-Object System.EnterpriseServices.Internal.Publish

Unregister-AdfsAuthenticationProvider -Name $name -Confirm:$false

restart-service adfssrv

$publish.GacRemove("C:\admin\install\ADFSToolkitExternalMFA\ADFSTK.ExternalMFA.AdapterMerged.dll")



# Rules for setting up proxy on ADFS

##Additional Authentication Rules (Forces AzureMFA)
Set-AdfsRelyingPartyTrust -TargetIdentifier $rp -AdditionalAuthenticationRules 
 '=>issue(Type = "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationmethod", Value = "http://schemas.microsoft.com/claims/multipleauthn");''

##Issuance Authorization Rules
Permit if otp
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value =~ "^(?i)http://schemas\.microsoft\.com/ws/2012/12/authmethod/otp$"]
 => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "PermitUsersWithClaim");

Deny if not otp
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value =~ "^(?i)^(?!http://schemas\.microsoft\.com/ws/2012/12/authmethod/otp)$"]
 => issue(Type = "http://schemas.microsoft.com/authorization/claims/deny", Value = "DenyUsersWithClaim");

##Issuance Transform Rules
Check RefedsMFA context class after successful MFA with TOTP
c:[Type == "http://schemas.microsoft.com/claims/authnmethodsreferences", Value == "http://schemas.microsoft.com/ws/2012/12/authmethod/otp"]
=> add(Type = "urn:adfstk:mfalogon", Value = "true");

Exists RefedsMFA context class after successful MFA with TOTP
NOT EXISTS([Type == "urn:adfstk:mfalogon"])
=> issue(Type = "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationmethod", Value = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport");

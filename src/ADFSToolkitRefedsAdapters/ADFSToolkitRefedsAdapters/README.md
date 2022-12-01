#### Powershell for installing and uninstalling the CustomPrimaryUsernamePasswordFactor ####
```

#Prerequisites 
##Enable third party, one time operation
Set-AdfsGlobalAuthenticationPolicy -AllowAdditionalAuthenticationAsPrimary $true -Force


# Install
Set-Location "C:\admin\install"
$nameMFA = "RefedsMFAUsernamePasswordAdapter"
$nameSFA = "RefedsSFAUsernamePasswordAdapter"
[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
$publish = New-Object System.EnterpriseServices.Internal.Publish

$publish.GacInstall("C:\admin\install\ADFSToolkitAdapters\ADFSToolkitAdapters.dll")

$fn = ([System.Reflection.Assembly]::LoadFile("C:\admin\install\ADFSToolkitAdapters\ADFSToolkitAdapters.dll")).FullName

$typeNameMFA = "ADFSTk.RefedsMFAUsernamePasswordAdapter, " + $fn.ToString() + ", processorArchitecture=MSIL"
$typeNameSFA = "ADFSTk.RefedsSFAUsernamePasswordAdapter, " + $fn.ToString() + ", processorArchitecture=MSIL"
Register-AdfsAuthenticationProvider -TypeName $typeNameMFA -Name $nameMFA 
Register-AdfsAuthenticationProvider -TypeName $typeNameSFA -Name $nameSFA


##Register 
$authPolicy = Get-AdfsGlobalAuthenticationPolicy
Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider ($authPolicy.PrimaryExtranetAuthenticationProvider + $nameMFA + $nameSFA) `
				   -PrimaryIntranetAuthenticationProvider ($authPolicy.PrimaryIntranetAuthenticationProvider + $nameMFA + $nameSFA)

net stop adfssrv
net start adfssrv


# Uninstall
$nameMFA = "RefedsMFAUsernamePasswordAdapter"
$nameSFA = "RefedsSFAUsernamePasswordAdapter"
[System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
$publish = New-Object System.EnterpriseServices.Internal.Publish

$authPolicy = Get-AdfsGlobalAuthenticationPolicy
$authPolicy.PrimaryIntranetAuthenticationProvider.Remove($nameMFA)
$authPolicy.PrimaryIntranetAuthenticationProvider.Remove($nameSFA)
$authPolicy.PrimaryExtranetAuthenticationProvider.Remove($nameMFA)
$authPolicy.PrimaryExtranetAuthenticationProvider.Remove($nameSFA)
Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider $authPolicy.PrimaryExtranetAuthenticationProvider `
				   -PrimaryIntranetAuthenticationProvider $authPolicy.PrimaryIntranetAuthenticationProvider

Unregister-AdfsAuthenticationProvider -Name $nameMFA -Confirm:$false
Unregister-AdfsAuthenticationProvider -Name $nameSFA -Confirm:$false
net stop adfssrv
net start adfssrv
$publish.GacRemove("C:\admin\install\ADFSToolkitAdapters\ADFSToolkitAdapters.dll")


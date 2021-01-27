# ADFSToolkit

A PowerShell Module for optimal handling of SAML2 multi-lateral federation aggregates for Microsoft's AD FS.

ADFSToolkit reduces installation and configuration time to minutes for proper handling of metadata aggregates from Research and Education (R&E) Federated Identity Management service federations. This allows AD FS to behave as a viable IdP in a SAML2 R&E federation.

# Sites using ADFSToolkit
- CANARIE's Canadian Access Federation: https://www.canarie.ca/identity/support/fim-tools/
- Sweden's Sunet - SWAMID: https://wiki.sunet.se/display/SWAMID/How+to+consume+SWAMID+metadata+with+ADFS+Toolkit

# Table Of Contents
* [Installation](./doc/README.md)
* [Upgrading](./doc/upgrade.md)

| :warning:      Install ADFSToolkit via [PowerShellGallery.com](https://www.powershellgallery.com/packages/ADFSToolkit/)  |
|-----------------------------------------------------------------------------|

For more details on how to prepare for using PowerShellGallery and PowerShellGet Modules see 
- https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget and 
- https://docs.microsoft.com/en-us/powershell/scripting/gallery/getting-started 

ADFSToolkit uses Microsoft’s PowerShellGallery.com service and distribution channel for code lifecycle management.
Critical to this is being current on PowerShellGallery's latest PowerShellGet Module.

ADFSToolkit's PowershellGallery page is [here](https://www.powershellgallery.com/packages/ADFSToolkit/) 


## System Requirements
ADFSToolkit V2 must be installed on Windows Server that is one of your AD FS hosts with:
- Microsoft Windows Server 2016 (AD FS v4) or higher and kept current on patches
- Powershell 5.1 which ships with Server 2016
- Local administrator privileges to schedule privileged jobs
- AD FS administrator-level permissions to run PowerShell commands
- Acceptance of the security considerations running PowerShell retrieved from Microsoft’s PowerShellgallery.com 

Optional but strongly suggested: A test AD FS environment to perform the installation prior to installing in production.

| :heavy_check_mark: Expect a few thousand Relying Party trusts in the AD FS Console after your first run|
|-----------------------------------------------------------------------------|


## Attribute Release Practices of ADFSToolkit 
Built for and by the Research and Educational(R&E) community ADFSToolkit embraces scalable attribute release management principles of R&E federations. 
One of these techniques is the use of Entity Categories for attribute release. 
Entity Categories are tags in SAML2 metadata on an entity that indicate membership in a given category of service. 
The attribute release model using Entity Categories has a release policy set against the category, not the entity. 
 When ADFSToolkit parses entities to load into AD FS and encounters an Entity Category called ‘Research and Scholarship’, it automatically creates multiple AD FS transform rules that reflect the minimal set of attributes released, not much different than your public directory pages. For R&S these are:
- eduPersonPrincipalName (left hand of the at sign of the UPN concatenated with your domain)
- mail
- displayName
- givenName
- sn (Surname)
- eduPersonScopedAffiliation (controlled vocabulary mapped from groups in AD)

This is the default behaviour of ADFSToolkit. Contact your Federatoon Operator to also tag your IdP entity as supporting R&S Entity Category and improve the user experience for all your users.

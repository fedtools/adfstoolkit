# ADFSToolkit

A PowerShell Module used to handle SAML2 multi-lateral federation aggregates

The ADFSToolkit was designed to rapidly configure your Active Directory Federation Services (AD FS v3 or higher) 
in order to connect to the CANARIE Canadian Access Federation’s Federated Identity Management (FIM) service. 
The ADFSToolkit reduces the installation and configuration time for CAF services to a matter of minutes and offers 
techniques to manage trust in a scalable fashion.

# Installation Procedure

:exclamation: Installing from this GIT repository is not recommended - please use PowerShellGallery.com: https://www.powershellgallery.com/packages/ADFSToolkit/

ADFSToolkit uses Microsoft’s PowerShellGallery.com service as the official primary distribution channel of ADFSToolkit as a PowerShell Module.  This allows us to rely on Microsoft’s approach to managing distribution and updated PowerShell Modules for the lifecycle of ADFSToolkit.
To install ADFSToolkit you will need to:
- Visit https://PowerShellgallery.com and follow the instructions to install the latest PowerShellGet Module from PowerShellGallery 


## System Requirements
ADFSToolkit must be installed on a Windows Server (your AD FS host) with:
- Microsoft AD FS v3 or higher
- Local administrator privileges to schedule privileged jobs
- AD FS administrator-level permissions to run PowerShell commands
- Acceptance of the security considerations running PowerShell retrieved from Microsoft’s PowerShellgallery.com 

While not a firm requirement, we strongly suggest a test AD FS environment to perform the installation prior to installing in production. 
You should be aware that after installation, you will see a few thousand trusts displayed within the administration toolset, AD FS-Microsoft Management Console (MMC).
###	Minimum Server OS 
Windows Server 2012 R2 or newer is the minimal level of OS supported. You should also be current on latest OS and security patch/updates provided by Microsoft.
###	Minimum PowerShell Version 
ADFSToolkit uses Microsoft’s PowerShell with Windows Management Framework (WMF) 5.1. To see if your host is WMF5.1 ready, check the Microsoft Compatibility Matrix.
To quickly see which version of PowerShell you have, open a PowerShell window or PowerShell ISE window and enter $PSVersionTable. If you do not see version 5.1, you will need to update your environment first.

## Attribute Release Practices of ADFSToolkit 
ADFSToolkit is a component built for and by the research and educational community that embraces scalable attribute release management principles of  R&E federations.  One of these techniques is the use of Entity Categories for attribute release. Entity Categories are tags in SAML2 metadata on an entity that indicate membership in a given category of service. The attribute release model using Entity Categories has a release policy set against the category, not the entity. 
 When ADFSToolkit parses entities to load into AD FS and encounters an Entity Category called ‘Research and Scholarship’ , it automatically creates multiple AD FS transform rules that reflect the minimal set of attributes released, not much different than your public directory pages, for R&S these are:
- eduPersonPrincipalName (left hand of the at sign of the UPN concatenated with your domain)
- mail
- displayName
- givenName
- sn (Surname)
- eduPersonScopedAffiliation (controlled vocabulary mapped from groups in AD)

This is the default behaviour of ADFSToolkit and by using this tool, you are enabling this model of attribute release by default.  You are  encouraged to contact CANARIE and register your organizations as supporting Research and Scholarship entity category for more benefits. See this link for more detail: https://www.canarie.ca/identity/fim/research-and-scholarship-entity-category/

# Related links

## Sites using ADFSToolkit
- CANARIE's Canadian Access Federation: https://www.canarie.ca/identity/support/fim-tools/
- Sweden's Sunet - SWAMID: https://wiki.sunet.se/display/SWAMID/How+to+consume+SWAMID+metadata+with+ADFS+Toolkit
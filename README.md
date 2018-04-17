# ADFSToolkit

A PowerShell Module used to handle SAML2 multi-lateral federation aggregates

The ADFSToolkit was designed to rapidly configure your Active Directory Federation Services (AD FS v3 or higher) 
to connect to Research and Education (R&E) Federated Identity Management services. 
The ADFSToolkit reduces the installation and configuration time for CAF services to a matter of minutes and offers 
techniques to manage trust in a scalable fashion stepping up AD FS's trust model to be sufficient to be an IdP in a SAML2 R&E federation.

# Sites using ADFSToolkit
- CANARIE's Canadian Access Federation: https://www.canarie.ca/identity/support/fim-tools/
- Sweden's Sunet - SWAMID: https://wiki.sunet.se/display/SWAMID/How+to+consume+SWAMID+metadata+with+ADFS+Toolkit

# Installation Procedure

:exclamation: Installing from this GIT repository is not recommended - please use PowerShellGallery.com :exclamation:

https://www.powershellgallery.com/packages/ADFSToolkit/ 

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

# ADFSToolkit’s Lifecycle Management / Update Practice 
ADFSToolkit’s Module uses the PowerShell Gallery tool command ‘Update-Module’ to manage delivery of updates.  Sites using ADFSToolkit are strongly encouraged to have a test system to review changes between versions.  In cases where there is no test system, a snapshot/backup of their environment is strongly recommended. 
Note that some updates may require removing the cache files and run again completely to apply new features.  Updates that require this will be flagged as such in the release notes. It is up to the site operator to determine when to do this and to allow for sufficient time to recalculate the new improved settings. ADFSToolkit is designed to be idempotent in it’s operation – no matter how many times it is run, the resulting set will be the same which. 
The process to handle an update of ADFSToolkit is to:
- Back up the  C:\ADFSToolkit directory
- Create a system snapshot/recovery point to return to
- Disable/suspend the ADFSToolkit scheduled job
- Issue ‘Update-Module ADFSToolkit’
  - When Update-Module is run, it will attempt to detect if there is a newer version available from PowerShellGallery.com and download it. 
  - Note that each module is downloaded into it’s own directory containing the version number of the script.  ADFSToolkit will not run properly with more than one version available so once the new version is confirmed on disk and available, we recommend moving the older version out of the PowerShell path so that only the latest version is available. 
- Migrate existing configuration file and related cache files
  - Is possible but if you hand edited the settings before, you need to re-apply the changes after migrating the configuration to the new format. There are two ways to do this
    - Create the configuration as if they are new hand entering old answers
    - Taking advantage of the pipelining features of New-ADFSTkConfiguration which can ingest your existing configuration and fetch many of the existing settings and bring them into the new format.  You still need to inspect for any hand edits to be applied however.


Example of pipelining your old configuration into the new is below:
```
"C:\ADFSToolkit\0.9.1.55\config\config.CAF.xml" |New-ADFSTkConfiguration
```
Once you have completed the review of the  settings in configurations from the old configuration to the new configuration,ADFSToolkit
 - Determining migrating caches from old to new is required.
   - A sub-directory called ‘\cache’ in the live ADFSToolkit home is used to track changes in metadata and save time re-calculating entity records in ADFS. 
   - It is possible to copy the cache from the old version to the new one to preserve current processing status and usually is possible.
 - If there are major changes in how ADFSToolkit processes records it may be worthwhile to permit ADFSToolkit to recalculate everything again. This is done by NOT moving the old cache files over but the consequence is that all records will be refreshed and overwritten using the new logic.  This may be desireable depending on the changes available in the new version.
- Migrate Site specific overrides
  - The file c:\ADFSToolkit\#.#.#.#\get-ADFSTkLocalManualSpSettings.ps1 contains all your local settings. Review the release notes and if no instructions are offered, simply copying the file from the old version to the new one is sufficient.
    - If you do not copy this file into the newly created folder with the latest verion of ADFSToolkit job, all your settings for existing entities will be removed.
- Resuming synchronization of Metadata
  - Once manual operation has been validated, the ADFSToolkit job can be resumed in the Microsoft Job Scheduler and your migration considered complete.

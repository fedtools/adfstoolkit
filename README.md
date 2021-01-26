# ADFSToolkit

A PowerShell Module for optimal handling of SAML2 multi-lateral federation aggregates for Microsoft's AD FS.

ADFSToolkit reduces installation and configuration time to minutes for proper handling metadata aggregates from Research and Education (R&E) Federated Identity Management service federations. This allows AD FS to behave as a viable IdP in a SAML2 R&E federation.

# Sites using ADFSToolkit
- CANARIE's Canadian Access Federation: https://www.canarie.ca/identity/support/fim-tools/
- Sweden's Sunet - SWAMID: https://wiki.sunet.se/display/SWAMID/How+to+consume+SWAMID+metadata+with+ADFS+Toolkit

# Installation

> :warning: 
> ## **Install by PowerShellGallery.com from: https://www.powershellgallery.com/packages/ADFSToolkit/ 

For more details on how to use PowerShellGallery and PowerShellGet Modules see:
- https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget and
- https://docs.microsoft.com/en-us/powershell/scripting/gallery/getting-started

ADFSToolkit uses Microsoft’s PowerShellGallery.com service and distribution channel for code lifecycle management.
Critical to this is being current on PowerShellGallery's latest PowerShellGet Module.


## System Requirements
ADFSToolkit must be installed on Windows Server that is one of your AD FS hosts with:
- Microsoft AD FS v3 or higher
- Local administrator privileges to schedule privileged jobs
- AD FS administrator-level permissions to run PowerShell commands
- Acceptance of the security considerations running PowerShell retrieved from Microsoft’s PowerShellgallery.com 

While not a firm requirement, we strongly suggest a test AD FS environment to perform the installation prior to installing in production. 
You should be aware that after installation, you will see a few thousand trusts displayed within the administration toolset, AD FS-Microsoft Management Console (MMC).

###	Minimum Server OS 
Windows Server 2016 or newer is the minimal level of OS supported. You should also be current on latest OS and security patch/updates provided by Microsoft.
###	Minimum PowerShell Version 
ADFSToolkit uses Microsoft’s PowerShell with Windows Management Framework (WMF) 5.1. To see if your host is WMF5.1 ready, check the Microsoft Compatibility Matrix.
To quickly see which version of PowerShell you have, open a PowerShell window or PowerShell ISE window and enter $PSVersionTable. If you do not see version 5.1, you will need to update your environment first.

## Attribute Release Practices of ADFSToolkit 
ADFSToolkit is a component built for and by the research and educational community and embraces scalable attribute release management principles of  R&E federations. 
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

This is the default behaviour of ADFSToolkit and by using this tool, you are enabling this model of attribute release by default. You are encouraged to contact federation operators and register your organizations as supporting Research and Scholarship and other entity categories for more benefits.

# Install and configure ADFSToolkit for the first time
ADFSToolkit’s Module uses the PowerShell Gallery tool command `Install-Module` to download and install the code.
## Install ADFSToolkit
Run the following command to install ADFSToolkit
- Install-Module ADFSToolkit
> [!IMPORTANT] when running Install-Module a warning will be shown regarding trust for PSGallery. You need to accept the warning to be able to install ADFSToolkit this way.
## Configure ADFSToolkit
ADFSToolkit needs to be configured for your federation and institution. First configure it to the federation by running the following command:
 `New-ADFSTkConfiguration`
- Choose your federation in the presented Grid View and click OK
 Second configure ADFSToolkit for your Institution by running the following command:
`New-ADFSTkInstitutionConfiguration`
- The federation operators can provide you with default configuration files which will standardize some answers for the installation (i.e. the URL for the metadata etc). You will be prompted:
  - 'If your federation operators provides a federation-specific default configuration file, make sure to copy the folder to `C:\ADFSToolkit\config\federation` before proceeding.'
  - If you have been provided theese files, copy them to your federation's name folder provided above.
  - If you don't have the files or don't know if your federation provides them, you can proceed but need to type in the answers by yourself.
- If more than one default configuration file were provided by the federation operators, a Grid View will be presented with the different files. Choose the appropriate default configuration file and click OK.
- Answer the questions to complete the first stage of the institution configuration.
> [!IMPORTANT] You will be prompted to create a Scheduled Task in the end of the configuration. Only do this once! The Scheduled Task needs to be configured to run with an account with ADFS privileges. We also recommend to change the trigger to run every hour. 
- The `New-ADFSTkInstitutionConfiguration` has now created a institution configuration file under `C:\ADFSToolkit\config\institution` with the name `config.[federationprefix].xml`. Edit this file to configure the attribute release of ADFSToolkit. Use the inline help in the file for guidance.
- After all configuration is done we recommend that you import one or more SP's manually to review the attribute release. Do this by running the following command:
`Import-ADFSTkMetadata -ConfigFile C:\ADFSToolkit\config\institution\config.[federationprefix].xml -EntityId [entityID]`
- If the import were successful, enable the full import by enabling the configurationfile(s) with this command:
`Enable-ADFSTkInstitutionConfiguration`
    - Select the proper configuration file(s) and click OK.

ADFSToolkit will now be run by the Scheduled Task and make a full import/refresh each time. This first import will take some time due to all the new SP's. After that only the new/changed and removed SP's needs to be handled and that will be much faster.

Logging will occur in the Event Log, default under `Applications and Services log\ADFSToolkit`. 

# ADFSToolkit’s Lifecycle Management / Update Practice 
ADFSToolkit’s Module uses the PowerShell Gallery tool command `Update-Module` to manage delivery of updates. Sites using ADFSToolkit are strongly encouraged to have a test system to review changes between versions. In cases where there is no test system, a snapshot/backup of their environment is strongly recommended.

Note that some updates may require removing the cache files and run again completely to apply new features. Updates that require this will be flagged as such in the upgrade process. It is up to the site operator to determine when to do this and to allow for sufficient time to recalculate the new improved settings. ADFSToolkit is designed to be idempotent in it’s operation – no matter how many times it is run, the resulting set will be the same which. 

## Follow this  process to handle an update of ADFSToolkit
> [!IMPORTANT]
> If upgrading from an earlier version than v2.0.0, the ADFSToolkit scheduled job needs to be disabled/suspended before upgrading, and after the upgrade is done it needs to be updated manually.
- Back up the  C:\ADFSToolkit directory
- Create a system snapshot/recovery point to return to
- Issue `Update-Module ADFSToolkit`
  - When `Update-Module` is run, it will attempt to detect if there is a newer version available from PowerShellGallery.com and download it. 
  - Note that each module is downloaded into it’s own directory containing the version number of the script. ADFSToolkit might not run properly with more than one version available so once the new version is confirmed on disk and available, we recommend moving the older version out of the PowerShell path so that only the latest version is available. Use the cmdlet `Uninstall-Module ADFSToolkit -RequiredVersion 1.0.0.0` to uninstall v1.0.0.0
- Upgrade existing configuration file(s) by running the `Update-ADFSTkInstitutionConfiguration` cmdlet
    - The command will search for existing institution configuration files and present them in a Grid View. Select one or more configuration file(s) to start the upgrade.
    - The upgrade process will upgrade the configuration in version steps, so it's possible to jump several versions at the same time.
    - If the new version needs to re-process all SP's a message will show to inform that the cache files needs to be deleted. If you choose not to do this we cannot guarantee that the correct attributes are released from the Toolkit!
  > [!IMPORTANT] If the upgrade is from v1.0.0.0 or earlier we recommended that the ADFSToolkit folder `C:\ADFSToolkit` is cleaned from old folders and files. Only `C:\ADFSToolkit\config` and `C:\ADFSToolkit\cache` folders should remain, and no file(s) directly in the `C:\ADFSToolkit` folder. 

    > [!CAUTION] Take a backup of the files and folders before they are deleted!

Once the upgrade is done you should review the settings in the configuration file(s) too see that they are still looking correct.

  > [!IMPORTANT] If the upgrade is from v1.0.0.0 or earlier we recommended that the file `C:\ADFSToolkit\#.#.#.#\get-ADFSTkLocalManualSpSettings.ps1` (which contains all your local SP settings) are copied to `C:\ADFSToolkit\config\institution`. Please also review the release notes to see which new settings are offered.
If you do not copy this file into the new folder, all your manual settings for the existing entities will be removed.
- Resuming synchronization of Metadata
    - To enable the upgraded version, run `Enable-ADFSTkInstitutionConfiguration` and select the proper configuration file(s) and click OK.
> [!IMPORTANT] If the upgrade is from v1.0.0.0 or earlier the Scheduled job needs to be updated. Change the arguments under the action tab to: `-NoProfile -WindowStyle Hidden -Command 'Sync-ADFSTkAggregates'`

# ADFSToolkit

A PowerShell Module for optimal handling of SAML2 multi-lateral federation aggregates for Microsoft's AD FS.

ADFSToolkit reduces installation and configuration time to minutes for proper handling of metadata aggregates from Research and Education (R&E) Federated Identity Management service federations. This allows AD FS to behave as a viable IdP in a SAML2 R&E federation.

# Sites using ADFSToolkit
- CANARIE's Canadian Access Federation: https://www.canarie.ca/identity/support/fim-tools/
- Sweden's Sunet - SWAMID: https://wiki.sunet.se/display/SWAMID/How+to+consume+SWAMID+metadata+with+ADFS+Toolkit

# Table Of Contents
* [Installation](./doc/README.md)

| :warning:      Installation of ADFSToolkit is via PowerShellGallery.com only |
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

This is the default behaviour of ADFSToolkit and by using this tool, you are enabling this model of attribute release by default. You are encouraged to contact federation operators and register your organizations as supporting Research and Scholarship and other entity categories for more benefits.



# Upgrading
ADFSToolkit can be updated using the PowerShell command `Update-Module` which will fetch and install the latest updates. 
This may only take a few moments however propagating the changes completely may require the cache to be deleted and recalculated as if it were an initial install so plan accordingly and allocate sufficient time during an update. Updates that require this will be flagged as such in the upgrade process. 

## Recommended Update Practice for 
|:exclamation: When updating from versions prior to v2.0.0.0 be sure to disable/suspend the scheduled job and resume it after updates |
   |-----------------------------------------------------------------------------|

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

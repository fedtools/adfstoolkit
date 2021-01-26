# ADFSToolkit

A PowerShell Module for optimal handling of SAML2 multi-lateral federation aggregates for Microsoft's AD FS.

ADFSToolkit reduces installation and configuration time to minutes for proper handling of metadata aggregates from Research and Education (R&E) Federated Identity Management service federations. This allows AD FS to behave as a viable IdP in a SAML2 R&E federation.

# Sites using ADFSToolkit
- CANARIE's Canadian Access Federation: https://www.canarie.ca/identity/support/fim-tools/
- Sweden's Sunet - SWAMID: https://wiki.sunet.se/display/SWAMID/How+to+consume+SWAMID+metadata+with+ADFS+Toolkit

# Installation

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

# First Time Installation and Configuration of ADFSToolkit V2

## Installing
- Open a PowerShell prompt or PowerShell ISE window as administrator
- Run the following to download and install the latest stable ADFSToolkit:
```PowerShell
Install-Module ADFSToolkit
```

|:heavy_check_mark: If asked, accept the requested trust for PSGallery to be able to install ADFSToolkit.|
|-----------------------------------------------------------------------------|

## Configuring

ADFSToolkit V2 now two main steps to configure: one stepfor your federation and one step for your institution. 

### Step1: Federation Configuration

- **First, configure your federation with PowerShell command:**
 ```Powershell
 New-ADFSTkConfiguration
 ```
  - Choose your federation in the presented Grid View and click OK
- **Next, set Federation defaults if they are available:**
  - ADFSToolkit V2 allows Federations to have defaults set during install (i.e. the URL for the metadata, the fingerprint of the cert, etc)
  - If you have been offered a URL for Federation Defaults this command will fetch and install them:
  ```Powershell
  get-ADFSTkFederationDefaults https://url.from.your.federation/operator.zip -InstallDefaults
  ```
    - Removing the -InstallDefaults setting will fetch the file and exit without installingto allow for review prior to use.
    - Federation Operators interested in constructing their own Federation defaults should contact the authors for guidance.
### Step2: Configuring ADFSToolkit for your institution 
 - To start issue this PowerShell command:
 ```Powershell
 New-ADFSTkInstitutionConfiguration
 ```
  - You may be prompted for federation defaults with:
    ```text
    If your federation operators provides a federation-specific default configuration file, make sure to copy the folder to `C:\ADFSToolkit\config\federation` before proceeding.
    ```
    - These may have already been installed in the prior step. If so, proceed.
    - If you have been provided these files, copy them to your federation's name folder provided above.
    - Do not worry if you do not have the files or do not know, you can still proceed but now have to enter the answers yourself.
    - **About the defaults**
     - One or more defaults will then be shown for you to choose to configure, choose one and click OK.  
   - Next, answer the questions to complete the first stage of the institution configuration.
   
   |:exclamation: You will be prompted to create a Scheduled Task in the end of the configuration. Only do this once! |
   |-----------------------------------------------------------------------------|
   - The Scheduled Task will be created and needs to be configured to run with an account with ADFS privileges. 
   - A time is not set on the task and should be set to trigger to run hourly via the Windows Scheduler
- **Base ADFSToolkit configuration is complete.**
###  Step 3: Apply Site Specific Settings and Mappings

- `New-ADFSTkInstitutionConfiguration` has created an institution configuration file under `C:\ADFSToolkit\config\institution` with the name `config.[federationprefix].xml`. 
 - **Edit this file** to configure the site specific attribute release of ADFSToolkit use inline help in the file for guidance.

### Step 4: Test Configuration
- Test your configuration by importing one or more Relying Parties (RPs) manually to review the attribute release. 
- Do this by running the following command to surgically load a relying party from the metadata:
```Powershell
Import-ADFSTkMetadata -ConfigFile C:\ADFSToolkit\config\institution\config.[federationprefix].xml -EntityId [entityID]
```
### Step 5: Enable or Disable Configurations

- After reviewing the Relying Party in the AD FS Console enable the full import by enabling the configurationfile(s) with this command:
```Powershell
Enable-ADFSTkInstitutionConfiguration
```
  - Select the proper configuration file(s) and click OK.
- Disable a specific configuration file uses this command:
  ```Powershell
  Disable-ADFSTkInstitutionConfiguration
  ```
  |:exclamation: Disabling a configuration means disabling the loadinging/maintenance of that aggregate, it does not remove or deactivate the Relying Party. |
   |-----------------------------------------------------------------------------|
### You're Done!

ADFSToolkit will now be run by the Scheduled Task and make a full import/refresh each time. This first import will take some time due to all the new SP's. After that only the new/changed and removed SP's needs to be handled and that will be much faster.

## Logging

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

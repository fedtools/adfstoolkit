# Installation and Configuration of ADFSToolkit V2

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

## Enabling optional REFEDS MFA support for AD FS

After doing your base installation of ADFSToolkit, we recommend you enable [REFEDS MFA support](/doc/mfa.md) for your site.

## System Preparation

ADFSToolkit relies on [PowerShellGallery.com](https://www.powershellgallery.com/packages/ADFSToolkit/). Many systems may be able to use PowerShellGalllery out of the box however be sure your system is operating properly reviewing both: 
- https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget and 
- https://docs.microsoft.com/en-us/powershell/scripting/gallery/getting-started 

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
  - Some federation default settings [exist here](https://github.com/fedtools/federation-settings) however if you have been offered a URL for Federation Defaults use it in this command to fetch and install your default settings:
  ```Powershell
  get-ADFSTkFederationDefaults -URL https://github.com/fedtools/federation-settings/archive/refs/heads/main.zip -InstallDefaults
  ```
    - Removing the -InstallDefaults setting will fetch the file and exit without installing to allow for review prior to use.
    - Federation Operators interested in constructing their own Federation defaults should contact the authors for guidance.
    - Note that the federation choseen during the `New-ADFSTkConfiguration` step will be used to filter what is installed.
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
 
 - Install ADFSTkStore to permit subject-id and pairwise-id generation capabilites by issuing this PowerShell command:

   |:exclamation: This will require ADFS to be restarted to recognize the DLL and needs to be done on each ADFS Farm server |
   |-----------------------------------------------------------------------------|
 ```Powershell
 Install-ADFSTkStore
 ```
- **Base ADFSToolkit configuration is complete.**
###  Step 3: Apply Site Specific Settings and Mappings

- `New-ADFSTkInstitutionConfiguration` has created an institution configuration file under `C:\ADFSToolkit\config\institution` with the name `config.[federationprefix].xml`. 
 - :exclamation: **Edit this file** to configure the site specific attribute release of ADFSToolkit use inline help in the file for guidance.

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
  |:exclamation: Disabling a configuration means disabling the loading/maintenance of that aggregate, it does not remove or deactivate the Relying Party. |
   |-----------------------------------------------------------------------------|
### You're Done!

ADFSToolkit will now be run by the Scheduled Task and make a full import/refresh each time. This first import will take some time due to all the new SP's. After that only the new/changed and removed SP's needs to be handled and that will be much faster.

## Logging

Logging will occur in the Event Log, default under `Applications and Services log\ADFSToolkit`. 

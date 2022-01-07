# Installation and Configuration of MFA for ADFSToolkit V2

## System Requirements
- All pre-requisits in (docs/README.md) must be met
- Your chosen MFA provider technology (DUO,Azure MFA) is successfully installed, proven working  independantly on it's own. 

|:exclamation: Strongly suggested: A test AD FS environment to perform the installation prior to installing in production is in your best interest. |
|-----------------------------------------------------------------------------|


| :heavy_check_mark: Expect a few thousand Relying Party trusts in the AD FS Console after your first run|
|-----------------------------------------------------------------------------|

## Before you start

|:exclamation: A DLL is installed in the ADFS server and in an ADFS Farm setting, the command muwt be done Strongly suggested: A test AD FS environment to perform the installation prior to installing in production is in your best interest. |
|-----------------------------------------------------------------------------|

## Installing

- **First, configure your federation with PowerShell command:**
- Open a PowerShell prompt or PowerShell ISE window as administrator
- Run the following to download and install the latest stable ADFSToolkit:
```PowerShell
Install-ADFSTkMFAAdapter  -RefedsMFA
```
- **Next, accept the defaults when asked**
- When asked, accept the Additional Authentication as Primary  property step
- When asked, accept registering 'Forms Authentication(RefedsMFA)' as primary  Authentication Provider step

- **

## Configuring


###  Step N


### Step 4: Test Configuration
- Test your configuration by importing one or more Relying Parties (RPs) manually to review the attribute release. 

### Step 5: Enable or Disable Configurations

### You're Done!

ADFSToolkit will now be run by the Scheduled Task and make a full import/refresh each time. This first import will take some time due to all the new SP's. After that only the new/changed and removed SP's needs to be handled and that will be much faster.

## Logging

Logging will occur in the Event Log, default under `Applications and Services log\ADFSToolkit`. 

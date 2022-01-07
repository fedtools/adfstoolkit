# Installation and Configuration of MFA for ADFSToolkit V2

## System Requirements

  - All pre-requisites in [Installation](/docs/README.md) must be met
  - Your chosen MFA provider technology (DUO,Azure MFA) is successfully installed and demonstrably working on it's own. 

  |:exclamation:  A test AD FS environment is strongly recommended prior to installing in production. |
  |---------------------------------------------------------------------------------------------------|


## Installing

- **First, configure your federation with PowerShell command:**
  - Open a PowerShell prompt or PowerShell ISE window as administrator  
  - Run the following to download and install the latest stable ADFSToolkit:
  ```PowerShell
  Install-ADFSTkMFAAdapter  -RefedsMFA
  ```

- **Accept the defaults when asked**
  - accept the Additional Authentication as Primary  property step
  - accept registering 'Forms Authentication(RefedsMFA)' as primary  Authentication Provider step

- **Ensure MFA DLL is propagated to other servers in the farm**
  - in a farm configuration there are multiple hosts that need updating to possess the DLL, to do this choose to either:
    - install the module on the other servers but not configure it
    - use an existing practice you have now to distribute the DLL so other servers in the AD FS farm have it

    |:exclamation: A DLL is installed in the ADFS server and in an ADFS Farm setting, the command must be done on each of the ADFS servers. If  you have already answered 'yes' to the questions once, answer no to subsequent runs on the different servers in the farm.  |
     |-----------------------------------------------------------------------------|


## Configuring


###  Step N


### Step 4: Test Configuration
  - Test your configuration by importing one or more Relying Parties (RPs) manually to review the attribute release. 

### Step 5: Enable or Disable Configurations

### You're Done!

ADFSToolkit will now be run by the Scheduled Task and make a full import/refresh each time. This first import will take some time due to all the new SP's. After that only the new/changed and removed SP's needs to be handled and that will be much faster.

## Logging

Logging will occur in the Event Log, default under `Applications and Services log\ADFSToolkit`. 

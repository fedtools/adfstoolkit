# Installation and Configuration of MFA for ADFSToolkit V2

The use of the REFEDS MFA portion of ADFSToolkit is optional. 
ADFSToolkit out of the box will function normally for regular sign on requests and AD FS will deny REFEDS MFA SAML transactions as an error, which is an appropriate response for AD FS to issue. 

This installation guidance is geared toward the AD FS administrator who is responsible for the ADFSToolkit installation in AD FS and will require involvment and understanding on how to use your 3rd party MFA provider  which may be DUO Security or Azure MFA. 

## How REFEDS MFA is enabled in AD FS with ADFSToolkit
AD FS'  REFEDS MFA support requires the use of the AD FS extensions which require a Windows DLL to be installed. This DLL with additional ADFSToolkit elements add the ability to recognize, process, and configure the [REFEDS MFA](https://refeds.org/profile/mfa) SAML2 AuthenticationContext and allow  AD  FS to respond to sites requiring this context for MFA access.

Key elements of the REFEDS MFA and ADFS+ADFSToolkit solution are:

-  ADFSToolkit accellerator PowerShell cmd-lets that assist deploying new DLL to add REFEDS MFA support
-  AD FS Access Control Policies specific to REFEDS MFA are created by ADFSToolkit
-  AD FS  RPs overseen by ADFSToolkit must be recalculated to add a safety measure Transformation rule to each RP.
-  AD FS must use the Paginated theme in order to be properly functioning.  (ships with Server 2019)


## Important Considerations and Limitations

ADFSToolkit works within the confines of various design decisions and supported features in AD FS. These limitations force certain techniques to be used to enable REFEDS MFA capability and like any other Identity Provider platform using external services, carry some risks.

**ADFSToolkit goes to great lengths to align with REFEDS MFA behaviour on your behalf and diminish risk, however it cannot be eliminated.  If configuration is only partially followed/performed, your installation may be at risk claiming MFA when it is not MFA.**

AD FS configurations ADFSToolkit performs on your behalf to support REFEDS MFA are:
- Slight Adjustments to AD FS Global Defaults
- Creation of a REFEDS MFA Access Control Policie in AD FS
- Addition to each of the Relying Parties (RPs) that ADFSToolkit oversees adding a transformation rule as a safety measure to prevent improper MFA attestation. 

### Review your  MFA provider policies to prevent 'weak' or other improper behaviour

Equally noteworthy in the configuration space are your MFA provider configurations outside of ADFS and ADFSToolkit. 
Review these configurations for alignment to REFEDS MFA best practices and for what you have enabled as interplay between what you have now and REFEDS MFA policies could be different.
You may need to adjust your MFA provider policies to be in good alignment.

For more depth on what REFEDS MFA means please review the [REFEDS MFA Profile FAQ](https://wiki.refeds.org/display/PRO/MFA+Profile+FAQ)

## System Requirements

  - See [Installation Requirements](/docs/README.md) for ADFSToolkit base requirements
  - Your ADFS MFA provider technology MUST be successfully installed and demonstrably working on it's own. 

  |:exclamation:  A test AD FS environment is strongly recommended prior to installing in production. |
  |---------------------------------------------------------------------------------------------------|


## Installing

All the steps below assume you have done a base installation of the [ADFSToolkit Module from PowerShellGallery](https://www.powershellgallery.com/packages/ADFSToolkit) and verified it as properly functioning.

If you have no MFA provider, enable it first THEN return to these steps.

### Step 1: install the adapter with a PowerShell command:**
  - Open a PowerShell prompt or PowerShell ISE window as administrator  
  - Run the following to download and install the latest stable ADFSToolkit:
  ```PowerShell
  Install-ADFSTkMFAAdapter  -RefedsMFA
  ```
- **Accept the defaults when asked**
  - accept the Additional Authentication as Primary  property step
  - accept registering 'Forms Authentication(RefedsMFA)' as primary  Authentication Provider step

- **Ensure the MFA DLL is propagated to other servers in the farm**
  - in a farm configuration there are multiple hosts that need updating to have the DLL present on all servers, to do this choose to either:
    - install the module on the other servers but not configure it
    - use an existing practice to distribute the DLL so other servers in the AD FS farm

    |:exclamation: the REFEDS MFA DLL is installed in the ADFS server it is on. In an ADFS Farm setting, the command must be done on each of the ADFS servers. If you have already answered 'yes' to the questions once, answer no to subsequent runs on the different servers in the farm.  |
     |-----------------------------------------------------------------------------|


### Optional step: If using Azure AD MFA, apply appropriate ADFSToolkit MFA configurations to All ADFSToolkit managed SPs




### Step 2: Test Configuration

-  If you are in an R&E federation, inquire to see if your federation operator has a test or production entity to test against.
-  If you have the ability to test your pre-production or production environment, the National Institute of Health (NIH) has a [Security Compliance Check Tool site](https://auth.nih.gov/CertAuthV3/forms/compliancecheck.aspx)

 Alternatively, a local test can be performed if  you have a [Shibboleth Service Provider and enable REFEDS MFA](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2114781453/Requiring+Multi-Factor+Authentication) with it and register it manually in your ADFS to test your configuration. 

 Regardless of the testing techniques,  the outcomes you want  are:
 - when an SAML Authentication Context of ``https://refeds.org/profile/mfa`` is requested of your ADFS installation the ADFS server:
   - does not trigger an error
   - force you to use the MFA authentication method  **AND** another option to sign in to qualify is multiple factors.
   -





### You're Done!

ADFSToolkit will now be run by the Scheduled Task and make a full import/refresh each time. This first import will take some time due to all the new SP's. After that only the new/changed and removed SP's needs to be handled and that will be much faster.

## Logging

Logging will occur in the Event Log, default under `Applications and Services log\ADFSToolkit`. 

# Installation and configuration of REFEDS MFA for ADFSToolkit
## Audience for this guide
This installation guidance is geared toward the AD FS administrator who is responsible for the ADFSToolkit installation in AD FS and will require involvment and understanding on how to use your 3rd party MFA provider which may be DUO Security or Azure MFA. It is possible to use additional 3rd pary providers and encourage reviewing their abilities against the REFEDS MFA profile.

## What happens when this feature is enabled

Enabling support for REFEDS MFA means that when a Relying Party (RP) requests REFEDS MFA from your AD FS+ADFSToolkit enabled IdP it will recognize the request properly and honour the Multi-Factor Authentication (MFA) requirements [REFEDS MFA](https://refeds.org/profile/mfa) for that sign on.

This only happens when it is requested and NOT on each sign-on. Details on how to test this are blow.  When this feature is enabled via ADFSToolkit, a specific REFEDS MFA Access Control Policy will be created as will a few other elements which are described below.

 Sites may choose to shape their MFA end-user experiences via [AD FS's  Access Control Policies](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/access-control-policies-in-ad-fs) 

## How REFEDS MFA works in AD FS with ADFSToolkit
ADFSToolkit embraces the Microsoft AD FS capability of [Custom Authenticaiton Methods](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/development/ad-fs-build-custom-auth-method) to enable the recognition and processing of REFEDS MFA AuthenticationContext sign-ons. ADFSToolkit provides a code signed Windows DLL as well as other configurations and Powershell cmd-lets to be installed to support the recognition, processing, and configuration of [REFEDS MFA](https://refeds.org/profile/mfa) SAML2 [AuthenticationContext](https://docs.oasis-open.org/security/saml/v2.0/saml-authn-context-2.0-os.pdf) support.

ADFSToolkit codebase is curated openly here in GitHub and operationally handled in PowerShellGallery.com.
We strongly recommend installing ADFSToolkit as code-signed code via ADFSToolkit Module from PowerShellGallery](https://www.powershellgallery.com/packages/ADFSToolkit)

### Important elements of the REFEDS MFA and ADFS+ADFSToolkit solution are:

-  PowerShell cmd-lets that assist deploying and configuring the new DLL to add REFEDS MFA support
-  An AD FS Access Control Policy(ACP) created by  ADFSToolkit specific to REFEDS MFA named "ADFSTk:Permit everyone and force MFA"
-  All RPs overseen by ADFSToolkit recalculated to add a safety measure Transformation rule to each RP as well as the aforementioned ACP
-  The default use of the Paginated AD FS theme for proper UI functions.  (ships native to ADFS with Server 2019)

## Important considerations and limitations

ADFSToolkit works within the confines of various design decisions and supported features in AD FS. These limitations force certain techniques to be used to enable REFEDS MFA capability and like any other Identity Provider platform using external services, carry some risks.

**ADFSToolkit goes to great lengths to align with REFEDS MFA behaviour on your behalf and diminish risk, however not all risks can be eliminated.  If configuration is only partially followed/performed, your installation may be at risk claiming MFA when it is not MFA.**

### Preparing for your install

- **Review your MFA provider policies to prevent 'weak' or other improper behaviour**

  Your MFA provider configurations outside of ADFS and ADFSToolkit may need reviewing in light of REFEDS MFA practices around MFA.

  Review your MFA providers policies and  configurations for alignment to REFEDS MFA best practices mindfull of the interplay between what you have now and REFEDS MFA policies could be different.
  You may need to adjust your MFA provider policies to be in proper alignment to REFEDS MFA.

  For more depth on what REFEDS MFA means please review the [REFEDS MFA Profile FAQ](https://wiki.refeds.org/display/PRO/MFA+Profile+FAQ)

- **Review existing Access Control Policies for collisions with REFEDS MFA**

  You may have already applied an existing Access Control Policy (ACP) to some entities that  will be assigned the REFEDS MFA policy.
  It's ok to elevate to an internal MFA practice for those not with REFEDS MFA however it's not ok to downgrade or dilute the REFEDS MFA policy for an RP.

- **Allow for time to recalculate RPs**

  Relying Parties (RPs) overseen by ADFSToolkit will need to be recalculated. Ensure there is adequate time for the recalculation which may take 30-45min depending on hardware configurations.



## System requirements

  - For base ADFSToolkit requirements see [Installation Requirements](/docs/README.md) 
  - Your ADFS MFA provider technology MUST be successfully installed and demonstrably working on it's own with  AD FS.

  |:exclamation:  A test AD FS environment is strongly recommended prior to installing in production. |
  |---------------------------------------------------------------------------------------------------|


## Installing

### **Before you start...**

All the steps below assume you have done a base installation of the [ADFSToolkit Module from PowerShellGallery](https://www.powershellgallery.com/packages/ADFSToolkit) and verified it as properly functioning.

If you have no MFA provider, enable it first THEN return to these steps.

### **Step 1: install the adapter with via PowerShell command:**
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


### **Optional step: If using Azure AD MFA, apply appropriate ADFSToolkit MFA configurations to All ADFSToolkit managed SPs**




### **Step 2: Test your configuration**

-  If you are in an R&E federation, inquire to see if your federation operator has a test or production entity to test against.
-  If you have the ability to test your pre-production or production environment, the National Institute of Health (NIH) has a [Security Compliance Check Tool site](https://auth.nih.gov/CertAuthV3/forms/compliancecheck.aspx)

- **Testing locally**

   Alternatively, a local test can be performed if  you have a [Shibboleth Service Provider and enable REFEDS MFA](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2114781453/Requiring+Multi-Factor+Authentication) with it and register it manually in your ADFS to test your configuration. 

  - A passing test is when the multiple factors are used at all times when the AuthenticationContext is REFEDS MFA.
  - It is possible to start a session for single factor and then experience a 403 Forbidden at the RP and recommend improving the 403 page to be aware and redirect the user to login with MFA by setting the appropriate AuthenticationContext requirements (see the Shibboleth SP example)



### **You're Done!**
With the ADFSToolkit REFEDS MFA DLL and tools in place your ADFS instance will recognize REFEDS MFA sign-on requirements. 

## **Logging**

Logging will occur in the Event Log, default under `Applications and Services log\ADFSToolkit`. 
Individual logins will not be present however you can [increase ADFS logging](https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/troubleshooting/ad-fs-tshoot-logging) for more depth of diagnosis on events. 

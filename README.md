# ADFSToolkit

A PowerShell Module used to handle SAML2 multi-lateral federation aggregates

The ADFSToolkit was designed to rapidly configure your Active Directory Federation Services (AD FS v3 or higher) 
in order to connect to the CANARIE Canadian Access Federation’s Federated Identity Management (FIM) service. 
The ADFSToolkit reduces the installation and configuration time for CAF services to a matter of minutes and offers 
techniques to manage trust in a scalable fashion.
## System Requirements
CANARIE’s ADFSToolkit must be installed on a Windows Server (your AD FS host) with:
- Microsoft AD FS v3 or higher
- Local administrator privileges to schedule privileged jobs
- AD FS administrator-level permissions to run PowerShell commands
- Acceptance of the security considerations running PowerShell retrieved from Microsoft’s PowerShellgallery.com 

While not a firm requirement, we strongly suggest a test AD FS environment to perform the installation prior to installing in production. 
You should be aware that after installation, you will see a few thousand trusts displayed within the administration toolset, AD FS-Microsoft Management Console (MMC).
###	Minimum Server OS 
Windows Server 2012 R2 or newer is the minimal level of OS supported. You should also be current on latest OS and security patch/updates provided by Microsoft.
##	Minimum PowerShell Version 
ADFSToolkit uses Microsoft’s PowerShell with Windows Management Framework (WMF) 5.1. To see if your host is WMF5.1 ready, check the Microsoft Compatibility Matrix.
To quickly see which version of PowerShell you have, open a PowerShell window or PowerShell ISE window and enter $PSVersionTable. If you do not see version 5.1, you will need to update your environment first.

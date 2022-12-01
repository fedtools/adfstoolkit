# Upgrading
ADFSToolkit can be updated using the PowerShell command `Update-Module` which will fetch and install the latest updates. 
This may only take a few moments however propagating the changes completely may require the cache to be deleted and recalculated as if it were an initial install. Plan accordingly allocating sufficient time during an update. Updates that require this will be flagged as such in the upgrade process. 

## Steps
|:exclamation: When updating from versions prior to v2.0.0.0 be sure to disable/suspend the scheduled job |
   |-----------------------------------------------------------------------------|
    
   |:exclamation: Upgrading to v2.2.0 requires a restart of ADFS for new features to be recognized, plan the update accordingly |
   |-----------------------------------------------------------------------------|
   

**Step 1: Create a Known Recovery Point**
  - Back up the  C:\ADFSToolkit directory
  - Create a system snapshot/recovery point to return to
  
**Step 2: Identify Relying Parties for Post-upgrade Testing and Review**
  - Optionally identify key Relying Parties for Post-upgrade testing
  - Preserve their 'before' attribute release claim rules for later review by running this cmdlet for each record:
  ```Powershell
  (Get-AdfsRelyingPartyTrust  -Identifier  https://some.entity/id/here).issuanceTransformRules | Out-File entity1-rules-before.txt
  ```
  - Document for yourself expected sign-on and attribute release behaviour to compare post-upgrade.
  
**Step 3: Preparing for Updates**

Updating is _usually_ performed with an update-module command and then uninstall-module to eliminate the old one.

:exclamation: v2.1.0 is signed with a newer, different trusted CA root. This triggers a warning for upgrading only for this version. We encourage keeping true to the RemoteSigned execution policy and for this version update to do the uninstall first and then an install of 2.1.0only after taking a vm  snapshot of your machine. Subsequent updates should be with the same signing key and can use the Update-module technique. Commands for these steps are below for your to run in the appropriate order needed.

***How to see which Modules are installed***
- To see which modules are installed use:
  ```PowerShell
   get-module -name ADFSToolkit

***How to Fetch the Latest Module***
  - Issue PowerShell command to attempt to detect if there is a newer version available from PowerShellGallery.com and download it:
    ```PowerShell
     Update-Module ADFSToolkit
    ```
**How to Move Older Versions Out Of The Way**
  - ADFSToolkit might not run properly with more than one version available on disk
  - The Remedy is to move the older version out of the PowerShell path so that only the latest version is available. 
  - Use the following cmdlet to uninstall previous versions. Substitute the version # with the one you are migrating from. 
  -
    ```PowerShell
      Uninstall-Module ADFSToolkit -RequiredVersion 2.1.0
    ```
   - :exclamation: **Close your existing PowerShell window and re-open (with Administrator level privileges) to ensure old settings are removed from memory**

**Step 4: Upgrade Existing Configuration File(s)**
  - Clear the language cache to use newest language settings:
    ```PowerShell
    Remove-ADFSTkCache -LanguageTables
    ```
  - Refresh the ADFSTk Federation defaults to latest versions:
    ```PowerShell
    get-ADFSTkFederationDefaults -URL https://github.com/fedtools/federation-settings/archive/refs/heads/main.zip -InstallDefaults
    ```
  - Run the upgrade cmdlet:
    ```PowerShell
    Update-ADFSTkInstitutionConfiguration
    ```
    - This will search for existing institution configuration files and present them in a Grid View. 
      - Select a single configuration file to start the upgrade for a given aggregate
      - Pair you choice of default with your choice of existing file (e.g. test default set to existing test config, prod to prod etc)
    - The upgrade process will upgrade the configuration in version steps, so it's possible to jump several versions at the same time.
    - If the new version needs to re-process all SP's a message will show to inform that the cache files needs to be deleted.
      - :exclamation: **If you choose not to do this we cannot guarantee that the correct attributes are released from the Toolkit!**

  - Ensure the DLL for ADFSTkStore is installed (on all servers in the farm and will require ADFS service restart):
    ```PowerShell
    Install-ADFSTkStore
    ```
      
**Step 5: Remove Older Folders to Avoid Confusion**
   - :exclamation: If the upgrade is from v1.0.0.0 or earlier we recommended older folders and files in the ADFSToolkit folder `C:\ADFSToolkit` be removed
     - Only `C:\ADFSToolkit\config` and `C:\ADFSToolkit\cache` folders should remain
     - No file(s) are directly in the `C:\ADFSToolkit` folder. 
     > :exclamation: Take a backup of the files and folders before they are deleted!

**Step 6: Review Settings and ManualSPSettings for Customizations**
  - Review your configuration file(s)  post upgrade to ensure they meet expectations
  - :exclamation: If the upgrade is from v1.0.0.0 or earlier:
    - Ensure that the file `C:\ADFSToolkit\#.#.#.#\get-ADFSTkLocalManualSpSettings.ps1` (which contains all your local SP settings) has been copied to `C:\ADFSToolkit\config\institution`. 
     - :exclamation: **If this  file is not in the new folder all your manual settings for the existing entities will be removed**

**Step 7: Test the  Upgraded Configuration**
   - Import and test select entities from Step 2 by manually loading and then testing sign-on with each entity
     - To load an entity individually, use this PowerShell command:
       ```Powershell
       Import-ADFSTkMetadata -ConfigFile C:\ADFSToolkit\config\institution\config.YouFedPrefixHere.xml -EntityId TheEntityIDToLoad
       ```
   - Perform your sign-on to assess consistent behaviour to pre-upgrade state
     - Optionally compare the 'before' claim rules extracted in Step 2 by re-extracting them after loading the  new record
      - :exclamation: **Note: Post-upgrade claimset rules will be different but produce the same attribute release**
      - To see attributes set up your  own Relying Party as a test service or use [Microsoft Claims X-Ray test relying party](https://adfshelpppe.microsoft.com/ClaimsXray/TokenRequest) to inspect the attributes
         - :exclamation: **Note: Exercise care and use test accounts where possible: this technique will transmit data to Microsoft**
         - If Claims X-Ray is used you can take the extracted claims rules being tested and load them by:
         ```Powershell
          Set-AdfsRelyingPartyTrust -TargetName "ClaimsXray"  -IssuanceTransformRulesFile "C:\entity1-rules-after.txt"
         ```
         - Sign in  to your test Relying Party or Claims Xray to see the results of the attribute claims release and determine if things are in order
   - Move on to the next step when satisfied with the testing results

**Step 8:Review and Prepare Scheduled Jobs**
  - If the upgrade is from v1.0.0.0 or earlier the Scheduled job needs to be updated. 
    - Change the arguments under the action tab in the scheduled job to: `-NoProfile -WindowStyle Hidden -Command &{Sync-ADFSTkAggregates}`
  - Note that `Sync-ADFSTkAggregates` can be run in your privileged PowerShell window to see it run as opposed to waiting for the job to trigger 
    
**Step 9:Resume Synchronization of Metadata**
   - To enable the upgraded version, run `Enable-ADFSTkInstitutionConfiguration` and select the proper configuration file(s) and click OK.
 
 **Step 10:Do a Health Check**
 
 ADFSToolkit 2.x+ has a health check feature to determine if all things are in alignment. This can be run at any time and will identify any drift from regular expected use of ADFSToolkit. On upgrades we recommend doing a full healthcheck by invoking it this way:
 ```Powershell
  Get-ADFSTkHealth -HealthCheckMode Full 
  ```
  :exclamation: **Note well:** Health check relies on the configuration and if aggregates are disabled, it does not know about them. For a comprehensive health check ensure all aggregates are enabled to ensure they are reviewed.
 
  
**Step 11: Observe System Post-upgrade**
  - Your update is complete and should now be running with the new scheduled job.
  - Spot check your customized Relying Parties and review for consistent attribute release.
  - Review the Event-Log for any anomalies
  - That's it! You are done the upgrade!
  


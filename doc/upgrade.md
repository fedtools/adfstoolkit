# Upgrading
ADFSToolkit can be updated using the PowerShell command `Update-Module` which will fetch and install the latest updates. 
This may only take a few moments however propagating the changes completely may require the cache to be deleted and recalculated as if it were an initial install. Plan accordingly allocating sufficient time during an update. Updates that require this will be flagged as such in the upgrade process. 

## Steps
|:exclamation: When updating from versions prior to v2.0.0.0 be sure to disable/suspend the scheduled job |
   |-----------------------------------------------------------------------------|

**Step 1: Create a Known Recovery Point**
  - Back up the  C:\ADFSToolkit directory
  - Create a system snapshot/recovery point to return to
  
**Step 2: Identity Relying Parties for Post-upgrade testing and review**
  - Optionally identify key Relying Parties for Post-upgrade testing
  - Preserve their 'before' attribute release claim rules for later review by running this cmdlet for each record:
  ```Powershell
  (Get-AdfsRelyingPartyTrust  -Identifier  https://some.entity/id/here).issuanceTransformRules | Out-File entity1-before.txt
  ```
  - Document for yourself expected sign-on and attribute release behaviour to compare post-upgrade.
  
**Step 3: Fetch the Latest Module**
  - Issue PowerShell command to attempt to detect if there is a newer version available from PowerShellGallery.com and download it:
    ```PowerShell
     Update-Module ADFSToolkit
    ```
**Step 4: Move Older Version Out Of The Way**
  - ADFSToolkit might not run properly with more than one version available on disk
  - The Remedy is to move the older version out of the PowerShell path so that only the latest version is available. 
  - Use the following cmdlet to uninstall v1.0.0.0
    ```PowerShell
      Uninstall-Module ADFSToolkit -RequiredVersion 1.0.0.0
    ```
   - :exclamation: **Close your existing PowerShell window and re-open (with Administrator level privileges) to ensure old settings are removed from memory**

**Step 5: Upgrade Existing Configuration File(s)**
  - Run the upgrade cmdlet:
    ```PowerShell
    Update-ADFSTkInstitutionConfiguration
    ```
    - This will search for existing institution configuration files and present them in a Grid View. 
      - Select one or more configuration file(s) to start the upgrade.
    - The upgrade process will upgrade the configuration in version steps, so it's possible to jump several versions at the same time.
    - If the new version needs to re-process all SP's a message will show to inform that the cache files needs to be deleted.
      - :exclamation: **If you choose not to do this we cannot guarantee that the correct attributes are released from the Toolkit!**
      
**Step 6: Remove Older Folders to Avoid Confusion**
   - :exclamation: If the upgrade is from v1.0.0.0 or earlier we recommended older folders and files in the ADFSToolkit folder `C:\ADFSToolkit` be removed
     - Only `C:\ADFSToolkit\config` and `C:\ADFSToolkit\cache` folders should remain
     - No file(s) are directly in the `C:\ADFSToolkit` folder. 
     > :exclamation: Take a backup of the files and folders before they are deleted!

**Step 7: Review Settings and ManualSPSettings for Customizations**
  - Review your configuration file(s)  post upgrade to ensure they meet expectations
  - :exclamation: If the upgrade is from v1.0.0.0 or earlier:
    - Ensure that the file `C:\ADFSToolkit\#.#.#.#\get-ADFSTkLocalManualSpSettings.ps1` (which contains all your local SP settings) has been copied to `C:\ADFSToolkit\config\institution`. 
     - :exclamation: **If this  file is not in the new folder all your manual settings for the existing entities will be removed**

**Step 8: Test the  Upgraded Configuration**
   - Import and test select entities from Step 2 by manually loading and then testing sign-on with each entity
     - To load an entity individually, use this PowerShell command:
       ```Powershell
       Import-ADFSTkMetadata -ConfigFile C:\ADFSToolkit\config\institution\config.YouFedPrefixHere.xml -EntityId TheEntityIDToLoad
       ```
   - Perform your sign-on to assess consistent behaviour to pre-upgrade state
     - Optionally compare the 'before' claim rules extracted in Step 2 by re-extracting them after loading the  new record
      - Seek functional equivalence of the resulting attributes sent during sign-on
      - :exclamation: **Note: Claimset rules post-upgrade may be noticably different but produce the same attribute release for the Relying Party**
      - Additional Optional test step: 
       - Leverage  [Microsoft Claims X-Ray test relying party](https://adfshelpppe.microsoft.com/ClaimsXray/TokenRequest) to  inspect the attributes themselves
       - **Note: Exercise care by using test accounts where possible: this technique while convenient  and powerful will transmit data to Microsoft**
        - If Claims X-Ray is added to your AD FS you can take the extracted claims rules and load them by:
        ```Powershell
         Set-AdfsRelyingPartyTrust -TargetName "ClaimsXray"  -IssuanceTransformRulesFile "C:\path.txt"
        ```
        - Sign into Claims Xray to see the results of the attribute claims release and determine if things are in order
   - Move on to the next step when satisfied with the testing results

**Step 9:Review and Prepare Schedule Jobs**
  - If the upgrade is from v1.0.0.0 or earlier the Scheduled job needs to be updated. 
    - Change the arguments under the action tab in the scheduled job to: `-NoProfile -WindowStyle Hidden -Command &{Sync-ADFSTkAggregates}`
  - Note that `Sync-ADFSTkAggregates` can be run in your privileged PowerShell window to see it run as opposed to waiting for the job to trigger 
    
**Step 10:Resuming synchronization of Metadata**
   - To enable the upgraded version, run `Enable-ADFSTkInstitutionConfiguration` and select the proper configuration file(s) and click OK.
   
**Step 11: Your Update Is Complete!**
  - Your update is complete and should now be running with the new scheduled job.
  - Spot check your customized Relying Parties and review for consistent attribute release.
  


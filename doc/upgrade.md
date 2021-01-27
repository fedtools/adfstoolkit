# Upgrading
ADFSToolkit can be updated using the PowerShell command `Update-Module` which will fetch and install the latest updates. 
This may only take a few moments however propagating the changes completely may require the cache to be deleted and recalculated as if it were an initial install so plan accordingly and allocate sufficient time during an update. Updates that require this will be flagged as such in the upgrade process. 

## Recommended Update Practice for 
|:exclamation: When updating from versions prior to v2.0.0.0 be sure to disable/suspend the scheduled job and resume it after updates |
   |-----------------------------------------------------------------------------|

- Back up the  C:\ADFSToolkit directory
- Create a system snapshot/recovery point to return to
- Issue PowerShell command:
  ```PowerShell
   Update-Module ADFSToolkit
  ```
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

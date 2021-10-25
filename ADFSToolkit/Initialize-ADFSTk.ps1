$modulePath = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1 | Select -ExpandProperty ModuleBase

. (Join-Path $modulePath "Public\Get-ADFSTkPaths.ps1")
. (Join-Path $modulePath "Private\ADFSTk-TestAndCreateDir.ps1")

$Global:ADFSTkPaths = Get-ADFSTKPaths
$Global:ADFSTkCompatibleInstitutionConfigVersion = "1.3"
$Global:ADFSTkCompatibleADFSTkConfigVersion = "1.0"
$Global:ADFSTkCompatibleLanguageTableConfigVersion = "1.0"

#region Create main dirs
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainDir               -PathName "ADFSTk install directory" #C:\ADFSToolkit
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainConfigDir         -PathName "Main configuration" #C:\ADFSToolkit\config
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.mainBackupDir         -PathName "Main backup" #C:\ADFSToolkit\config\backup
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.cacheDir              -PathName "Cache directory" #C:\ADFSToolkit\cache
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.institutionDir        -PathName "Institution config directory" #C:\ADFSToolkit\config\institution
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.institutionBackupDir  -PathName "Institution backup directory" #C:\ADFSToolkit\config\institution\backup
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.federationDir         -PathName "Federation config directory" #C:\ADFSToolkit\config\federation
ADFSTk-TestAndCreateDir -Path $Global:ADFSTkPaths.federationBackupDir   -PathName "Federation backup directory" #C:\ADFSToolkit\config\federation\backup
#endregion



function Get-ADFSTKPaths
{
    $paths = @{}
    $paths.mainDir = 'C:\ADFSToolkit'
    
    $paths.mainConfigDir = Join-Path $paths.MainDir 'config'
    $paths.mainConfigFile = Join-Path $paths.MainConfigDir 'config.ADFSTk.xml'    
    $paths.mainBackupDir = Join-Path $paths.MainConfigDir 'backup'
    
    $paths.cacheDir = Join-Path $paths.MainDir 'cache'
    
    $paths.institutionDir = Join-Path $paths.MainConfigDir 'institution'
    $paths.institutionBackupDir = Join-Path $paths.institutionDir 'backup'
    $paths.institutionLocalTransformRulesFile = Join-Path $paths.institutionDir 'Get-ADFSTkLocalTransformRules.ps1'

    $paths.federationDir = Join-Path $paths.MainConfigDir 'federation'
    $paths.federationBackupDir = Join-Path $paths.FederationDir 'backup'

    $paths.federationsFile = Join-Path $paths.federationDir 'federations.xml'

    $paths.modulePath = Get-Module -ListAvailable ADFSToolkit | Sort-Object Version -Descending | Select -First 1 | Select -ExpandProperty ModuleBase
    $paths.moduleConfigDir = Join-Path $paths.modulePath 'config'
    $paths.moduleConfigDefaultDir = Join-Path $paths.moduleConfigDir 'default'

    $paths.defaultConfigFile = Join-Path $paths.moduleConfigDefaultDir 'config.ADFSTk.default.xml'
    $paths.defaultInstitutionLocalSPFile = Join-Path $paths.moduleConfigDefaultDir 'get-ADFSTkLocalManualSPSettings-dist.ps1'
    $paths.defaultInstitutionLocalTransformRulesFile = Join-Path $paths.moduleConfigDefaultDir 'Get-ADFSTkLocalTransformRules-dist.ps1'
    #$paths.defaultConfigFile = Join-Path $paths.modulePath 'config\default\config.ADFSTk.default.xml' #Next version with language support



    #Create main dirs
    ADFSTk-TestAndCreateDir -Path $paths.mainDir               -PathName "ADFSTk install directory" #C:\ADFSToolkit
    ADFSTk-TestAndCreateDir -Path $paths.mainConfigDir         -PathName "Main configuration" #C:\ADFSToolkit\config
    ADFSTk-TestAndCreateDir -Path $paths.mainBackupDir         -PathName "Main backup" #C:\ADFSToolkit\config\backup
    ADFSTk-TestAndCreateDir -Path $paths.cacheDir              -PathName "Cache directory" #C:\ADFSToolkit\cache
    ADFSTk-TestAndCreateDir -Path $paths.institutionDir        -PathName "Institution config directory" #C:\ADFSToolkit\config\institution
    ADFSTk-TestAndCreateDir -Path $paths.institutionBackupDir  -PathName "Institution backup directory" #C:\ADFSToolkit\config\institution\backup
    ADFSTk-TestAndCreateDir -Path $paths.federationDir         -PathName "Federation config directory" #C:\ADFSToolkit\config\federation

    return $paths
}
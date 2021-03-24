
function Write-ADFSTkLog {
[CmdletBinding(DefaultParametersetName="Default")]
param (        
    [Parameter(Mandatory=$false,
                ParameterSetName="Set",
                ValueFromPipelineByPropertyName=$false)]
    [string]
    #The path to the logfile. This needs to be set once in the script. The path will be stored in a global variable 'LogFilePath'
    $SetLogFilePath,
    [Parameter(Mandatory=$false,
                ParameterSetName="Set",
                ValueFromPipelineByPropertyName=$false)]
    [string]
    #The name of the eventlog. This needs to be set once in the script. The name will be stored in a global variable 'EventLogName'
    $SetEventLogName,
    [Parameter(Mandatory=$false,
                ParameterSetName="Set",
                ValueFromPipelineByPropertyName=$false)]
    [string]
    <#The Source that will be used in the eventlog.
    
    Use New-EventLog -LogName <EventLogName> -Source <NewSource> to add a new source to a eventlog.
    
    This needs to be set once in the script. The name will be stored in a global variable 'EventLogSource'#>
    $SetEventLogSource,
    [Parameter(Mandatory=$false,
                ParameterSetName="Get",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Returns the path to the LogFile.
    $GetLogFilePath,
    [Parameter(Mandatory=$false,
                ParameterSetName="Get",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Returns the name of the EventLog that will be used.
    $GetEventLogName,
    [Parameter(Mandatory=$false,
                ParameterSetName="Get",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Returns the Source of the EventLog that will be used.
    $GetEventLogSource,
    
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    #The message to be written in the log...
    $Message,
    
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [int]
    #The EventID if EventLog is used
    $EventID,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [string]
    #Used in LogFile and on Screen to clarify the message. In EventLog the Level on the event is set to EntryType. Default is Information
    [ValidateSet("Information", "Error", "Warning")]
    $EntryType="Information",
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #If used the EntryType will be set as "Error" the message will be thown as an error. 
    $MajorFault,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [int]
    #Only for EventLog. Task Category on the event is set to Category. If -Verbose is used, Category will be set to 4
    $Category=1,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Used in LogFile and on Screen make the message underlined
    $Underline,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$false)]
    [char]
    #The char used to make the underline (see parameter Underline). Default is '-'
    $UnderlineChar='-',
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Use this to get output on the screen
    $Screen,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Use this to log to file
    $File,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Use this to log to EventLog
    $EventLog,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Doesn't write Date and Time in the beginning of the row
    $SkipDateTime,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [ConsoleColor]
    #Sets the color the screen-text should be written in
    $ForegroundColor = [ConsoleColor]::Gray
)
       
Begin {
    
    if ($PsCmdlet.ParameterSetName -eq "Set")
    {
        if ($SetLogFilePath -ne [string]::Empty) 
        {
            $FilePath = $SetLogFilePath.SubString(0,$SetLogFilePath.LastIndexOf('\'))
            if (! (Test-Path ($FilePath)))
            {
                Write-Warning (Get-ADFSTkLanguageText logPathNotFound -f $FilePath)
            }
            else
            {
                Write-Verbose (Get-ADFSTkLanguageText logSettingXPathTo -f 'LogFilePath', $SetLogFilePath)
                $global:LogFilePath = $SetLogFilePath                    
            }
        }
        
        if ($SetEventLogName -ne [string]::Empty)
        {
            try
            {
                $TestEventLog = Get-EventLog $SetEventLogName -Newest 1
                
                Write-Verbose (Get-ADFSTkLanguageText logSettingXPathTo -f 'EventLogName', $SetEventLogName)
                $global:EventLogName = $SetEventLogName 
            }
            catch
            {
                Write-Warning (Get-ADFSTkLanguageText logEventLogNameNotExist)
            }
        }
        
        if ($SetEventLogSource -ne [string]::Empty)
        { 
            Write-Verbose (Get-ADFSTkLanguageText logSettingXPathTo -f 'SetEventLogSource', $SetLogFilePath)
            $global:EventLogSource = $SetEventLogSource
        }
    }
    elseif ($PsCmdlet.ParameterSetName -eq "Get")
    {
        if ($GetLogFilePath) { $LogFilePath }
        if ($GetEventLogName) { $EventLogName }
        if ($GetEventLogSource) { $EventLogSource }
    }
}
Process {
    ### Write main script below ###
    if ($PsCmdlet.ParameterSetName -eq "Default")
    {
        if ($MajorFault) { $EntryType = "Error" }
        if ($verbosePreference -eq "Continue") { $Category = 4 }
        
        $CurrentTime = (Get-Date).ToString()
        
        if (!$Screen.IsPresent -and !$File.IsPresent -and !$EventLog.IsPresent)
        {
            $Screen = $true

            if ($EventLogName -ne $null -and $EventLogSource -ne $null)
            {
                $EventLog = $true
            }

            if ($LogFilePath -ne $null)
            {
                $File = $true
            }
        }
        
        if ($Screen -and -not $MajorFault -and -not $Silent)
        { 
            #Write-Verbose "Logging to Screen..." 
            
            if (!$SkipDateTime) 
            {
                Write-Host "$($CurrentTime): " -ForegroundColor DarkYellow -NoNewline
            }
            
            if ($EntryType -eq "Error")
            { 
                Write-Error $Message
                if ($Underline) { Write-Error "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
            }
            elseif ($EntryType -eq "Warning")
            {
                Write-Warning $Message
                if ($Underline) { Write-Warning "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
            }
            else
            {
                if ($verbosePreference -eq "Continue")
                { 
                    Write-Verbose $Message
                    if ($Underline) { Write-Verbose "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
                }
                else 
                { 
                    Write-Host $Message -ForegroundColor $ForegroundColor
                    if ($Underline) { Write-Host "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
                    
                }
            }
        }
        
        if ($File) 
        {
            if ($LogFilePath -eq [string]::Empty) { Write-Warning (Get-ADFSTkLanguageText logLogFilePathNotSet) }
            else
            {
                $FileMessage = ""
                if (!$SkipDateTime) 
                {
                    $FileMessage = "$CurrentTime - "
                }
                 $FileMessage += "$($EntryType): $Message"

                #Write-Verbose "Logging to File `'$LoggFilePath`'..."
                Add-Content -Path $LogFilePath -Value $FileMessage
                if ($Underline) { Add-Content -Path $LogFilePath -Value "$([string]::Empty.PadLeft($FileMessage.Length,$UnderlineChar))" }
            }
        }
        
        if ($EventLog)
        { 
            if ($EventLogName -eq [string]::Empty) { Write-Warning (Get-ADFSTkLanguageText logEventLogNameNotSet) }
            elseif ($EventLogSource -eq [string]::Empty) { Write-Warning (Get-ADFSTkLanguageText logEventSourceNotSet) }
            else
            {
                #Write-Verbose "Logging to EventLog `'$EventLogName`' as Source `'$EventLogSource`'..." 
            
                Write-EventLog -LogName $EventLogName -Source $EventLogSource -EventId $EventID -Message $Message -EntryType $EntryType -Category $Category    
            }
        }

        if($EntryType -eq "Warning")
        {
            $global:Warnings++
            $global:LastWarning = $Message
        }
        elseif($EntryType -eq "Error")
        {
            $global:Errors++
            $global:LastError = $Message
        }
        
        if ($MajorFault) { throw $Message }   
    }
}
<#
.SYNOPSIS
Use this cmdlet to add logging to your script. Can log to Screen/File and EventLog

.DESCRIPTION
Start by setting FilePath and/or EventLogName/EventLogSource. The values are stored in global variables and don't need to be set again.

Call Write-ADFSTkLog with one or more parameters depending on how much logging needed. 

If a Warning is logged the following global variables will be changed:
$Warnings will increase with 1
$LastWarning will be set to $Message

If an Error is logged the following global variables will be changed:
$Errors will increase with 1
$LastError will be set to $Message

If -MajorFault is provided, EntryType will automatically be set as Error and after logging has been done, the Message will be thrown.

If a variable namned $Silent is used and equals $true in the script calling Write-ADFSTkLog, no logging to screen will be done

.EXAMPLE
C:\PS> Write-ADFSTkLog -Message "Hello World!"
2012-02-02 16:40:16: Hello World!

-Message parameter are not needed as long as the message is written first

C:\PS> Write-ADFSTkLog "Hello World!" -EntryType Warning
WARNING: 2012-02-02 16:41:23: Hello World!

C:\PS> Write-ADFSTkLog -SetLogFilePath C:\Logs\myLogfile.txt
C:\PS> Write-ADFSTkLog "Hello textfile!" -File -Screen -Underline
2012-02-02 16:46:31: Hello textfile!
------------------------------------
.EXAMPLE
If none of the parameters (-Screen, -File or -EventLog) is provided, all defined ways will be used.
Default will only be the screen, a -SetLogFilePath has been set, the logging will be to screen and file, etc

C:\PS> Write-ADFSTkLog -SetLogFilePath C:\Logs\myLogfile.txt
C:\PS> Write-ADFSTkLog "Look, I don't use any parameters! :)"
2012-02-02 16:59:46: Look, I don't use any parameters! :)

C:\PS> Get-Content $LogFilePath
2012-02-02 16:46:31 - Information: Hello textfile!
--------------------------------------------------
2012-02-02 16:59:46 - Information: Look, I don't use any parameters! :)

C:\PS> Write-ADFSTkLog "Something isn't quite right!" -EntryType Warning
WARNING: 2012-02-02 17:00:45: Something isn't quite right!

C:\PS> Get-Content $LogFilePath
2012-02-02 16:46:31 - Information: Hello textfile!
--------------------------------------------------
2012-02-02 16:59:46 - Information: Look, I don't use any parameters! :)
2012-02-02 17:00:45 - Warning: Something isn't quite right!
C:PS> $Warnings
2
C:PS> $Errors
0
C:PS> $LastWarning
Something isn't quite right!
#>
}

function Write-ADFSTkVerboseLog {
[CmdletBinding(SupportsShouldProcess=$true)] 
param (
    [parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    #The message to be written in the log...
    $Message,
    [string]
    #Used in LogFile and on Screen to clarify the message. In EventLog the Level on the event is set to EntryType. Default is Information
    [ValidateSet("Information", "Error", "Warning")]
    $EntryType="Information",
    [switch]
    #Use this to log to EventLog
    $EventLog,
    [switch]
    #Use this to log to file
    $File,
    [int]
    #The EventID if EventLog is used
    $EventID
)
    if ($verbosePreference -eq "Continue")
    { 
        if (!$File.IsPresent -and !$EventLog.IsPresent)
        {
            if ($EventLogName -ne $null -and $EventLogSource -ne $null)
            {
                $EventLog = $true
            }

            if ($LogFilePath -ne $null)
            {
                $File = $true
            }
        }

        if ($EventLog)
        {
            Write-ADFSTkLog -Message $Message -EventLog -EventID $EventID -EntryType $EntryType
        }
        
        if($File)
        {
            Write-ADFSTkLog -Message $Message -File -EventID $EventID -EntryType $EntryType
        }
        
        Write-ADFSTkLog -Message $Message -EntryType $EntryType -Screen
        
    }
<#
.SYNOPSIS
Use this cmdlet to add Verbose-logging to your script. Logging will always be to screen, but can also be done to File and/or EventLog

.DESCRIPTION
Start by setting FilePath and/or EventLogName/EventLogSource with Write-ADFSTkLog.

Category will always be set to 4

.EXAMPLE
Scriptfile below (Test-Script.ps1)
---
[CmdletBinding(SupportsShouldProcess=$true)]
param()

Write-VerboseLiULog "This is a verbose message"
---

C:\PS> .\Test-Script.ps1

C:\PS> .\Test-Script.ps1 -Verbose
VERBOSE: This is a verbose message
.EXAMPLE
Scriptfile below (Test-Script.ps1)
---
[CmdletBinding(SupportsShouldProcess=$true)]
param()

Write-ADFSTkLog -SetLogFilePath .\myLogfile.txt
Write-VerboseLiULog "This is a verbose message"
---

C:\PS> .\Test-Script.ps1 -File -Verbose
VERBOSE: Setting LogFilePath to '.\myLogfile.txt'...
VERBOSE: 2012-01-04 12:56:50: This is a verbose message

C:\PS> Get-Content .\myLogfile.txt
2012-01-04 12:58:13 - Information: This is a verbose message
#>
}


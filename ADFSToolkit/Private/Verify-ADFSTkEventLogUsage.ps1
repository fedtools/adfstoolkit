function Verify-ADFSTkEventLogUsage 
{
[CmdletBinding(DefaultParameterSetName='Auto')]
param(
    [Parameter(Mandatory=$true, 
                ParameterSetName='Manual')]
    $LogName,
    [Parameter(Mandatory=$true, 
                ParameterSetName='Manual')]
    $Source
)
    # We ingest the eventLogging settings from the config file and set things up to accept eventlog traffic 
    $EventLogEnabled = $false

    if (!$PSBoundParameters.ContainsKey('LogName'))
    {
        if ($Settings.configuration.Logging -ne $null -and `
            $Settings.configuration.Logging.HasAttribute('useEventLog') -and `
            $Settings.configuration.Logging.useEventLog.ToLower() -eq 'true')
        {
            $LogName = $Settings.configuration.logging.LogName
            $Source = $Settings.configuration.logging.Source
        }
        else
        {
            # EventLogging is not used, we signal false  
            return $false
        }
    }
   
    try 
    {
        # We know we should log to the event log by the time we are here.

        # Both LogName and Source need to be non empty

        if ([System.Diagnostics.EventLog]::Exists($LogName) -and [System.Diagnostics.EventLog]::SourceExists($Source))
        {
            # This is good, both log and source exist, and logging is activatated
            #Only logg as verbose
            #Write-EventLog -LogName $LogName -Source $Source -EventId 1 -Message (Get-ADFSTkLanguageText logEventLogUsed)
                
            $EventLogEnabled = $true
        }
        else 
        {
            # eventlog does not exist yet, create when sufficient info is provided
                       
            if (![string]::IsNullOrEmpty($LogName) -and -not [string]::IsNullOrEmpty($Source))
            {
                #both the logName and Source need to exist before we'll create them.

                #First, we delete the eventlog source so we can assign it to the right LogName destination
                Remove-EventLog -Source $Source -ErrorAction SilentlyContinue

                # Second, we now issue the appropriate Association to the LogName

                # If the log does not exist, New-EventLog creates the log and uses this value 
                # for the Log and LogDisplayName properties of the new event log. 
                # If the log exists, New-EventLog registers a new source for the event log.
                # https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-eventlog?view=powershell-5.1 
                            
                New-EventLog -LogName $LogName -Source $Source
                Limit-EventLog -OverflowAction OverWriteAsNeeded -LogName $LogName
                Write-EventLog -LogName $LogName -Source $Source -EventId 1 -Message (Get-ADFSTkLanguageText logEventLogCreated)
                $EventLogEnabled=1
            }
            else 
            {
                Write-ADFSTkLog (Get-ADFSTkLanguageText logCouldNotCreateEventLog)
                $EventLogEnabled = $false
            }
        } # end eventlog creation step
    }
    catch
    {
        throw $_
    }
    
    # pass the true/false for eventlog to invoker
    return $EventLogEnabled
}

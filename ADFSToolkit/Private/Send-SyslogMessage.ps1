function Send-SyslogMessage
{
    #region Parameters
    [CmdletBinding(PositionalBinding=$false,                  
                  ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]

    Param
    (
        # The message to send
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Message,

        # The syslog server hostname/IP
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server,

        # The severity of the event
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Emergency", "Alert", "Critical", "Error", "Warning", "Notice", "Information", "Debug")]
        [String]
        $Severity,

        # The facility of the event
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Kern", "User", "Mail", "Daemon", "Auth", "Syslog", "LPR",
                     "News", "UUCP", "Cron", "AuthPriv", "FTP", "NTP", "Security",
                     "Console", "Solaris-Chron", "Local0", "Local1", "Local2",
                     "Local3", "Local4", "Local5", "Local6", "Local7")]
        [String]
        $Facility,

        # The host name
        [Parameter(Mandatory=$false)]
        [String]
        $Hostname = $env:COMPUTERNAME,

        # The application name
        [Parameter(Mandatory=$false)]
        [String]
        $Application = "PowerShell",

        # The protocol to use
        [Parameter(Mandatory=$false)]
        [ValidateSet("UDP", "TCP")]
        [string]
        $Protocol = "UDP",

        # The syslog server port
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Port = 514
    )
    #endregion

    #region Begin
    Begin
    {
    }
    #endregion

    #region Process
    Process
    {
        # Process the facility
        [int]$FacilityInt = -1
        switch ($Facility)
        {
            'Kern'          {$FacilityInt = 0}
            'User'          {$FacilityInt = 1}
            'Mail'          {$FacilityInt = 2}
            'Daemon'        {$FacilityInt = 3}
            'Auth'          {$FacilityInt = 4}
            'Syslog'        {$FacilityInt = 5}
            'LPR'           {$FacilityInt = 6}
            'News'          {$FacilityInt = 7}
            'UUCP'          {$FacilityInt = 8}
            'Cron'          {$FacilityInt = 9}
            'AuthPriv'      {$FacilityInt = 10}
            'FTP'           {$FacilityInt = 11}
            'NTP'           {$FacilityInt = 12}
            'Security'      {$FacilityInt = 13} 
            'Console'       {$FacilityInt = 14}
            'Solaris-Chron' {$FacilityInt = 15}
            'Local0'        {$FacilityInt = 16}
            'Local1'        {$FacilityInt = 17}
            'Local2'        {$FacilityInt = 18}
            'Local3'        {$FacilityInt = 19}
            'Local4'        {$FacilityInt = 20}
            'Local5'        {$FacilityInt = 21}
            'Local6'        {$FacilityInt = 22}
            'Local7'        {$FacilityInt = 23} 
            Default         {}
        }

        # Process the severity
        [int]$SeverityInt = -1
        switch ($Severity)
        {
            'Emergency'   {$SeverityInt = 0}
            'Alert'       {$SeverityInt = 1}
            'Critical'    {$SeverityInt = 2}
            'Error'       {$SeverityInt = 3}
            'Warning'     {$SeverityInt = 4}
            'Notice'      {$SeverityInt = 5}
            'Information' {$SeverityInt = 6}
            'Debug'       {$SeverityInt = 7}
            Default     {}
        }

        # Calculate the priority of the message
        $Priority = ($FacilityInt * 8) + [int]$SeverityInt

        # Get the timestamp in a syslog format
        # Create a locale object
        $LocaleEN = New-Object System.Globalization.CultureInfo("en-US")
        #$Timestamp = Get-Date -Format "MMM dd HH:mm:ss"
        $Timestamp = (Get-Culture).TextInfo.ToTitleCase([DateTime]::Now.ToString('MMM dd HH:mm:ss', $LocaleEN))

        foreach($m in $Message)
        {
            # Format the syslog message
            $syslogMessage = "<{0}>{1} {2} {3} {4}" -f $Priority, $Timestamp, $Hostname, $Application, $m
            Write-Verbose ("Sending message: " + $syslogMessage)

            # Create an encoding object to encode to ASCII
            $Encoder = [System.Text.Encoding]::ASCII

            # Convert the message to byte array
            try
            {
                Write-Verbose "Encoding the message."
                $syslogMessageBytes= $Encoder.GetBytes($syslogMessage)
            }
            catch
            {
                Write-Error "Failed to encode the message to ASCII."
                continue
            }

            $syslogMessage | clip

            # Send the Message
            if($Protocol -eq "UDP")
            {
                Write-Verbose "Sending using UDP."

                # Create the UDP Client object
                $UDPCLient = New-Object System.Net.Sockets.UdpClient
                $UDPCLient.Connect($Server, $Port)

                # Send the message
                try
                {
                    $UDPCLient.Send($syslogMessageBytes, $syslogMessageBytes.Length) |
                        Out-Null
                    Write-Verbose "Message sent."
                }
                catch
                {
                    Write-Error ("Failed to send the message. " + $_.Exception.Message)
                    continue
                }
            }
            else
            {
                Write-Verbose "Sending using TCP."

                # Send the message via TCP
                try
                {
                    # Create a TCP socket object
                    $socket = New-Object System.Net.Sockets.TcpClient($Server, $Port)

                    # Write the message in the stream
                    $stream = $socket.GetStream()
                    $stream.Write($syslogMessageBytes, 0, $syslogMessageBytes.Length)

                    # Flush and close the stream
                    $stream.Flush()
                    $stream.Close()

                    Write-Verbose "Message sent."
                }
                catch
                {
                    Write-Error ("Failed to send the message. " + $_.Exception.Message)
                    continue
                }
            }
        }
    }
    #endregion

    #region End
    End
    {
    }
    #endregion
}
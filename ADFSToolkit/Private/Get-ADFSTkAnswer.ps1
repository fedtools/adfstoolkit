function Get-ADFSTkAnswer {
[CmdletBinding(DefaultParameterSetName='NonPipeline')]

param (        
    [Parameter(Mandatory=$true,
                position=0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [Alias('Name')]
    [ValidateNotNullOrEmpty()]
    [string]
    #The message that should be viewed before Yes/No
    $Message,
    [Parameter(Mandatory=$false,
                position=1)]
    [string]
    #The caption for the message
    $Caption = "Choose wisely...",
    [Parameter(Mandatory=$false,
                position=2)]
    [switch]
    #Show abort as an alternative
    $Abort,
    [Parameter(Mandatory=$false,
                position=3)]
    [switch]
    #Use this to prompt Yes as default value
    $DefaultYes
)

BEGIN
{
    if (!$PSBoundParameters.ContainsKey('Message'))
    {
        $Pipeline = $true
        $Abort = $false
    }

    $YesToAll = $false
    $NoToAll = $false
}
PROCESS      
{
    if ($Pipeline)
    {
        $CurrentObject = $_
    }

    if ($YesToAll)
    {
        if ($Pipeline)
        {
            return $CurrentObject
        }
        else
        {
            return 1
        }
    }
    elseif ($NoToAll)
    {
        if (!$Pipeline)
        {
            return 0
        }
    }
    else
    {
        if ($DefaultYes) { $DefaultAnswer = 0 } else { $DefaultAnswer = 1 }

    
        $choices = @()
    

        $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
        $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&No",""

        if ($Abort)
        {
            $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&Abort",""
        }

        if ($Pipeline)
        {
            $choices += New-Object System.Management.Automation.Host.ChoiceDescription "Yes to &ALL",""
            $choices += New-Object System.Management.Automation.Host.ChoiceDescription "No to A&LL",""
        }

        $caption = $Caption
        $message = $Message
        #$result = $Host.UI.PromptForChoice($caption,$message,$choices,$DefaultAnswer) 
        $result = $Host.UI.PromptForChoice($caption,$message,[System.Management.Automation.Host.ChoiceDescription[]]($choices),0)

        switch ($result)
        {
            0 {
                if ($Pipeline) 
                { 
                    return $CurrentObject
                }
                else 
                { 
                    return 1 
                }
            }
            1 {
                if (!$Pipeline) 
                {
                    return 0
                }
            }
            2 {
                if ($Abort)
                {
                    return 2
                }
                else
                {
                    $YesToAll = $true
                    if ($Pipeline) 
                    {
                        return $CurrentObject
                    }
                    else
                    {
                        return 1
                    }
                }
            }
            3 {
                $NoToAll = $true
                if (!$Pipeline) 
                {
                    return 0
                }
            }
#            4 {
#                if (!$Pipeline) 
#                   {
#                        $NoToAll = $true
#                    return 0
#                }
#            }
        }
    }
}
END
{
}

<#
.SYNOPSIS
Gives a Yes/No question and returns the answer

.DESCRIPTION
Use this cmdlet to make a quick question to the user.

.EXAMPLE
C:\PS> if (Get-LiUAnswer "Do you want to continue?") {Write-Host "Continuing..."}

Choose wisely...
Do you want to continue?
[Y] Yes  [N] No  [?] Help (default is "N"): y
Continuing...

.EXAMPLE
C:\PS> $Answer = Get-LiUAnswer "Do you want to continue?" -Abort

Choose wisely...
Do you want to continue?
[Y] Yes  [N] No  [A] Abort  [?] Help (default is "N"): A

C:\PS> if ($Answer -eq 2) {throw "Script aborted!"}
Script aborted!
At line:1 char:21
+ if ($Answer -eq 2) {throw "Script aborted!"}
+                     ~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (Script aborted!:String) [], RuntimeException
    + FullyQualifiedErrorId : Script aborted!
.EXAMPLE
C:\PS> Get-ChildItem $env:TEMP *.tmp | Get-LiUAnswer -Caption "Delete file?" | Remove-Item -WhatIf
Delete file?
tmp36AC.tmp
[Y] Yes  [N] No  [A] Yes to ALL  [L] No to ALL  [?] Help (default is "Y"): A
What if: Performing operation "Remove File" on Target "C:\Users\adm_johpe12\AppData\Local\Temp\tmp36AC.tmp".
What if: Performing operation "Remove File" on Target "C:\Users\adm_johpe12\AppData\Local\Temp\tmp4423.tmp".
What if: Performing operation "Remove File" on Target "C:\Users\adm_johpe12\AppData\Local\Temp\tmp4424.tmp".
...
#>
}


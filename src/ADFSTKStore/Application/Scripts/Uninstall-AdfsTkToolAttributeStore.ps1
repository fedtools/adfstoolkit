
Write-Host "Uninstall AdfsTkToolStore"
## ADFS 
$Name="AdfsTkToolStore"
Remove-ADFSAttributeStore -TargetName $Name
        
$dll = Join-Path "c:\windows\adfs" "Urn.Adfstk.Application.dll"

if(Test-Path $dll)
{
    if(Test-Path $dll)
    {
        Stop-Service adfssrv
        Remove-Item $dll
        Start-Service adfssrv
        Write-Host "Done!"
    }
}
else
{
    Write-Host "No dll found, aborting..."
}
    
    
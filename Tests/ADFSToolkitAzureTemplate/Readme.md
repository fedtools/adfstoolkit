# Install-Module Az
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
Install-Module Az.Accounts
Install-Module Az.Resources
```
# Connect to Azure
```
$SubscriptionName = "[TargetSubscriptionName]"
Connect-AzAccount -Subscription $SubscriptionName 
```
# Azure Template Spec
```
$TemplateSpecsResourceGroupName = "TemplateSpecs-rg"
$ADFSTemplateName = "ADFSLabEnvironment"

Get-AzTemplateSpec -ResourceGroupName $TemplateSpecsResourceGroupName -Name $ADFSTemplateName
```
# Create Resource Group
```
$ResourceGroupName = "ADFSToolkit-Lab-rg"
$Location = "[AzureRegion]"
New-AzResourceGroup -Name $ResourceGroupName -Location $Location
```
# Deploy Template Spec
```
$AdminPassword = ConvertTo-SecureString -String "!$(([guid]::NewGuid()).guid)!" -AsPlainText -Force
$Parameters = @{
    TemplateSpecId = (Get-AzTemplateSpec -Name $ADFSTemplateName -ResourceGroupName $TemplateSpecsResourceGroupName -Version 1.0).Versions.Id
    ResourceGroupName = $ResourceGroupName
    TemplateParameterFile = "C:\ADFS Azure Template\parameters.json"
    adminPassword = $AdminPassword
}

New-AzResourceGroupDeployment @Parameters

[System.Net.NetworkCredential]::New("", $AdminPassword).Password | Clip
```
# Remove Resource Group
```
Remove-AzResourceGroup -Name $ResourceGroupName
```
Param (
    [Parameter(Mandatory=$true)][string] $azureAdminUsername,
    [Parameter(Mandatory=$true)][string] $azureAdminPassword,
    [Parameter(Mandatory=$true)][string] $subscriptionId,
    [Parameter(Mandatory=$true)][string] $resourceGroup,
    [Parameter(Mandatory=$true)][string] $vmName
)

$azureAdminPasswordEnc = ConvertTo-SecureString $azureAdminPassword -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAdminUsername, $azureAdminPasswordEnc)

Login-AzureRmAccount -Credential $psCred

Select-AzureRmSubscription -SubscriptionId $subscriptionId
Stop-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName
Set-AzureRmVm -ResourceGroupName $resourceGroup -Name $vmName -Generalized

Write "===================================================================================="
write "Do you want to proceed?"
$vm = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName -Status
$vm.Statuses
$confirmation = Read-Host "Confirmation(y/n) "
Write "===================================================================================="

if ($confirmation -eq 'y') {
    Save-AzureRmVMImage -ResourceGroupName $resourceGroup -Name $vmName `
    -DestinationContainerName vhd -VHDNamePrefix $vmName `
    -Path $vmName".json"
} else {
    write Aborted
}



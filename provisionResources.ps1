# TODO: set variables
$studentName = "melissa"
$rgName = "$studentName-lc0820-ps-rg"
$vmName = "$studentName-lc0820-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = "Canonical:UbuntuServer:18.04-LTS:latest"
$vmAdminUsername = "student"
$vmAdminPassword = "LaunchCode-@zure1"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG
az configure --default location=eastus
az group create -n "$rgName"
az configure --default group="$rgName"

# TODO: provision VM
az vm create -n "$vmName" --size "$vmSize" --image "$vmImage" --admin-username "$vmAdminUsername" --admin-password "$vmAdminPassword" --authentication-type password --assign-identity --generate-ssh-keys
az configure --default vm="$vmName"

# TODO: capture the VM systemAssignedIdentity
$vmObjectId="$(az vm show --query "identity.principalId")"

# TODO: open vm port 443
# az network nsg rule create --nsg-name "$vmName"-nsg -n inboundWeb --priority 310 --direction Inbound --destination-port-ranges 443

# az network nsg rule create --nsg-name "$vmName"-nsg -n outboundWeb --priority 100 --direction Outbound --destination-port-ranges 443
az vm open-port --port 443

# provision KV

az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name "$kvName" -n "$kvSecretName" --value "$kvSecretValue"

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
az keyvault set-policy -n "$kvName" --object-id "$vmObjectId" --secret-permissions get list

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file
$publicIp = "$(az vm show -n $vmName -g $rgName --query "publicIpAddress")"
Write-Output $publicIp
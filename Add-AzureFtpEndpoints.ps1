
# Arguments.
param 
(
	[Microsoft.WindowsAzure.Management.ServiceManagement.Model.PersistentVMRoleContext]$vm = $(throw "'vm' is required."),
	[int]$publicPort = $(throw "'publicPort' is required."),
	[int]$dynamicPortFirst = $(throw "'dynamicPortFirst' is required."),
	[int]$dynamicPortLast = $(throw "'dynamicPortLast' is required.")
)
Get-ChildItem "${Env:ProgramFiles(x86)}\Microsoft SDKs\Windows Azure\PowerShell\Azure\*.dll" | ForEach-Object {[Reflection.Assembly]::LoadFile($_) | out-null }

$totalPorts = $dynamicPortLast - $dynamicPortFirst + 1
if ($totalPorts -gt 150)
{
	$(throw "You cannot add more than 150 endpoints (this includes the Public FTP Port)")
}

# Add endpoints.
Write-Host -Fore Green "Adding: FTP-Public-$publicPort"
Add-AzureEndpoint -VM $vm -Name "FTP-Public-$publicPort" -Protocol "tcp" -PublicPort $publicPort -LocalPort $publicPort
for ($i = $dynamicPortFirst; $i -le $dynamicPortLast; $i++)
{
	$name = "FTP-Dynamic-" + $i
	Write-Host -Fore Green "Adding: $name"
	Add-AzureEndpoint -VM $vm -Name $name -Protocol "tcp" -PublicPort $i -LocalPort $i
}

# Update VM.
Write-Host -Fore Green "Updating VM..."
$vm | Update-AzureVM 
Write-Host -Fore Green "Done."

param (
	[Parameter(Mandatory = $True)]
	[string]$DomainName,

	[Parameter(Mandatory = $True)]
	[string]$DSRMPassword

)

$netbiosDomain = ($DomainName -split '\.')[0].ToUpperInvariant()
$DSRMPasswordSec = ConvertTo-SecureString -AsPlainText $DSRMPassword -Force

# make sure the Administrator has a password that meets the minimum Windows
# password complexity requirements (otherwise the AD will refuse to install).
Write-Output 'Resetting the Administrator account password and settings...'
Set-LocalUser -Name 'Administrator' -AccountNeverExpires -Password $DSRMPasswordSec -PasswordNeverExpires:$true -UserMayChangePassword:$true

Write-Output 'Installing the AD services and administration tools...'
Install-WindowsFeature AD-Domain-Services, RSAT-AD-AdminCenter, RSAT-ADDS-Tools | Out-Null

Write-Output 'Installing the AD forest ( This may take a minute :) )...'
Import-Module ADDSDeployment
# NOTE: ForestMode and DomainMode are set to WinThreshold (Windows Server 2016).
#    see https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/active-directory-functional-levels
Install-ADDSForest `
	-InstallDns `
	-CreateDnsDelegation:$false `
	-ForestMode 'WinThreshold' `
	-DomainMode 'WinThreshold' `
	-DomainName $DomainName `
	-DomainNetbiosName $netbiosDomain `
	-SafeModeAdministratorPassword $DSRMPasswordSec `
	-NoRebootOnCompletion `
	-Force
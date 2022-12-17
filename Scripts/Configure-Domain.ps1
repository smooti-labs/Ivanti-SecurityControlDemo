$adDomain = Get-ADDomain
$domain = $adDomain.DNSRoot
$domainDn = $adDomain.DistinguishedName
$usersAdPath = "CN=Users,$($domainDn)"
$msaAdPath = "CN=Managed Service Accounts,$($domainDn)"

# Configure AD to allow the use of Group Managed Service Accounts (gMSA).
# https://docs.microsoft.com/en-us/windows-server/security/group-managed-service-accounts/group-managed-service-accounts-overview
# https://docs.microsoft.com/en-us/windows-server/security/group-managed-service-accounts/create-the-key-distribution-services-kds-root-key
# NOTE: We cannot use -EffectiveImmediately because it would still wait 10h for
# the KDS root key to propagate, instead, we force the time to 10h ago to make it really immediate.
Add-KdsRootKey -EffectiveTime (Get-Date).AddHours(-10) | Out-Null

# Remove the non-routable vagrant nat ip address from dns.
# NOTE: The nat interface is the first dhcp interface of the machine.
$vagrantNatAdapter = Get-NetAdapter -Physical | Where-Object {
	$_ | Get-NetIPAddress | Where-Object {
		$_.PrefixOrigin -eq 'Dhcp' }
} | Sort-Object -Property Name | Select-Object -First 1
$vagrantNatIpAddress = ($vagrantNatAdapter | Get-NetIPAddress).IPv4Address

# Remove the $domain nat ip address resource records from dns.
$vagrantNatAdapter | Set-DnsClient -RegisterThisConnectionsAddress $false
Get-DnsServerResourceRecord -ZoneName $domain -Type 1 | Where-Object {
	$_.RecordData.IPv4Address -eq $vagrantNatIpAddress } | Remove-DnsServerResourceRecord -ZoneName $domain -Force

# Disable ipv6.
$vagrantNatAdapter | Disable-NetAdapterBinding -ComponentID ms_tcpip6

# Remove the dc.$domain nat ip address resource record from dns.
$dnsServerSettings = Get-DnsServerSetting -All
$dnsServerSettings.ListeningIPAddress = @(
	$dnsServerSettings.ListeningIPAddress | Where-Object { $_ -ne $vagrantNatIpAddress }
)

Set-DnsServerSetting $dnsServerSettings
Clear-DnsClientCache

# Create group Managed Service Account (gMSA).
# NOTE: Computer principals (or security group of computer principals) need
#    to be explicitly allowed to use the gMSA with one of the following
#    cmdlets:
#       Set-ADServiceAccount
#       Add-ADComputerServiceAccount
# NOTE: You can use this account to run a windows service by using the
#    EXAMPLE\whoami$ account name and an empty password.
$msaName = 'whoami'
$msaServiceAcct = @{
	Name        = $msaName
	Path        = $msaAdPath
	DNSHostName = $domain
}

New-ADServiceAccount @msaServiceAcct

# Allow any domain controller/computer to use the gMSA
# NOTE: Check security groups a computer is a member of with: Get-ADPrincipalGroupMembership <MyComputerName>
$allowedPrincipals = @(
	"CN=Domain Controllers,$($usersAdPath)",
	"CN=Domain Computers,$($usersAdPath)"
)
Set-ADServiceAccount -Identity $msaName	-PrincipalsAllowedToRetrieveManagedPassword $allowedPrincipals

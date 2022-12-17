param (
	[Parameter(Mandatory = $True)]
	[string]$Password

)

$domainRoot = (Get-ADDomain).DNSRoot
$domainName = (Get-ADDomain).Name
$passwordSec = ConvertTo-SecureString -AsPlainText $Password -Force
$users = @('john.doe', 'jane.doe') # NOTE: Usernames must be <first.last>
$groups = @(
	'sonar-administrators', # NOTE: this is used by https://github.com/rgl/sonarqube-windows-vagrant
	"$($domainName)-auditors"
)

# Create groups
foreach ($group in $groups) {
	$groupArgs = @{
		Name          = $group
		GroupCategory = 'Security'
		GroupScope    = 'DomainLocal'
	}

	New-ADGroup @groupArgs
}

# Create users
foreach ($user in $users) {
	$firstname = (Get-Culture).TextInfo.ToTitleCase($user.Split('.')[0])
	$lastname = (Get-Culture).TextInfo.ToTitleCase($user.Split('.')[1])
	# $photo = [byte[]](Get-Content -Encoding byte "users-photos/user-photo-$user.jpg")
	$userArgs = @{
		Name                 = $user
		UserPrincipalName    = "$($user)@$($domainRoot)"
		EmailAddress         = "$($user)@$($domainRoot)"
		GivenName            = $firstname
		Surname              = $lastname
		DisplayName          = $firstname + $lastname
		AccountPassword      = $passwordSec
		Enabled              = $true
		PasswordNeverExpires = $true
		HomePage             = "https://$($domainRoot)/~/$($user)"
		# OtherAttributes      = @{
		# 	photo = $photo
		# }
	}

	New-ADUser @userArgs
}

# Add first user to all groups
# NOTE: The admin supreme's apprentice
ForEach ($group in $Groups) {

	Add-ADPrincipalGroupMembership $Users[0]  -MemberOf  $Group
}
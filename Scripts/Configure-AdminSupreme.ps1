param (
	[Parameter(Mandatory = $True)]
	[string]$UserName
)

$groups = @(
	'Domain Admins', # NOTE: Necessary to to add KDS key for gMSA
	'Enterprise Admins' # NOTE: Needed to install the Enterprise Root Certification Authority
)
foreach ($group in $groups) {
	Add-ADGroupMember -Identity $group -Members $UserName
}

# Set the vagrant user photo.
# $userPhoto = [byte[]] (Get-Content -Encoding byte "Images/user-photo-$UserName.jpg")
# Set-ADUser -Identity $UserName -Replace @{photo = $userPhoto}
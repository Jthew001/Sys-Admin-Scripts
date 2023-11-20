Start-Transcript "c:\ProgramData\Microsoft\IntuneManagementExtension\Logs\lapsadminremediation.log"
Add-Type -AssemblyName 'System.Web'
$username = "UserName" # Update me with the username of the admin account you want!
$user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
$userParams = @{
    Name = 'Fix_LAPS'
    Description = 'LAPS Client Local Admin'
    Password = [System.Web.Security.Membership]::GeneratePassword(16, 0) | ConvertTo-SecureString -AsPlainText -Force
}
# create user with random password
if(!$user)
{
	$user = New-LocalUser @userParams

	# Add user to built-in administrators group
	Add-LocalGroupMember -SID 'S-1-5-32-544' -Member $user
}
Stop-Transcript
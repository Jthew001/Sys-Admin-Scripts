# Gets a list of devices from a device group and provides the user account, device name and account status. 
# Update the variables below to modify the output. 


# Variable Delacation (Non-Static Variables) --------------------------------------------------------------
$accountEnabledStatus = $false #($true = Get active accnts, $false = Get disabled accnts) Set the device filter to include or exclude accounts based on status.  
$groupID = "update with object ID of group" #Object ID of group you want to get users from.  
#----------------------------------------------------------------------------------------------------------

# Connect to Azure AD
Connect-AzureAD

# Get the list of users from the AzureAD group. 
$devices = Get-AzureADGroupMember -ObjectId $groupID -All $true

# Get the registered devices for each user. 
foreach ($device in $devices) {
    $user = Get-AzureADDeviceRegisteredUser -ObjectId $device.ObjectId
    If ($user.AccountEnabled -eq $accountEnabledStatus){
        Write-Host "User: $($user.DisplayName) || Device: $($device.DisplayName) || Account is active: $($user.AccountEnabled)"
    }
}

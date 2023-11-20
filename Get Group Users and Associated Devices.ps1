#Variable Delacation (Non-Static Variables) --------------------------------------------------------------
$deviceType = "Windows" #Change the OS type to filter on what devices are selected. Ex, Windows, iOS, Mac
$accountEnabledStatus = "True" #Set the device filter to include or exclude accounts based on status (True = Get active accnts, False = Get disabled accnts).  
$groupID = "update with group object ID" #Object ID of group you want to get users from.  
$userDevices = @() #Empty array to store the user devices

#----------------------------------------------------------------------------------------------------------

# Connect to Azure AD
Connect-AzureAD

# Get the list of users from the AzureAD group. 
$users = Get-AzureADGroupMember -ObjectId $groupID -All $true

# Get the registered devices for each active user.
foreach ($user in $users) {
    If ($user.AccountEnabled -eq $accountEnabledStatus){
        $devices = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId
        Write-Host "User: $($user.UserPrincipalName) - Account is active: $($user.AccountEnabled)"
    }
    Else {
        Write-Host "User: $($user.UserPrincipalName) - Account is active: $($user.AccountEnabled)"
        Continue
    }
    #Add each Windows device of each active user to the userDevices array with the following properties. 
    foreach ($device in $devices) {
        If ($device.DeviceOSType -eq $deviceType){
            $userDevice = New-Object PSObject
            Add-Member -InputObject $userDevice -MemberType NoteProperty -Name DeviceName -Value $device.DisplayName
            Add-Member -InputObject $userDevice -MemberType NoteProperty -Name User -Value $user.UserPrincipalName
            Add-Member -InputObject $userDevice -MemberType NoteProperty -Name ObjectID -Value $device.ObjectID
            $userDevices += $userDevice
            #Write-Host "Device Name: $($device.DisplayName)"
        }
        Else{
        Continue
        }
        
    }
}

Write-Host "___________________________________"


# Output the user devices, this will not show devices for users with disabled accounts!
foreach ($userDevice in $userDevices) {
    
    Write-Host "$($userDevice.User) - $($userDevice.DeviceName)"
    
}
Write-Host "___________________________________"
Write-Host "`n"


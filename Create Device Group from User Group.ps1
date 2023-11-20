# 1) This script parses the users of a group and grabs the associated devices. 
# 2) Stores the device info into an array, then uses the info to create a new group with only the user devices. 

#IMPORTANT!! This script can be used to parse mulitple groups of users and add the devices to one grouping. 
#IMPORTANT!! Simply update the $groupID variable with the group to be search and run the app, do this for each group that needs to be searched. 

# Useful for instances where an app/script needs to be pushed to user devices, but only a user group is avail. 

#Variable Delacation (Non-Static Variables) --------------------------------------------------------------
$deviceType = "Windows" #Change the OS type to filter on what devices are selected. Ex, Windows, iOS, Mac
$accountEnabledStatus = "True" #Set the device filter to include or exclude accounts based on status (True = Get active accnts, False = Get disabled accnts).  
$groupName = "update with group name" #Name of new group
$groupDesc = "update with group desc" #Desc of new group
$groupNickname = "mailNicknameforNotmailEnabled" #Mail Nickname for group. REQUIRED EVEN IF NOT MAIL ENABLED GROUPING.
$groupID = "enter group object ID" #Object ID of group you want to get users from.  
$userDevices = @() #Empty array to store the user devices
$newGroupDevices = @() #Empty array to store devices from new group created.

#----------------------------------------------------------------------------------------------------------

# Connect to Azure AD
Connect-AzureAD

# Get the list of users from the AzureAD group. 
$users = Get-AzureADGroupMember -ObjectId $groupID -All $true

# Get the registered devices for each active user.
foreach ($user in $users) {
    If ($user.AccountEnabled -eq $accountEnabledStatus){
        $devices = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId
        #Write-Host "User: $($user.UserPrincipalName) - Account is active: $($user.AccountEnabled)"
    }
    Else {
        #Write-Host "User: $($user.UserPrincipalName) - Account is active: $($user.AccountEnabled)"
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


#Check if group exists, if so, set flag to True for future use and break the loop. 
$groupCheckFlag = $false # Static Variable, needs to be False.
$groupFind = Get-AzureADMSGroup -All $true
foreach($group in $groupFind) {
    If ($group.DisplayName -eq $groupName){
        $groupCheckFlag = $true
        $groupFind = $group.Id
        Write-Host "Group Found: $($groupName)"
        Break
    }
    Else {Continue}
}

#Check the status of the groupcheck and create group if still false. 
#Set the new group ID to $groupFind to be used later. 
If($groupCheckFlag -eq $false){
    Write-Host "Creating group: $($groupName)"
    $newGroup = New-AzureADMSGroup -DisplayName $groupName -Description $groupDesc -MailEnabled $False -MailNickname "testGroupmarketing" -SecurityEnabled $True
    $groupFind = $newGroup.Id
    #Write-Host $groupFind
}

# Get list of members in the new group. 
$newGroupList = Get-AzureADGroupMember -ObjectId $groupFind -All $true

#Insert the Object ID & Display Name of each devices in the $newGroupDevices array. 
foreach ($newGroupDevice in $newGroupList){
    $newGroupUserDevice = New-Object PSObject
    Add-Member -InputObject $newGroupUserDevice -MemberType NoteProperty -Name Name -Value $newGroupDevice.DisplayName
    Add-Member -InputObject $newGroupUserDevice -MemberType NoteProperty -Name ObjectID -Value $newGroupDevice.ObjectID
    $newGroupDevices += $newGroupUserDevice
}

# Iterate over the userDevices array and check if there are any matching ObjectIDs in the $newGroupDevices array. 
foreach ($userDevice in $userDevices) {
    if($newGroupDevices.ObjectID -contains $userDevice.ObjectID){
        Write-Host "Device found: $($userDevice.ObjectID)"
    }
    Else {
        Add-AzureADGroupMember -ObjectId $groupFind -RefObjectId $userDevice.ObjectID
        Write-Host "Device Added: $($userDevice.ObjectID)"

    }

}








# Gets a list of all devices (and their last ApproxLogonTimeStamp) in Azure and a list of all devices (and their last ApproxLogonTimeStamp) from a device group.
# Compares the lists for matches, and then finds devices with either no LastLogon or a LastLogon older then the value at $DaysInactive. 
# Allow you to find stale devices in a group. 
# Could be modified to just check LogonTime for all devices is desired. 


# Var Declare----------------------------
$groupID = "update with group object ID" #group to compare against
$groupDeviceList = @()
$allDeviceList = @()
$groupDevicesTimeStamps = @()
$allDevicesTimeStamps = @()
$DaysInactive = 180
$time = (Get-Date).Adddays(-($DaysInactive))
$inactiveCount = 0
#----------------------------------------


# Connect to Azure AD
Connect-AzureAD

#----------------

# Get all Azure AD devices
$allDevices = Get-AzureADDevice -All $true

# Write all Azure AD devices to array for later use. 
foreach ($member in $allDevices){
    #Write-Host "$($device.DisplayName) -- $($device.ApproximateLastLogonTimeStamp)"
    $allDevicesTimeStamps += $member.ApproximateLastLogonTimeStamp
    $allDeviceList += $member.DisplayName
}
#-----------------

# Get all members of group specified 
$devices = Get-AzureADGroupMember -ObjectId $groupID -All $true

# For each device found in the command above, get last logon time stamp and display name and write to array.
# Then loop through the array to find matches.
# Output matches and their last login timestamp.  
foreach ($device in $devices){
    #Write-Host "$($device.DisplayName) -- $($device.ApproximateLastLogonTimeStamp)"
    $groupDevicesTimeStamps += $device.ApproximateLastLogonTimeStamp
    $groupDeviceList += $device.DisplayName
    foreach($obj in $allDeviceList){
        if($obj -match $device.DisplayName){
            If ($device.ApproximateLastLogonTimeStamp -eq $null){
                Write-Host "Device $($device.DisplayName) has no logon time stamp (Azure has no record of use)" -ForegroundColor Gray   
                $inactiveCount++
            }
            Elseif ($device.ApproximateLastLogonTimeStamp -le $time){
                Write-Host "Device: $($device.DisplayName) -- Approx Last Logon: $($device.ApproximateLastLogonTimeStamp) match" -ForegroundColor DarkYellow
                $inactiveCount++
            }
            
        }
    }
}
Write-Host "------------------------------"
Write-Host "$($inactiveCount) devices from 'group: $($groupID)' that are $($DaysInactive) days inactive"
Write-Host "------------------------------"







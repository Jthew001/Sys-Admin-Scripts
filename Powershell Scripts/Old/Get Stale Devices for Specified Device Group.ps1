# Var Declare----------------------------
$groupID = "specify group object ID" #group to parse
$groupDeviceList = @()
$allDeviceList = @()
$groupDevicesTimeStamps = @()
$allDevicesTimeStamps = @()
$DaysInactive = 180
$time = (Get-Date).Adddays(-($DaysInactive))
$inactiveCount = 0
#----------------------------------------

Connect-AzureAD

# Get all members of group specified 
$devices = Get-AzureADGroupMember -ObjectId $groupID -All $true

# For each device found in the command above, get last logon time stamp and display name and write to array.
# Then loop through the array to find matches.
# Output matches and their last login timestamp.  
foreach ($device in $devices){
    #Write-Host "$($device.DisplayName) -- $($device.ApproximateLastLogonTimeStamp)"
    If ($device.ApproximateLastLogonTimeStamp -eq $null){
        Write-Host "Device $($device.DisplayName) has no logon time stamp (Azure has no record of use)" -ForegroundColor Gray   
        $inactiveCount++
   }
    Elseif ($device.ApproximateLastLogonTimeStamp -le $time){
         Write-Host "Device: $($device.DisplayName) -- Approx Last Logon: $($device.ApproximateLastLogonTimeStamp) match" -ForegroundColor DarkYellow
         $inactiveCount++
   }
}

Write-Host "------------------------------"
Write-Host "$($inactiveCount) devices from 'group: $($groupID)' that are $($DaysInactive) days inactive"
Write-Host "------------------------------"

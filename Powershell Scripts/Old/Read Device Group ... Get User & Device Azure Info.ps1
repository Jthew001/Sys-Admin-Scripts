# Gets a list of devices from a csv file and provides device and user info from Azure. 
# Requires a CSV file with a single column of device names to parse, THE FIRST CEll of each Column being the header ('Name' in this case). Update filepath var with path to file. 

#-------------------------------------------
# Variable Delacation (Non-Static Variables)
#-------------------------------------------

#----------Variables-------------
$groupID = "Object ID of Group" # Object ID of Group to parse. 
$DaysInactive = 180
$accountEnabledStatus = $false # ($true = Get active accnts, $false = Get disabled accnts) Set the device filter to include or exclude accounts based on status.  
#-------------------------------------------

#--------Static Variables------------------
$time = (Get-Date).Adddays(-($DaysInactive))
#----------------------------------------

#-----------Arrays--------------------------
$Names = @() # Array to write device names found in CSV file. 
$issueUsers = @() # Array to write users/devices found to have issues (disabled accounts. 
$issueDevices = @()
$fineUser  = @() # Array to write users that are active. 
$fineDevice = @() #Array to write devices that are active. 
$notFound = @() # Array to write devices that are not found in Azure.
$nullUser = @() # Array to write devices who have users that are null. 
$duplicateDevice = @()
$staleDevices = @()
#-------------------------------------------

#----------Counters-------------------------
$fineCount = 0 # Holds count for devices with active users and devices.
$notFoundCount = 0 # Holds count of devices not found in Azure. 
$nullUserCount = 0 # Holds count of devices with null users. 
$duplicateDeviceCount = 0
$issueUserCount = 0 # Var to hold count for users/devices that disabled.
$issueDeviceCount = 0
$staleCount = 0
#-------------------------------------------

# Connect to Azure AD
Connect-AzureAD

# Get the list of users from the AzureAD group. 
$devices = Get-AzureADGroupMember -ObjectId $groupID -All $true

Foreach ($device in $devices) {
    try{
        $user = Get-AzureADDeviceRegisteredUser -ObjectId $device.ObjectId # Get user associated with azure device. 
        }
     catch{
        If ($PSItem -match "Cannot bind argument to parameter 'ObjectId' because it is null."){
            Write-Host "------------------------------------------"
            Write-Host "Device: $($device.DisplayName) not found in Azure." -ForegroundColor Red
            Write-Host "------------------------------------------"
            $notFoundCount++
            $notFound += $device.DisplayName
            Continue
        }
        #Write-Output "Ran into an issue: $PSItem"
        #Write-Host "Duplicate value found: $($device)" 
        Write-Host "------------------------------------------"
        Write-Host "Device: $($device.DisplayName) duplicate found in Azure." -ForegroundColor Yellow
        Write-Host "------------------------------------------"
        $duplicateDeviceCount++
        $duplicateDevice += $device.DisplayName # Logs any devices not found in Azure into $notFound array. 
        Continue
        }

        If ($device.ApproximateLastLogonTimeStamp -le $time -or $device.ApproximateLastLogonTimeStamp -eq $null){
            Write-Host "------------------------------------------"
            Write-Host "Device: $($device.DisplayName) -- Approx Last Logon: $($device.ApproximateLastLogonTimeStamp) match" -ForegroundColor DarkYellow
            Write-Host "------------------------------------------"
            $staleCount++
            $staleDevices += $device.DisplayName
        }

        If ($user.DisplayName -eq $null){
            
            Write-Host "------------------------------------------"
            Write-Host "User: $($user.DisplayName)" -ForegroundColor Gray
            Write-Host "User status is active: $($user.AccountEnabled)" -ForegroundColor Gray
            Write-Host "Device: $($device.DisplayName)" -ForegroundColor Gray
            Write-Host "Device active?: $($device.AccountEnabled)" -ForegroundColor Gray
            Write-Host "------------------------------------------"  
            
            $nullUserCount++
            #$nullUser += $user.DisplayName # Logs any devices not found in Azure into $notFound array. 
            $nullUser += $device.DisplayName
            Continue
        }
        ElseIf($device.AccountEnabled -eq $accountEnabledStatus){
            Write-Host "------------------------------------------"
            Write-Host "User account is disabled" -ForegroundColor Magenta
            Write-Host "User: $($user.DisplayName)" -ForegroundColor Magenta
            Write-Host "Device: $($device.DisplayName)" -ForegroundColor Magenta
            Write-Host "Device active?: $($device.AccountEnabled)" -ForegroundColor Magenta
            Write-Host "------------------------------------------"
            $issueDeviceCount++
            $issueDevices += $device.DisplayName
            Continue
        }
        ElseIf($user.AccountEnabled -eq $accountEnabledStatus){
            Write-Host "------------------------------------------"
            Write-Host "User account is disabled" -ForegroundColor DarkYellow
            Write-Host "User: $($user.DisplayName)" -ForegroundColor DarkYellow
            Write-Host "Device: $($device.DisplayName)" -ForegroundColor DarkYellow
            Write-Host "Device active?: $($device.AccountEnabled)" -ForegroundColor DarkYellow
            Write-Host "------------------------------------------"
            $issueUserCount++
            $issueUsers += $user.DisplayName
            Continue
        }
        
        Else{
            
            Write-Host "------------------------------------------"
            Write-Host "User: $($user.DisplayName)"
            Write-Host "User status is active: $($user.AccountEnabled)"
            Write-Host "Device: $($device.DisplayName)"
            Write-Host "Device active?: $($device.AccountEnabled)"
            Write-Host "------------------------------------------"
            
            $fineCount++
            $fineUser += $user.DisplayName
            $fineDevice += $device.DisplayName
        }
        
   }

   Write-Host "------------------------------------------------------------------"
   Write-Host "Fine Count: $($fineCount)"
   Write-Host "------------------------------------------------------------------"
   Write-Host "Issue User Count: $($issueUserCount)"
   Write-Host "------------------------------------------------------------------"
   Write-Host "Issue Device Count: $($issueDeviceCount)"
   Write-Host "------------------------------------------------------------------"
   Write-Host "Not Found Count: $($notFoundCount)"
   Write-Host "------------------------------------------------------------------"
   Write-Host "Null user Count: $($nullUserCount)"
   Write-Host "------------------------------------------------------------------"
   Write-Host "Duplicate Device Count: $($duplicateDeviceCount)"
   Write-Host "-------------------------------------------------------------------"
   Write-Host "Stale Device Count: $($staleCount)"
   Write-Host "-------------------------------------------------------------------"
   

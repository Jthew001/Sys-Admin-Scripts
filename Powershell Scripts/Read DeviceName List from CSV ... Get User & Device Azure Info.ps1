# Gets a list of devices from a csv file and provides device and user info from Azure. 
# Requires a CSV file with a single column of device names to parse, THE FIRST CEll of each Column being the header ('Name' in this case). Update filepath var with path to file. 

#-------------------------------------------
#            Variable Delacation 
#-------------------------------------------

#----------Import File Location-------------
$filePath = "C:\Temp\AllAzureDevices.csv" # Filepath for csv with info. 
$accountEnabledStatus = $false # ($true = Get active accnts, $false = Get disabled accnts) Set the device filter to include or exclude accounts based on status.
$header = "displayName" # Update this var with the name of the column header on your CSV file. The file MUST have a column header.  
$DaysInactive = 180
#------------------------------------------

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

# Get list of device names from specified CSV file. 
$devices = Import-Csv -Path $filePath | ForEach-Object { # Parses file and grabs each device in the 'Name' column of the .csv file. 
    $Names += $_.$header # Get each value under 'Name' column on .csv and writes value of the cell to the array, runs until all devices of file have been parsed. 

}

Foreach ($device in $Names) {
    #Write-Host $device
    $deviceObj = Get-AzureADDevice -Searchstring $device # Search for device in Azure by device name. 
    try{
        $user = Get-AzureADDeviceRegisteredUser -ObjectId $deviceObj.ObjectId # Get user associated with azure device. 
        }
     catch{
        If ($PSItem -match "Cannot bind argument to parameter 'ObjectId' because it is null."){
            Write-Host "------------------------------------------"
            Write-Host "Device: $($device) not found in Azure." -ForegroundColor Red
            Write-Host "------------------------------------------"
            $notFoundCount++
            $notFound += $device
            Continue
        }
        #Write-Output "Ran into an issue: $PSItem"
        #Write-Host "Duplicate value found: $($device)" 
        Write-Host "------------------------------------------"
        Write-Host "Device: $($device) duplicate found in Azure." -ForegroundColor Yellow
        Write-Host "------------------------------------------"
        $duplicateDeviceCount++
        $duplicateDevice += $device # Logs any devices not found in Azure into $notFound array. 
        Continue
        }

        If ($deviceObj.ApproximateLastLogonTimeStamp -le $time -or $deviceObj.ApproximateLastLogonTimeStamp -eq $null){
            Write-Host "Device: $($device) -- Approx Last Logon: $($deviceObj.ApproximateLastLogonTimeStamp)" -ForegroundColor DarkYellow
            $staleCount++
            $staleDevices += $device
        }

        If ($user.DisplayName -eq $null){
            
            Write-Host "------------------------------------------"
            Write-Host "User: $($user.DisplayName)" -ForegroundColor Gray
            Write-Host "User status is active: $($user.AccountEnabled)" -ForegroundColor Gray
            Write-Host "Device: $($device)" -ForegroundColor Gray
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor Gray
            Write-Host "------------------------------------------"  
            
            $nullUserCount++
            #$nullUser += $user.DisplayName # Logs any devices not found in Azure into $notFound array. 
            $nullUser += $device
            Continue
        }
        ElseIf($deviceObj.AccountEnabled -eq $accountEnabledStatus){
            Write-Host "------------------------------------------"
            Write-Host "User account is disabled" -ForegroundColor Magenta
            Write-Host "User: $($user.DisplayName)" -ForegroundColor Magenta
            Write-Host "Device: $($device)" -ForegroundColor Magenta
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor Magenta
            Write-Host "------------------------------------------"
            $issueDeviceCount++
            $issueDevices += $device
            Continue
        }
        ElseIf($user.AccountEnabled -eq $accountEnabledStatus){
            Write-Host "------------------------------------------"
            Write-Host "User account is disabled" -ForegroundColor DarkYellow
            Write-Host "User: $($user.DisplayName)" -ForegroundColor DarkYellow
            Write-Host "Device: $($device)" -ForegroundColor DarkYellow
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor DarkYellow
            Write-Host "------------------------------------------"
            $issueUserCount++
            $issueUsers += $user.DirSyncEnabled
            Continue
        }
        
        Else{
            
            Write-Host "------------------------------------------"
            Write-Host "User: $($user.DisplayName)"
            Write-Host "User status is active: $($user.AccountEnabled)"
            Write-Host "Device: $($device)"
            Write-Host "Device active?: $($deviceObj.AccountEnabled)"
            Write-Host "------------------------------------------"
            
            $fineCount++
            $fineUser += $user.DisplayName
            $fineDevice += $device
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

   
# Gets a list of devices from a csv file and provides device and user info from Azure. 
# Requires a CSV file with a single column of device names to parse. Update filepath var with path to file. 
# Also requires CSV output locations, see vars below.

# Variable Delacation (Non-Static Variables) --------------------------------------------------------------
$Names = @() # Array to write device names found in CSV file. 

$issues = @() # Array to write users/devices found to have issues (disabled accounts. 
$issueCount = 0 # Var to hold count for users/devices that disabled.

$fineUser  = @() # Array to write users that are active. 
$fineDevice = @() #Array to write devices that are active. 
$fineCount = 0 # Holds count for devices with active users and devices.

$notFound = @() # Array to write devices that are not found in Azure.
$notFoundCount = 0 # Holds count of devices not found in Azure. 

$nullUser = @() # Array to write devices who have users that are null. 
$nullUserCount = 0 # Holds count of devices with null users. 


$accountEnabledStatus = $false # ($true = Get active accnts, $false = Get disabled accnts) Set the device filter to include or exclude accounts based on status.  


$filePath = "C:\Temp\devices.csv" # Filepath for csv with info. 
$exportPathFineUsers = "C:\Temp\devices.csv" # Filepath for csv with exported Fine user info.
$exportPathFineDevices = "C\Temp\devices.csv" # Filepath for csv to be exported the Fine device info. 
#----------------------------------------------------------------------------------------------------------

# Connect to Azure AD
Connect-AzureAD

# Get list of device names from specified CSV file. 
$devices = Import-Csv -Path $filePath | ForEach-Object {
    $Names += $_.Name

}

Foreach ($device in $Names) {
    #Write-Host $device
    $deviceObj = Get-AzureADDevice -Searchstring $device # Search for device in Azure by device name. 
    try{
        $user = Get-AzureADDeviceRegisteredUser -ObjectId $deviceObj.ObjectId # Get user associated with azure device. 
        }
     catch{
        <#
        Write-Host "------------------------------------------"
        Write-Host "Device: $($device) not found in Azure" -ForegroundColor DarkYellow
        Write-Host "------------------------------------------"
        #>
        $notFoundCount++
        $notFound += $device # Logs any devices not found in Azure into $notFound array. 
        Continue
        }


        If ($user.DisplayName -eq $null){
           <# 
            Write-Host "------------------------------------------"
            Write-Host "User: $($user.DisplayName)" -ForegroundColor Gray
            Write-Host "User status is active: $($user.AccountEnabled)" -ForegroundColor Gray
            Write-Host "Device: $($device)" -ForegroundColor Gray
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor Gray
            Write-Host "------------------------------------------"  
            #>
            $nullUserCount++
            $nullUser += $user.DisplayName # Logs any devices not found in Azure into $notFound array. 
            $nullUser += $device
        }
        ElseIf($user.AccountEnabled -eq $accountEnabledStatus -or $deviceObj.AccountEnabled -eq $accountEnabledStatus){
            $issueCount++
            $issues += $user.DisplayName
            $issues += $device
            }
        <#
        ElseIf($user.AccountEnabled -eq $accountEnabledStatus){
            Write-Host "User account is disabled" -ForegroundColor DarkYellow
            Write-Host "User: $($user.DisplayName)" -ForegroundColor DarkYellow
            Write-Host "Device: $($device)" -ForegroundColor DarkYellow
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor DarkYellow
        }
        ElseIf($deviceObj.AccountEnabled -eq $accountEnabledStatus){
            Write-Host "User account is disabled" -ForegroundColor Magenta
            Write-Host "User: $($user.DisplayName)" -ForegroundColor Magenta
            Write-Host "Device: $($device)" -ForegroundColor Magenta
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor Magenta
        }
        #>
        Else{
            <#
            Write-Host "------------------------------------------"
            Write-Host "User: $($user.DisplayName)"
            Write-Host "User status is active: $($user.AccountEnabled)"
            Write-Host "Device: $($device)"
            Write-Host "Device active?: $($deviceObj.AccountEnabled)"
            Write-Host "------------------------------------------"
            #>
            $fineCount++
            $fineUser += $user.DisplayName
            $fineDevice += $device
        }
        
   }
   Write-Host "Fine Count: $($fineCount)"
   #Write-Host $fine | ft
   $ObjUserArray = $fineUser | Select-Object @{Name='Name';Expression={$_}} # Convert string array into Object Array with object property 'Name'.
   $ObjDeviceArray += $fineDevice | Select-Object @{Name='Device';Expression={$_}} # Convert string array into Object Array with object property 'Device'.
   $ObjUserArray | Export-Csv $exportPathFineUsers -NoTypeInformation # Export array info to csv file
   $ObjDeviceArray | Export-Csv $exportPathFineDevices -NoTypeInformation # Export array info to csv file. 
   Write-Host "Issue Count: $($issueCount)"
   Write-Host $issues |ft
   Write-Host "Not Found Count: $($notFoundCount)"
   Write-Host $notFound |ft
   Write-Host "Null user Count: $($nullUserCount)"
   Write-Host $nullUser |ft
   

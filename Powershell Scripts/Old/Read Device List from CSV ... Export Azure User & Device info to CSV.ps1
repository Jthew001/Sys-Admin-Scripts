# Gets a list of devices from a csv file and provides device and user info from Azure. 
# Requires a CSV file with a single column of device names to parse, THE FIRST CEll of each Column being the header ('Name' in this case). Update filepath var with path to file. 
# Also requires CSV output locations, see vars below.

#-------------------------------------------
# Variable Delacation (Non-Static Variables)
#-------------------------------------------

#----------Import File Location-------------
$filePath = "C:\Temp\devices.csv" # Filepath for csv with info. 
#-------------------------------------------

#-----------Arrays--------------------------
$Names = @() # Array to write device names found in CSV file. 
$issueUsers = @() # Array to write users/devices found to have issues (disabled accounts. 
$issueDevices = @()
$fineUser  = @() # Array to write users that are active. 
$fineDevice = @() #Array to write devices that are active. 
$notFound = @() # Array to write devices that are not found in Azure.
$nullUser = @() # Array to write devices who have users that are null. 
$duplicateDevice = @()
#-------------------------------------------

#----------Counters-------------------------
$fineCount = 0 # Holds count for devices with active users and devices.
$notFoundCount = 0 # Holds count of devices not found in Azure. 
$nullUserCount = 0 # Holds count of devices with null users. 
$duplicateDeviceCount = 0
$issueUserCount = 0 # Var to hold count for users/devices that disabled.
$issueDeviceCount = 0
#-------------------------------------------

#---------Boolean Vars----------------------
$accountEnabledStatus = $false # ($true = Get active accnts, $false = Get disabled accnts) Set the device filter to include or exclude accounts based on status.  
#-------------------------------------------

#----------Export Locations-----------------
$exportPathFineUsers = "C:\Temp\FineUsers.csv" # Filepath for csv with exported Fine user info.
$exportPathFineDevices = "C:\Temp\FineDevices.csv" # Filepath for csv to be exported the Fine device info. 
$exportPathNotFoundDevices = "C:\Temp\DeviceNotFoundinAzure.csv"
$exportIssueUsers = "C:\Temp\IssueUsers.csv"
$exportIssueDevices = "C:\Temp\IssueDevices.csv"
$exportNullUserDevices = "C:\Temp\NullUsers.csv"
$exportDuplicateDevices = "C:\Temp\DuplicateDevices.csv"
#----------------------------------------------------------------------------------------------------------



# Connect to Azure AD
Connect-AzureAD

# Get list of device names from specified CSV file. 
$devices = Import-Csv -Path $filePath | ForEach-Object { # Parses file and grabs each device in the 'Name' column of the .csv file. 
    $Names += $_.Name # Get each value under 'Name' column on .csv and writes value of the cell to the array, runs until all devices of file have been parsed. 

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
        If ($PSItem -match "Cannot bind argument to parameter 'ObjectId' because it is null."){
            #Write-Host "Device not Found: $($device)"
            $notFoundCount++
            $notFound += $device
            Continue

        }
        #Write-Output "Ran into an issue: $PSItem"
        #Write-Host "Duplicate value found: $($device)" 
        $duplicateDeviceCount++
        $duplicateDevice += $device # Logs any devices not found in Azure into $notFound array. 
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
            #$nullUser += $user.DisplayName # Logs any devices not found in Azure into $notFound array. 
            $nullUser += $device
            Continue
        }
        ElseIf($deviceObj.AccountEnabled -eq $accountEnabledStatus){
        <#
            Write-Host "User account is disabled" -ForegroundColor Magenta
            Write-Host "User: $($user.DisplayName)" -ForegroundColor Magenta
            Write-Host "Device: $($device)" -ForegroundColor Magenta
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor Magenta
        #>
            $issueDeviceCount++
            $issueDevices += $device
            Continue
        }
        ElseIf($user.AccountEnabled -eq $accountEnabledStatus){
        <#
            Write-Host "User account is disabled" -ForegroundColor DarkYellow
            Write-Host "User: $($user.DisplayName)" -ForegroundColor DarkYellow
            Write-Host "Device: $($device)" -ForegroundColor DarkYellow
            Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor DarkYellow
        #>
            $issueUserCount++
            $issueUsers += $user.DirSyncEnabled
            Continue
        }
        
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
   #----------------------------------------------------------------------------------------------------
   Write-Host "Fine Count: $($fineCount)"
   #Write-Host $fine | ft
   $ObjUserArray = $fineUser | Select-Object @{Name='Name';Expression={$_}} # Convert string array into Object Array with object property 'Name'.
   $ObjDeviceArray = $fineDevice | Select-Object @{Name='Device';Expression={$_}} # Convert string array into Object Array with object property 'Device'.

   $ObjUserArray | Export-Csv $exportPathFineUsers -NoTypeInformation # Export array info to csv file
   $ObjDeviceArray | Export-Csv $exportPathFineDevices -NoTypeInformation # Export array info to csv file. 
   #------------------------------------------------------------------------------------------------------
   Write-Host "Issue User Count: $($issueUserCount)"
   Write-Host "Issue Device Count: $($issueDeviceCount)"
   $ObjDeviceIssueArray = $issueDevices | Select-Object @{Name='Device';Expression={$_}}
   $ObjUserIssuesArray = $issueUsers | Select-Object @{Name='Name';Expression={$_}}

   $ObjDeviceIssueArray | Export-Csv $exportIssueDevices -NoTypeInformation # Export array info to csv file. 
   $ObjUserIssuesArray | Export-Csv $exportIssueUsers -NoTypeInformation # Export array info to csv file. 
   #------------------------------------------------------------------------------
   Write-Host "Not Found Count: $($notFoundCount)"
   $ObjNotFoundArray = $notFound | Select-Object @{Name='Device';Expression={$_}}
   $ObjNotFoundArray | Export-Csv $exportPathNotFoundDevices -NoTypeInformation
   #------------------------------------------------------------------------------
   Write-Host "Null user Count: $($nullUserCount)"
   $ObjNullUsersArray = $nullUser | Select-Object @{Name='Devices';Expression={$_}}
   $ObjNullUsersArray | Export-Csv $exportNullUserDevices -NoTypeInformation # Export array info to csv file. 
   #-------------------------------------------------------------------------------
   Write-Host "Duplicate Device Count: $($duplicateDeviceCount)"
   $ObjDuplicateDeviceArray = $duplicateDevice | Select-Object @{Name='Devices';Expression={$_}}
   $ObjDuplicateDeviceArray | Export-Csv $exportDuplicateDevices -NoTypeInformation # Export array info to csv file. 
   #------------------------------------------------------------------------------
   Write-Host "------------------------------------------------------------------"

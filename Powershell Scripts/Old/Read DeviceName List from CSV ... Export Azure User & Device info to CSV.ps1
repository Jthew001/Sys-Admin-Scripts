# Gets a list of devices from a csv file and provides device and user info from Azure. 
# Requires a CSV file with a single column of device names to parse, THE FIRST CEll of each Column being the header ('Name' or 'Device' for example). Update filepath var with path to file. 
# Also requires CSV output locations, see vars below.

#-------------------------------------------
# Variable Delacation (Non-Static Variables)
#-------------------------------------------

#-----Variables you MUST review & set-------
$filePath = "C:\Temp\VulunDevices.csv" # Filepath for csv with Device List info.
$outputFolder = "C:\Temp\Vulun Devices Output" # Output folder for .csv files
$accountEnabledStatus = $false # ($true = Get active accnts, $false = Get disabled accnts) Set the device filter to include or exclude accounts based on status.
$header = "displayName" # Update this var with the name of the column header on your CSV file. The file MUST have a column header.  
$DaysInactive = 90
$whileVar = $true
#------------------------------------------

#--------Static Variables------------------
$time = (Get-Date).Adddays(-($DaysInactive))
#----------------------------------------

#-----------Arrays--------------------------
$Names = @() # Array to write device names found in CSV file. 
$issueUsers = @() # Array to write users/devices found to have issues (disabled accounts. 
$issueDevices = @()
$activeUsersandDevices = @() #Array to write users and devices that are active. 
$notFound = @() # Array to write devices that are not found in Azure.
$nullUser = @() # Array to write devices who have users that are null. 
$duplicateDevice = @()
$staleDevices = @()
$notManagedDevices = @()
#-------------------------------------------

#----------Counters-------------------------
$fineCount = 0 # Holds count for devices with active users and devices.
$notFoundCount = 0 # Holds count of devices not found in Azure. 
$nullUserCount = 0 # Holds count of devices with null users. 
$duplicateDeviceCount = 0
$issueUserCount = 0 # Var to hold count for users/devices that disabled.
$issueDeviceCount = 0
$staleCount = 0
$isNotManagedCount = 0
$totalCount = 0
#-------------------------------------------

#----------Export Locations-----------------
$exportPathNotFoundDevices = "$($outputFolder)\DeviceNotFoundinAzure.csv"
$exportIssueUsers = "$($outputFolder)\DisabledUsers.csv"
$exportIssueDevices = "$($outputFolder)\DisabledDeviceswithUser.csv"
$exportNullUserDevices = "$($outputFolder)\NullUserDevices.csv"
$exportDuplicateDevices = "$($outputFolder)\DuplicateDevices.csv"
$exportStaleDevices = "$($outputFolder)\StaleDevices$($DaysInactive)Inactive.csv"
$exportNotManagedDevices = "$($outputFolder)\NotManagedDevices.csv"
$exportActiveUsersandDevices = "$($outputFolder)\ActiveDeviceswithUser.csv"
#----------------------------------------------------------------------------------------------------------



    # Connect to Azure AD
    Connect-AzureAD

    # For use with pulling devices from CSV file. 
        # Get list of device names from specified CSV file. 
    $devices = Import-Csv -Path $filePath | ForEach-Object { # Parses file and grabs each device in the 'Name' column of the .csv file. 
        $Names += $_.$header # Get each value under 'Name' column on .csv and writes value of the cell to the array, runs until all devices of file have been parsed. 

    }

    Foreach ($device in $Names) {
        $totalCount++
        #Write-Host $device
        $deviceObj = Get-AzureADDevice -Searchstring $device # Search for device in Azure by device name. 
        
        #Write-Host $deviceObj
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
                $notFound += $deviceObj.DisplayName
                Continue
            }
            #Write-Output "Ran into an issue: $PSItem"
            #Write-Host "Duplicate value found: $($device)" 
            $duplicateDeviceCount++
            $duplicateDevice += $deviceObj.DisplayName # Logs any devices not found in Azure into $notFound array.
            Continue 
            }

        

            If ($deviceObj.IsManaged -eq $accountEnabledStatus){
                $isNotManagedCount++
                $notManagedDevices += $deviceObj.DisplayName
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
                $nullUser += $deviceObj.DisplayName
            }

            If($deviceObj.AccountEnabled -eq $accountEnabledStatus){
            <#
                Write-Host "User account is disabled" -ForegroundColor Magenta
                Write-Host "User: $($user.DisplayName)" -ForegroundColor Magenta
                Write-Host "Device: $($device)" -ForegroundColor Magenta
                Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor Magenta
            #>
                $issueDeviceCount++
                $issueObject = New-Object PSObject
                Add-Member -InputObject $issueObject -MemberType NoteProperty -Name Device -Value $deviceObj.DisplayName
                Add-Member -InputObject $issueObject -MemberType NoteProperty -Name LastLogin -Value $deviceObj.ApproximateLastLogonTimeStamp
                Add-Member -InputObject $issueObject -MemberType NoteProperty -Name User -Value $user.DisplayName
                Add-Member -InputObject $issueObject -MemberType NoteProperty -Name IsManaged -Value $deviceObj.IsManaged
                $issueDevices += $issueObject
            }

            If($user.AccountEnabled -eq $accountEnabledStatus){
            <#
                Write-Host "User account is disabled" -ForegroundColor DarkYellow
                Write-Host "User: $($user.DisplayName)" -ForegroundColor DarkYellow
                Write-Host "Device: $($device)" -ForegroundColor DarkYellow
                Write-Host "Device active?: $($deviceObj.AccountEnabled)" -ForegroundColor DarkYellow
            #>
                $issueUserCount++
                $issueUsers += $user.DisplayName
            }

            if ($deviceObj.ApproximateLastLogonTimeStamp -le $time -or $deviceObj.ApproximateLastLogonTimeStamp -eq $null){
                #Write-Host "Device: $($device.DisplayName) -- Approx Last Logon: $($device.ApproximateLastLogonTimeStamp) match" -ForegroundColor DarkYellow
                $staleCount++
               
                $staleObject = New-Object PSObject
                Add-Member -InputObject $staleObject -MemberType NoteProperty -Name Device -Value $deviceObj.DisplayName
                Add-Member -InputObject $staleObject -MemberType NoteProperty -Name LastLogin -Value $deviceObj.ApproximateLastLogonTimeStamp
                Add-Member -InputObject $staleObject -MemberType NoteProperty -Name User -Value $user.DisplayName
                $staleDevices += $staleObject
            }
            
        
            if ($deviceObj.AccountEnabled -ne $accountEnabledStatus){
                <#
                Write-Host "------------------------------------------"
                Write-Host "User: $($user.DisplayName)"
                Write-Host "User status is active: $($user.AccountEnabled)"
                Write-Host "Device: $($device)"
                Write-Host "Device active?: $($deviceObj.AccountEnabled)"
                Write-Host "------------------------------------------"
                #>
                $fineCount++
                # This is how you handle exporting data to multiples lines in a CSV file.
                # Create and object, loaded it with what info you want, write object to array. 
                $activeObject = New-Object PSObject
                Add-Member -InputObject $activeObject -MemberType NoteProperty -Name Device -Value $deviceObj.DisplayName
                Add-Member -InputObject $activeObject -MemberType NoteProperty -Name LastLogin -Value $deviceObj.ApproximateLastLogonTimeStamp
                Add-Member -InputObject $activeObject -MemberType NoteProperty -Name User -Value $user.DisplayName
                Add-Member -InputObject $activeObject -MemberType NoteProperty -Name IsManaged -Value $deviceObj.IsManaged
                $activeUsersandDevices += $activeObject
            }
        
       }

   
       if (-Not(Test-Path -Path $outputFolder)) {
            New-Item -Path $outputFolder -Type Directory
       }

       #----------------------------------------------------------------------------------------------------
       Write-Host "Total Count: $($totalCount)"
       Write-Host "Active Count: $($fineCount)"
       $activeUsersandDevices | Export-Csv -Path $exportActiveUsersandDevices -NoTypeInformation #Export PSObject contents to CSV (Multi Column).
       #------------------------------------------------------------------------------------------------------
       Write-Host "Disabled User Count: $($issueUserCount)"
       Write-Host "Disabled Device Count: $($issueDeviceCount)"
       $issueDevices | Export-Csv $exportIssueDevices -NoTypeInformation # Export array info to csv file. 
       
       $ObjUserIssuesArray = $issueUsers | Select-Object @{Name='Name';Expression={$_}}
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
       Write-Host "Stale Device Count: $($staleCount)"
       $staleDevices | Export-Csv -Path $exportStaleDevices -NoTypeInformation #Export PSObject contents to CSV (Multi Column).
       #-------------------------------------------------------------------------------
       Write-Host "Intune Not Managed Device Count: $($isNotManagedCount)"
       $ObjManagedDeviceArray = $notManagedDevices | Select-Object @{Name='Devices';Expression={$_}}
       $ObjManagedDeviceArray | Export-CSV $exportNotManagedDevices -NoTypeInformation
       Write-Host "------------------------------------------------------------------"


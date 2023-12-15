# Gets a list of devices from a csv file and provides device and user info from Azure. 
# Requires a CSV file with a single column of device names to parse, THE FIRST CEll of each Column being the header ('Name' or 'displayName' for example). Update filepath var with path to file. 
# Also requires CSV output locations, see vars below.

#-----Variables you MUST review & set-------
$filePath = "C:\Temp\VulunDevices.csv" # Filepath for csv with Device List info.
$outputFolder = "C:\Temp\TestAfterChange4" # Output folder for .csv files
$header = "displayName" # Update this var with the name of the column header on your CSV file. The file MUST have a column header.  
$DaysInactive = 90
#------------------------------------------

#--------Static Variables------------------
$time = (Get-Date).Adddays(-($DaysInactive))
#----------------------------------------

#-----------Arrays--------------------------
$Names = @() # Array to write device names found in CSV file. 
$allDevices = @()
$notFound = @() # Array to write devices that are not found in Azure.
$duplicateDevice = @()
#-------------------------------------------

#----------Counters-------------------------
$notFoundCount = 0 # Holds count of devices not found in Azure. 
$duplicateDeviceCount = 0
$totalCount = 0
#-------------------------------------------

#----------Export Locations-----------------
$exportPathNotFoundDevices = "$($outputFolder)\DevicesNotFoundinAzure.csv"
$exportDuplicateDevices = "$($outputFolder)\DuplicateDevices.csv"
$exportAllDevices = "$($outputFolder)\AllDevicesInfo.csv"
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
        $deviceObj = Get-AzureADDevice -Searchstring $device # Search for device in Azure by device name. 
        try{
            $user = Get-AzureADDeviceRegisteredUser -ObjectId $deviceObj.ObjectId # Get user associated with azure device. 
            }
         catch{
            If ($PSItem -match "Cannot bind argument to parameter 'ObjectId' because it is null."){
                #Write-Host "Device not Found: $($device)"
                $notFoundCount++
                $notFound += $deviceObj.DisplayName
                Continue
            }
            $duplicateDeviceCount++
            $duplicateDevice += $deviceObj.DisplayName # Logs any devices not found in Azure into $notFound array.
            Continue 
            }

            $allObject = New-Object PSObject
            # Add additonal columns to the .csv file by adding more members here!
            Add-Member -InputObject $allObject -MemberType NoteProperty -Name User -Value $user.DisplayName
            Add-Member -InputObject $allObject -MemberType NoteProperty -Name UserEnabled? -Value $user.AccountEnabled
            Add-Member -InputObject $allObject -MemberType NoteProperty -Name Device -Value $deviceObj.DisplayName
            Add-Member -InputObject $allObject -MemberType NoteProperty -Name DeviceEnabled? -Value $deviceObj.AccountEnabled
            Add-Member -InputObject $allObject -MemberType NoteProperty -Name DeviceLastLogin -Value $deviceObj.ApproximateLastLogonTimeStamp
            Add-Member -InputObject $allObject -MemberType NoteProperty -Name MDMMgmtStatus -Value $deviceObj.IsManaged
            $allDevices += $allObject
            
       }

   
       if (-Not(Test-Path -Path $outputFolder)) {
            New-Item -Path $outputFolder -Type Directory
       }

       
       #----------------------------------------------------------------------------------------------------
       Write-Host "Total Count: $($totalCount)"
       $allDevices | Export-Csv -Path $exportAllDevices -NoTypeInformation #Export PSObject contents to CSV (Multi Column).
       #------------------------------------------------------------------------------------------------------
       Write-Host "Not Found Count: $($notFoundCount)"
       $ObjNotFoundArray = $notFound | Select-Object @{Name='Device';Expression={$_}}
       $ObjNotFoundArray | Export-Csv $exportPathNotFoundDevices -NoTypeInformation
       #-----------------------------------------------------------------------------
       Write-Host "Duplicate Device Count: $($duplicateDeviceCount)"
       $ObjDuplicateDeviceArray = $duplicateDevice | Select-Object @{Name='Devices';Expression={$_}}
       $ObjDuplicateDeviceArray | Export-Csv $exportDuplicateDevices -NoTypeInformation # Export array info to csv file. 
       #------------------------------------------------------------------------------
       
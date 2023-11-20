#Script is designed to create a Computer Info.lnk shortcut on Public Desktop.
#It will remove any traces of System Info.lnk that I first Deployed.  


#------------------------------------------
#Public Desktop location for Shortcuts
$publicDesktopShortcuttoRemove = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('CommonDesktopDirectory'), 'System Info.lnk')
$publicDesktopShortcut = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('CommonDesktopDirectory'), 'Computer Info.lnk')


#Test for C:\Temp and create if not there. 
$FolderPath = "C:\Temp"
if (-not (Test-Path -Path $FolderPath -PathType Container)) {
       New-Item -Path $FolderPath -ItemType Directory -Force
}

#Check for old shortcut and remove. 
if (Test-Path -Path $publicDesktopShortcuttoRemove -PathType Leaf) {
    Remove-Item -Path $publicDesktopShortcuttoRemove -Force
}


#Test for correct shortcut and leave if exists-------------------------------------
if (Test-Path -Path $publicDesktopShortcut -PathType Leaf) {
        Break
}
Else{
    #Download Icon to C:\Temp-------------------------------------------------------
    $sasUrl = "update with link to .ico" # UPDATE ME WITH GOOD URL!!
    $localFolderPath = "C:\Temp\"
    $blobName = [System.IO.Path]::GetFileName($sasUrl)
    $localFilePath = Join-Path -Path $localFolderPath -ChildPath "System.ico"
    Invoke-WebRequest -Uri $sasUrl -OutFile $localFilePath
    #-------------------------------------------------------------------------------
    
    #Create shortcut on public desktop, to given location using given icon
    $Url = "C:\Windows\System32\control.exe"
    $ShortcutName = "Computer Info"
    $IconFilePath = "C:\Temp\System.ico"
    $ShortcutPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonDesktopDirectory), "$ShortcutName.lnk")
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $Url
    $Shortcut.Arguments = "/name Microsoft.System"
    $Shortcut.IconLocation = $IconFilePath
    $Shortcut.Save()
    $Shortcut = $null
    $WScriptShell = $null
  
}





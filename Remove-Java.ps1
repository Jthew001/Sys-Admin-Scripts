#Source: https://adamtheautomator.com/removing-old-java/
#Needs to be run as Admin. 

#------Regkeys with uninstall strings----------------
$RegUninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)
#-----------------------------------------------


#-----Control Panel name of the Version of Java to Keep.----------- 
$VersionsToKeep = @('Java 20000 Update 461') #This version does not exist, therefore all versions unistalled.
                                           #Update with version to a real version if you do want to keep. Latest Version (10/20/23): Java 8 Update 381
#------------------------------------------------------------


#-------Find any Java processes and stop them----------

Get-CimInstance -ClassName 'Win32_Process' | Where-Object {$_.ExecutablePath -like '*Program Files\Java*'} | 
    Select-Object @{n='Name';e={$_.Name.Split('.')[0]}} | Stop-Process -Force
 
Get-process -Name *iexplore* | Stop-Process -Force -ErrorAction SilentlyContinue
#----------------------------------------------------------------------------------


#-------Filter for version to keep----------------------

$UninstallSearchFilter = {($_.GetValue('DisplayName') -like '*Java*') -and (($_.GetValue('Publisher') -eq 'Oracle Corporation')) -and ($VersionsToKeep -notcontains $_.GetValue('DisplayName'))}
#-------------------------------------------------------


#-------Uninstall unwanted Java versions and clean up program files--------------
foreach ($Path in $RegUninstallPaths) {
    if (Test-Path $Path) {
        Get-ChildItem $Path | Where-Object $UninstallSearchFilter | 
       foreach { 
           
        Start-Process 'C:\Windows\System32\msiexec.exe' "/X$($_.PSChildName) /qn" -Wait
    
        }
    }
}
#--------------------------------------------------------------------------------

#----------Remove addional regkey for uninstalled versions---------------
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
$ClassesRootPath = "HKCR:\Installer\Products"
Get-ChildItem $ClassesRootPath | 
    Where-Object { ($_.GetValue('ProductName') -like '*Java*')} | Foreach {
    Remove-Item $_.PsPath -Force -Recurse
}
#-------------------------------------------------------------------------

#-------Additonal Regkey to remove for uninstalled versions--------------
$JavaSoftPath = 'HKLM:\SOFTWARE\JavaSoft'
if (Test-Path $JavaSoftPath) {
    Remove-Item $JavaSoftPath -Force -Recurse
}
#------------------------------------------------------------------------
# Deploy and set new Wall Paper


$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\"
$FullRegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP\"

$LockScreenPath = "LockScreenImagePath"
$LockScreenStatus = "LockScreenImageStatus"
$LockScreenUrl = "LockScreenImageUrl"

$StatusValue = "1"

$DesktopImagePath = "DesktopImagePath"
$DesktopImageStatus = "DesktopImageStatus"
$DesktopImageUrl = "DesktopImageUrl"

$StatusValue = "1"


$url = "URL to .ico file" #Update me with a good URL!
$ImageValue = "path to .ico downloaded" # UPdate me with a good path!
$directory = "C:\temp\"


If ((Test-Path -Path $directory) -eq $false)
{
	New-Item -Path $directory -ItemType directory
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $ImageValue)



New-Item -Path $RegKeyPath -Name "PersonalizationCSP" -Force 
	

New-ItemProperty -Path $FullRegKeyPath -Name $LockScreenStatus -Value $StatusValue -PropertyType DWORD -Force
New-ItemProperty -Path $FullRegKeyPath -Name $LockScreenPath -Value $ImageValue -PropertyType STRING -Force
New-ItemProperty -Path $FullRegKeyPath -Name $LockScreenUrl -Value $url -PropertyType STRING -Force

New-ItemProperty -Path $FullRegKeyPath -Name $DesktopImageStatus -Value $StatusValue -PropertyType DWORD -Force
New-ItemProperty -Path $FullRegKeyPath -Name $DesktopImagePath -Value $ImageValue -PropertyType STRING -Force
New-ItemProperty -Path $FullRegKeyPath -Name $DesktopImageUrl -Value $url -PropertyType STRING -Force

RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True

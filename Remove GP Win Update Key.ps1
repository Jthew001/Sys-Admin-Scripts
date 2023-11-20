# Script checks for a key and removes if found. 
# -Recurse needed for Remove-Item for script to succeed, bec there are subkeys. Cannot just use a -Force

# Regkey path for GP Win Update Config
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

# Check if the WindowsUpdate folder already exists
# If it does, remove it. If not, break out of script. 
# Included Try/Catch for success/failure messages for Intune.  
if (Test-Path $registryPath) {
    Remove-Item -Path $registryPath -Recurse
}

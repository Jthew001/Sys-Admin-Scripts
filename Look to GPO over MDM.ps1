$registryPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\ControlPolicyConflict"

# Check if the ControlPolicyConflict folder already exists
if (-not (Test-Path $registryPath)) {
    # Create the ControlPolicyConflict folder if it doesn't exist
    New-Item -Path $registryPath -Force | Out-Null
}

# Set the registry values MDMWinsOverGP and MDMWinsOverGP_ProviderSet to 1
# Value of 1 tells device to look to MDM (Intune) over GPO. 
Set-ItemProperty -Path $registryPath -Name "MDMWinsOverGP" -Value 0 -Type DWORD | Out-Null
Set-ItemProperty -Path $registryPath -Name "MDMWinsOverGP_ProviderSet" -Value 0 -Type DWORD | Out-Null



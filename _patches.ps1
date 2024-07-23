$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'

# Patches
Write-Host "Applying patches" -ForegroundColor Green
Get-ChildItem -Name *.patch | ForEach-Object {
    git apply $_
}

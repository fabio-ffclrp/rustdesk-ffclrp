$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'
$ErrorActionPreference = 'Stop'
$Version = "1.2.7"

$PYTHON = Get-Command -Name "python3" -ErrorAction SilentlyContinue
if ($null -eq $PYTHON) {
    $PYTHON = Get-Command -Name "python"
}

# Get variables
$Env:RENDEZVOUS_SERVER = Get-Content -Path .server
$Env:RS_PUB_KEY = Get-Content -Path .key

# Clear output directories
Write-Host "Clean output directories" -ForegroundColor Green
Remove-Item -Path .\rustdesk\* -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path .\SignOutput\* -Recurse -Force -ErrorAction SilentlyContinue

# Compile
Write-Host "Compiling Flutter" -ForegroundColor Green
Push-Location flutter ; flutter pub get ; Pop-Location

Write-Host "Building rustdesk" -ForegroundColor Green
$Env:RUSTFLAGS = "-Awarnings" # Do not show Rust Warnings
&$PYTHON .\build.py --portable --hwcodec --flutter --vram --skip-portable-pack
Move-Item .\flutter\build\windows\x64\runner\Release\* .\rustdesk\

Write-Host "Finding Runner.res" -ForegroundColor Green
$filepath = Get-ChildItem -Path "flutter" -Recurse -Include "Runner.res" -Name
if ($null -eq $filepath) {
    Write-Host "Runner.res not found" -ForegroundColor Red
} else {
    Write-Host "Runner.res found at flutter\$filepath" -ForegroundColor Cyan
    Copy-Item -Path "flutter\$filepath" -Destination .\libs\portable\Runner.res
}

Write-Host "Buildind Portable Installer" -ForegroundColor Green
Copy-Item -Force .\usbmmidd_v2 .\rustdesk
Push-Location .\libs\portable
&$PYTHON .\generate.py -f ..\..\rustdesk\ -o . -e ..\..\rustdesk\rustdesk.exe
Pop-Location
Move-Item .\target\release\rustdesk-portable-packer.exe .\SignOutput\rustdesk-${Version}-x86_64.exe

Write-Host "Building MSI" -ForegroundColor Green
Push-Location .\res\msi
&$PYTHON preprocess.py --arp -d ..\..\rustdesk
nuget restore msi.sln
msbuild msi.sln -p:Configuration=Release -p:Platform=x64 /p:TargetVersion=Windows10
Move-Item .\Package\bin\x64\Release\en-us\Package.msi ..\..\SignOutput\rustdesk-${Version}-x86_64.msi
Pop-Location

# Clean up
Write-Host "Clean up" -ForegroundColor Green
git checkout res\msi\*
#cargo clean

Write-Host "All right" -ForegroundColor Green
Get-ChildItem -Path .\SignOutput
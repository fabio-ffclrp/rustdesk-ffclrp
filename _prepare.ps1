$ProgressPreference = 'SilentlyContinue'
$ConfirmPreference = 'None'

$LLVM_URL = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/LLVM-15.0.6-win64.exe"
$RUSTUP_URL = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe"
$FLUTTER_URL = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip"
$USBMMIDD_URL = "https://github.com/rustdesk-org/rdev/releases/download/usbmmidd_v2/usbmmidd_v2.zip"

# Download
Write-Host "Downloading..." -ForegroundColor Green
Invoke-WebRequest -Uri $LLVM_URL -OutFile $Env:TEMP\LLVM.exe
Invoke-WebRequest -Uri $RUSTUP_URL -OutFile $Env:TEMP\rustup-init.exe
Invoke-WebRequest -Uri $FLUTTER_URL -OutFile $Env:TEMP\flutter.zip
Invoke-WebRequest -Uri $USBMMIDD_URL -OutFile $Env:TEMP\usbmmidd_v2.zip

# Install
Write-Host "Installing" -ForegroundColor Green
&$Env:TEMP\LLVM.exe /S
&$Env:TEMP\rustup-init.exe -q -y --default-host x86_64-pc-windows-msvc --default-toolchain 1.75
Expand-Archive $Env:TEMP\flutter.zip -DestinationPath ~\flutter
$Env:PATH = "~\flutter\bin;$Env:PATH"
setx /M PATH $Env:PATH
cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid"

Write-Host "Cloning VCPKG" -ForegroundColor Green
git config --global core.longpaths true
git clone --single-branch -b 2024.06.15 https://github.com/microsoft/vcpkg.git

Write-Host "Bootstrap VCPKG" -ForegroundColor Green
.\vcpkg\bootstrap-vcpkg.bat
$Env:VCPKG_ROOT=(Get-Location).Path + "\vcpkg"
setx /M VCPKG_ROOT $Env:VCPKG_ROOT

Write-Host "Updating/Installing VCPKG packages" -ForegroundColor Green
&$Env:VCPKG_ROOT\vcpkg install --triplet x64-windows-static --x-install-root="$Env:VCPKG_ROOT/installed"

Write-Host "Unzipping usbmmidd_v2.zip" -ForegroundColor Green
Expand-Archive $Env:TEMP\usbmmidd_v2.zip -DestinationPath .
Remove-Item -Path "usbmmidd_v2\Win32" -Recurse -Force
Remove-Item -Path "usbmmidd_v2\deviceinstaller64.exe", "usbmmidd_v2\deviceinstaller.exe", "usbmmidd_v2\usbmmidd.bat" -Force
Copy-Item -Force .\usbmmidd_v2 .\rustdesk

Write-Host "Fixing res/manifest.xml" -ForegroundColor Green
Get-Content -Path "res/manifest.xml" | Select-String -Pattern 'dpiAware' -NotMatch | Out-File "res/manifest.xml"

Write-Host "Preparing portable" -ForegroundColor Green
Push-Location .\libs\portable
pip3 install -r requirements.txt
Pop-Location
New-Item -Force -Name .\SignOutput

# Clean-up
Write-Host "Clean-up" -ForegroundColor Green
Remove-Item -Path $Env:TEMP\LLVM.exe
Remove-Item -Path $Env:TEMP\rustup-init.exe
Remove-Item -Path $Env:TEMP\flutter.zip
Remove-Item -Path $Env:TEMP\usbmmidd_v2.zip

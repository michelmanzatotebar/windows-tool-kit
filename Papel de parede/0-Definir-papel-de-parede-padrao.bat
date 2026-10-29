@echo off

net session >nul 2>&1
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0script wallpaper\scriptWallpaper.ps1"

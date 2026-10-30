@echo off
setlocal
chcp 65001 >nul

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...
    powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0LimparTemporarios.ps1"
exit /b %errorlevel%

@echo off
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v NoConnectedUser /f

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v NoConnectedUser /f

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /f

reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RequirePrivateStoreOnly /f

reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /f

echo O usuario precisa desconectar para aplicar as alteracoes.

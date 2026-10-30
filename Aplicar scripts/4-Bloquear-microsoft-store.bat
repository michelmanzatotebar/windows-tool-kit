@echo off
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

:: Bloqueia contas Microsoft
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v NoConnectedUser /t REG_DWORD /d 3 /f

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v NoConnectedUser /t REG_DWORD /d 3 /f

:: Bloqueia OneDrive
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f

:: Store - somente loja corporativa
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RequirePrivateStoreOnly /t REG_DWORD /d 1 /f

:: Desativa download automático
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f

:: Fecha Store e OneDrive
taskkill /f /im WinStore.App.exe >nul 2>&1
taskkill /f /im OneDrive.exe >nul 2>&1
echo O usuario precisa desconectar para aplicar as alteracoes.

@echo off
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)



:: ==========================================
:: 1 - DESBLOQUEAR WIFI 
:: ==========================================
call "%~dp0\1-Desbloquear-wifi.bat"
if errorlevel 1 exit /b 1



:: ==========================================
:: 2 - DESBLOQUEAR MICROSOFT STORE / ONEDRIVE
:: ==========================================
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v NoConnectedUser /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v NoConnectedUser /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RequirePrivateStoreOnly /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /f

:: ==========================================
:: 3 - DESBLOQUEAR TELA PERSONALIZACAO E CONTAS
:: ==========================================
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoThemesTab /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispBackgroundPage /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispAppearancePage /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f
reg delete "HKCR\DesktopBackground\Shell\Personalize" /v LegacyDisable /f
taskkill /f /im SystemSettings.exe >nul 2>&1

:: ==========================================
:: 4 - REMOVER CONTROLE DE SENHA (USER LOCAL)
:: ==========================================
echo.
echo ==========================================
echo Usuarios locais encontrados:
echo ==========================================
echo.
net user
echo.
set /p USUARIO=Digite exatamente o nome do usuario:

net user "%USUARIO%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Usuario nao encontrado.
    pause
    exit /b
)

cls
echo.
echo ==========================================
echo DADOS DA CONTA SELECIONADA
echo ==========================================
echo.
net user "%USUARIO%"
echo.
echo ==========================================

choice /c SN /m "Remover bloqueios desta conta"
if errorlevel 2 (
    echo Operacao cancelada.
    pause
    exit /b
)

net user "%USUARIO%" /active:yes
net user "%USUARIO%" /passwordchg:yes
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableChangePassword /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowDomainPINLogon /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v UseDefaultTile /f
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 1 /f
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 1 /f

:: ==========================================
:: 5 - REATIVAR OFFLINE FILES E OPTIONS BACKUP
:: ==========================================
reg add "HKLM\SYSTEM\CurrentControlSet\Services\CSC" /v "Start" /t REG_DWORD /d 2 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\CscService" /v "Start" /t REG_DWORD /d 2 /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup\Client" /v DisableBackupUI /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup\Client" /v DisableBackupLauncher /f
reg delete "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v KFMBlockOptIn /t REG_DWORD /d 1 /f
:: ==========================================
:: FIM
:: ==========================================
echo.
echo Todos os bloqueios removidos com sucesso.
echo Reinicie a maquina para aplicar as alteracoes.
pause

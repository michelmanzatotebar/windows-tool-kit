@echo off

:: Verifica Admin
net session >nul 2>&1
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

:: ==========================================
:: 1 - BLOQUEAR WIFI 
:: ==========================================
echo.
echo Executando script de bloqueio de Wi-Fi...
echo.
call "%~dp0\2-bloquear-Wifi.bat"
if errorlevel 1 exit /b 1

@echo off

:: ==========================================
:: 2 - BLOQUEAR MICROSOFT STORE / ONEDRIVE
:: ==========================================
echo.
echo Executando script de Bloquear Microsoft store...
echo.
timeout /t 2 >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v NoConnectedUser /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v NoConnectedUser /t REG_DWORD /d 3 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RequirePrivateStoreOnly /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v AutoDownload /t REG_DWORD /d 2 /f
taskkill /f /im WinStore.App.exe >nul 2>&1
taskkill /f /im OneDrive.exe >nul 2>&1


:: ==========================================
:: 3 - BLOQUEIO TELA PERSONALIZACAO E CONTAS
:: ==========================================
echo.
echo Executando script de Bloqueio de tela personalizacao e contas...
echo.
timeout /t 2 >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoThemesTab /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispBackgroundPage /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispAppearancePage /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /t REG_SZ /d "hide:account;yourinfo;emailandaccounts;signinoptions;workplace;family-group;personalization;personalization-background;personalization-colors;themes;lockscreen" /f
reg add "HKCR\DesktopBackground\Shell\Personalize" /v LegacyDisable /t REG_SZ /d "" /f
taskkill /f /im SystemSettings.exe >nul 2>&1


:: ==========================================
:: 4 - CONTROLE DE SENHA (USER LOCAL)
:: ==========================================
echo.
echo Executando script de Controle de senhas...
echo.
timeout /t 2 >nul

echo.
echo ==========================================
echo Usuarios locais encontrados:
echo ==========================================
echo VERIFIQUE O USER LOCAL NA PASTA USUARIOS DA MAQUINA ANTES DE CONTINUAR
echo.
net user
echo.
set /p USUARIO=Digite exatamente o nome do usuario:

net user "%USUARIO%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo Usuario nao encontrado.
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
echo SE A CONTA ESTIVER COM CONTA MICROSOFT VINCULADA NAO EXECUTAR.
echo ==========================================

choice /c SN /m "Aplicar bloqueio nesta conta"
if errorlevel 2 (
    echo Operacao cancelada.
    exit /b
)


net user "%USUARIO%" /passwordchg:no
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableChangePassword /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowDomainPINLogon /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v UseDefaultTile /t REG_DWORD /d 1 /f
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f
reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f


:: ==========================================
:: 5 - DESATIVAR OFFLINE FILES + ONEDRIVE + BACKUP OPTIONS
:: ==========================================
echo.
echo Executando script de bloqueio de arquivos offline...
echo.
timeout /t 2 >nul
taskkill /f /im OneDrive.exe 2>nul

set ONEDRIVE32=%SystemRoot%\System32\OneDriveSetup.exe
set ONEDRIVE64=%SystemRoot%\SysWOW64\OneDriveSetup.exe

if exist "%ONEDRIVE32%" (
    "%ONEDRIVE32%" /uninstall
) else if exist "%ONEDRIVE64%" (
    "%ONEDRIVE64%" /uninstall
) else (
    echo OneDrive nao encontrado, pulando...
)

reg add "HKLM\SYSTEM\CurrentControlSet\Services\CSC" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\CscService" /v "Start" /t REG_DWORD /d 4 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup\Client" /v DisableBackupUI /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Backup\Client" /v DisableBackupLauncher /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v KFMBlockOptIn /t REG_DWORD /d 1 /f

:: ==========================================
:: FIM
:: ==========================================
echo.
echo Todos os scripts aplicados com sucesso.
echo Reinicie a maquina para aplicar as alteracoes.
echo.

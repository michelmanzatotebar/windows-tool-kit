@echo off

:: Verifica se está sendo executado como Administrador

:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

echo.
echo ==========================================
echo Usuarios locais encontrados:
echo ==========================================
echo VERIFIQUE O USER LOCAL NA PASTA USUARIOS DA MAQUINA ANTES DE RODAR O SCRIPT
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
echo SE A CONTA ESTIVER COM CONTA MICROSOFT VINCULADA EM VEZ DE USER LOCAL NAO EXECUTAR O SCRIPT.
echo ==========================================

choice /c SN /m "Aplicar bloqueio nesta conta"

if errorlevel 2 (
    echo.
    echo Operacao cancelada.
    pause
    exit /b
)


:: Impede alterar a propria senha
net user "%USUARIO%" /passwordchg:no

:: Bloqueio leve de conta Microsoft
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v NoConnectedUser /t REG_DWORD /d 3 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v NoConnectedUser /t REG_DWORD /d 3 /f

:: Bloqueia alterar senha pelo Windows
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableChangePassword /t REG_DWORD /d 1 /f

:: Bloqueia PIN / Windows Hello
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowDomainPINLogon /t REG_DWORD /d 0 /f

:: Força foto padrão da conta
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v UseDefaultTile /t REG_DWORD /d 1 /f

:: Fecha OneDrive
taskkill /f /im OneDrive.exe >nul 2>&1

:: Bloqueia OneDrive
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f

:: Remove OneDrive do Explorer
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f

reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f

echo.
echo Bloqueios aplicados com sucesso.
echo O usuario precisa desconectar para aplicar as alteracoes.
pause
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
    echo.
    echo Operacao cancelada.
    pause
    exit /b
)

:: Reativa a conta caso esteja desativada
net user "%USUARIO%" /active:yes

:: Permite alterar senha novamente
net user "%USUARIO%" /passwordchg:yes

:: Remove bloqueio de conta Microsoft
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v NoConnectedUser /f

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v NoConnectedUser /f

:: Remove bloqueio de alterar senha
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableChangePassword /f

:: Reabilita PIN / Windows Hello
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowDomainPINLogon /f

:: Permite foto personalizada
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v UseDefaultTile /f

:: Reabilita OneDrive
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v DisableFileSyncNGSC /f

:: Reexibe OneDrive no Explorer
reg add "HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 1 /f

reg add "HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 1 /f

echo.
echo Bloqueios removidos com sucesso.
echo O usuario precisa desconectar para aplicar as alteracoes.
pause
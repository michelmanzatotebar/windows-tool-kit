@echo off
setlocal
title Desbloquear rede Wi-Fi

:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

echo.
set /p "SSID=Digite o nome exato da rede Wi-Fi que deseja desbloquear: "
if not defined SSID (
    echo Nenhum nome informado. Operacao cancelada.

    exit /b 1
)

echo.
echo Removendo o bloqueio da rede "%SSID%"...
netsh wlan delete filter permission=block ssid="%SSID%" networktype=infrastructure
if errorlevel 1 (
    echo Nao foi possivel remover o bloqueio. Verifique o nome e tente novamente.

    exit /b 1
)

echo Bloqueio removido para "%SSID%".

exit /b 0

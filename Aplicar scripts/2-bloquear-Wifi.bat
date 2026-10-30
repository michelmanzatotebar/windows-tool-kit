@echo off
setlocal
title Bloquear rede Wi-Fi

net session >nul 2>&1
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

echo.
set /p "SSID=Digite o nome exato da rede Wi-Fi que deseja bloquear: "
if not defined SSID (
    echo Nenhum nome informado. Operacao cancelada.

    exit /b 1
)

echo.
echo Bloqueando a rede "%SSID%"...
netsh wlan add filter permission=block ssid="%SSID%" networktype=infrastructure
if errorlevel 1 (
    echo Nao foi possivel adicionar o bloqueio. Verifique o nome e tente novamente.

    exit /b 1
)

echo Bloqueio aplicado para "%SSID%".

exit /b 0

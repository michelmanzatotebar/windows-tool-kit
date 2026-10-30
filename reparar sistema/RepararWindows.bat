@echo off
title Reparacao do Windows



:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

echo ========================================
echo      REPARACAO DO WINDOWS
echo ========================================
echo.

echo Verificando processos anteriores...
echo.

:: Encerra processos do DISM caso estejam presos
taskkill /F /IM dism.exe >nul 2>&1

:: Encerra processos do SFC caso estejam presos
taskkill /F /IM sfc.exe >nul 2>&1

echo Verificacao concluida.
echo.
echo O processo iniciara em 3 segundos...
timeout /t 3 /nobreak >nul

echo.
echo [1/4] DISM - CheckHealth
echo ----------------------------------------
DISM /Online /Cleanup-Image /CheckHealth

echo.
echo CheckHealth finalizado.
echo.


echo.
echo [2/4] DISM - ScanHealth
echo ----------------------------------------
DISM /Online /Cleanup-Image /ScanHealth

echo.
echo ScanHealth finalizado.
echo.


echo.
echo [3/4] DISM - RestoreHealth
echo ----------------------------------------
DISM /Online /Cleanup-Image /RestoreHealth

echo.
echo RestoreHealth finalizado.
echo.


echo.
echo [4/4] SFC - Scannow
echo ----------------------------------------
sfc /scannow

echo.
echo SFC finalizado.
echo.
echo ========================================
echo       PROCESSO FINALIZADO
echo ========================================
echo.
echo Recomenda-se reiniciar o computador.
echo.
exit /b

@echo off
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)
cd /d "%~dp0"
echo Pasta do bat: %~dp0
echo.

if not exist "%~dp0LimparLixeira.ps1" (
    echo ARQUIVO NAO ENCONTRADO. Conteudo da pasta:
    dir "%~dp0"
    pause
    exit /b
)

echo Arquivo encontrado, executando...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0LimparLixeira.ps1"
echo.
echo Codigo de saida do PowerShell: %errorlevel%
pause
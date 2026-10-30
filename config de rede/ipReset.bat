@echo off
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

ipconfig /flushdns
ipconfig /release
ipconfig /renew
nbtstat -R
nbtstat -RR
netsh int ip reset
netsh winsock reset

echo O usuario precisa reiniciar a maquina para aplicar as alteracoes.

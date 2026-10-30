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

:: Desbloqueia papel de parede
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /f

:: Desbloqueia abas de personalização
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoThemesTab /f

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispBackgroundPage /f

reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispAppearancePage /f

:: Reexibe páginas de Personalização e Contas
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v SettingsPageVisibility /f

:: Restaura opção Personalizar
reg delete "HKCR\DesktopBackground\Shell\Personalize" /v LegacyDisable /f

:: Fecha Configurações
taskkill /f /im SystemSettings.exe >nul 2>&1


echo O usuario precisa desconectar para aplicar as alteracoes.

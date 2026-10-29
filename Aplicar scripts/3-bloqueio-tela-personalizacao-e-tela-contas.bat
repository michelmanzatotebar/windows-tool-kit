@echo off

:: Verifica se está sendo executado como Administrador
net session >nul 2>&1
:: Verifica se está executando como Administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando privilegios administrativos...

    powershell -Command ^
    "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

:: Bloqueia troca de papel de parede
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /v NoChangingWallPaper /t REG_DWORD /d 1 /f

:: Bloqueia abas clássicas de personalização
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoThemesTab /t REG_DWORD /d 1 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispBackgroundPage /t REG_DWORD /d 1 /f

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDispAppearancePage /t REG_DWORD /d 1 /f

:: Oculta páginas de Personalização e Contas
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" ^
/v SettingsPageVisibility ^
/t REG_SZ ^
/d "hide:account;yourinfo;emailandaccounts;signinoptions;workplace;family-group;personalization;personalization-background;personalization-colors;themes;lockscreen" ^
/f

:: Remove opção Personalizar do botão direito
reg add "HKCR\DesktopBackground\Shell\Personalize" /v LegacyDisable /t REG_SZ /d "" /f

:: Fecha Configurações
taskkill /f /im SystemSettings.exe >nul 2>&1

:: Faz logoff para aplicar tudo
echo O usuario precisa desconectado para aplicar as alteracoes.
pause
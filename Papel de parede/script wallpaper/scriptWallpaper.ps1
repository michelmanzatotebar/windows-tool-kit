$ErrorActionPreference = 'Stop'
$utf8Encoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $utf8Encoding
$OutputEncoding = $utf8Encoding

$isAdmin = ([Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ''
    Write-Host 'ERRO: execute este script como Administrador.' -ForegroundColor Red
    Read-Host 'Pressione Enter para sair' | Out-Null
    exit 1
}

$wallpaperFolder = $PSScriptRoot
$supportedExtensions = @('.jpg', '.jpeg', '.png', '.bmp')
$images = @(
    Get-ChildItem -LiteralPath $wallpaperFolder -File |
        Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object Name
)

if ($images.Count -eq 0) {
    Write-Host ''
    Write-Host "Nenhuma imagem encontrada em: $wallpaperFolder" -ForegroundColor Yellow
    Write-Host 'Adicione um arquivo JPG, JPEG, PNG ou BMP a essa pasta e tente novamente.'
    Read-Host 'Pressione Enter para sair' | Out-Null
    exit 1
}

Write-Host ''
Write-Host '  SELECIONAR PAPEL DE PAREDE' -ForegroundColor Cyan
Write-Host '  ==========================='
for ($index = 0; $index -lt $images.Count; $index++) {
    Write-Host ('  {0} - {1}' -f ($index + 1), $images[$index].Name)
}
Write-Host '  0 - Cancelar'
Write-Host ''

$selection = Read-Host 'Digite o numero da imagem'
if ($selection -notmatch '^\d+$' -or [int]$selection -eq 0 -or [int]$selection -gt $images.Count) {
    Write-Host 'Selecao invalida ou cancelada. Nenhuma alteracao foi feita.' -ForegroundColor Yellow
    Read-Host 'Pressione Enter para sair' | Out-Null
    exit 1
}

$colors = @(
    [pscustomobject]@{ Name = 'Preto';   Hex = '000000' },
    [pscustomobject]@{ Name = 'Branco';  Hex = 'FFFFFF' },
    [pscustomobject]@{ Name = 'Vermelho'; Hex = 'FF0000' },
    [pscustomobject]@{ Name = 'Azul';    Hex = '0078D7' },
    [pscustomobject]@{ Name = 'Amarelo'; Hex = 'FFFF00' },
    [pscustomobject]@{ Name = 'Verde';   Hex = '00B050' },
    [pscustomobject]@{ Name = 'Roxo';    Hex = '7030A0' }
)

Write-Host ''
Write-Host '  COR DE DESTAQUE DO TEMA' -ForegroundColor Cyan
Write-Host '  ======================='
for ($index = 0; $index -lt $colors.Count; $index++) {
    Write-Host ('  {0} - {1}' -f ($index + 1), $colors[$index].Name)
}
Write-Host '  0 - Cancelar'
Write-Host ''

$colorSelection = Read-Host 'Digite o numero da cor'
if ($colorSelection -notmatch '^\d+$' -or [int]$colorSelection -eq 0 -or [int]$colorSelection -gt $colors.Count) {
    Write-Host 'Selecao invalida ou cancelada. Nenhuma alteracao foi feita.' -ForegroundColor Yellow
    Read-Host 'Pressione Enter para sair' | Out-Null
    exit 1
}

$image = $images[[int]$selection - 1]
$color = $colors[[int]$colorSelection - 1]
$destinationFolder = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Themes\Wallpapers'
New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
$destination = Join-Path $destinationFolder $image.Name
Copy-Item -LiteralPath $image.FullName -Destination $destination -Force

$themeFolder = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Themes'
New-Item -ItemType Directory -Path $themeFolder -Force | Out-Null
$themeBaseName = '{0} - {1}' -f $image.BaseName, $color.Name
$themePath = Join-Path $themeFolder ($themeBaseName + '.theme')
$colorizationColor = '0xC4' + $color.Hex

$themeContent = @"
[Theme]
DisplayName=$themeBaseName

[Control Panel\Desktop]
Wallpaper=$destination
TileWallpaper=0
WallpaperStyle=10
Pattern=

[VisualStyles]
Path=%SystemRoot%\resources\Themes\Aero\Aero.msstyles
ColorStyle=NormalColor
Size=NormalSize
ColorizationColor=$colorizationColor
Transparency=1
AutoColorization=0
SystemMode=Dark
AppMode=Dark

[MasterThemeSelector]
MTSM=DABJDKT
"@

Set-Content -LiteralPath $themePath -Value $themeContent.Trim() -Encoding Unicode

# Abrir o arquivo .theme aplica o tema e mantem o papel de parede associado a ele.
Start-Process -FilePath $themePath
Start-Sleep -Seconds 3

# Reaplica as preferencias apos o Windows carregar o tema.
$personalizePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
New-Item -Path $personalizePath -Force | Out-Null
Set-ItemProperty -Path $personalizePath -Name 'AppsUseLightTheme' -Value 0 -Type DWord
Set-ItemProperty -Path $personalizePath -Name 'SystemUsesLightTheme' -Value 0 -Type DWord
# Mantem a barra Iniciar/tarefa neutra; a cor escolhida fica nos detalhes das janelas.
Set-ItemProperty -Path $personalizePath -Name 'ColorPrevalence' -Value 0 -Type DWord

$desktopPath = 'HKCU:\Control Panel\Desktop'
Set-ItemProperty -Path $desktopPath -Name 'AutoColorization' -Value 0 -Type DWord

$dwmPath = 'HKCU:\Software\Microsoft\Windows\DWM'
New-Item -Path $dwmPath -Force | Out-Null
$colorValue = [Convert]::ToUInt32($colorizationColor.Substring(2), 16)
Set-ItemProperty -Path $dwmPath -Name 'ColorizationColor' -Value $colorValue -Type DWord
Set-ItemProperty -Path $dwmPath -Name 'ColorPrevalence' -Value 1 -Type DWord

# Notifica o Windows para atualizar o modo de cor nas janelas abertas.
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class ThemeSettingsRefresh {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint message, UIntPtr wParam, string lParam,
        uint flags, uint timeout, out UIntPtr result);
}
'@
$messageResult = [UIntPtr]::Zero
[void][ThemeSettingsRefresh]::SendMessageTimeout(
    [IntPtr]0xffff, 0x001A, [UIntPtr]::Zero, 'ImmersiveColorSet',
    0x0002, 5000, [ref]$messageResult
)

Write-Host ''
Write-Host 'Tema criado e aplicado.' -ForegroundColor Green
Write-Host "Imagem: $($image.Name)"
Write-Host "Cor: $($color.Name)"
Write-Host "Arquivo do tema: $themePath"
Read-Host 'Pressione Enter para fechar' | Out-Null

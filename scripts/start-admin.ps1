$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$electronExecutable = Join-Path $projectRoot 'node_modules\electron\dist\electron.exe'

if (-not (Test-Path -LiteralPath $electronExecutable)) {
    Write-Error 'Electron nao encontrado. Execute npm.cmd install na pasta do projeto.'
    exit 1
}

$principal = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
$isAdministrator = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdministrator) {
    Start-Process -FilePath $electronExecutable -ArgumentList '.' -WorkingDirectory $projectRoot -Verb RunAs
    exit 0
}

Set-Location -LiteralPath $projectRoot
& $electronExecutable '.'
exit $LASTEXITCODE

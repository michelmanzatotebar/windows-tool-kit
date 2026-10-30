$ErrorActionPreference = 'Stop'
$utf8Encoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = $utf8Encoding
$OutputEncoding = $utf8Encoding

function Format-Size([long]$Bytes) {
    if ($Bytes -lt 1KB) { return ('{0} bytes' -f $Bytes) }
    if ($Bytes -lt 1MB) { return ('{0:N2} KB' -f ($Bytes / 1KB)) }
    if ($Bytes -lt 1GB) { return ('{0:N2} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -lt 1TB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    return ('{0:N2} TB' -f ($Bytes / 1TB))
}

function Get-FolderInventory([string]$Root) {
    $pending = [System.Collections.Generic.Stack[string]]::new()
    $files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $directories = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
    $scanIssues = 0
    $pending.Push($Root)

    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        try {
            $children = @(Get-ChildItem -LiteralPath $current -Force -ErrorAction Stop)
        } catch {
            $scanIssues++
            continue
        }

        foreach ($child in $children) {
            if (($child.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                continue
            }

            if ($child.PSIsContainer) {
                $directories.Add([System.IO.DirectoryInfo]$child)
                $pending.Push($child.FullName)
            } else {
                $files.Add([System.IO.FileInfo]$child)
            }
        }
    }

    [pscustomobject]@{
        Files = $files.ToArray()
        Directories = $directories.ToArray()
        ScanIssues = $scanIssues
    }
}

$folderDefinitions = @(
    [pscustomobject]@{ Id = '1'; Name = 'Temp do Windows'; Path = (Join-Path $env:SystemRoot 'Temp') },
    [pscustomobject]@{ Id = '2'; Name = '%TEMP% do usuario'; Path = $env:TEMP },
    [pscustomobject]@{ Id = '3'; Name = 'Prefetch'; Path = (Join-Path $env:SystemRoot 'Prefetch') }
)

# Evita apresentar duas vezes a mesma pasta caso as variaveis do Windows coincidam.
$seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$folders = @(
    foreach ($definition in $folderDefinitions) {
        if ([string]::IsNullOrWhiteSpace($definition.Path)) { continue }
        try {
            $fullPath = [System.IO.Path]::GetFullPath($definition.Path)
        } catch {
            continue
        }
        if ($seenPaths.Add($fullPath)) {
            [pscustomobject]@{
                Id = $definition.Id
                Name = $definition.Name
                Path = $fullPath
                Exists = (Test-Path -LiteralPath $fullPath -PathType Container)
                Inventory = $null
                Bytes = [long]0
            }
        }
    }
)

Write-Host ''
Write-Host '  LIMPEZA DE ARQUIVOS TEMPORARIOS' -ForegroundColor Cyan
Write-Host '  ==============================='
Write-Host 'Estimativa do conteudo encontrado:'

foreach ($folder in $folders) {
    if (-not $folder.Exists) {
        Write-Host ('  {0}: pasta nao encontrada ({1})' -f $folder.Name, $folder.Path) -ForegroundColor Yellow
        continue
    }

    $folder.Inventory = Get-FolderInventory -Root $folder.Path
    foreach ($file in $folder.Inventory.Files) {
        try { $folder.Bytes += $file.Length } catch { }
    }

    Write-Host ('  {0}: {1}' -f $folder.Name, (Format-Size $folder.Bytes))
    if ($folder.Inventory.ScanIssues -gt 0) {
        Write-Host '    Algumas subpastas nao puderam ser lidas; o total pode ser menor.' -ForegroundColor Yellow
    }
}

Write-Host ''
$menuLines = [System.Collections.Generic.List[string]]::new()
$menuLines.Add('Escolha o que deseja limpar:')
foreach ($folder in $folders) {
    $menuLines.Add(('  {0} - {1}' -f $folder.Id, $folder.Name))
}
$allOption = '4'
$menuLines.Add(('  {0} - Limpar todas as pastas' -f $allOption))
$menuLines.Add('  0 - Cancelar')
Write-Host ($menuLines -join [Environment]::NewLine)
Write-Host ''

$selection = Read-Host 'Digite uma opcao'
if ($selection -eq '0') {
    Write-Host 'Limpeza cancelada.' -ForegroundColor Yellow
    exit 0
}

if ($selection -eq $allOption) {
    $selectedFolders = @($folders)
} else {
    $selectedFolders = @($folders | Where-Object { $_.Id -eq $selection })
}

if ($selectedFolders.Count -eq 0) {
    Write-Host 'Opcao invalida. Nenhuma alteracao foi feita.' -ForegroundColor Yellow
    exit 0
}

$selectedSize = [long]0
foreach ($folder in $selectedFolders) { $selectedSize += $folder.Bytes }
Write-Host ''
Write-Host ('Tamanho estimado selecionado: {0}' -f (Format-Size $selectedSize))
Write-Host 'Iniciando a limpeza escolhida...' -ForegroundColor Cyan

$removedFiles = 0
$skippedFiles = 0
$removedDirectories = 0
$retainedDirectories = 0

foreach ($folder in $selectedFolders) {
    Write-Host ''
    Write-Host ('Limpando {0}...' -f $folder.Name) -ForegroundColor Cyan
    if (-not $folder.Exists) {
        Write-Host 'Pasta nao encontrada; ignorada.' -ForegroundColor Yellow
        continue
    }

    $inventory = $folder.Inventory
    foreach ($file in $inventory.Files) {
        try {
            Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
            $removedFiles++
        } catch {
            # Arquivos em uso, protegidos ou que desapareceram durante a limpeza sao ignorados.
            $skippedFiles++
        }
    }

    foreach ($directory in ($inventory.Directories | Sort-Object { $_.FullName.Length } -Descending)) {
        try {
            Remove-Item -LiteralPath $directory.FullName -Force -ErrorAction Stop
            $removedDirectories++
        } catch {
            # Diretorios com algum conteudo ainda presente sao mantidos sem interromper a rotina.
            $retainedDirectories++
        }
    }

    if ($inventory.ScanIssues -gt 0) {
        Write-Host 'Algumas subpastas protegidas ou inacessiveis foram ignoradas.' -ForegroundColor Yellow
    }
}

Write-Host ''
Write-Host 'Limpeza concluida.' -ForegroundColor Green
Write-Host ("Arquivos removidos: {0}" -f $removedFiles)
Write-Host ("Arquivos ignorados (em uso, protegidos ou indisponiveis): {0}" -f $skippedFiles)
Write-Host ("Pastas vazias removidas: {0}" -f $removedDirectories)
Write-Host ("Pastas mantidas por ainda conterem itens: {0}" -f $retainedDirectories)
exit 0

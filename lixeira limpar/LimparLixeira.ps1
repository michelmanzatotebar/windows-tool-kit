# Lista o tamanho da lixeira por usuario (em paralelo) e pergunta se deseja limpar
# Precisa rodar como Administrador

$maxThreads = 8   # ajuste conforme a maquina

function Formatar($bytes) {
    if ($bytes -ge 1GB) { return "{0:N2} GB" -f ($bytes / 1GB) }
    if ($bytes -ge 1MB) { return "{0:N2} MB" -f ($bytes / 1MB) }
    if ($bytes -ge 1KB) { return "{0:N2} KB" -f ($bytes / 1KB) }
    return "$bytes bytes"
}

# Bloco que roda dentro de cada thread: mede o tamanho da pasta
$blocoMedir = {
    param($item)
    $soma = (Get-ChildItem -LiteralPath $item.Path -Recurse -Force -File -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum).Sum
    if ($null -eq $soma) { $soma = 0 }
    [pscustomobject]@{ Sid = $item.Sid; Path = $item.Path; Bytes = [int64]$soma; Erro = $null }
}

# Bloco que roda dentro de cada thread: limpa a pasta e mede o que sobrou
$blocoLimpar = {
    param($item)
    $erro = $null
    try {
        Get-ChildItem -LiteralPath $item.Path -Force -ErrorAction Stop |
            Remove-Item -Recurse -Force -ErrorAction Stop
    } catch {
        $erro = $_.Exception.Message
    }
    $soma = (Get-ChildItem -LiteralPath $item.Path -Recurse -Force -File -ErrorAction SilentlyContinue |
             Measure-Object -Property Length -Sum).Sum
    if ($null -eq $soma) { $soma = 0 }
    [pscustomobject]@{ Sid = $item.Sid; Path = $item.Path; Bytes = [int64]$soma; Erro = $erro }
}

function Invoke-Paralelo($itens, $bloco, $max) {
    $pool = [runspacefactory]::CreateRunspacePool(1, $max)
    $pool.Open()
    $jobs = foreach ($i in $itens) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $pool
        [void]$ps.AddScript($bloco).AddArgument($i)
        [pscustomobject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
    }
    foreach ($j in $jobs) {
        $j.PS.EndInvoke($j.Handle)
        $j.PS.Dispose()
    }
    $pool.Close()
    $pool.Dispose()
}

$discos = (Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3").DeviceID

# Perfis existentes (SID -> nome da pasta)
$mapa = @{}
Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } |
    ForEach-Object { $mapa[$_.SID] = Split-Path $_.LocalPath -Leaf }

# Junta SIDs dos perfis + SIDs que existem nas lixeiras
$sids = New-Object System.Collections.Generic.HashSet[string]
foreach ($s in $mapa.Keys) { [void]$sids.Add($s) }
foreach ($d in $discos) {
    Get-ChildItem -LiteralPath (Join-Path $d '$Recycle.Bin') -Force -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { [void]$sids.Add($_.Name) }
}

# Monta lista de tarefas (SID + pasta existente)
$tarefas = foreach ($sid in $sids) {
    foreach ($d in $discos) {
        $p = Join-Path $d "`$Recycle.Bin\$sid"
        if (Test-Path -LiteralPath $p) {
            [pscustomobject]@{ Sid = $sid; Path = $p }
        }
    }
}

Write-Host "Analisando lixeiras em paralelo ($maxThreads threads), aguarde..."
Write-Host ""

$medidas = @(Invoke-Paralelo $tarefas $blocoMedir $maxThreads)

# Agrupa por usuario
$resultado = foreach ($sid in $sids) {
    if ($mapa.ContainsKey($sid)) {
        $nome = $mapa[$sid]
    } else {
        try {
            $nome = ([System.Security.Principal.SecurityIdentifier]$sid).Translate([System.Security.Principal.NTAccount]).Value
        } catch {
            $nome = "(sem perfil) $sid"
        }
    }
    $minhas = @($medidas | Where-Object { $_.Sid -eq $sid })
    $bytes = 0
    foreach ($m in $minhas) { $bytes += $m.Bytes }
    [pscustomobject]@{ Nome = $nome; Bytes = $bytes }
}

$resultado = $resultado | Sort-Object Bytes -Descending
$total = 0

foreach ($r in $resultado) {
    Write-Host ("usuario {0,-45} {1,12}" -f $r.Nome, (Formatar $r.Bytes))
    $total += $r.Bytes
}

Write-Host ""
Write-Host "TOTAL: $(Formatar $total)"
Write-Host ""

if ($total -eq 0) {
    Write-Host "Nada para limpar."
    exit
}

Write-Host "Deseja limpar ou cancelar? (L = limpar / C = cancelar)" -ForegroundColor Yellow
$resp = Read-Host "Digite L ou C"

if ($resp -notin @('L','l')) {
    Write-Host "Cancelado. Nada foi apagado."
    exit
}

Write-Host ""
Write-Host "Limpando em paralelo ($maxThreads threads)..."

$limpeza = @(Invoke-Paralelo $tarefas $blocoLimpar $maxThreads)

$restante = 0
foreach ($l in $limpeza) {
    $restante += $l.Bytes
    if ($l.Erro) { Write-Host "ERRO em $($l.Path): $($l.Erro)" }
}

Write-Host ""
Write-Host "TOTAL LIBERADO: $(Formatar ($total - $restante))"

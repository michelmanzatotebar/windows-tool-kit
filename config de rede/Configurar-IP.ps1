$ErrorActionPreference = 'Stop'

function Read-IPv4Address {
    param([string]$Prompt, [switch]$Optional)

    while ($true) {
        Write-Host $Prompt
        $value = (Read-Host).Trim()
        if ($Optional -and [string]::IsNullOrWhiteSpace($value)) { return $null }

        $parsed = $null
        if ([System.Net.IPAddress]::TryParse($value, [ref]$parsed) -and
            $parsed.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            return $parsed.ToString()
        }
        Write-Host 'Endereço IPv4 inválido. Tente novamente.' -ForegroundColor Yellow
    }
}

function Convert-MaskToPrefixLength {
    param([string]$Mask)

    $parsed = $null
    if (-not [System.Net.IPAddress]::TryParse($Mask, [ref]$parsed) -or
        $parsed.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) {
        throw 'Máscara de sub-rede inválida.'
    }

    $bits = [Convert]::ToString([BitConverter]::ToUInt32($parsed.GetAddressBytes()[3..0], 0), 2).PadLeft(32, '0')
    if ($bits -notmatch '^1*0*$' -or $bits -eq ('0' * 32)) { throw 'A máscara precisa ser contínua e diferente de 0.0.0.0.' }
    return ([regex]::Match($bits, '1*').Length)
}

function Get-SelectedAdapter {
    $adapters = @(Get-NetAdapter | Sort-Object ifIndex)
    if ($adapters.Count -eq 0) {
        Write-Host 'Nenhum adaptador de rede foi encontrado.' -ForegroundColor Yellow
        return $null
    }

    Write-Host "`nAdaptadores disponíveis:"
    for ($i = 0; $i -lt $adapters.Count; $i++) {
        $adapter = $adapters[$i]
        Write-Host ("{0}. {1} | {2} | {3} | índice {4}" -f ($i + 1), $adapter.Name, $adapter.InterfaceDescription, $adapter.Status, $adapter.ifIndex)
    }

    while ($true) {
        Write-Host 'Digite o número do adaptador ou 0 para voltar ao menu.'
        $choice = (Read-Host).Trim()
        if ($choice -eq '0') { return $null }
        $number = 0
        if ([int]::TryParse($choice, [ref]$number) -and $number -ge 1 -and $number -le $adapters.Count) {
            return $adapters[$number - 1]
        }
        Write-Host 'Opção inválida.' -ForegroundColor Yellow
    }
}

function Remove-IPv4Configuration {
    param([int]$InterfaceIndex, [switch]$IncludeDhcpAddresses)

    Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.PrefixOrigin -eq 'Manual' -or ($IncludeDhcpAddresses -and $_.IPAddress -notlike '127.*') } |
        Remove-NetIPAddress -Confirm:$false -ErrorAction Stop

    Get-NetRoute -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
        Remove-NetRoute -Confirm:$false -ErrorAction Stop
}

function Set-AdapterDhcp {
    param([int]$InterfaceIndex, [ValidateSet('IP', 'DNS', 'Ambos')][string]$Mode)

    if ($Mode -in @('IP', 'Ambos')) {
        Remove-IPv4Configuration -InterfaceIndex $InterfaceIndex
        Set-NetIPInterface -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -Dhcp Enabled -ErrorAction Stop
    }
    if ($Mode -in @('DNS', 'Ambos')) {
        Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ResetServerAddresses -ErrorAction Stop
    }
}

while ($true) {
    Write-Host "`n=== Configuração global do adaptador ===" -ForegroundColor Cyan
    Write-Host '1. Definir IP fixo'
    Write-Host '2. DHCP para o IP'
    Write-Host '3. DHCP para o DNS'
    Write-Host '4. DHCP para IP e DNS'
    Write-Host '0. Sair'
    Write-Host 'Escolha uma opção:'
    $option = (Read-Host).Trim()
    if ($option -eq '0') { break }
    if ($option -notin @('1', '2', '3', '4')) {
        Write-Host 'Opção inválida.' -ForegroundColor Yellow
        continue
    }

    $adapter = Get-SelectedAdapter
    if ($null -eq $adapter) { continue }
    $index = [int]$adapter.ifIndex
    Write-Host ("Adaptador selecionado: {0} (índice {1})" -f $adapter.Name, $index)

    if ($option -eq '1') {
        $ip = Read-IPv4Address 'Digite o endereço IPv4 fixo:'
        while ($true) {
            Write-Host 'Digite a máscara de sub-rede (ex.: 255.255.255.0):'
            $mask = (Read-Host).Trim()
            try { $prefix = Convert-MaskToPrefixLength $mask; break }
            catch { Write-Host $_.Exception.Message -ForegroundColor Yellow }
        }
        $gateway = Read-IPv4Address 'Digite o gateway padrão:'
        $dnsPrimary = Read-IPv4Address 'Digite o DNS preferencial:'
        $dnsSecondary = Read-IPv4Address 'Digite o DNS alternativo (ou deixe vazio para nenhum):' -Optional
        $dnsServers = @($dnsPrimary)
        if ($dnsSecondary) { $dnsServers += $dnsSecondary }

        Write-Host "`nConfira as configurações:"
        Write-Host ("Adaptador: {0}" -f $adapter.Name)
        Write-Host ("IP: {0}" -f $ip)
        Write-Host ("Máscara: {0} (/{1})" -f $mask, $prefix)
        Write-Host ("Gateway: {0}" -f $gateway)
        Write-Host ("DNS: {0}" -f ($dnsServers -join ', '))
        Write-Host 'Aplicar estas configurações? Digite S para confirmar ou N para cancelar:'
        $confirm = (Read-Host).Trim()
        if ($confirm -notmatch '^(s|sim)$') {
            Write-Host 'Operação cancelada; nenhuma alteração foi aplicada.' -ForegroundColor Yellow
            continue
        }

        try {
            Set-NetIPInterface -InterfaceIndex $index -AddressFamily IPv4 -Dhcp Disabled -ErrorAction Stop
            Remove-IPv4Configuration -InterfaceIndex $index -IncludeDhcpAddresses
            New-NetIPAddress -InterfaceIndex $index -AddressFamily IPv4 -IPAddress $ip -PrefixLength $prefix -DefaultGateway $gateway -ErrorAction Stop | Out-Null
            Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $dnsServers -ErrorAction Stop
            Write-Host 'Configuração fixa aplicada ao adaptador.' -ForegroundColor Green
        } catch {
            Write-Host ("Falha ao aplicar a configuração: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
        continue
    }

    $mode = @{ '2' = 'IP'; '3' = 'DNS'; '4' = 'Ambos' }[$option]
    $description = @{ 'IP' = 'DHCP para o IP'; 'DNS' = 'DHCP para o DNS'; 'Ambos' = 'DHCP para IP e DNS' }[$mode]
    Write-Host ("Ação: {0}" -f $description)
    Write-Host 'Confirma a alteração neste adaptador? Digite S para confirmar ou N para cancelar:'
    $confirm = (Read-Host).Trim()
    if ($confirm -notmatch '^(s|sim)$') {
        Write-Host 'Operação cancelada; nenhuma alteração foi aplicada.' -ForegroundColor Yellow
        continue
    }

    try {
        Set-AdapterDhcp -InterfaceIndex $index -Mode $mode
        Write-Host ("{0} aplicado ao adaptador {1}." -f $description, $adapter.Name) -ForegroundColor Green
    } catch {
        Write-Host ("Falha ao alterar o adaptador: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host 'Ferramenta encerrada.'

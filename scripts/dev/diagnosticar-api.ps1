<#
.SYNOPSIS
Diagnostica a conexao entre o app e a API AusterAgX.

.DESCRIPTION
Confere, em ordem, se a API responde, se o login funciona, se existe massa de
teste e quais dispositivos Android o adb enxerga. Para na primeira falha e diz
o que fazer.

.EXAMPLE
.\scripts\dev\diagnosticar-api.ps1
#>
[CmdletBinding()]
param(
    [int] $ApiPort = 8080,

    [string] $Email = 'matheus@austertec.com',

    [string] $Senha = '123456',

    [string] $AndroidSdk = 'C:\auster-mobile-tools\android-sdk'
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$base = "http://localhost:$ApiPort"
$adb = Join-Path $AndroidSdk 'platform-tools\adb.exe'

function Etapa([string] $Texto) {
    Write-Host ''
    Write-Host "=== $Texto ===" -ForegroundColor Cyan
}

function Ok([string] $Texto) {
    Write-Host "OK - $Texto" -ForegroundColor Green
}

function Falhar([string] $Texto) {
    Write-Host "FALHOU - $Texto" -ForegroundColor Red
    exit 1
}

function CorpoDoErro($Erro) {
    # PowerShell 7 expoe o corpo em ErrorDetails; o 5.1 exige ler o stream da resposta.
    if ($Erro.ErrorDetails -and $Erro.ErrorDetails.Message) { return $Erro.ErrorDetails.Message }
    try {
        $leitor = New-Object System.IO.StreamReader($Erro.Exception.Response.GetResponseStream())
        return $leitor.ReadToEnd()
    } catch {
        return ''
    }
}

Etapa "1. API em $base"
try {
    $saude = Invoke-RestMethod "$base/actuator/health" -TimeoutSec 5
    Ok "status $($saude.status)"
} catch {
    Falhar "a API nao respondeu: $($_.Exception.Message)`n  Suba o ambiente com .\scripts\dev\subir-ambiente.ps1 ou veja: docker compose logs api"
}

Etapa "2. Login com $Email"
$corpo = @{ email = $Email; senha = $Senha } | ConvertTo-Json
try {
    $inicio = Get-Date
    $sessao = Invoke-RestMethod "$base/auth/login" -Method Post -ContentType 'application/json' -Body $corpo -TimeoutSec 15
    $ms = [int]((Get-Date) - $inicio).TotalMilliseconds
    Ok "perfil $($sessao.perfil), resposta em $ms ms"
} catch {
    $detalhe = CorpoDoErro $_
    Falhar "login recusado: $($_.Exception.Message) $detalhe`n  401 costuma indicar banco sem a massa de teste: veja docker compose logs seed"
}

Etapa '3. Massa de teste'
try {
    $cabecalho = @{ Authorization = "Bearer $($sessao.accessToken)" }
    $pagina = Invoke-RestMethod "$base/dashboard/demandas?pagina=0&tamanho=1" -Headers $cabecalho -TimeoutSec 15
    if ($pagina.totalElementos -gt 0) {
        Ok "$($pagina.totalElementos) demandas visiveis para $Email"
    } else {
        Falhar 'a API respondeu, mas nao ha demandas. Veja: docker compose logs seed'
    }
} catch {
    Falhar "o dashboard falhou: $($_.Exception.Message)"
}

Etapa '4. Dispositivos Android'
if (-not (Test-Path $adb)) {
    Falhar "adb nao encontrado em $adb. Ajuste o parametro -AndroidSdk."
}
$linhas = & $adb devices | Select-Object -Skip 1 | Where-Object { $_.Trim() }
if (-not $linhas) {
    Write-Host '  Nenhum dispositivo conectado ao adb.'
    Write-Host '  Emulador: flutter emulators --launch auster_test'
    Write-Host '  Celular: ative a Depuracao USB e use Transferencia de arquivos no cabo, ou instale o APK sem adb.'
    exit 0
}
foreach ($linha in $linhas) {
    if ($linha -match '^(\S+)\s+(\S+)') {
        $serial = $Matches[1]
        $estado = $Matches[2]
        if ($estado -ne 'device') {
            Write-Host "  $serial : $estado (aceite a depuracao USB na tela do aparelho)" -ForegroundColor Yellow
        } elseif ($serial -like 'emulator-*') {
            Ok "$serial - use API_BASE_URL=http://10.0.2.2:$ApiPort"
        } else {
            Ok "$serial - use API_BASE_URL=http://IP_DO_COMPUTADOR:$ApiPort"
        }
    }
}

$reverso = (& $adb reverse --list 2>$null) -join ' '
if ($reverso -match "tcp:$ApiPort") {
    Write-Host ''
    Write-Host "  Ha um adb reverse ativo na porta $ApiPort. Ele engasga com requisicoes paralelas;" -ForegroundColor Yellow
    Write-Host "  prefira 10.0.2.2 no emulador e remova com: adb reverse --remove-all" -ForegroundColor Yellow
}

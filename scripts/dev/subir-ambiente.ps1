<#
.SYNOPSIS
Sobe o ambiente de desenvolvimento do AusterAgX Mobile.

.DESCRIPTION
1. Sobe banco, API e massa de teste com o docker-compose.yml da raiz.
2. Espera a API ficar pronta e a massa de teste existir.
3. Emulador: sobe o AVD, se preciso, e executa o app com flutter run.
   Celular: gera o APK de debug apontando para o IP Wi-Fi do computador e
   instala pelo cabo quando houver um aparelho conectado.

.EXAMPLE
.\scripts\dev\subir-ambiente.ps1

.EXAMPLE
.\scripts\dev\subir-ambiente.ps1 -Alvo celular
#>
[CmdletBinding()]
param(
    [ValidateSet('emulador', 'celular')]
    [string] $Alvo = 'emulador',

    [string] $Emulador = 'auster_test',

    [string] $IpComputador,

    [int] $ApiPort = 8080,

    [string] $FlutterSdk = 'C:\auster-mobile-tools\flutter',

    [string] $AndroidSdk = 'C:\auster-mobile-tools\android-sdk',

    # Pula o rebuild da imagem da API quando o backend nao mudou.
    [switch] $SemBuild
)

# Continue: comandos nativos (docker, adb, flutter) escrevem progresso no stderr,
# e o Windows PowerShell 5.1 trataria isso como erro fatal. O resultado de cada
# comando e conferido por $LASTEXITCODE.
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$raiz = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$compose = Join-Path $raiz 'docker-compose.yml'
$adb = Join-Path $AndroidSdk 'platform-tools\adb.exe'
$emuladorExe = Join-Path $AndroidSdk 'emulator\emulator.exe'

$env:ANDROID_HOME = $AndroidSdk
$env:PATH = "$FlutterSdk\bin;$AndroidSdk\platform-tools;$AndroidSdk\emulator;$env:PATH"

function Etapa([string] $Texto) {
    Write-Host ''
    Write-Host "=== $Texto ===" -ForegroundColor Cyan
}

function Ok([string] $Texto) {
    Write-Host "OK - $Texto" -ForegroundColor Green
}

function Aviso([string] $Texto) {
    Write-Host "AVISO - $Texto" -ForegroundColor Yellow
}

function Falhar([string] $Texto) {
    Write-Host "FALHOU - $Texto" -ForegroundColor Red
    exit 1
}

function Aguardar([scriptblock] $Condicao, [int] $Segundos, [string] $Descricao) {
    $limite = (Get-Date).AddSeconds($Segundos)
    while ((Get-Date) -lt $limite) {
        if (& $Condicao) { return $true }
        Write-Host "  aguardando $Descricao..."
        Start-Sleep -Seconds 5
    }
    return $false
}

function ApiPronta {
    try {
        $saude = Invoke-RestMethod "http://localhost:$ApiPort/actuator/health" -TimeoutSec 3
        return $saude.status -eq 'UP'
    } catch {
        return $false
    }
}

function TotalDemandas {
    $saida = & docker compose -f $compose exec -T db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT count(*) FROM demanda"' 2>$null
    $texto = "$saida".Trim()
    if ($texto -match '^\d+$') { return [int] $texto }
    return 0
}

function EmuladorOnline {
    return ((& $adb devices) -join "`n") -match 'emulator-\d+\s+device'
}

function CelularConectado {
    foreach ($linha in (& $adb devices)) {
        if ($linha -match '^(\S+)\s+device$' -and $Matches[1] -notlike 'emulator-*') {
            return $Matches[1]
        }
    }
    return $null
}

if ($raiz -match '[^\x00-\x7F]') {
    Aviso 'o caminho do projeto tem caracteres fora do ASCII (ex.: "Area de Trabalho" com acento).'
    Write-Host "  $raiz"
    Write-Host '  O Android Gradle Plugin recusa esse caminho. Mova o projeto (ex.: C:\dev) ou adicione'
    Write-Host "  android.overridePathCheck=true em $env:USERPROFILE\.gradle\gradle.properties."
}

Etapa '1. Banco, API e massa de teste'
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Falhar 'docker nao encontrado. Instale ou abra o Docker Desktop.'
}
& docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Falhar 'o Docker nao esta respondendo. Abra o Docker Desktop e aguarde ele iniciar.'
}

$argumentos = @('compose', '-f', $compose, 'up', '-d')
if (-not $SemBuild) { $argumentos += '--build' }
& docker @argumentos
if ($LASTEXITCODE -ne 0) {
    Falhar 'docker compose up falhou. Confira AUSTERAGX_BACKEND_DIR no .env e a saida acima.'
}

if (-not (Aguardar { ApiPronta } 300 'a API aplicar as migrations e subir')) {
    Falhar 'a API nao respondeu. Veja: docker compose logs api'
}
Ok "API pronta em http://localhost:$ApiPort"

if (-not (Aguardar { (TotalDemandas) -gt 0 } 120 'a massa de teste')) {
    Falhar 'o banco continua sem demandas. Veja: docker compose logs seed'
}
Ok "$(TotalDemandas) demandas no banco"

if (-not (Test-Path $adb)) {
    Falhar "adb nao encontrado em $adb. Ajuste o parametro -AndroidSdk."
}

if ($Alvo -eq 'emulador') {
    Etapa '2. Emulador Android'
    if (-not (EmuladorOnline)) {
        if (-not (Test-Path $emuladorExe)) {
            Falhar "emulador nao encontrado em $emuladorExe. Veja a secao de emulador no INSTALACAO.md."
        }
        Write-Host "  subindo o AVD $Emulador..."
        Start-Process -FilePath $emuladorExe -ArgumentList @('-avd', $Emulador)
        if (-not (Aguardar { EmuladorOnline } 180 'o emulador conectar ao adb')) {
            Falhar "o emulador $Emulador nao ficou online. Confira o nome com: flutter emulators"
        }
    }
    $iniciou = Aguardar { ((& $adb shell getprop sys.boot_completed 2>$null) -join '').Trim() -eq '1' } 180 'o Android terminar de iniciar'
    if (-not $iniciou) { Falhar 'o Android do emulador nao terminou de iniciar.' }
    & $adb shell setprop log.tag.EGL_emulation SILENT 2>$null
    Ok 'emulador pronto'

    Etapa '3. App'
    Write-Host '  login: matheus@austertec.com / 123456' -ForegroundColor Yellow
    Set-Location $raiz
    & flutter run "--dart-define=API_BASE_URL=http://10.0.2.2:$ApiPort"
    exit $LASTEXITCODE
}

Etapa '2. Rede para o celular'
if (-not $IpComputador) {
    $IpComputador = Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '169.254.*' } |
        Select-Object -First 1 -ExpandProperty IPAddress
}
if (-not $IpComputador) {
    Falhar 'nenhum IPv4 no adaptador Wi-Fi. Informe o endereco com -IpComputador.'
}
Ok "IP do computador: $IpComputador"

$perfil = Get-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -ErrorAction SilentlyContinue
if ($perfil -and $perfil.NetworkCategory -ne 'Private') {
    Aviso "a rede Wi-Fi esta como $($perfil.NetworkCategory); o firewall vai bloquear o celular."
    Write-Host '  Em um PowerShell como administrador:'
    Write-Host "  Set-NetConnectionProfile -InterfaceAlias 'Wi-Fi' -NetworkCategory Private"
}
$regra = Get-NetFirewallRule -DisplayName "AusterAgX API $ApiPort" -ErrorAction SilentlyContinue
if (-not $regra) {
    Aviso "nao existe regra de firewall liberando a porta $ApiPort."
    Write-Host '  Em um PowerShell como administrador:'
    Write-Host "  New-NetFirewallRule -DisplayName 'AusterAgX API $ApiPort' -Direction Inbound -Protocol TCP -LocalPort $ApiPort -Action Allow -Profile Private"
}
Write-Host "  Antes de instalar, abra no navegador do celular: http://${IpComputador}:$ApiPort/actuator/health"

Etapa '3. APK de debug'
Set-Location $raiz
& flutter build apk --debug --target-platform android-arm64 "--dart-define=API_BASE_URL=http://${IpComputador}:$ApiPort"
if ($LASTEXITCODE -ne 0) { Falhar 'o build do APK falhou. Veja a saida acima.' }
$apk = Join-Path $raiz 'build\app\outputs\flutter-apk\app-debug.apk'
$tamanho = [math]::Round((Get-Item $apk).Length / 1MB, 1)
Ok "APK gerado: $apk ($tamanho MB)"

$serial = CelularConectado
if ($serial) {
    Write-Host "  instalando no aparelho $serial..."
    & $adb -s $serial install -r $apk
    if ($LASTEXITCODE -eq 0) { Ok 'app instalado no celular' } else { Aviso 'a instalacao pelo cabo falhou; envie o APK para o celular.' }
} else {
    Write-Host '  Nenhum celular com depuracao USB conectado: envie o APK para o celular e instale por la.'
}
Write-Host '  login: matheus@austertec.com / 123456' -ForegroundColor Yellow

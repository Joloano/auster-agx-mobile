<#
.SYNOPSIS
Sobe o ambiente de desenvolvimento do AusterAgX Mobile.

.DESCRIPTION
1. Sobe banco, API e massa de teste com o docker-compose.yml da raiz.
2. Espera a API ficar pronta e a massa de teste existir.
3. Emulador: otimiza o AVD para WHPX, GPU do host e teclado fisico, sobe o
   emulador, se preciso, e executa o app com flutter run.
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

    [string] $Emulador = 'Pixel_8',

    [string] $IpComputador,

    [int] $ApiPort = 8080,

    [string] $FlutterSdk = 'C:\auster-mobile-tools\flutter',

    [string] $AndroidSdk = 'C:\auster-mobile-tools\android-sdk',

    # Ignora o bloqueio remoto do emulador quando o driver local foi validado.
    [switch] $ForcarGpuHost,

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

function ArquivoConfigAvd {
    $pastas = @()
    if ($env:ANDROID_AVD_HOME) { $pastas += $env:ANDROID_AVD_HOME }
    if ($env:ANDROID_USER_HOME) { $pastas += (Join-Path $env:ANDROID_USER_HOME 'avd') }
    $pastas += (Join-Path $env:USERPROFILE '.android\avd')
    foreach ($pasta in $pastas) {
        $ini = Join-Path $pasta "$Emulador.ini"
        if (-not (Test-Path -LiteralPath $ini)) { continue }
        # O <nome>.ini aponta para a pasta real do AVD, que pode estar fora do padrao.
        $caminho = Select-String -LiteralPath $ini -Pattern '^path=(.+)$' | Select-Object -First 1
        $pastaAvd = if ($caminho) { $caminho.Matches[0].Groups[1].Value.Trim() } else { Join-Path $pasta "$Emulador.avd" }
        $config = Join-Path $pastaAvd 'config.ini'
        if (Test-Path -LiteralPath $config) { return $config }
    }
    return $null
}

function OtimizarAvd {
    # Mantem o AVD na aceleracao nativa do Windows e fixa a renderizacao na GPU
    # do host. Quando o perfil muda, o primeiro boot ignora o snapshot antigo;
    # os proximos voltam a usar Quick Boot com a configuracao ja validada.
    $config = ArquivoConfigAvd
    if (-not $config) {
        Aviso "config.ini do AVD $Emulador nao encontrado; os ajustes de desempenho nao foram aplicados."
        return $false
    }

    $ajustes = [ordered]@{
        'hw.keyboard' = 'yes'
        'hw.gpu.enabled' = 'yes'
        'hw.gpu.mode' = 'host'
        'hw.ramSize' = '3072'
        'hw.cpu.ncore' = '2'
        'showDeviceFrame' = 'no'
        'fastboot.forceColdBoot' = 'no'
        'fastboot.forceFastBoot' = 'yes'
    }
    $linhas = @(Get-Content -LiteralPath $config)
    $alterou = $false
    $encontrados = @{}
    $novas = foreach ($linha in $linhas) {
        $substituida = $false
        foreach ($chave in $ajustes.Keys) {
            if ($linha -match "^\s*$([regex]::Escape($chave))\s*=") {
                $nova = "$chave=$($ajustes[$chave])"
                if ($linha -ne $nova) { $alterou = $true }
                $encontrados[$chave] = $true
                $nova
                $substituida = $true
                break
            }
        }
        if (-not $substituida) { $linha }
    }
    foreach ($chave in $ajustes.Keys) {
        if (-not $encontrados.ContainsKey($chave)) {
            $novas = @($novas) + "$chave=$($ajustes[$chave])"
            $alterou = $true
        }
    }
    if ($alterou) {
        [System.IO.File]::WriteAllLines($config, [string[]] $novas)
        Ok "AVD otimizado para WHPX, GPU do host e teclado fisico em $config"
    }
    return $alterou
}

function ConfigurarGpuHostGlobal {
    # O Android Studio nao aceita os mesmos argumentos usados abaixo na linha
    # de comando. Estas flags oficiais mantem a Intel HD 620 no renderizador do
    # host mesmo quando o AVD e iniciado diretamente pelo Device Manager.
    $pastaAndroid = Join-Path $env:USERPROFILE '.android'
    $arquivo = Join-Path $pastaAndroid 'advancedFeatures.ini'
    $backup = "$arquivo.auster-backup"
    $ajustes = [ordered]@{
        'ForceGpuHost' = 'on'
        'ForceSwiftshader' = 'off'
        'Vulkan' = 'off'
    }
    $linhas = if (Test-Path -LiteralPath $arquivo) {
        @(Get-Content -LiteralPath $arquivo)
    } else {
        @()
    }
    $alterou = $false
    $encontrados = @{}
    $novas = foreach ($linha in $linhas) {
        $substituida = $false
        foreach ($chave in $ajustes.Keys) {
            if ($linha -match "^\s*$([regex]::Escape($chave))\s*=") {
                $nova = "$chave = $($ajustes[$chave])"
                if ($linha -ne $nova) { $alterou = $true }
                $encontrados[$chave] = $true
                $nova
                $substituida = $true
                break
            }
        }
        if (-not $substituida) { $linha }
    }
    foreach ($chave in $ajustes.Keys) {
        if (-not $encontrados.ContainsKey($chave)) {
            $novas = @($novas) + "$chave = $($ajustes[$chave])"
            $alterou = $true
        }
    }
    if (-not $alterou) { return }
    if (-not (Test-Path -LiteralPath $pastaAndroid)) {
        [void] (New-Item -ItemType Directory -Path $pastaAndroid)
    }
    if ((Test-Path -LiteralPath $arquivo) -and -not (Test-Path -LiteralPath $backup)) {
        Copy-Item -LiteralPath $arquivo -Destination $backup
    }
    [System.IO.File]::WriteAllLines($arquivo, [string[]] $novas)
    Ok "GPU do host persistida para o Android Studio em $arquivo"
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
    $avdAlterado = OtimizarAvd
    $gpuIntel620 = $false
    try {
        $gpuIntel620 = [bool] (Get-CimInstance Win32_VideoController -ErrorAction Stop |
            Where-Object { $_.Name -match 'Intel\(R\).*HD Graphics 620' } |
            Select-Object -First 1)
    } catch {
        Aviso 'nao foi possivel identificar a GPU do host; sera respeitada a selecao padrao do emulador.'
    }
    $usarGpuHostForcada = $ForcarGpuHost -or $gpuIntel620
    if ($usarGpuHostForcada) { ConfigurarGpuHostGlobal }
    if ($avdAlterado -and (EmuladorOnline)) {
        # A configuracao de hardware so vale num boot novo do emulador.
        Write-Host '  reiniciando o emulador para aplicar o perfil de hardware...'
        & $adb emu kill *> $null
        [void] (Aguardar { -not (EmuladorOnline) } 60 'o emulador fechar')
    }
    if (-not (EmuladorOnline)) {
        if (-not (Test-Path $emuladorExe)) {
            Falhar "emulador nao encontrado em $emuladorExe. Veja a secao de emulador no INSTALACAO.md."
        }
        $argumentosEmulador = @(
            '-avd', $Emulador,
            '-accel', 'on',
            '-gpu', 'host',
            '-memory', '3072',
            '-cores', '2'
        )
        if ($usarGpuHostForcada) {
            # O servidor de flags do emulador 37 força SwiftShader na Intel HD
            # 620, apesar de o driver OpenGL 4.5 funcionar corretamente.
            $argumentosEmulador += @(
                '-feature', 'ForceGpuHost',
                '-feature', '-ForceSwiftshader',
                '-feature', '-Vulkan'
            )
        }
        if ($avdAlterado) {
            # Descarta somente a leitura do snapshot antigo. O encerramento
            # normal ainda salva um Quick Boot com o novo perfil de hardware.
            $argumentosEmulador += '-no-snapshot-load'
        }
        Write-Host "  subindo o AVD $Emulador..."
        Start-Process -FilePath $emuladorExe -ArgumentList $argumentosEmulador
        if (-not (Aguardar { EmuladorOnline } 180 'o emulador conectar ao adb')) {
            Falhar "o emulador $Emulador nao ficou online. Confira o nome com: flutter emulators"
        }
    }
    $iniciou = Aguardar { ((& $adb shell getprop sys.boot_completed 2>$null) -join '').Trim() -eq '1' } 180 'o Android terminar de iniciar'
    if (-not $iniciou) { Falhar 'o Android do emulador nao terminou de iniciar.' }
    Start-Sleep -Seconds 10
    & $adb shell setprop log.tag.EGL_emulation SILENT 2>$null
    # O teclado do computador continua ativo sem manter o Gboard aberto, o que
    # reduz travamentos do System UI em maquinas com poucos nucleos.
    & $adb shell settings put secure show_ime_with_hard_keyboard 0 2>$null
    & $adb shell settings put global window_animation_scale 0.5 2>$null
    & $adb shell settings put global transition_animation_scale 0.5 2>$null
    & $adb shell settings put global animator_duration_scale 0.5 2>$null
    & $adb shell settings put global show_hw_screen_updates 0 2>$null
    & $adb shell setprop debug.sf.showupdates 0 2>$null
    & $adb shell setprop debug.hwui.show_dirty_regions false 2>$null
    $renderer = ((& $adb shell dumpsys SurfaceFlinger 2>$null) |
        Select-String '^GLES:' | Select-Object -First 1).Line
    if ($renderer) {
        if ($renderer -match 'SwiftShader') {
            Aviso "renderizacao por software ativa: $renderer"
        } else {
            Ok "renderizacao acelerada ativa: $renderer"
        }
    }
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

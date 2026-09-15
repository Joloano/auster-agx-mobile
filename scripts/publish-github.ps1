param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[^/\s]+/[^/\s]+$')]
    [string] $RepositoryFullName,

    [ValidateSet('private', 'public', 'internal')]
    [string] $Visibility = 'private',

    [switch] $CreateRepo,

    [switch] $CreateIssues
)

$ErrorActionPreference = 'Stop'

function Assert-Command($Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Comando obrigatorio nao encontrado: $Name"
    }
}

Assert-Command git
Assert-Command gh

gh auth status | Out-Null

$repoRoot = (git rev-parse --show-toplevel).Trim()
Set-Location $repoRoot

$branch = (git branch --show-current).Trim()
if ($branch -ne 'main') {
    throw "Execute a publicacao a partir da branch main. Branch atual: $branch"
}

$status = (git status --porcelain)
if ($status) {
    throw "O repositorio possui mudancas locais. Commit ou limpe antes de publicar."
}

$remoteUrl = "https://github.com/$RepositoryFullName.git"
$origin = git remote get-url origin 2>$null

if ($CreateRepo) {
    $visibilityFlag = "--$Visibility"
    if ($origin) {
        git remote set-url origin $remoteUrl
    }

    gh repo create $RepositoryFullName --source . --remote origin --push $visibilityFlag
} else {
    if ($origin) {
        git remote set-url origin $remoteUrl
    } else {
        git remote add origin $remoteUrl
    }

    git push -u origin main
}

if ($CreateIssues) {
    $issueDir = Join-Path $repoRoot 'docs/issues'
    if (-not (Test-Path $issueDir)) {
        throw "Diretorio de issues nao encontrado: $issueDir"
    }

    Get-ChildItem $issueDir -Filter '*.md' |
        Where-Object { $_.Name -ne 'README.md' } |
        Sort-Object Name |
        ForEach-Object {
            $firstHeading = Select-String -Path $_.FullName -Pattern '^#\s+(.+)$' | Select-Object -First 1
            if (-not $firstHeading) {
                throw "Issue sem titulo H1: $($_.FullName)"
            }

            $title = $firstHeading.Matches[0].Groups[1].Value.Trim()
            gh issue create `
                --repo $RepositoryFullName `
                --title $title `
                --body-file $_.FullName `
                --label 'academico' `
                --label 'mobile'
        }
}

Write-Host "Publicado em https://github.com/$RepositoryFullName"

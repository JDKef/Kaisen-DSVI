[CmdletBinding()]
param(
    [string]$FlutterExecutable
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-FlutterExecutable {
    param([string]$RequestedExecutable)

    $candidate = $RequestedExecutable
    if ([string]::IsNullOrWhiteSpace($candidate)) {
        $candidate = $env:FLUTTER_EXE
    }

    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
        $command = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $command) {
            return $command.Source
        }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
        throw "Flutter executable was not found: $candidate"
    }

    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw 'Flutter is not on PATH. Pass -FlutterExecutable or set FLUTTER_EXE.'
    }
    return $command.Source
}

function Invoke-FlutterStep {
    param(
        [string]$Label,
        [string[]]$Arguments
    )

    Write-Host "[Kaisen handoff] $Label" -ForegroundColor Cyan
    & $script:FlutterCommand @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE."
    }
    Write-Host "[Kaisen handoff] $Label succeeded." -ForegroundColor Green
}

try {
    $repositoryRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
    $mobileDirectory = Join-Path $repositoryRoot 'mobile'
    $pubspecPath = Join-Path $mobileDirectory 'pubspec.yaml'

    if (-not (Test-Path -LiteralPath $pubspecPath -PathType Leaf)) {
        throw "Flutter project was not found at $mobileDirectory."
    }

    $script:FlutterCommand = Resolve-FlutterExecutable $FlutterExecutable
    Write-Host "[Kaisen handoff] Repository: $repositoryRoot"
    Write-Host "[Kaisen handoff] Flutter project: $mobileDirectory"

    Push-Location $mobileDirectory
    try {
        Invoke-FlutterStep 'flutter pub get' @('pub', 'get')
        Invoke-FlutterStep 'flutter analyze' @('analyze')
        Invoke-FlutterStep 'flutter test' @('test')
    }
    finally {
        Pop-Location
    }

    Write-Host '[Kaisen handoff] Validation completed successfully.' -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[Kaisen handoff] Validation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}


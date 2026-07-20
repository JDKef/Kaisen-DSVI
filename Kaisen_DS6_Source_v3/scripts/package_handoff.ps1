[CmdletBinding()]
param(
    [string]$SupabaseUrl,
    [string]$SupabasePublishableKey,
    [string]$FlutterExecutable,
    [ValidateSet('release', 'debug')]
    [string]$BuildMode = 'release'
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

try {
    if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
        $SupabaseUrl = $env:SUPABASE_URL
    }
    if ([string]::IsNullOrWhiteSpace($SupabasePublishableKey)) {
        $SupabasePublishableKey = $env:SUPABASE_PUBLISHABLE_KEY
    }
    if ([string]::IsNullOrWhiteSpace($SupabaseUrl)) {
        throw 'SUPABASE_URL is required as a parameter or environment variable.'
    }
    if ([string]::IsNullOrWhiteSpace($SupabasePublishableKey)) {
        throw 'SUPABASE_PUBLISHABLE_KEY is required as a parameter or environment variable.'
    }

    $repositoryRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
    $mobileDirectory = Join-Path $repositoryRoot 'mobile'
    $validationScript = Join-Path $PSScriptRoot 'validate_handoff.ps1'
    $flutterCommand = Resolve-FlutterExecutable $FlutterExecutable

    Write-Host '[Kaisen handoff] Running required validation first.' -ForegroundColor Cyan
    & $validationScript -FlutterExecutable $flutterCommand
    if ($LASTEXITCODE -ne 0) {
        throw 'Validation failed. Packaging was not started.'
    }

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        throw 'Git is required to create the clean source archive.'
    }

    $workingTree = & $gitCommand.Source -C $repositoryRoot status --porcelain
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect the Git working tree.'
    }
    if (-not [string]::IsNullOrWhiteSpace(($workingTree -join [Environment]::NewLine))) {
        throw 'Packaging requires a clean committed repository. Review and commit the handoff files first.'
    }

    Write-Host "[Kaisen handoff] Building universal Android APK ($BuildMode)." -ForegroundColor Cyan
    Push-Location $mobileDirectory
    try {
        $buildArguments = @(
            'build',
            'apk',
            "--$BuildMode",
            "--dart-define=SUPABASE_URL=$SupabaseUrl",
            "--dart-define=SUPABASE_PUBLISHABLE_KEY=$SupabasePublishableKey"
        )
        & $flutterCommand @buildArguments
        if ($LASTEXITCODE -ne 0) {
            if ($BuildMode -eq 'release') {
                throw 'Release APK build failed. Verify Android signing. If a debug handoff is explicitly acceptable, rerun with -BuildMode debug.'
            }
            throw "Android APK build failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }

    $apkSource = Join-Path $mobileDirectory "build\app\outputs\flutter-apk\app-$BuildMode.apk"
    if (-not (Test-Path -LiteralPath $apkSource -PathType Leaf)) {
        throw "Expected APK was not produced at $apkSource."
    }

    $distDirectory = Join-Path $repositoryRoot 'dist'
    New-Item -ItemType Directory -Path $distDirectory -Force | Out-Null

    $apkDestination = Join-Path $distDirectory 'Kaisen_DS6_v3.apk'
    $sourceArchive = Join-Path $distDirectory 'Kaisen_DS6_Source_v3.zip'
    foreach ($outputPath in @($apkDestination, $sourceArchive)) {
        if (Test-Path -LiteralPath $outputPath -PathType Leaf) {
            Remove-Item -LiteralPath $outputPath -Force
        }
    }
    Copy-Item -LiteralPath $apkSource -Destination $apkDestination -Force

    Write-Host '[Kaisen handoff] Creating source archive from committed Git content.' -ForegroundColor Cyan
    $archiveArguments = @(
        '-C', $repositoryRoot,
        'archive',
        '--format=zip',
        "--output=$sourceArchive",
        'HEAD',
        '--',
        '.',
        ':(exclude)Kaisen-1.2-baseline.apk',
        ':(exclude)FLUTTER_DOCTOR_JOSE.txt',
        ':(exclude)mobile/docs/~$ia_del_Software_Kaisen.docx',
        ':(exclude)docs/references/**',
        ':(exclude)docs/INDUSTRIAL_UI_IMPLEMENTATION_PLAN.md',
        ':(exclude)design-qa.md'
    )
    & $gitCommand.Source @archiveArguments
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $sourceArchive -PathType Leaf)) {
        throw 'Git source archive creation failed.'
    }

    $handoffDocuments = @(
        'SETUP_GROUP.md',
        'GROUP_RUN_ARGS.example.txt',
        'DEMO_CHECKLIST.md',
        'HANDOFF_CONTENTS.md',
        'FLUTTER_VERSION.txt'
    )
    foreach ($document in $handoffDocuments) {
        $source = Join-Path $repositoryRoot $document
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Required handoff document is missing: $document"
        }
        Copy-Item -LiteralPath $source -Destination $distDirectory -Force
    }

    Write-Host '[Kaisen handoff] Packaging completed successfully.' -ForegroundColor Green
    Write-Host "[Kaisen handoff] APK: $apkDestination"
    Write-Host "[Kaisen handoff] Source: $sourceArchive"
    exit 0
}
catch {
    Write-Host "[Kaisen handoff] Packaging failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

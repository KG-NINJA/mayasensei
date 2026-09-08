param(
    [Parameter(Mandatory=$true)][string]$Godot,
    [string]$TemplatesDirectory = '',
    [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$workRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $workRoot 'aztec3'
$presetPath = Join-Path $projectRoot 'export_presets.cfg'
$presetOriginal = [IO.File]::ReadAllText($presetPath)
New-Item -ItemType Directory -Force -Path (Join-Path $workRoot 'build/windows'),(Join-Path $workRoot 'build/linux') | Out-Null

function Invoke-CheckedGodot([string[]]$EngineArguments, [string]$LogName) {
    $logPath = Join-Path $workRoot "build/$LogName.log"
    & $Godot --headless --path $projectRoot --log-file $logPath @EngineArguments | Out-Host
    $processCode = $LASTEXITCODE
    $logText = [IO.File]::ReadAllText($logPath)
    if ($processCode -ne 0 -or $logText -match 'SCRIPT ERROR|Parse Error|Compile Error|Project export for preset .+ failed|Failed to load script') {
        throw "Godot failed: $LogName. See $logPath"
    }
    return $logText
}

try {
    if ($TemplatesDirectory) {
        $templateFiles = @('web_nothreads_release.zip','windows_release_x86_64.exe','linux_release.x86_64')
        $presetLocal = $presetOriginal
        for ($i=0; $i -lt 3; $i++) {
            $templatePath = (Join-Path $TemplatesDirectory $templateFiles[$i]).Replace('\','/')
            if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) { throw "Missing template: $templatePath" }
            $pattern = '(?s)(\[preset\.'+$i+'\.options\]\s*)custom_template/release="[^"]*"'
            $replacement = '${1}custom_template/release="'+$templatePath+'"'
            $presetLocal = [regex]::Replace($presetLocal,$pattern,$replacement)
        }
        [IO.File]::WriteAllText($presetPath,$presetLocal,[Text.UTF8Encoding]::new($false))
    }
    Invoke-CheckedGodot @('--editor','--import','--quit') 'import' | Out-Null
    $testLog = Invoke-CheckedGodot @('--script','res://tests/run.gd') 'tests'
    $match = [regex]::Match($testLog,'AZTEC3_TESTS (\{[^\r\n]+\})')
    if (-not $match.Success) { throw 'Test completion marker missing' }
    $report = $match.Groups[1].Value | ConvertFrom-Json
    if ($report.failures.Count -ne 0) { throw ($report.failures -join '; ') }
    Invoke-CheckedGodot @('--export-release','Web',(Join-Path $workRoot 'web/index.html')) 'export-web' | Out-Null
    Invoke-CheckedGodot @('--export-release','Windows',(Join-Path $workRoot 'build/windows/AZTEC3.exe')) 'export-windows' | Out-Null
    Invoke-CheckedGodot @('--export-release','Linux',(Join-Path $workRoot 'build/linux/AZTEC3.x86_64')) 'export-linux' | Out-Null
    & $Python (Join-Path $PSScriptRoot 'package.py')
    if ($LASTEXITCODE -ne 0) { throw 'Packaging failed' }
} finally {
    [IO.File]::WriteAllText($presetPath,$presetOriginal,[Text.UTF8Encoding]::new($false))
}

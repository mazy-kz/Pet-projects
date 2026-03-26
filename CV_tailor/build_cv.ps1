$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$preferredPdflatex = Join-Path $env:LOCALAPPDATA "Programs\MiKTeX\miktex\bin\x64\pdflatex.exe"

if (Test-Path $preferredPdflatex) {
    $pdflatex = $preferredPdflatex
} else {
    $cmd = Get-Command pdflatex -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "pdflatex was not found. Install MiKTeX first."
    }
    $pdflatex = $cmd.Source
}

Write-Host "Building main.tex..."
& $pdflatex -interaction=nonstopmode -halt-on-error (Join-Path $projectRoot "main.tex")
exit $LASTEXITCODE

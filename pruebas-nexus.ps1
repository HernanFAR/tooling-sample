# VSlices Tooling - Hierarchical Nexus integration verification
# Run from tooling-sample root. Does not modify Docs Standard registry or definitions.
# Compatible with Windows PowerShell 5.1 and PowerShell 7+.

$ErrorActionPreference = 'Stop'
$evidence = 'evidence/nexus-hierarchy-rerun'
$nexus = 'prueba-nexus-jerarquico'
$note = 'prueba-nexus-jerarquico-nota'
$definition = '.vslices/docs/local/nexus-qa/nexus/hierarchical-qa.yml'
$registry = '.vslices/docs/registry.yaml'
$results = [System.Collections.Generic.List[object]]::new()

if (-not (Test-Path '.vslices')) { throw 'Run this script from the root of tooling-sample.' }
if (-not (Test-Path $registry)) { throw "Missing registry: $registry" }
if (-not (Test-Path $definition)) { throw "Missing experimental definition: $definition" }
if (Test-Path "docs/$nexus/README.md") { throw "Nexus already exists. Do not overwrite: docs/$nexus/README.md" }
if (Test-Path "docs/$note.md") { throw "Support Note already exists. Do not overwrite: docs/$note.md" }
New-Item -ItemType Directory -Force $evidence | Out-Null

function Invoke-Check {
    param(
        [string]$Name,
        [string[]]$CliArgs,
        [bool]$ShouldFail = $false,
        [string[]]$Contains = @()
    )
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    $originalPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $raw = & vslices @CliArgs 2>&1
        $exitCode = $LASTEXITCODE
        $output = ($raw | Out-String)
    } finally {
        $ErrorActionPreference = $originalPreference
    }
    [System.IO.File]::WriteAllText(
        (Join-Path (Get-Location).Path "$evidence/$Name.txt"),
        $output, [System.Text.UTF8Encoding]::new($false))
    Write-Host $output
    $ok = if ($ShouldFail) { $exitCode -ne 0 } else { $exitCode -eq 0 }
    foreach ($needle in $Contains) {
        if (-not $output.Contains($needle)) { $ok = $false; Write-Host "Missing expected text: $needle" -ForegroundColor Yellow }
    }
    $results.Add([pscustomobject]@{
        Test = $Name; ExitCode = $exitCode; ExpectedFailure = $ShouldFail; Passed = $ok
    })
    if (-not $ok) { throw "Test '$Name' failed. Further dependent tests are skipped; evidence saved." }
}

function Snapshot([string]$Path) {
    if (-not (Test-Path $Path)) { throw "Expected artifact missing: $Path" }
    return (Get-FileHash -Algorithm SHA256 $Path).Hash
}

try {
    Invoke-Check '01-version' @('--version')
    Invoke-Check '02-list-standards' @('list', 'docs-standards') $false @('nexus-qa', 'vslices')
    Invoke-Check '03-create' @('new', 'nexus', $nexus, '--kind', 'nexus-qa.hierarchical-qa', '--target', 'Nexus hierarchical QA', '--scope', 'project')
    Invoke-Check '04-discovery-initial' @('discovery', 'nexus', $nexus) $false @('[1]', '[1.1]', '[1.1.1]', '[2]')
    Invoke-Check '05-answer-root' @('update', 'nexus', $nexus, '--question-id', '1', '--answer', 'Comprobar la navegacion jerarquica sin modificar los estandares canonicos.')
    Invoke-Check '06-answer-child' @('update', 'nexus', $nexus, '--question-id', '1.1', '--answer', 'Los resultados de discovery y read constituyen evidencia observable.')
    Invoke-Check '07-answer-grandchild' @('update', 'nexus', $nexus, '--question-id', '1.1.1', '--answer', 'La prueba usa un vocabulario experimental local, no el estandar oficial.')
    Invoke-Check '08-read-deep' @('read', 'nexus', $nexus, '--question-id', '1.1.1', '--deep') $false @('Comprobar la navegacion jerarquica', 'Los resultados de discovery', 'La prueba usa un vocabulario experimental')
    Invoke-Check '09-discovery-answered' @('discovery', 'nexus', $nexus) $false @('answered')

    $nexusPath = "docs/$nexus/README.md"
    $beforeNegative = Snapshot $nexusPath
    Invoke-Check '10-invalid-question' @('update', 'nexus', $nexus, '--question-id', '999', '--answer', 'No debe escribirse') $true @('RELART020')
    $afterNegative = Snapshot $nexusPath
    $notModified = $beforeNegative -eq $afterNegative
    $results.Add([pscustomobject]@{Test='10b-negative-no-mutation'; ExitCode=0; ExpectedFailure=$false; Passed=$notModified})
    if (-not $notModified) { throw 'Invalid question unexpectedly changed Nexus README.' }

    Invoke-Check '11-create-note' @('new', 'support-note', $note, '--kind', 'draft', '--target', 'Observaciones sobre Nexus jerarquico')
    Invoke-Check '12-relate' @('relate', $nexus, '--to', $note, '--role', 'Conserva observaciones experimentales')
    Invoke-Check '13-read-deep-after-relate' @('read', 'nexus', $nexus, '--question-id', '1.1.1', '--deep') $false @('Comprobar la navegacion jerarquica', 'La prueba usa un vocabulario experimental')
    Invoke-Check '14-discovery-after-relate' @('discovery', 'nexus', $nexus) $false @('Conserva observaciones experimentales')
    Invoke-Check '15-discovery-reciprocal' @('discovery', 'support-note', $note) $false @('Conserva observaciones experimentales')
    Invoke-Check '16-read-other-root' @('read', 'nexus', $nexus, '--question-id', '2') $false @('Que decision queda abierta?')
} catch {
    Write-Host "`nSTOP: $($_.Exception.Message)" -ForegroundColor Yellow
} finally {
    $results | ConvertTo-Json -Depth 5 | Set-Content "$evidence/results.json" -Encoding UTF8
    $failed = @($results | Where-Object { -not $_.Passed })
    $summary = "Executed: $($results.Count); Passed: $($results.Count - $failed.Count); Failed: $($failed.Count)"
    $summary | Set-Content "$evidence/summary.txt" -Encoding UTF8
    Write-Host "`n$summary" -ForegroundColor Cyan
    Write-Host "Evidence: $evidence"
    Write-Host 'No registry/standards changes, commit, or push were performed.'
}

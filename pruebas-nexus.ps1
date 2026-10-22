# VSlices Tooling - Nexus hierarchical question integration test
# Execute in the root of tooling-sample (PowerShell 7+ recommended).
# Creates an independent, project-local experimental Docs Standard: nexus-qa.
# Never changes the canonical vslices Docs Standard snapshot.

$ErrorActionPreference = 'Stop'
$evidence = 'evidence/nexus-hierarchy'
$standardName = 'nexus-qa'
$nexus = 'prueba-nexus-jerarquico'
$note = 'prueba-nexus-jerarquico-nota'
$registry = '.vslices/docs/registry.yaml'
$standardRoot = ".vslices/docs/local/$standardName"
$definition = "$standardRoot/nexus/hierarchical-qa.yml"
$results = [System.Collections.Generic.List[object]]::new()

if (-not (Test-Path '.vslices')) { throw 'Run this script from the root of tooling-sample.' }
if (-not (Test-Path $registry)) { throw "Missing registry: $registry" }
if (Test-Path $standardRoot) { Write-Host 'Reusing existing nexus-qa snapshot from previous attempt.' -ForegroundColor Yellow }
if (Test-Path "docs/$nexus") { throw "Test Nexus already exists: docs/$nexus" }
New-Item -ItemType Directory -Force $evidence, "$standardRoot/nexus" | Out-Null

# Register a second, explicitly local standard, preserving the existing registry as-is.
$registryOriginal = [System.IO.File]::ReadAllText((Resolve-Path $registry))
$alreadyRegistered = ($registryOriginal -match '(?m)^\s*-\s*name:\s*nexus-qa\s*$')
if ($registryOriginal -notmatch '(?m)^standards:\s*$') { throw 'Unrecognized docs registry shape; do not modify automatically.' }
$registryUpdated = $registryOriginal.TrimEnd("`r", "`n") + "`n  - name: nexus-qa`n    declared-name: nexus-qa`n    local: 'true'`n"
# This registry addition is intentional and remains local so the generated artifact remains readable.
if (-not $alreadyRegistered) { [System.IO.File]::WriteAllText((Resolve-Path $registry), $registryUpdated, [System.Text.UTF8Encoding]::new($false)) }

$manifestSource = @'
kind: vslices-docs-standard
version: 0.1
name: nexus-qa
documents: []
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path "$standardRoot/manifest.yaml"), $manifestSource, [System.Text.UTF8Encoding]::new($false))

$definitionSource = @'
kind: vslices-nexus-definition
version: 0.1
nexus:
  type: hierarchical-qa
  scopes: [project]
  questions:
    - id: objective
      text: Que buscamos comprobar?
      children:
        - id: evidence
          text: Que evidencia respalda el objetivo?
          children:
            - id: limits
              text: Que limites tiene la evidencia?
    - id: tradeoff
      text: Que decision queda abierta?
'@
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path $definition), $definitionSource, [System.Text.UTF8Encoding]::new($false))

function Invoke-VSlicesTest {
    param([string]$Name, [string[]]$CliArgs, [bool]$ShouldFail = $false, [string]$Contains = '')
    Write-Host "`n=== $Name ===" -ForegroundColor Cyan
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { $output = (& vslices @CliArgs 2>&1 | Out-String); $exit = $LASTEXITCODE }
    finally { $ErrorActionPreference = $previousPreference }
    $output | Set-Content "$evidence/$Name.txt" -Encoding utf8
    Write-Host $output
    $ok = if ($ShouldFail) { $exit -ne 0 } else { $exit -eq 0 }
    if ($Contains -and $output -notmatch [regex]::Escape($Contains)) { $ok = $false }
    $results.Add([pscustomobject]@{Test=$Name; ExitCode=$exit; ExpectedFailure=$ShouldFail; Passed=$ok})
}

try {
    Invoke-VSlicesTest '01-version' @('--version')
    Invoke-VSlicesTest '02-list-standards' @('list','docs-standards') $false 'nexus-qa'
    Invoke-VSlicesTest '03-create' @('new','nexus',$nexus,'--kind','nexus-qa.hierarchical-qa','--target','Nexus hierarchical QA','--scope','project')
    Invoke-VSlicesTest '04-discovery-initial' @('discovery','nexus',$nexus) $false '[1]'
    Invoke-VSlicesTest '05-answer-root' @('update','nexus',$nexus,'--question-id','1','--answer','Comprobar la navegacion jerarquica sin modificar los estandares canonicos.')
    Invoke-VSlicesTest '06-answer-child' @('update','nexus',$nexus,'--question-id','1.1','--answer','Los resultados de discovery y read constituyen evidencia observable.')
    Invoke-VSlicesTest '07-answer-grandchild' @('update','nexus',$nexus,'--question-id','1.1.1','--answer','La prueba usa un vocabulario experimental local, no el estandar oficial.')
    Invoke-VSlicesTest '08-read-deep' @('read','nexus',$nexus,'--question-id','1.1.1','--deep') $false 'Comprobar la navegacion jerarquica'
    Invoke-VSlicesTest '09-discovery-answered' @('discovery','nexus',$nexus) $false 'answered'
    Invoke-VSlicesTest '10-invalid-question' @('update','nexus',$nexus,'--question-id','999','--answer','No debe escribirse') $true 'RELART020'
    Invoke-VSlicesTest '11-create-note' @('new','support-note',$note,'--kind','draft','--target','Observaciones sobre Nexus jerarquico')
    Invoke-VSlicesTest '12-relate' @('relate',$nexus,'--to',$note,'--role','Conserva observaciones experimentales')
    Invoke-VSlicesTest '13-read-deep-after-relate' @('read','nexus',$nexus,'--question-id','1.1.1','--deep') $false 'La prueba usa un vocabulario experimental'
    Invoke-VSlicesTest '14-discovery-after-relate' @('discovery','nexus',$nexus) $false 'Conserva observaciones experimentales'
    Invoke-VSlicesTest '15-discovery-reciprocal' @('discovery','support-note',$note) $false 'Conserva observaciones experimentales'
    Invoke-VSlicesTest '16-read-other-root' @('read','nexus',$nexus,'--question-id','2') $false 'Que decision queda abierta?'
} finally {
    $results | ConvertTo-Json -Depth 5 | Set-Content "$evidence/results.json" -Encoding utf8
    $failed = @($results | Where-Object { -not $_.Passed })
    "Executed: $($results.Count); Passed: $($results.Count-$failed.Count); Failed: $($failed.Count)" |
        Tee-Object -FilePath "$evidence/summary.txt"
    Write-Host "`nEvidence: $evidence"
    Write-Host 'Experimental Docs Standard is retained at .vslices/docs/local/nexus-qa for later discovery.'
    Write-Host 'No commit or push was performed.'
}

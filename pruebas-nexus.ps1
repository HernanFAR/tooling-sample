# VSlices Tooling - Nexus question contract on official Docs Standard
# Run from tooling-sample root. PowerShell 7+ recommended.
# The official capability and service-consumption Nexus definitions have recommendations, not questions.
# This script validates that this boundary is observable and that invalid read/update attempts do not mutate artifacts.

$ErrorActionPreference = 'Continue'
$evidence = 'evidence/nexus-questions'
$nexus = 'prueba-nexus-preguntas-limite'
$results = @()
New-Item -ItemType Directory -Force -Path $evidence | Out-Null

function Invoke-Case {
  param([string]$Name,[string[]]$CliArgs,[bool]$ExpectFailure=$false)
  Write-Host "`n=== $Name ===" -ForegroundColor Cyan
  $output = & vslices @CliArgs 2>&1 | Out-String
  $code = $LASTEXITCODE
  $output | Set-Content -Path (Join-Path $evidence "$Name.txt") -Encoding utf8
  Write-Host $output
  $script:results += [pscustomobject]@{Test=$Name; ExitCode=$code; ExpectedFailure=$ExpectFailure; Passed=($(if($ExpectFailure){$code -ne 0}else{$code -eq 0}))}
}

Invoke-Case '01-version' @('--version')
Invoke-Case '02-standards' @('list','docs-standards')
Invoke-Case '03-create-nexus' @('new','nexus',$nexus,'--kind','capability','--target','Prueba de preguntas Nexus','--scope','capability')
Invoke-Case '04-discovery' @('discovery','nexus',$nexus)

# Resolve Nexus README with expected configured docs root; read-only scan fallback.
$readme = Join-Path 'docs' (Join-Path $nexus 'README.md')
if (-not (Test-Path $readme)) {
  $matches = @(Get-ChildItem -Path . -Filter 'README.md' -File -Recurse | Where-Object { $_.Directory.Name -eq $nexus })
  if ($matches.Count -eq 1) { $readme = $matches[0].FullName }
}
if (-not (Test-Path $readme)) { throw "Cannot find the created Nexus README; inspect 03-create-nexus.txt" }
$before = (Get-FileHash -Algorithm SHA256 -Path $readme).Hash

# A recommendation selection is NOT a question selection.
Invoke-Case '05-read-recommendation-as-question' @('read','nexus',$nexus,'--question-id','1') $true
Invoke-Case '06-read-deep-recommendation-as-question' @('read','nexus',$nexus,'--question-id','1','--deep') $true
Invoke-Case '07-update-recommendation-as-question' @('update','nexus',$nexus,'--question-id','1','--answer','This must not be written') $true
Invoke-Case '08-read-invalid-question' @('read','nexus',$nexus,'--question-id','999','--deep') $true

$after = (Get-FileHash -Algorithm SHA256 -Path $readme).Hash
$unchanged = $before -eq $after
"README: $readme`nBefore SHA256: $before`nAfter SHA256: $after`nUnchanged: $unchanged" | Set-Content -Path (Join-Path $evidence '09-integrity.txt') -Encoding utf8
$results += [pscustomobject]@{Test='09-no-mutation';ExitCode=$(if($unchanged){0}else{1});ExpectedFailure=$false;Passed=$unchanged}

$results | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $evidence 'results.json') -Encoding utf8
$results | Format-Table -AutoSize
$failures = @($results | Where-Object { -not $_.Passed })
Write-Host "Passed: $($results.Count-$failures.Count) / $($results.Count)" -ForegroundColor $(if($failures.Count -eq 0){'Green'}else{'Yellow'})
Write-Host 'Evidence is saved regardless of failures. Script does not commit or push.'
Write-Host 'To upload: git add evidence/nexus-questions docs; git commit -m "test: capture nexus question boundary"; git push'

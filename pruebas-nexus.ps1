# VSlices Tooling - Nexus lifecycle integration evidence
# Run from tooling-sample root with the PR #16 build installed.
# Uses new artifact names; remove old test artifacts before rerunning if desired.

$ErrorActionPreference = 'Continue'
$evidence = 'evidence/nexus-lifecycle'
$nexus = 'prueba-nexus-capability'
$note = 'prueba-nexus-nota'
$results = [System.Collections.Generic.List[object]]::new()
New-Item -ItemType Directory -Path $evidence -Force | Out-Null

function Test-VSlices {
    param(
        [string]$Name,
        [string[]]$Arguments,
        [bool]$ExpectFailure = $false
    )
    Write-Host "`n===== $Name =====" -ForegroundColor Cyan
    $output = (& vslices @Arguments 2>&1 | Out-String)
    $exitCode = $LASTEXITCODE
    $output | Set-Content -Path (Join-Path $evidence "$Name.txt") -Encoding utf8
    Write-Host $output
    $passed = if ($ExpectFailure) { $exitCode -ne 0 } else { $exitCode -eq 0 }
    $script:results.Add([PSCustomObject]@{
        Test = $Name
        ExitCode = $exitCode
        ExpectedFailure = $ExpectFailure
        Passed = $passed
    })
}

# The CLI announces generated document paths. Never assume name or route conventions.
function Get-RecommendationDocumentPath {
    param([string]$Selection)
    $output = (& vslices discovery nexus $nexus 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) { throw "Cannot discover Nexus to resolve selection $Selection : $output" }
    $escaped = [regex]::Escape($Selection)
    $match = [regex]::Match($output, "(?ms)^\[$escaped\] document:.*?^\s+command:\s+vslices discovery document\s+([^\r\n]+)")
    if (-not $match.Success) { throw "No materialized Document found at Nexus selection $Selection" }
    return $match.Groups[1].Value.Trim().Trim('"')
}

Test-VSlices '01-version' @('--version')
Test-VSlices '02-docs-standards' @('list','docs-standards')
Test-VSlices '03-create-nexus' @('new','nexus',$nexus,'--kind','capability','--target','Sistema de solicitudes','--scope','capability')
Test-VSlices '04-discovery-initial' @('discovery','nexus',$nexus)
Test-VSlices '05-create-scope' @('new','document','--from-nexus',"${nexus}:1")
Test-VSlices '06-discovery-after-scope' @('discovery','nexus',$nexus)
Test-VSlices '07-create-behavior' @('new','document','--from-nexus',"${nexus}:2")
Test-VSlices '08-discovery-after-behavior' @('discovery','nexus',$nexus)

try {
    $scopePath = Get-RecommendationDocumentPath '1'
    Test-VSlices '09-discovery-scope' @('discovery','document',$scopePath)
} catch { $_ | Out-String | Set-Content (Join-Path $evidence '09-discovery-scope.txt'); $results.Add([PSCustomObject]@{Test='09-discovery-scope';ExitCode=-1;ExpectedFailure=$false;Passed=$false}) }
try {
    $behaviorPath = Get-RecommendationDocumentPath '2'
    Test-VSlices '10-discovery-behavior' @('discovery','document',$behaviorPath)
} catch { $_ | Out-String | Set-Content (Join-Path $evidence '10-discovery-behavior.txt'); $results.Add([PSCustomObject]@{Test='10-discovery-behavior';ExitCode=-1;ExpectedFailure=$false;Passed=$false}) }

Test-VSlices '11-duplicate-recommendation' @('new','document','--from-nexus',"${nexus}:1") $true
Test-VSlices '12-invalid-selection' @('new','document','--from-nexus',"${nexus}:999") $true
Test-VSlices '13-missing-nexus' @('discovery','nexus','nexus-que-no-existe') $true
Test-VSlices '14-create-related-note' @('new','support-note',$note,'--kind','draft','--target','Observaciones sobre la capacidad')
Test-VSlices '15-relate-nexus-note' @('relate',$nexus,'--to',$note,'--role','Aporta observaciones complementarias')
Test-VSlices '16-discovery-nexus-related' @('discovery','nexus',$nexus)
Test-VSlices '17-discovery-note-related' @('discovery','support-note',$note)
Test-VSlices '18-duplicate-relation' @('relate',$nexus,'--to',$note,'--role','Relacion duplicada') $true

Get-ChildItem -Path 'docs' -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -like "*${nexus}*" } |
    Select-Object FullName,Length |
    Format-Table -AutoSize | Out-String |
    Set-Content (Join-Path $evidence '19-artifacts.txt')

$results | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $evidence 'results.json') -Encoding utf8
$results | Format-Table -AutoSize
$failed = @($results | Where-Object { -not $_.Passed })
Write-Host "Total: $($results.Count); Passed: $($results.Count - $failed.Count); Failed: $($failed.Count)"
Write-Host 'Evidence saved even if some tests failed.' -ForegroundColor Yellow
Write-Host 'Review git status, then commit/push manually (the script will NOT automatically push).'

# VSlices Tooling - Nexus Integration Tests
# Ejecutar desde la raíz de tooling-sample

$ErrorActionPreference = "Continue"
$evidence = "evidence/nexus-lifecycle"
$nexus = "prueba-nexus-capability"
$results = @()

New-Item -ItemType Directory -Force $evidence | Out-Null

function Test-VSlices {
    param(
        [string]$Name,
        [string[]]$Arguments,
        [bool]$ExpectFailure = $false
    )

    Write-Host "`n===== $Name =====" -ForegroundColor Cyan

    $output = & vslices @Arguments 2>&1 | Out-String
    $exitCode = $LASTEXITCODE

    $output | Set-Content "$evidence/$Name.txt" -Encoding utf8
    Write-Host $output

    $passed = if ($ExpectFailure) {
        $exitCode -ne 0
    } else {
        $exitCode -eq 0
    }

    $script:results += [PSCustomObject]@{
        Test = $Name
        ExitCode = $exitCode
        ExpectedFailure = $ExpectFailure
        Passed = $passed
    }
}

# 1. Estado inicial
Test-VSlices "01-version" @("--version")
Test-VSlices "02-docs-standards" @("list", "docs-standards")

# 2. Crear Nexus
Test-VSlices "03-create-nexus" @(
    "new", "nexus", $nexus,
    "--kind", "capability",
    "--target", "Sistema de solicitudes",
    "--scope", "capability"
)

# 3. Descubrir recomendaciones
Test-VSlices "04-discovery-initial" @(
    "discovery", "nexus", $nexus
)

# 4. Materializar primera recomendación
Test-VSlices "05-create-scope" @(
    "new", "document",
    "--from-nexus", "${nexus}:1"
)

Test-VSlices "06-discovery-after-scope" @(
    "discovery", "nexus", $nexus
)

# 5. Materializar segunda recomendación
Test-VSlices "07-create-behavior" @(
    "new", "document",
    "--from-nexus", "${nexus}:2"
)

Test-VSlices "08-discovery-after-behavior" @(
    "discovery", "nexus", $nexus
)

# 6. Leer documentos creados
Test-VSlices "09-discovery-scope" @(
    "discovery", "document", "$nexus/scope"
)

Test-VSlices "10-discovery-behavior" @(
    "discovery", "document", "$nexus/behavior"
)

# 7. Prueba negativa: recomendación ya utilizada
Test-VSlices "11-duplicate-recommendation" @(
    "new", "document",
    "--from-nexus", "${nexus}:1"
) $true

# 8. Prueba negativa: selección inexistente
Test-VSlices "12-invalid-selection" @(
    "new", "document",
    "--from-nexus", "${nexus}:999"
) $true

# 9. Prueba negativa: Nexus inexistente
Test-VSlices "13-missing-nexus" @(
    "discovery", "nexus", "nexus-que-no-existe"
) $true

# 10. Relación con un documento generado
Test-VSlices "14-create-related-note" @(
    "new", "support-note", "prueba-nexus-nota",
    "--kind", "draft",
    "--target", "Observaciones sobre la capacidad"
)

Test-VSlices "15-relate-nexus-note" @(
    "relate", $nexus,
    "--to", "prueba-nexus-nota",
    "--role", "Aporta observaciones complementarias"
)

Test-VSlices "16-discovery-nexus-related" @(
    "discovery", "nexus", $nexus
)

Test-VSlices "17-discovery-note-related" @(
    "discovery", "support-note", "prueba-nexus-nota"
)

# 11. Verificar que no se repita la relación
Test-VSlices "18-duplicate-relation" @(
    "relate", $nexus,
    "--to", "prueba-nexus-nota",
    "--role", "Relación duplicada"
) $true

# 12. Capturar artefactos físicos
Get-ChildItem $nexus -Recurse -File |
    Select-Object FullName, Length |
    Format-Table -AutoSize |
    Out-String |
    Set-Content "$evidence/19-artifacts.txt"

# 13. Resumen
$results | Format-Table -AutoSize

$results |
    ConvertTo-Json -Depth 4 |
    Set-Content "$evidence/results.json" -Encoding utf8

$failed = @($results | Where-Object { -not $_.Passed })

Write-Host "`nTotal: $($results.Count)"
Write-Host "Passed: $($results.Count - $failed.Count)"
Write-Host "Failed: $($failed.Count)"

# 14. Subir evidencia y artefactos a GitHub
git add -- $evidence
git add -- $nexus
git add -- "prueba-nexus-nota.md"

git status --short

if ($failed.Count -eq 0) {
    git commit -m "test: capture nexus lifecycle and relational evidence"
    if ($LASTEXITCODE -eq 0) {
        git push
    }
} else {
    Write-Host "`nHay pruebas fallidas. Evidencia conservada; no se realizó commit." -ForegroundColor Yellow
}
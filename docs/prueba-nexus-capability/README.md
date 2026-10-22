---
artifact:
  kind: nexus
  type: vslices.capability
  scope: capability
  target: "Sistema de solicitudes"

metadata:
  status: draft
  relates:
    - relation: related
      target: vslices-scope.md
      kind: document
      type: vslices.scope
      role: "Define los límites de la capacidad"
      recommendation: "1"
      recommendation-context: "485C1B34D87231728BF3012A6532ABE4CDB9620E9BB6D4FB3F311B85D0583E8F"
    - relation: related
      target: vslices-behavior.md
      kind: document
      type: vslices.behavior
      role: "Explica qué debe ocurrir al ejercer la capacidad"
      recommendation: "2"
      recommendation-context: "485C1B34D87231728BF3012A6532ABE4CDB9620E9BB6D4FB3F311B85D0583E8F"
    - relation: related
      target: "../prueba-nexus-nota.md"
      kind: support-note
      type: vslices.draft
      role: "Aporta observaciones complementarias"

tooling:
  version: build16.1330
  schema:
    version: 0.1.0
  template:
    name: vslices.capability.nexus
    version: "0.1.0"
---

# Nexus vslices.capability de Sistema de solicitudes

## Artifacts asociados

<!-- vslices:associated-artifacts -->
| Artifact | Utilidad | Link |
| --- | --- | --- |
| vslices-scope | Define los límites de la capacidad | [vslices-scope.md](vslices-scope.md) |
| vslices-behavior | Explica qué debe ocurrir al ejercer la capacidad | [vslices-behavior.md](vslices-behavior.md) |
| prueba-nexus-nota | Aporta observaciones complementarias | [../prueba-nexus-nota.md](../prueba-nexus-nota.md) |
<!-- /vslices:associated-artifacts -->


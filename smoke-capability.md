---
artifact:
  kind: nexus
  type: capability
  scope: capability
  target: "Smoke capability"

metadata:
  status: draft
  relates:
    - relation: related
      target: smoke-capability-behavior.md
      kind: document
      type: behavior
      role: "Explica qué debe ocurrir al ejercer la capacidad"
      recommendation: "2"
      recommendation-context: "2779D77A8CD1C355D34B16DAD4C2C6FBFB0CABBE0E2C739C152F02A542B24F60"
    - relation: related
      target: smoke-capability-scope.md
      kind: document
      type: scope
      role: "Define los límites de la capacidad"
      recommendation: "1"
      recommendation-context: "2779D77A8CD1C355D34B16DAD4C2C6FBFB0CABBE0E2C739C152F02A542B24F60"
    - relation: related
      target: smoke-arbitrary-context.md
      kind: document
      type: context
      role: "Preserva contexto arbitrario del smoke"

tooling:
  version: build10.1130
  schema:
    version: 0.1.0
  template:
    name: capability.nexus
    version: "0.1.0"
---

# Nexus capability de Smoke capability

## Artifacts asociados

<!-- vslices:associated-artifacts -->
| Artifact | Utilidad | Link |
| --- | --- | --- |
| smoke-capability-behavior | Explica qué debe ocurrir al ejercer la capacidad | [smoke-capability-behavior.md](smoke-capability-behavior.md) |
| smoke-capability-scope | Define los límites de la capacidad | [smoke-capability-scope.md](smoke-capability-scope.md) |
| smoke-arbitrary-context | Preserva contexto arbitrario del smoke | [smoke-arbitrary-context.md](smoke-arbitrary-context.md) |
<!-- /vslices:associated-artifacts -->


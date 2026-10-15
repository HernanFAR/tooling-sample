# VSlices Ruleset Standard

VSlices Ruleset Standard is the official, external source of lowering knowledge used by VSlices Tooling.

It describes how semantic structures represented by VSIR may be materialized for concrete targets without embedding target-specific lowering knowledge in the `vslices` executable.

The intended boundary is:

```text
VSIR
  = semantic source

VSlices Ruleset Standard
  = source-owned revisable lowering knowledge

VSlices Tooling
  = execution and orchestration mechanisms

project/.vslices/rulesets/<name>
  = named, imported lowering snapshot

project/.vslices/rulesets/local/<name>
  = original, project-owned editable standard

project/.vslices/extensions
  = project-owned semantic extension overlay
```

## Why this repository exists

Lowering knowledge is expected to evolve as VSIR grows and as target materialization is better understood. Keeping that knowledge outside the CLI allows rules to change, be reviewed, and be experimented with without requiring a new tooling release for every target mapping change.

The CLI should therefore know how to discover, load, validate, and execute supported classes of rules, while concrete target mappings live here.

A missing rule is not permission for the CLI or an interpreter to guess. Unsupported or unresolved lowering must remain explicit.

## Current status

This repository is experimental. The supported surface is intentionally small and exists to validate the boundary between tooling mechanisms and lowering knowledge.

Current C# rules include deterministic expression mappings for consumer-proven intrinsics such as `non-empty`, `not-whitespace`, `length-at-most`, ordinal equality and `trim`.

## Layout

```text
manifest.yaml
manifest.schema.json
csharp/
  intrinsics.yaml
```

`manifest.yaml` discovers target-specific rule files. `manifest.schema.json` describes that distributable snapshot. Project semantic extensions are deliberately **not** part of this manifest.

## Named, coexisting installations

`manifest.yaml` declares the official standard identity:

```yaml
kind: vslices-ruleset
version: 0.1
name: vslices
```

The repository/CLI family is **Ruleset Standard**. The lower-level manifest `kind:
vslices-ruleset` is retained for schema compatibility; renaming the repository
does not imply rewriting the rule language.

VSlices Tooling manages the lifecycle of multiple named installations. A consumer
can override the installation name without mutating this source manifest:

```text
.vslices/rulesets/
  vslices/      # imported managed snapshot
  local/
    my-team/                    # original, editable local standard
```

A new local standard can begin as `targets: {}` with no lowering rules. Adding
a target to a local standard introduces target-specific rules under its own
manifest. Empty standards are useful for progressive authoring but cannot
perform target lowering until they admit validated rules.

Separate rule sets may coexist, but **no implicit precedence** exists for
overlapping `node` identifiers. Tooling must diagnose a collision instead of
quietly replacing one definition with another. Project-owned extensions remain
orthogonal under `.vslices/extensions`, never inside a distributable source.

The historical single installation path `.vslices/ruleset` is recognized by
Tooling during transition. The old command `vslices update ruleset` retains
legacy meaning; `vslices new ruleset-standard --origin` installs named standards
under the new layout.

## Evolution principle

A useful working distinction is:

- when VSlices gains a new operational capability, `vslices/tooling` may need to change;
- when VSlices learns a new way to lower already-recognized core semantic structure, this Ruleset should usually change instead;
- when one project explicitly admits custom semantic vocabulary, that declaration belongs to the project's `.vslices/extensions` overlay rather than this distributable Ruleset snapshot.

The Ruleset is not intended to become an unrestricted plugin or package system. New rule execution primitives should be introduced only when concrete VSIR structures demonstrate the need for them.

## Longer-term validation

The Ruleset should be exercised through deterministic, reproducible tests in VSlices Tooling. A long-term goal is for VSlices projects, including the tooling itself where appropriate, to increasingly describe representable semantics through `.vsir` artifacts and use the same lowering pipeline they provide to other projects.

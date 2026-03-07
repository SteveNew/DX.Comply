# Current Status

## Purpose

This document preserves the current implementation context for the ongoing
transition from an artefact-scan-centric SBOM generator to a build-evidence-
driven Delphi analysis pipeline.

Date: 2026-03-07

## Confirmed Project Decisions

- License for generated project code: MIT
- Tests should be generated and maintained
- Deep Evidence is MAP-first
- Build evidence is the truth model; static search-path scanning remains a fallback

## Completed Implementation Slices

### 1. Build-evidence contracts

Implemented in `DX.Comply.BuildEvidence.Intf.pas`:

- evidence source model
- unit evidence model
- origin model
- confidence model
- composition evidence container types

### 2. Project metadata expansion

Implemented in `DX.Comply.Engine.Intf.pas` and `DX.Comply.ProjectScanner.pas`:

- resolved search paths
- unit scope names
- output directories for DCU, DCP, and BPL
- expected map file path
- scanner warnings transport

### 3. Build-evidence reader

Implemented in `DX.Comply.BuildEvidence.Reader.pas`:

- project metadata evidence items
- expected map-file evidence item
- map-file derived unit evidence when a detailed map exists

### 4. MAP reader

Implemented in `DX.Comply.MapFile.Reader.pas`:

- extracts unit names from detailed Delphi MAP files
- uses linker output as first-class evidence instead of treating it as a side note

### 5. Initial unit resolver

Implemented in `DX.Comply.UnitResolver.pas`:

- creates first `TResolvedUnitInfo` entries from `besMapFile`
- merges project and evidence warnings
- uses conservative default classification for unresolved representation/origin details

### 6. First Build-Orchestrator slice

Implemented in `DX.Comply.BuildOrchestrator.pas` and integrated into `DX.Comply.Engine.pas`:

- deterministic Deep-Evidence build-plan creation
- optional explicit build step before evidence collection
- forced detailed MAP generation via additional MSBuild properties
- script integration through `build/DelphiBuildDPROJ.ps1`
- config support for:
  - `deepEvidence.build`
  - `deepEvidence.delphiVersion`

## Current Engine Pipeline

`TDxComplyGenerator.Generate` currently follows this high-level flow:

1. validate project
2. scan project metadata
3. optionally ensure a Deep-Evidence build
4. read build evidence
5. resolve composition evidence
6. scan build output artefacts
7. write SBOM

This means the engine can now consume existing MAP evidence or, in Deep-
Evidence mode, actively try to create the required build inputs first.

## Verification Status

### Verified

- Delphi IDE diagnostics for the changed source files reported no issues
- the Build-Orchestrator files were integrated into the package and test projects
- `DelphiBuildDPROJ.ps1` accepts `AdditionalMSBuildProperties`
- the new DUnitX tests for the first Build-Orchestrator slice are present

### Known environment blocker

Real Delphi compilation is currently blocked on this machine because the build
script fails with:

- `No Delphi installation found`

This is an environment issue, not currently a confirmed code issue.

## Important Current Limitations

- MAP-derived membership is available, but representation resolution is still incomplete
- origin classification is not implemented yet
- evidence sidecar output is not implemented yet
- Deep-Evidence CLI switches are not exposed yet
- end-to-end validation with a real Delphi installation is still pending

## Next Planned Steps

### Recommended next implementation order

1. refine representation resolution for map-derived units
   - distinguish `.pas`, `.dcu`, `.dcp`, `.bpl`, and `unknown`
2. implement `OriginClassifier`
   - RTL
   - VCL
   - FMX
   - local project
   - third-party
   - unknown
3. implement `EvidenceWriter`
   - likely `bom.evidence.json`
4. expose Deep-Evidence switches in the CLI/config UX where useful
5. run end-to-end verification on a machine with Delphi installed

## Files Most Relevant for the Next Session

- `docs/ImplementationPlan.md`
- `docs/BuildEvidenceDesign.md`
- `src/DX.Comply.Engine.Intf.pas`
- `src/DX.Comply.ProjectScanner.pas`
- `src/DX.Comply.BuildEvidence.Intf.pas`
- `src/DX.Comply.BuildEvidence.Reader.pas`
- `src/DX.Comply.MapFile.Reader.pas`
- `src/DX.Comply.UnitResolver.pas`
- `src/DX.Comply.BuildOrchestrator.pas`
- `src/DX.Comply.Engine.pas`
- `tests/DX.Comply.Tests.BuildOrchestrator.pas`

## Last Relevant Commits

- `511e97d` - feat: add build evidence contracts and reader
- `2fa0b7c` - feat: add initial unit resolver pipeline
- `c26894b` - feat: add map-driven deep evidence seeding

The next commit after this document should capture the first Build-Orchestrator
slice plus this status handover note.
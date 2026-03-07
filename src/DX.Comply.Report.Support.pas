/// <summary>
/// DX.Comply.Report.Support
/// Shared formatting helpers for human-readable compliance reports.
/// </summary>
///
/// <remarks>
/// The helper functions centralize enum-to-text mappings and summary labels so the
/// Markdown and HTML writers stay focused on layout concerns.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.Report.Support;

interface

uses
  System.SysUtils,
  DX.Comply.Engine.Intf,
  DX.Comply.BuildEvidence.Intf,
  DX.Comply.Report.Intf;

function HumanReadableReportFormatToString(AValue: THumanReadableReportFormat): string;
function SbomFormatToString(AValue: TSbomFormat): string;
function BuildEvidenceSourceKindToString(AValue: TBuildEvidenceSourceKind): string;
function UnitEvidenceKindToString(AValue: TUnitEvidenceKind): string;
function UnitOriginKindToString(AValue: TUnitOriginKind): string;
function ResolutionConfidenceToString(AValue: TResolutionConfidence): string;
function ValidationStatusText(const AData: TComplianceReportData): string;
function DeepEvidenceStatusText(const AData: TComplianceReportData): string;
function SafeText(const AValue: string; const AFallback: string = 'n/a'): string;

implementation

uses
  DX.Comply.BuildOrchestrator;

function BuildEvidenceSourceKindToString(AValue: TBuildEvidenceSourceKind): string;
begin
  case AValue of
    besProjectMetadata: Result := 'Project metadata';
    besCompilerCommandLine: Result := 'Compiler command line';
    besCompilerResponseFile: Result := 'Compiler response file';
    besCompileNotification: Result := 'Compile notification';
    besMapFile: Result := 'MAP file';
    besDcuFile: Result := 'DCU file';
    besDcpFile: Result := 'DCP file';
    besBplFile: Result := 'BPL file';
    besSearchPathFallback: Result := 'Search path fallback';
    besManualOverride: Result := 'Manual override';
  else
    Result := 'Unknown';
  end;
end;

function DeepEvidenceStatusText(const AData: TComplianceReportData): string;
begin
  if not AData.DeepEvidenceRequested then
    Exit('Not requested');
  if not AData.DeepEvidenceResult.Success then
    Exit('Failed');
  if AData.DeepEvidenceResult.Executed then
    Exit('Executed successfully');
  Result := SafeText(AData.DeepEvidenceResult.Message, 'Skipped');
end;

function HumanReadableReportFormatToString(AValue: THumanReadableReportFormat): string;
begin
  case AValue of
    hrfMarkdown: Result := 'Markdown';
    hrfHtml: Result := 'HTML';
    hrfBoth: Result := 'Markdown + HTML';
  else
    Result := 'Unknown';
  end;
end;

function ResolutionConfidenceToString(AValue: TResolutionConfidence): string;
begin
  case AValue of
    rcAuthoritative: Result := 'Authoritative';
    rcStrong: Result := 'Strong';
    rcHeuristic: Result := 'Heuristic';
    rcUnknown: Result := 'Unknown';
  else
    Result := 'Unknown';
  end;
end;

function SafeText(const AValue, AFallback: string): string;
begin
  if Trim(AValue) = '' then
    Exit(AFallback);
  Result := AValue;
end;

function SbomFormatToString(AValue: TSbomFormat): string;
begin
  case AValue of
    sfCycloneDxJson: Result := 'CycloneDX JSON';
    sfCycloneDxXml: Result := 'CycloneDX XML';
    sfSpdxJson: Result := 'SPDX JSON';
  else
    Result := 'Unknown';
  end;
end;

function UnitEvidenceKindToString(AValue: TUnitEvidenceKind): string;
begin
  case AValue of
    uekPas: Result := 'PAS';
    uekDcu: Result := 'DCU';
    uekDcp: Result := 'DCP';
    uekBpl: Result := 'BPL';
  else
    Result := 'Unknown';
  end;
end;

function UnitOriginKindToString(AValue: TUnitOriginKind): string;
begin
  case AValue of
    uokEmbarcaderoRtl: Result := 'Embarcadero RTL';
    uokEmbarcaderoVcl: Result := 'Embarcadero VCL';
    uokEmbarcaderoFmx: Result := 'Embarcadero FMX';
    uokLocalProject: Result := 'Local project';
    uokThirdParty: Result := 'Third party';
  else
    Result := 'Unknown';
  end;
end;

function ValidationStatusText(const AData: TComplianceReportData): string;
begin
  if AData.ValidationResult.IsValid then
    Exit('Passed');
  Result := 'Failed';
end;

end.
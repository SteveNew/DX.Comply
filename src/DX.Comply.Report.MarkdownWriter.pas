/// <summary>
/// DX.Comply.Report.MarkdownWriter
/// Generates human-readable compliance reports in Markdown format.
/// </summary>
///
/// <remarks>
/// The Markdown report complements the formal SBOM with a concise summary for humans:
/// project context, build/evidence quality, artefacts, resolved units and warnings.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.Report.MarkdownWriter;

interface

uses
  System.Classes,
  DX.Comply.BuildEvidence.Intf,
  DX.Comply.Engine.Intf,
  DX.Comply.Report.Intf;

type
  /// <summary>
  /// Writes a Markdown companion report.
  /// </summary>
  TMarkdownReportWriter = class(TInterfacedObject, IHumanReadableReportWriter)
  private
    function EscapeMarkdown(const AValue: string): string;
    procedure AddKeyValue(Lines: TStrings; const AKey, AValue: string);
    procedure AddArtefacts(Lines: TStrings; const AData: TComplianceReportData);
    procedure AddBuildEvidence(Lines: TStrings; const AData: TComplianceReportData);
    procedure AddCompositionEvidence(Lines: TStrings; const AData: TComplianceReportData);
    procedure AddWarnings(Lines: TStrings; const AData: TComplianceReportData);
    procedure AddValidation(Lines: TStrings; const AData: TComplianceReportData);
  public
    function Write(const AOutputPath: string; const AData: TComplianceReportData;
      const AConfig: THumanReadableReportConfig): Boolean;
    function GetFormat: THumanReadableReportFormat;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  DX.Comply.Report.Support;

procedure TMarkdownReportWriter.AddArtefacts(Lines: TStrings; const AData: TComplianceReportData);
var
  LArtefact: TArtefactInfo;
begin
  Lines.Add('## Artefacts');
  Lines.Add('| Relative Path | Type | Size | SHA-256 |');
  Lines.Add('| --- | --- | ---: | --- |');
  for LArtefact in AData.Artefacts do
    Lines.Add(Format('| %s | %s | %d | %s |', [
      EscapeMarkdown(SafeText(LArtefact.RelativePath, LArtefact.FilePath)),
      EscapeMarkdown(SafeText(LArtefact.ArtefactType)),
      LArtefact.FileSize,
      EscapeMarkdown(SafeText(LArtefact.Hash))]));
  Lines.Add('');
end;

procedure TMarkdownReportWriter.AddBuildEvidence(Lines: TStrings; const AData: TComplianceReportData);
var
  LEvidenceItem: TBuildEvidenceItem;
begin
  Lines.Add('## Build Evidence');
  Lines.Add('| Source | Display Name | Unit / Package | Detail |');
  Lines.Add('| --- | --- | --- | --- |');
  for LEvidenceItem in AData.BuildEvidence.EvidenceItems do
    Lines.Add(Format('| %s | %s | %s | %s |', [
      EscapeMarkdown(BuildEvidenceSourceKindToString(LEvidenceItem.SourceKind)),
      EscapeMarkdown(SafeText(LEvidenceItem.DisplayName)),
      EscapeMarkdown(SafeText(LEvidenceItem.UnitName, SafeText(LEvidenceItem.PackageName))),
      EscapeMarkdown(SafeText(LEvidenceItem.Detail, LEvidenceItem.FilePath))]));
  Lines.Add('');
end;

procedure TMarkdownReportWriter.AddCompositionEvidence(Lines: TStrings; const AData: TComplianceReportData);
var
  LUnit: TResolvedUnitInfo;
begin
  Lines.Add('## Composition Evidence');
  Lines.Add('| Unit | Origin | Evidence | Confidence | Location |');
  Lines.Add('| --- | --- | --- | --- | --- |');
  for LUnit in AData.CompositionEvidence.Units do
    Lines.Add(Format('| %s | %s | %s | %s | %s |', [
      EscapeMarkdown(SafeText(LUnit.UnitName)),
      EscapeMarkdown(UnitOriginKindToString(LUnit.OriginKind)),
      EscapeMarkdown(UnitEvidenceKindToString(LUnit.EvidenceKind)),
      EscapeMarkdown(ResolutionConfidenceToString(LUnit.Confidence)),
      EscapeMarkdown(SafeText(LUnit.ResolvedPath, SafeText(LUnit.ContainerPath)))]));
  Lines.Add('');
end;

procedure TMarkdownReportWriter.AddKeyValue(Lines: TStrings; const AKey, AValue: string);
begin
  Lines.Add(Format('| %s | %s |', [EscapeMarkdown(AKey), EscapeMarkdown(AValue)]));
end;

procedure TMarkdownReportWriter.AddValidation(Lines: TStrings; const AData: TComplianceReportData);
var
  LEntry: string;
begin
  Lines.Add('## Validation');
  Lines.Add('| Field | Value |');
  Lines.Add('| --- | --- |');
  AddKeyValue(Lines, 'Status', ValidationStatusText(AData));
  AddKeyValue(Lines, 'Warnings', IntToStr(Length(AData.ValidationResult.Warnings)));
  AddKeyValue(Lines, 'Errors', IntToStr(Length(AData.ValidationResult.Errors)));
  Lines.Add('');
  for LEntry in AData.ValidationResult.Errors do
    Lines.Add('- Error: ' + EscapeMarkdown(LEntry));
  for LEntry in AData.ValidationResult.Warnings do
    Lines.Add('- Warning: ' + EscapeMarkdown(LEntry));
  Lines.Add('');
end;

procedure TMarkdownReportWriter.AddWarnings(Lines: TStrings; const AData: TComplianceReportData);
var
  LWarning: string;
begin
  Lines.Add('## Warnings');
  if (not Assigned(AData.Warnings)) or (AData.Warnings.Count = 0) then
    Lines.Add('- No warnings were recorded.')
  else
    for LWarning in AData.Warnings do
      Lines.Add('- ' + EscapeMarkdown(LWarning));
  Lines.Add('');
end;

function TMarkdownReportWriter.EscapeMarkdown(const AValue: string): string;
begin
  Result := StringReplace(AValue, '|', '\|', [rfReplaceAll]);
  Result := StringReplace(Result, sLineBreak, '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '<br>', [rfReplaceAll]);
end;

function TMarkdownReportWriter.GetFormat: THumanReadableReportFormat;
begin
  Result := hrfMarkdown;
end;

function TMarkdownReportWriter.Write(const AOutputPath: string;
  const AData: TComplianceReportData; const AConfig: THumanReadableReportConfig): Boolean;
var
  Lines: TStringList;
  LWarningsCount: Integer;
begin
  ForceDirectories(TPath.GetDirectoryName(AOutputPath));
  LWarningsCount := 0;
  if Assigned(AData.Warnings) then
    LWarningsCount := AData.Warnings.Count;
  Lines := TStringList.Create;
  try
    Lines.Add('# DX.Comply Human-Readable Compliance Report');
    Lines.Add('');
    Lines.Add('## Project Overview');
    Lines.Add('| Field | Value |');
    Lines.Add('| --- | --- |');
    AddKeyValue(Lines, 'Project', SafeText(AData.ProjectInfo.ProjectName));
    AddKeyValue(Lines, 'Version', SafeText(AData.Metadata.ProductVersion, SafeText(AData.ProjectInfo.Version)));
    AddKeyValue(Lines, 'Platform', SafeText(AData.ProjectInfo.Platform));
    AddKeyValue(Lines, 'Configuration', SafeText(AData.ProjectInfo.Configuration));
    AddKeyValue(Lines, 'SBOM Format', SbomFormatToString(AData.SbomFormat));
    AddKeyValue(Lines, 'Formal SBOM', AData.SbomOutputPath);
    AddKeyValue(Lines, 'Generated At', SafeText(AData.Metadata.Timestamp, AData.CompositionEvidence.GeneratedAt));
    Lines.Add('');
    Lines.Add('## Summary');
    Lines.Add('| Metric | Value |');
    Lines.Add('| --- | ---: |');
    AddKeyValue(Lines, 'Artefacts', IntToStr(AData.Artefacts.Count));
    AddKeyValue(Lines, 'Build Evidence Items', IntToStr(AData.BuildEvidence.EvidenceItems.Count));
    AddKeyValue(Lines, 'Resolved Units', IntToStr(AData.CompositionEvidence.Units.Count));
    AddKeyValue(Lines, 'Warnings', IntToStr(LWarningsCount));
    AddKeyValue(Lines, 'Deep Evidence', DeepEvidenceStatusText(AData));
    AddKeyValue(Lines, 'Validation', ValidationStatusText(AData));
    Lines.Add('');
    AddValidation(Lines, AData);
    AddArtefacts(Lines, AData);
    if AConfig.IncludeCompositionEvidence then
      AddCompositionEvidence(Lines, AData);
    if AConfig.IncludeBuildEvidence then
      AddBuildEvidence(Lines, AData);
    if AConfig.IncludeWarnings then
      AddWarnings(Lines, AData);
    Lines.SaveToFile(AOutputPath, TEncoding.UTF8);
    Result := True;
  finally
    Lines.Free;
  end;
end;

end.
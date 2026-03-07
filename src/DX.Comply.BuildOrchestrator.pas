/// <summary>
/// DX.Comply.BuildOrchestrator
/// Orchestrates explicit Deep-Evidence builds for MAP-first analysis.
/// </summary>
///
/// <remarks>
/// The first implementation slice focuses on deterministic plan construction
/// and a minimal build execution path that invokes the shared
/// `DelphiBuildDPROJ.ps1` script with additional MSBuild properties.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.BuildOrchestrator;

interface

uses
  DX.Comply.Engine.Intf;

type
  /// <summary>
  /// Deterministic plan for an explicit Deep-Evidence build.
  /// </summary>
  TDeepEvidenceBuildPlan = record
    Enabled: Boolean;
    ShouldExecute: Boolean;
    WorkingDirectory: string;
    ScriptPath: string;
    ProjectPath: string;
    Platform: string;
    Configuration: string;
    DelphiVersion: Integer;
    ExpectedMapFilePath: string;
    AdditionalMSBuildProperties: TArray<string>;
    CommandLine: string;
  end;

  /// <summary>
  /// Result of a Deep-Evidence build orchestration attempt.
  /// </summary>
  TDeepEvidenceBuildResult = record
    Success: Boolean;
    Executed: Boolean;
    ExitCode: Integer;
    Message: string;
    CommandLine: string;
    MapFilePath: string;
  end;

  /// <summary>
  /// Orchestrates explicit build execution for Deep-Evidence collection.
  /// </summary>
  IBuildOrchestrator = interface
    ['{18BBA16E-313A-45E2-B793-0A1A8B985F42}']
    /// <summary>
    /// Creates a deterministic plan for a Deep-Evidence build.
    /// </summary>
    function CreatePlan(const AProjectInfo: TProjectInfo;
      ADeepEvidenceBuildEnabled: Boolean; ADelphiVersion: Integer): TDeepEvidenceBuildPlan;
    /// <summary>
    /// Executes the specified Deep-Evidence build plan.
    /// </summary>
    function ExecutePlan(const APlan: TDeepEvidenceBuildPlan): TDeepEvidenceBuildResult;
    /// <summary>
    /// Ensures the requested Deep-Evidence build exists and produced a map file.
    /// </summary>
    function EnsureDeepEvidenceBuild(const AProjectInfo: TProjectInfo;
      ADeepEvidenceBuildEnabled: Boolean; ADelphiVersion: Integer): TDeepEvidenceBuildResult;
  end;

  /// <summary>
  /// Implementation of IBuildOrchestrator.
  /// </summary>
  TBuildOrchestrator = class(TInterfacedObject, IBuildOrchestrator)
  private
    const
      cDetailedMapProperty = 'DCC_MapFile=3';
    /// <summary>
    /// Builds the expected repository root from the project metadata.
    /// </summary>
    function GetRepositoryRoot(const AProjectInfo: TProjectInfo): string;
    /// <summary>
    /// Quotes one command-line argument.
    /// </summary>
    function QuoteArgument(const AValue: string): string;
    /// <summary>
    /// Builds the PowerShell command line for the given plan.
    /// </summary>
    function BuildCommandLine(const APlan: TDeepEvidenceBuildPlan): string;
  public
    function CreatePlan(const AProjectInfo: TProjectInfo;
      ADeepEvidenceBuildEnabled: Boolean; ADelphiVersion: Integer): TDeepEvidenceBuildPlan;
    function ExecutePlan(const APlan: TDeepEvidenceBuildPlan): TDeepEvidenceBuildResult;
    function EnsureDeepEvidenceBuild(const AProjectInfo: TProjectInfo;
      ADeepEvidenceBuildEnabled: Boolean; ADelphiVersion: Integer): TDeepEvidenceBuildResult;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows;

function TBuildOrchestrator.BuildCommandLine(const APlan: TDeepEvidenceBuildPlan): string;
var
  LMsBuildProperty: string;
begin
  Result := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File ' +
    QuoteArgument(APlan.ScriptPath) +
    ' -ProjectPath ' + QuoteArgument(APlan.ProjectPath) +
    ' -Configuration ' + APlan.Configuration +
    ' -Platform ' + APlan.Platform;

  if APlan.DelphiVersion > 0 then
    Result := Result + ' -DelphiVersion ' + IntToStr(APlan.DelphiVersion);

  for LMsBuildProperty in APlan.AdditionalMSBuildProperties do
    Result := Result + ' -AdditionalMSBuildProperties ' + QuoteArgument(LMsBuildProperty);
end;

function TBuildOrchestrator.CreatePlan(const AProjectInfo: TProjectInfo;
  ADeepEvidenceBuildEnabled: Boolean; ADelphiVersion: Integer): TDeepEvidenceBuildPlan;
begin
  Result := Default(TDeepEvidenceBuildPlan);
  Result.Enabled := ADeepEvidenceBuildEnabled;
  Result.WorkingDirectory := GetRepositoryRoot(AProjectInfo);
  Result.ScriptPath := TPath.Combine(Result.WorkingDirectory, 'build\DelphiBuildDPROJ.ps1');
  Result.ProjectPath := AProjectInfo.ProjectPath;
  Result.Platform := AProjectInfo.Platform;
  Result.Configuration := AProjectInfo.Configuration;
  Result.DelphiVersion := ADelphiVersion;
  Result.ExpectedMapFilePath := AProjectInfo.MapFilePath;
  Result.AdditionalMSBuildProperties := [cDetailedMapProperty];
  Result.ShouldExecute := Result.Enabled and
    ((Result.ExpectedMapFilePath = '') or not TFile.Exists(Result.ExpectedMapFilePath));
  Result.CommandLine := BuildCommandLine(Result);
end;

function TBuildOrchestrator.EnsureDeepEvidenceBuild(const AProjectInfo: TProjectInfo;
  ADeepEvidenceBuildEnabled: Boolean; ADelphiVersion: Integer): TDeepEvidenceBuildResult;
var
  LPlan: TDeepEvidenceBuildPlan;
begin
  LPlan := CreatePlan(AProjectInfo, ADeepEvidenceBuildEnabled, ADelphiVersion);
  Result := ExecutePlan(LPlan);
end;

function TBuildOrchestrator.ExecutePlan(const APlan: TDeepEvidenceBuildPlan): TDeepEvidenceBuildResult;
var
  LCommandLine: string;
  LExitCode: Cardinal;
  LProcessInfo: TProcessInformation;
  LStartupInfo: TStartupInfo;
begin
  Result := Default(TDeepEvidenceBuildResult);
  Result.Success := True;
  Result.CommandLine := APlan.CommandLine;
  Result.MapFilePath := APlan.ExpectedMapFilePath;

  if not APlan.Enabled then
  begin
    Result.Message := 'Deep-Evidence build disabled.';
    Exit;
  end;

  if not APlan.ShouldExecute then
  begin
    Result.Message := 'Deep-Evidence build skipped because the expected map file already exists.';
    Exit;
  end;

  if not TFile.Exists(APlan.ScriptPath) then
  begin
    Result.Success := False;
    Result.Message := 'Build script not found: ' + APlan.ScriptPath;
    Exit;
  end;

  FillChar(LStartupInfo, SizeOf(LStartupInfo), 0);
  LStartupInfo.cb := SizeOf(LStartupInfo);
  FillChar(LProcessInfo, SizeOf(LProcessInfo), 0);

  LCommandLine := APlan.CommandLine;
  UniqueString(LCommandLine);

  if not CreateProcess(nil, PChar(LCommandLine), nil, nil, False, CREATE_NO_WINDOW,
    nil, PChar(APlan.WorkingDirectory), LStartupInfo, LProcessInfo) then
  begin
    Result.Success := False;
    Result.Message := SysErrorMessage(GetLastError);
    Exit;
  end;

  Result.Executed := True;
  try
    WaitForSingleObject(LProcessInfo.hProcess, INFINITE);
    if not GetExitCodeProcess(LProcessInfo.hProcess, LExitCode) then
      LExitCode := Cardinal(-1);
    Result.ExitCode := Integer(LExitCode);
    Result.Success := Result.ExitCode = 0;

    if Result.Success and (APlan.ExpectedMapFilePath <> '') and
       not TFile.Exists(APlan.ExpectedMapFilePath) then
    begin
      Result.Success := False;
      Result.Message := 'Build succeeded but the expected map file was not generated: ' +
        APlan.ExpectedMapFilePath;
    end
    else if Result.Success then
      Result.Message := 'Deep-Evidence build completed successfully.'
    else
      Result.Message := 'Deep-Evidence build failed with exit code ' + IntToStr(Result.ExitCode) + '.';
  finally
    CloseHandle(LProcessInfo.hThread);
    CloseHandle(LProcessInfo.hProcess);
  end;
end;

function TBuildOrchestrator.GetRepositoryRoot(const AProjectInfo: TProjectInfo): string;
var
  LProjectDir: string;
begin
  LProjectDir := AProjectInfo.ProjectDir;
  if (LProjectDir = '') and (AProjectInfo.ProjectPath <> '') then
    LProjectDir := TPath.GetDirectoryName(AProjectInfo.ProjectPath);

  if LProjectDir = '' then
    Exit('');

  Result := TPath.GetFullPath(TPath.Combine(LProjectDir, '..'));
end;

function TBuildOrchestrator.QuoteArgument(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '""', [rfReplaceAll]) + '"';
end;

end.
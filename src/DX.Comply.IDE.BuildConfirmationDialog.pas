/// <summary>
/// DX.Comply.IDE.BuildConfirmationDialog
/// Provides the confirmation dialog shown before a Deep-Evidence IDE build starts.
/// </summary>
///
/// <remarks>
/// The dialog is implemented as a regular VCL form so RAD Studio can apply its
/// standard scaling behavior without relying on a fully manual runtime layout.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.IDE.BuildConfirmationDialog;

interface

uses
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Controls,
  DX.Comply.BuildOrchestrator, System.Classes;

type
  /// <summary>
  /// Displays the confirmation UI before DX.Comply starts the build pipeline.
  /// </summary>
  TFormDXComplyBuildConfirmationDialog = class(TForm)
    TitleLabel: TLabel;
    DescriptionLabel: TLabel;
    ProjectCaptionLabel: TLabel;
    ProjectValueLabel: TLabel;
    ConfigurationCaptionLabel: TLabel;
    ConfigurationValueLabel: TLabel;
    PlatformCaptionLabel: TLabel;
    PlatformValueLabel: TLabel;
    MapCaptionLabel: TLabel;
    MapValueLabel: TLabel;
    DisablePromptCheckBox: TCheckBox;
    OkButton: TButton;
    CancelButton: TButton;
  private
    procedure InitializeDialog(const AProjectPath: string;
      const APlan: TDeepEvidenceBuildPlan);
  end;

/// <summary>
/// Shows the Deep-Evidence build confirmation dialog and returns True when the
/// user accepts the build.
/// </summary>
function ShowDXComplyBuildConfirmationDialog(const AProjectPath: string;
  const APlan: TDeepEvidenceBuildPlan; out ADisablePrompt: Boolean): Boolean;

implementation

{$R *.dfm}

uses
  System.SysUtils;

procedure TFormDXComplyBuildConfirmationDialog.InitializeDialog(
  const AProjectPath: string; const APlan: TDeepEvidenceBuildPlan);
begin
  ProjectValueLabel.Caption := ExtractFileName(AProjectPath);
  ConfigurationValueLabel.Caption := APlan.Configuration;
  PlatformValueLabel.Caption := APlan.Platform;
  MapValueLabel.Caption := APlan.ExpectedMapFilePath;
end;

function ShowDXComplyBuildConfirmationDialog(const AProjectPath: string;
  const APlan: TDeepEvidenceBuildPlan; out ADisablePrompt: Boolean): Boolean;
var
  LDialog: TFormDXComplyBuildConfirmationDialog;
begin
  ADisablePrompt := False;
  LDialog := TFormDXComplyBuildConfirmationDialog.Create(nil);
  try
    LDialog.InitializeDialog(AProjectPath, APlan);
    Result := LDialog.ShowModal = mrOk;
    if Result then
      ADisablePrompt := LDialog.DisablePromptCheckBox.Checked;
  finally
    LDialog.Free;
  end;
end;

end.

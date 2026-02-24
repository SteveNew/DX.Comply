/// <summary>
/// ExampleApp
/// Minimal console application demonstrating DX.Comply programmatic SBOM generation.
/// </summary>
///
/// <remarks>
/// Resolves the engine .dproj relative to the binary location at runtime so the
/// example works regardless of the working directory from which it is launched.
/// Build output lands in demo\build\$(Platform)\$(Config) to keep sources clean.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

program ExampleApp;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  DX.Comply.Engine,
  DX.Comply.Engine.Intf;

/// <summary>Demonstrates generating a CycloneDX SBOM using DX.Comply.</summary>
procedure RunExample;
var
  LConfig: TSbomConfig;
  LGenerator: TDxComplyGenerator;
  LProjectPath: string;
  LOutputPath: string;
begin
  // Resolve the engine .dproj relative to the example application.
  // The example app is in demo/ExampleApp/ and builds to build/Win32/Debug/
  LProjectPath := TPath.GetFullPath(
    TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..' + PathDelim + '..' + PathDelim + '..' + PathDelim +
      'src' + PathDelim + 'DX.Comply.Engine.dproj'));

  LOutputPath := TPath.GetFullPath(
    TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..' + PathDelim + '..' + PathDelim + '..' + PathDelim +
      'bom-example.json'));

  Writeln('DX.Comply Example Application');
  Writeln('==============================');
  Writeln('Project : ', LProjectPath);
  Writeln('Output  : ', LOutputPath);
  Writeln;

  if not TFile.Exists(LProjectPath) then
  begin
    Writeln('ERROR: Project file not found: ', LProjectPath);
    ExitCode := 1;
    Exit;
  end;

  LConfig := TSbomConfig.Default;
  LConfig.Platform := 'Win32';
  LConfig.Configuration := 'Debug';
  LConfig.ProductName := 'DX.Comply Engine';
  LConfig.ProductVersion := '1.0.0';
  LConfig.Supplier := 'Olaf Monien';

  LGenerator := TDxComplyGenerator.Create(LConfig);
  try
    LGenerator.OnProgress :=
      procedure(const AMessage: string; const AProgress: Integer)
      begin
        if AProgress < 0 then
          Writeln('[ERROR] ', AMessage)
        else
          Writeln(Format('[%3d%%] %s', [AProgress, AMessage]));
      end;

    if LGenerator.Generate(LProjectPath, LOutputPath) then
      Writeln(#13#10'Success! SBOM written to: ', LOutputPath)
    else
      Writeln(#13#10'ERROR: SBOM generation failed.');
  finally
    LGenerator.Free;
  end;
end;

begin
  try
    RunExample;
  except
    on E: Exception do
    begin
      Writeln('Exception: ', E.Message);
      ExitCode := 1;
    end;
  end;

  {$IFNDEF CI}
  Write(#13#10'Press <Enter> to quit.');
  Readln;
  {$ENDIF}
end.

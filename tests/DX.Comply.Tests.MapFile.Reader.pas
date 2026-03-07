/// <summary>
/// DX.Comply.Tests.MapFile.Reader
/// DUnitX tests for TMapFileReader.
/// </summary>
///
/// <remarks>
/// Uses synthetic detailed map-file snippets to verify unit extraction from
/// "Line numbers for ..." sections.
/// </remarks>
///
/// <copyright>
/// Copyright © 2026 Olaf Monien
/// Licensed under MIT
/// </copyright>

unit DX.Comply.Tests.MapFile.Reader;

interface

uses
  DUnitX.TestFramework,
  DX.Comply.MapFile.Reader;

type
  /// <summary>
  /// DUnitX fixture for the map file reader.
  /// </summary>
  [TestFixture]
  TMapFileReaderTests = class
  public
    /// <summary>
    /// The reader must extract unique unit names from line-number sections.
    /// </summary>
    [Test]
    procedure ReadUnitNames_DetailedMap_ExtractsUniqueUnitNames;
  end;

implementation

uses
  System.IOUtils,
  System.SysUtils;

procedure TMapFileReaderTests.ReadUnitNames_DetailedMap_ExtractsUniqueUnitNames;
var
  LMapContent: string;
  LMapFilePath: string;
  LUnitNames: TArray<string>;
begin
  LMapContent :=
    '  Detailed map of segments' + sLineBreak +
    sLineBreak +
    '  Line numbers for DX.Comply.Engine(DX.Comply.Engine.pas) segment CODE' + sLineBreak +
    '  Line numbers for System.SysUtils(System.SysUtils.pas) segment CODE' + sLineBreak +
    '  Line numbers for DX.Comply.Engine(DX.Comply.Engine.pas) segment DATA';

  LMapFilePath := TPath.GetTempFileName;
  try
    TFile.WriteAllText(LMapFilePath, LMapContent, TEncoding.UTF8);
    LUnitNames := TMapFileReader.ReadUnitNames(LMapFilePath);

    Assert.AreEqual(NativeInt(2), NativeInt(Length(LUnitNames)),
      'The map file reader must return unique unit names only once');
    Assert.AreEqual('DX.Comply.Engine', LUnitNames[0],
      'The first extracted unit name must match the first line-number section');
    Assert.AreEqual('System.SysUtils', LUnitNames[1],
      'The second extracted unit name must match the next unique line-number section');
  finally
    if TFile.Exists(LMapFilePath) then
      TFile.Delete(LMapFilePath);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMapFileReaderTests);

end.
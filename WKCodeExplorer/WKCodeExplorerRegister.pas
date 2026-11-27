{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit WKCodeExplorerRegister;

{$warn 5023 off : no warning about unused units}
interface

uses
  WKCodeExplorer, WKAddLocalVariableForm, WKCodeExplorerToolbar, 
  WKCodeExplOpts, WKPasteFormat, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('WKCodeExplorer', @WKCodeExplorer.Register);
end;

initialization
  RegisterPackage('WKCodeExplorer', @Register);
end.

unit WKCodeExplorerToolbar;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Buttons, IDEImagesIntf;

type
  { TWKCodeExplorerToolbar }
  TWKCodeExplorerToolbar = class(TFrame)
  published
    BtnCopy: TBitBtn;
    BtnDelete: TBitBtn;
    BtnJumpTo: TBitBtn;
    BtnPaste: TBitBtn;
    BtnRename: TBitBtn;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

constructor TWKCodeExplorerToolbar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  IDEImages.AssignImage(BtnCopy, 'laz_copy');
  IDEImages.AssignImage(BtnPaste, 'laz_paste');
  IDEImages.AssignImage(BtnDelete, 'laz_delete');
  IDEImages.AssignImage(BtnRename, 'item_rename');
  IDEImages.AssignImage(BtnJumpTo, 'menu_jumpto_section');
end;

end.

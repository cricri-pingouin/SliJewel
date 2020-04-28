unit OPTIONS;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, JEWEL, IniFiles;

type
  tForm2 = class(TForm)
    lblX: TLabel;
    scrlX: TScrollBar;
    lblY: TLabel;
    scrlY: TScrollBar;
    btnCancel: TButton;
    btnOk: TButton;
    lblXval: TLabel;
    lblYval: TLabel;
    scrlColours: TScrollBar;
    lblColours: TLabel;
    lblColoursVal: TLabel;
    btnDefault: TButton;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure scrlXChange(Sender: TObject);
    procedure scrlYChange(Sender: TObject);
    procedure scrlColoursChange(Sender: TObject);
    procedure btnDefaultClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: tForm2;

implementation

{$R *.dfm}

procedure tForm2.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure tForm2.btnDefaultClick(Sender: TObject);
begin
  scrlX.Position := 8;
  scrlY.Position := 8;
  scrlColours.Position := 6;
end;

procedure tForm2.btnOkClick(Sender: TObject);
var
  myINI: TINIFile;
begin
  Form1.BoardSizeX := scrlX.Position;
  Form1.BoardSizeY := scrlY.Position;
  Form1.NumColours := scrlColours.Position;
  //Save settings to INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliJewel.ini');
  myINI.WriteInteger('Settings', 'BoardSizeX', Form1.BoardSizeX);
  myINI.WriteInteger('Settings', 'BoardSizeY', Form1.BoardSizeY);
  myINI.WriteInteger('Settings', 'NumColours', Form1.NumColours);
  myINI.Free;
  Close;
end;

procedure tForm2.FormCreate(Sender: TObject);
begin
  scrlX.Position := Form1.BoardSizeX;
  scrlX.Max := MaxBoardSize;
  lblXval.Caption := IntToStr(scrlX.Position);
  scrlY.Position := Form1.BoardSizeY;
  scrlY.Max := MaxBoardSize;
  lblYval.Caption := IntToStr(scrlY.Position);
  scrlColours.Position := Form1.NumColours;
  lblColoursVal.Caption := IntToStr(scrlColours.Position);
end;

procedure tForm2.scrlXChange(Sender: TObject);
begin
  lblXval.Caption := IntToStr(scrlX.Position);
end;

procedure tForm2.scrlYChange(Sender: TObject);
begin
  lblYval.Caption := IntToStr(scrlY.Position);
end;

procedure tForm2.scrlColoursChange(Sender: TObject);
begin
  lblColoursVal.Caption := IntToStr(scrlColours.Position);
end;

end.


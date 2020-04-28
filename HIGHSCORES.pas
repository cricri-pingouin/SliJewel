unit HIGHSCORES;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, JEWEL;

type
  TForm3 = class(TForm)
    strngrdHS: TStringGrid;
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

procedure TForm3.FormShow(Sender: TObject);
var
  I: Integer;
begin
  strngrdHS.Cells[1, 0] := 'Name';
  strngrdHS.Cells[2, 0] := 'Jewels';
  strngrdHS.Cells[3, 0] := 'Score';
  for I := 1 to 10 do
  begin
    strngrdHS.Cells[0, I] := IntToStr(I);
    strngrdHS.Cells[1, I] := Form1.HSname[I];
    strngrdHS.Cells[2, I] := IntToStr(Form1.HSjewels[I]);
    strngrdHS.Cells[3, I] := IntToStr(Form1.HSscore[I]);
  end;
end;

end.


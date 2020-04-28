program SliJewel;

uses
  Forms,
  JEWEL in 'JEWEL.pas' {Form1},
  HIGHSCORES in 'HIGHSCORES.pas' {Form3},
  OPTIONS in 'OPTIONS.pas' {Form2};

{$R *.res}
{$SetPEFlags 1}

begin
  Application.Initialize;
  Application.Title := 'SliJewel';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.

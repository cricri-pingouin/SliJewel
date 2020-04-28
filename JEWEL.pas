unit JEWEL;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Menus, IniFiles;

type
  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    N1: TMenuItem;
    mniExit: TMenuItem;
    mniNew: TMenuItem;
    mniSep2: TMenuItem;
    mniHighscores: TMenuItem;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    ImageV1: TImage;
    ImageV2: TImage;
    ImageV3: TImage;
    ImageV4: TImage;
    ImageV5: TImage;
    ImageV6: TImage;
    ImageV7: TImage;
    ImageBlank: TImage;
    mniScore: TMenuItem;
    mniHint: TMenuItem;
    mniSep1: TMenuItem;
    mniSettings: TMenuItem;
    function QuickCheckLines(): Boolean;
    function CheckGameOver(): Boolean;
    procedure ScoreLines();
    procedure Animate(OX, OY, OBlock, DX, DY, DBlock: Integer);
    procedure FormCreate(Sender: TObject);
    procedure mniExitClick(Sender: TObject);
    procedure DrawShape(X, Y, Block: Integer);
    procedure NewGame();
    procedure GameOver();
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure mniNewClick(Sender: TObject);
    procedure mniHighscoresClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure mniHintClick(Sender: TObject);
    procedure mniSettingsClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    //High scores
    HSname: array[1..10] of string;
    HSscore: array[1..10] of DWORD;
    HSjewels: array[1..10] of DWORD;
    BoardSizeX, BoardSizeY, NumColours: Byte;
    procedure Paint; override; //Paint override needed to display new game from FormCreate
  end;

const
  BlockSize = 46; //Size of a Block in pixels; Needs to be even as animation is in 2 pixels steps
  MaxBoardSize = 20;

var
  Form1: TForm1;
  Shape: array[0..6] of^TBitmap;
  Vanish: array[1..7] of^TBitmap;
  Board: array[0..MaxBoardSize + 1, 0..MaxBoardSize + 1] of Byte; //0 and BoardSizeX+1 = fixed border
  //Scoring
  Score, Jewels: DWord;
  //Flags
  EndGame: Boolean;
  //Selected start block coordinates
  StartX, StartY: Integer;
  //Hint block coordinates (also used to test game over)
  HintOX, HintOY, HintDX, HintDY: Integer;
  CheckingLines: Boolean;

implementation

{$R *.dfm}

uses
  HIGHSCORES, OPTIONS;

function TForm1.QuickCheckLines(): Boolean;
var
  X, Y, TestShape: Byte;
begin
  for X := 1 to BoardSizeX do
  begin
    for Y := 1 to BoardSizeY do
    begin
      TestShape := Board[X, Y];
      if (Board[X, Y] > 0) then //Only check lines of actual shapes, not blanks!
      begin
        //Test horizontal
        if (Board[X - 1, Y] = TestShape) and (Board[X + 1, Y] = TestShape) then
        begin
          //Horizontal line found
          Result := True;
          Exit;
        end;
        //Test vertical
        if (Board[X, Y - 1] = TestShape) and (Board[X, Y + 1] = TestShape) then
        begin
          //Vertical line found
          Result := True;
          Exit;
        end;
      end;
    end;
  end;
  //Reached here: no lines found
  Result := False;
end;

function TForm1.CheckGameOver(): Boolean;
var
  X, Y, OBlock, DBlock: Byte;
begin
  for X := 1 to BoardSizeX do
    for Y := 1 to BoardSizeY do
    begin
      OBlock := Board[X, Y];
      if (X < BoardSizeX) then
      begin
        DBlock := Board[X + 1, Y];
        Board[X, Y] := DBlock;
        Board[X + 1, Y] := OBlock;
        if QuickCheckLines() then
        begin
          HintOX := X;
          HintOY := Y;
          HintDX := X + 1;
          HintDY := Y;
          Board[X, Y] := OBlock;
          Board[X + 1, Y] := DBlock;
          Result := False;
          Exit;
        end;
        Board[X, Y] := OBlock;
        Board[X + 1, Y] := DBlock;
      end;
      if (X > 1) then
      begin
        DBlock := Board[X - 1, Y];
        Board[X, Y] := DBlock;
        Board[X - 1, Y] := OBlock;
        if QuickCheckLines() then
        begin
          HintOX := X;
          HintOY := Y;
          HintDX := X - 1;
          HintDY := Y;
          Board[X, Y] := OBlock;
          Board[X - 1, Y] := DBlock;
          Result := False;
          Exit;
        end;
        Board[X, Y] := OBlock;
        Board[X - 1, Y] := DBlock;
      end;
      if (Y < BoardSizeY) then
      begin
        DBlock := Board[X, Y + 1];
        Board[X, Y] := DBlock;
        Board[X, Y + 1] := OBlock;
        if QuickCheckLines() then
        begin
          HintOX := X;
          HintOY := Y;
          HintDX := X;
          HintDY := Y + 1;
          Board[X, Y] := OBlock;
          Board[X, Y + 1] := DBlock;
          Result := False;
          Exit;
        end;
        Board[X, Y] := OBlock;
        Board[X, Y + 1] := DBlock;
      end;
      if (Y > 1) then
      begin
        DBlock := Board[X, Y - 1];
        Board[X, Y] := DBlock;
        Board[X, Y - 1] := OBlock;
        if QuickCheckLines() then
        begin
          HintOX := X;
          HintOY := Y;
          HintDX := X;
          HintDY := Y - 1;
          Board[X, Y] := OBlock;
          Board[X, Y - 1] := DBlock;
          Result := False;
          Exit;
        end;
        Board[X, Y] := OBlock;
        Board[X, Y - 1] := DBlock;
      end;
    end;
  Result := True;
end;

procedure TForm1.ScoreLines();
var
  LinesNum, JewelsNum: Word;
  X, Y, R, TestShape, ScoreMult: Byte;
  TestBoard: array[1..MaxBoardSize, 1..MaxBoardSize] of Boolean;
  TempVector: array[1..MaxBoardSize] of Byte;
begin
  CheckingLines := True;
  ScoreMult := 0;
  repeat
    JewelsNum := 0;
    LinesNum := 0;
    Inc(ScoreMult);
    //Initialise test board
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
        TestBoard[X, Y] := False;
    //Check for lines
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
      begin
        TestShape := Board[X, Y];
        if (Board[X, Y] > 0) then //Only check lines of actual shapes, not blanks!
        begin
          //Test horizontal
          if (Board[X - 1, Y] = TestShape) and (Board[X + 1, Y] = TestShape) then
          begin
            Inc(LinesNum);
            TestBoard[X - 1, Y] := True;
            TestBoard[X, Y] := True;
            TestBoard[X + 1, Y] := True;
          end;
          //Test vertical
          if (Board[X, Y - 1] = TestShape) and (Board[X, Y + 1] = TestShape) then
          begin
            Inc(LinesNum);
            TestBoard[X, Y - 1] := True;
            TestBoard[X, Y] := True;
            TestBoard[X, Y + 1] := True;
          end;
        end;
      end;
    //No lines formed? Exit
    if LinesNum = 0 then
    begin
      CheckingLines := False;
      Exit;
    end;
    //Count jewels
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
        if (TestBoard[X, Y] = True) then
        begin
          Inc(JewelsNum);
          Board[X, Y] := 0;
        end;
    //Update lines completed count
    Inc(Jewels, JewelsNum);
    //Update score depending on number of lines and iteration multiplier
    Inc(Score, LinesNum * 30 * ScoreMult);
    mniScore.Caption := 'Score = ' + IntToStr(Score);
    //Animate 7 frames, 40 ms each = 0.28s total
    for R := 1 to 7 do
    begin
      Application.ProcessMessages;
      for Y := 1 to BoardSizeY do
        for X := 1 to BoardSizeX do
          if (TestBoard[X, Y] = True) then
            Form1.Canvas.Draw((X - 1) * BlockSize, (Y - 1) * BlockSize, Vanish[R]^);
      Sleep(40);
    end;
    //Remove all scored blocks
    //If I can ever be bothered to animate new balls dropping in, it will go below
    for X := 1 to BoardSizeX do
    begin
      //Initialise temp column
      for Y := 1 to BoardSizeY do
        TempVector[Y] := Random(NumColours) + 1;
      //Populate temp vector with only non-zero values
      R := BoardSizeY + 1;
      for Y := BoardSizeY downto 1 do
        if (Board[X, Y] > 0) then
        begin
          Dec(R);
          TempVector[R] := Board[X, Y];
        end;
      //Copy whole temp column into destination
      for Y := 1 to BoardSizeY do
        Board[X, Y] := TempVector[Y];
    end;
    //ReDraw board
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
        DrawShape(X, Y, Board[X, Y]);
  until (LinesNum = 0);
  CheckingLines := False;
end;

procedure TForm1.Animate(OX, OY, OBlock, DX, DY, DBlock: Integer);
var
  i, Steps: Byte;
begin
  Steps := BlockSize div 2;
  if (DX = OX + 1) then //Right
    for i := 1 to Steps do
    begin
      Form1.Canvas.Draw((DX - 1) * BlockSize, (DY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize, (OY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((DX - 1) * BlockSize - (i * 2), (DY - 1) * BlockSize, Shape[DBlock]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize + (i * 2), (OY - 1) * BlockSize, Shape[OBlock]^);
      Sleep(10);
    end;
  if (DX = OX - 1) then //Left
    for i := 1 to Steps do
    begin
      Form1.Canvas.Draw((DX - 1) * BlockSize, (DY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize, (OY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((DX - 1) * BlockSize + (i * 2), (DY - 1) * BlockSize, Shape[DBlock]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize - (i * 2), (OY - 1) * BlockSize, Shape[OBlock]^);
      Sleep(10);
    end;
  if (DY = OY + 1) then //Down
    for i := 1 to Steps do
    begin
      Form1.Canvas.Draw((DX - 1) * BlockSize, (DY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize, (OY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((DX - 1) * BlockSize, (DY - 1) * BlockSize - (i * 2), Shape[DBlock]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize, (OY - 1) * BlockSize + (i * 2), Shape[OBlock]^);
      Sleep(10);
    end;
  if (DY = OY - 1) then //Up
    for i := 1 to Steps do
    begin
      Form1.Canvas.Draw((DX - 1) * BlockSize, (DY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize, (OY - 1) * BlockSize, Shape[0]^);
      Form1.Canvas.Draw((DX - 1) * BlockSize, (DY - 1) * BlockSize + (i * 2), Shape[DBlock]^);
      Form1.Canvas.Draw((OX - 1) * BlockSize, (OY - 1) * BlockSize - (i * 2), Shape[OBlock]^);
      Sleep(10);
    end;
end;

procedure TForm1.DrawShape(X, Y, Block: Integer);
begin
  Form1.Canvas.Draw((X - 1) * BlockSize, (Y - 1) * BlockSize, Shape[Block]^);
end;

procedure TForm1.NewGame();
var
  X, Y: ShortInt;
  NoLines: boolean;
  TestShape: Byte;
begin
  CheckingLines := True; //Just to prevent user messing about while initialising
  Jewels := 0;
  Score := 0;
  mniScore.Caption := 'Score = 0';
  mniHint.Enabled := True;
  //Initialise board and borders
  for X := 0 to MaxBoardSize + 1 do
    for Y := 0 to MaxBoardSize + 1 do
      Board[X, Y] := 9; //Use 9 so that it's not any shape to avoid confusion when checking lines
  //Set board
  Form1.ClientHeight := BoardSizeX * BlockSize;
  Form1.ClientWidth := BoardSizeY * BlockSize;
  Randomize;
  repeat
    for X := 1 to BoardSizeX do
      for Y := 1 to BoardSizeY do
        Board[X, Y] := Random(NumColours) + 1;
    //Make sure there are no lines completed on start!
    //Trimmed down version of CheckLines
    repeat
      NoLines := True;
      //Check for lines
      for X := 1 to BoardSizeX do
        for Y := 1 to BoardSizeY do
        begin
          TestShape := Board[X, Y];
          if (Board[X, Y] > 0) then //Only check lines of actual shapes, not blanks!
          begin
          //Test horizontal
            if (Board[X - 1, Y] = TestShape) and (Board[X + 1, Y] = TestShape) then
            begin
              NoLines := False;
              Board[X, Y] := Random(NumColours) + 1; //Line! Replace block!
            end;
          //Test vertical
            if (Board[X, Y - 1] = TestShape) and (Board[X, Y + 1] = TestShape) then
            begin
              NoLines := False;
              Board[X, Y] := Random(NumColours) + 1;
            end;
          end;
        end;
    until NoLines; //No lines...
  until not CheckGameOver(); //... but not game over!
  //Draw board
  for X := 1 to BoardSizeX do
    for Y := 1 to BoardSizeY do
      DrawShape(X, Y, Board[X, Y]);
  CheckingLines := False;
  EndGame := False;
end;

procedure TForm1.GameOver();
var
  X, Y: ShortInt;
  //High score
  myINI: TINIFile;
  WinnerName: string;
begin
  EndGame := True;
  mniHint.Enabled := False;
  //Game over, fill board
  Application.ProcessMessages;
  //Highscore?
  for X := 1 to 10 do
  begin
    if (Score > HSscore[X]) then
    begin
      //Get name
      WinnerName := InputBox('You''re Winner!', 'You placed #' + IntToStr(X) + ' with your score of ' + IntToStr(Score) + '.' + slinebreak + 'Enter your name:', HSname[1]);
      //Shift high scores downwards; If placed 10, skip as we'll simply overwrite last score
      if X < 10 then
        for Y := 10 downto X + 1 do
        begin
          HSname[Y] := HSname[Y - 1];
          HSscore[Y] := HSscore[Y - 1];
          HSjewels[Y] := HSjewels[Y - 1];
        end;
      //Set new high score
      HSname[X] := WinnerName;
      HSscore[X] := Score;
      HSjewels[X] := Jewels;
      //Save high scores to INI file
      myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliJewel.ini');
      for Y := 1 to 10 do
      begin
        myINI.WriteString('HighScores', 'Name' + IntToStr(Y), HSname[Y]);
        myINI.WriteInteger('HighScores', 'Score' + IntToStr(Y), HSscore[Y]);
        myINI.WriteInteger('HighScores', 'Jewels' + IntToStr(Y), HSjewels[Y]);
      end;
      //Close INI file
      myINI.Free;
      //Exit so that we only get 1 high score!
      Exit;
    end;
  end;
  //Reached here: game over and no high score
  ShowMessage('No more moves, and your score of ' + IntToStr(Score) + ' doesn''t make it to the high scores.');
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  myINI: TINIFile;
  i: Byte;
begin
  //Initialise shapes images
  New(Shape[0]);
  Shape[0]^ := ImageBlank.Picture.Bitmap;
  New(Shape[1]);
  Shape[1]^ := Image1.Picture.Bitmap;
  New(Shape[2]);
  Shape[2]^ := Image2.Picture.Bitmap;
  New(Shape[3]);
  Shape[3]^ := Image3.Picture.Bitmap;
  New(Shape[4]);
  Shape[4]^ := Image4.Picture.Bitmap;
  New(Shape[5]);
  Shape[5]^ := Image5.Picture.Bitmap;
  New(Shape[6]);
  Shape[6]^ := Image6.Picture.Bitmap;
  //Initialise vanishing images
  New(Vanish[1]);
  Vanish[1]^ := ImageV1.Picture.Bitmap;
  New(Vanish[2]);
  Vanish[2]^ := ImageV2.Picture.Bitmap;
  New(Vanish[3]);
  Vanish[3]^ := ImageV3.Picture.Bitmap;
  New(Vanish[4]);
  Vanish[4]^ := ImageV4.Picture.Bitmap;
  New(Vanish[5]);
  Vanish[5]^ := ImageV5.Picture.Bitmap;
  New(Vanish[6]);
  Vanish[6]^ := ImageV6.Picture.Bitmap;
  New(Vanish[7]);
  Vanish[7]^ := ImageV7.Picture.Bitmap;
  EndGame := True;
  //Initialise options from INI file
  myINI := TINIFile.Create(ExtractFilePath(Application.EXEName) + 'SliJewel.ini');
  BoardSizeX := myINI.ReadInteger('Settings', 'BoardSizeX', 8);
  BoardSizeY := myINI.ReadInteger('Settings', 'BoardSizeY', 8);
  NumColours := myINI.ReadInteger('Settings', 'NumColours', 6);
  //Read high scores from INI file
  for i := 1 to 10 do
  begin
    HSname[i] := myINI.ReadString('HighScores', 'Name' + IntToStr(i), 'Nobody');
    HSscore[i] := myINI.ReadInteger('HighScores', 'Score' + IntToStr(i), (11 - i) * 100);
    HSjewels[i] := myINI.ReadInteger('HighScores', 'Jewels' + IntToStr(i), (11 - i) * 10);
  end;
  myINI.Free;
  NewGame();
end;

procedure TForm1.Paint;
//Paint override needed, otherwise won't display game if started from FormCreate
begin
  NewGame();
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TForm1.mniNewClick(Sender: TObject);
begin
  NewGame();
end;

procedure TForm1.mniSettingsClick(Sender: TObject);
begin
  if Form2.visible = false then
    Form2.show
  else
    Form2.hide;
end;

procedure TForm1.mniHintClick(Sender: TObject);
begin
  Animate(HintOX, HintOY, Board[HintOX, HintOY], HintDX, HintDY, Board[HintDX, HintDY]);
  Animate(HintOX, HintOY, Board[HintDX, HintDY], HintDX, HintDY, Board[HintOX, HintOY]);
end;

procedure TForm1.mniExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.mniHighscoresClick(Sender: TObject);
begin
  if Form3.visible = false then
    Form3.show
  else
    Form3.hide;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if EndGame then
    Exit;
  StartX := X;
  StartY := Y;
end;

procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  //Coordinates
  DeltaX, DeltaY, OrigX, OrigY, DestX, DestY: Integer;
  //Blocks colours
  OrigBlock, DestBlock: Byte;
begin
  if EndGame or CheckingLines then
    Exit;
  DeltaX := StartX - X;
  DeltaY := StartY - Y;
  if (DeltaX = 0) or (DeltaY = 0) then
    Exit; //No mouse movement = exit
  OrigX := StartX div BlockSize + 1;
  OrigY := StartY div BlockSize + 1;
  DestX := OrigX;
  DestY := OrigY;
  //Horizontal move
  if (Abs(DeltaX) > Abs(DeltaY)) then
    if (DeltaX < 0) then
      Inc(DestX)  //Right
    else
      Dec(DestX); //Left
  //Move vertically
  if (Abs(DeltaX) < Abs(DeltaY)) then
    if (DeltaY < 0) then
      Inc(DestY)  //Up
    else
      Dec(DestY); //Down
  //Trying to drag outside board? Exit
  if (DestX < 1) or (DestX > BoardSizeX) or (DestY < 1) or (DestY > BoardSizeY) then
    Exit;
  //Animate
  OrigBlock := Board[OrigX, OrigY];
  DestBlock := Board[DestX, DestY];
  Animate(OrigX, OrigY, OrigBlock, DestX, DestY, DestBlock);
  //Commit to test for lines
  Board[OrigX, OrigY] := DestBlock;
  Board[DestX, DestY] := OrigBlock;
  //Will it make at least one line?
  if not QuickCheckLines() then
  begin
    //No: reverse animation
    Animate(OrigX, OrigY, DestBlock, DestX, DestY, OrigBlock);
    //Reverse blocks
    Board[OrigX, OrigY] := OrigBlock;
    Board[DestX, DestY] := DestBlock;
  end
  else
  begin
    ScoreLines();
    //Check game over
    if CheckGameOver() then
      GameOver();
  end;
end;

end.


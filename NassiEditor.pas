unit NassiEditor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, PNGImage, Generics.Collections, Jpeg, Math,
  Vcl.Grids, FileCtrl, SHDocVw, System.ImageList, Vcl.ImgList,
  Vcl.ComCtrls, Vcl.ToolWin;

type
  TMyGridType = (tNone, tBase, tBase2, tCaption, tIf, tWhile, tUntil, tSwitch);
  TMyComponentType = (tText, tSpace, tAdd, tUp, tDown, tClose, tLeft);
  TFileForm = (png, Jpeg, bmp, tiff);

  TInfoToSave = record
    location: string;
    fileForm: TFileForm;
  end;

  TLogs = record
    data: string[10];
    time: string[10];
    fileName: string[50];
    fileDir: string[100];
    fileType: string[10];
  end;

  TMyComponent = class
    Typee: TMyComponentType;
    Caption: string;
    ClickParent: tObject;
    constructor Create(const Typee: TMyComponentType;
      const ClickParent: tObject);
  end;

  TMyGrid = class
    Typee: TMyGridType;
    Width: Integer;
    Height: Integer;
    RowCount: Integer;
    ColumnCount: Integer;
    Components: TList<TList<tObject>>;
    ComponentsLeft: TList<TList<Integer>>;
    ComponentsTop: TList<TList<Integer>>;
    ComponentsWidth: TList<TList<Integer>>;
    ComponentsHeight: TList<TList<Integer>>;
    constructor Create(const Typee: TMyGridType;
      const RowCount, ColumnCount: Integer);
  end;

  TMainForm = class(TForm)
    Image: TImage;
    ImageList: TImageList;
    Panel: TPanel;
    ToolBar1: TToolBar;
    SaveButton: TToolButton;
    ShowAgrButton: TToolButton;
    ShowLogsButton: TToolButton;
    ToolBar2: TToolBar;
    ExitButton: TToolButton;
    TrackBar: TTrackBar;
    ShowReadMeBtn: TToolButton;
    procedure FormCreate(Sender: tObject);
    procedure Calc(const Sender: TMyGrid);
    procedure DrawGrid(const Sender: TMyGrid; const x, y: Integer);
    procedure ImageClick(const Sender: tObject);
    procedure SaveRes(info: TInfoToSave);
    procedure FormKeyDown(Sender: tObject; var Key: Word; Shift: TShiftState);
    procedure InputInfoToSave;
    procedure SaveLogs(info: string);
    procedure ShowAgreement;
    procedure FormResize(Sender: tObject);
    procedure SaveButtonClick(Sender: tObject);
    procedure ShowAgrButtonClick(Sender: tObject);
    procedure ShowLogsButtonClick(Sender: tObject);
    procedure ExitButtonClick(Sender: tObject);
    procedure ScrollBoxMouseWheel(Sender: tObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure ShowReadME;
    procedure ShowReadMeBtnClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;
  Grid: TMyGrid;
  h, h2, ClickParentRow: Integer;
  isFind: Boolean;

implementation

{$R *.dfm}

constructor TMyComponent.Create(const Typee: TMyComponentType;
  const ClickParent: tObject);
begin
  self.Typee := Typee;
  self.Caption := '';
  self.ClickParent := ClickParent;
end;

constructor TMyGrid.Create(const Typee: TMyGridType;
  const RowCount, ColumnCount: Integer);
var
  i, j: Integer;
begin

  // Initialising grid parameters
  self.Typee := Typee;
  self.Width := 0;
  self.Height := 0;
  self.RowCount := RowCount;
  self.ColumnCount := ColumnCount;

  self.Components := TList < TList < tObject >>.Create;
  self.ComponentsLeft := TList < TList < Integer >>.Create;
  self.ComponentsTop := TList < TList < Integer >>.Create;
  self.ComponentsWidth := TList < TList < Integer >>.Create;
  self.ComponentsHeight := TList < TList < Integer >>.Create;

  for i := 0 to RowCount - 1 do
  begin
    self.Components.Add(TList<tObject>.Create);
    self.ComponentsLeft.Add(TList<Integer>.Create);
    self.ComponentsTop.Add(TList<Integer>.Create);
    self.ComponentsWidth.Add(TList<Integer>.Create);
    self.ComponentsHeight.Add(TList<Integer>.Create);

    for j := 0 to ColumnCount - 1 do
    begin
      self.Components[i].Add(nil);
      self.ComponentsLeft[i].Add(0);
      self.ComponentsTop[i].Add(0);
      self.ComponentsWidth[i].Add(0);
      self.ComponentsHeight[i].Add(0);
    end;
  end;
end;

function InputCombo: Integer;
const
  blockNum = 5;
  blockTypes: array [1 .. blockNum] of string = ('Process', 'If', 'Switch',
    'While', 'Until');

var
  Form: TForm;
  Table: TGridPanel;
  i, w, h: Integer;

begin
  result := -1;

  Form := TForm.Create(Application);

  with Form do
  begin
    BorderStyle := bsDialog;
    Position := poScreenCenter;
    Caption := ' Add instruction';

    Table := TGridPanel.Create(Form);
    with Table do
    begin
      Parent := Form;
      BevelOuter := bvNone;

      RowCollection.Delete(1);
      ColumnCollection.Delete(1);
      ColumnCollection.Delete(0);

      for i := 0 to blockNum - 1 do
      begin
        ColumnCollection.Add;
        ColumnCollection[i].SizeStyle := ssAuto;
      end;

      RowCollection[0].SizeStyle := ssAuto;

      Left := 12;
      top := 12;
    end;

    w := 0;

    for i := 0 to blockNum - 1 do
    begin
      with TButton.Create(Form) do
      begin
        modalResult := -5 + i;
        Parent := Table;
        Caption := blockTypes[i + 1];
        w := w + Width;
        h := Height;
      end;
    end;

    Table.Width := w;
    ClientWidth := w + 24;

    with TButton.Create(Form) do
    begin
      Parent := Form;
      Caption := 'Cancel';
      modalResult := mrCancel;
      Cancel := True;
      Left := w + 12 - Width;
      top := 24 + h;
      Form.ClientHeight := top + Height + 12;
    end;

    if ShowModal < 0 then
      result := modalResult + 5;
  end;
end;

function CalcWidth(const Sender: TMyGrid): Integer;
var
  columns: array of Integer;
  i, j, k: Integer;

begin

  SetLength(columns, Sender.ColumnCount);

  for i := 0 to (Sender.ColumnCount - 1) do
    columns[i] := 0;

  for i := 0 to (Sender.RowCount - 1) do
  begin
    for j := 0 to (Sender.ColumnCount - 1) do
    begin
      Sender.ComponentsWidth[i][j] := 0;
      
      if Sender.Components[i][j].ClassType = TMyGrid then
      begin
        TMyGrid(Sender.Components[i][j]).Width :=
          CalcWidth(TMyGrid(Sender.Components[i][j]));

        Sender.ComponentsWidth[i][j] := TMyGrid(Sender.Components[i][j]).Width;
      end;

      if Sender.Components[i][j].ClassType = TMyComponent then
      begin
        if (TMyComponent(Sender.Components[i][j]).Typee = tText) then
          Sender.ComponentsWidth[i][j] :=
            round(MainForm.Canvas.TextWidth(TMyComponent(Sender.Components[i][j]
            ).Caption)) + round(h2 / 4)
        else if (TMyComponent(Sender.Components[i][j]).Typee = tSpace) then
          Sender.ComponentsWidth[i][j] := h2
        else
          Sender.ComponentsWidth[i][j] := h;
      end;

      if columns[j] < Sender.ComponentsWidth[i][j] then
        columns[j] := Sender.ComponentsWidth[i][j];
    end;
  end;

  for i := 0 to (Sender.RowCount - 1) do
  begin
    for j := 0 to (Sender.ColumnCount - 1) do
    begin
      Sender.ComponentsLeft[i][j] := 0;

      if j > 0 then
        for k := 0 to j - 1 do
          Sender.ComponentsLeft[i][j] := Sender.ComponentsLeft[i][j] +
            columns[k];
    end;
  end;

  result := 0;

  for i := 0 to (Sender.ColumnCount - 1) do
    result := result + columns[i];
end;

function CalcHeight(const Sender: TMyGrid): Integer;
var
  rows: array of Integer;
  i, j, k: Integer;

begin

  SetLength(rows, Sender.RowCount);

  for i := 0 to (Sender.RowCount - 1) do
    rows[i] := 0;

  for i := 0 to (Sender.RowCount - 1) do
  begin
    for j := 0 to (Sender.ColumnCount - 1) do
    begin
      Sender.ComponentsHeight[i][j] := 0;

      if Sender.Components[i][j].ClassType = TMyGrid then
      begin
        TMyGrid(Sender.Components[i][j]).Height :=
          CalcHeight(TMyGrid(Sender.Components[i][j]));

        Sender.ComponentsHeight[i][j] :=
          TMyGrid(Sender.Components[i][j]).Height;
      end;

      if Sender.Components[i][j].ClassType = TMyComponent then
      begin
        if (TMyComponent(Sender.Components[i][j]).Typee = tText) then
        begin
          if ((Sender.Typee = tSwitch) or (Sender.Typee = tIf)) and (i = 0) then
            Sender.ComponentsHeight[i][j] := MainForm.Canvas.TextHeight
              (TMyComponent(Sender.Components[i][j]).Caption) * 2 +
              round(h2 / 6)
          else
            Sender.ComponentsHeight[i][j] := MainForm.Canvas.TextHeight
              (TMyComponent(Sender.Components[i][j]).Caption) + round(h2 / 6);

        end
        else if (TMyComponent(Sender.Components[i][j]).Typee = tSpace) then
        begin
          Sender.ComponentsHeight[i][j] := h2;
        end
        else
          Sender.ComponentsHeight[i][j] := h;
      end;

      if rows[i] < Sender.ComponentsHeight[i][j] then
        rows[i] := Sender.ComponentsHeight[i][j];
    end;
  end;

  for i := 0 to (Sender.RowCount - 1) do
  begin
    for j := 0 to (Sender.ColumnCount - 1) do
    begin
      Sender.ComponentsTop[i][j] := 0;

      if i > 0 then
        for k := 0 to i - 1 do
          Sender.ComponentsTop[i][j] := Sender.ComponentsTop[i][j] + rows[k];
    end;
  end;

  result := 0;

  for i := 0 to (Sender.RowCount - 1) do
    result := result + rows[i];
end;

procedure CalcWidth2(const Sender: TMyGrid);
var
  i, j, a, b, c, m: Integer;

begin

  if Sender.Typee = tIf then
  begin
    Sender.Width := TMyGrid(TMyComponent(Sender.Components[0][0])
      .ClickParent).Width;

    if (Max(Sender.ComponentsWidth[1][0], Sender.ComponentsWidth[2][0]) <
      round(Sender.Width / 2)) and
      (Max(Sender.ComponentsWidth[1][1], Sender.ComponentsWidth[2][1]) <
      round(Sender.Width / 2)) then
    begin
      Sender.ComponentsLeft[0][1] := round(Sender.Width / 2);
      Sender.ComponentsLeft[1][1] := round(Sender.Width / 2);
      Sender.ComponentsLeft[2][1] := round(Sender.Width / 2);

      Sender.ComponentsWidth[2][0] := round(Sender.Width / 2);
      Sender.ComponentsWidth[2][1] := round(Sender.Width / 2);

      Sender.ComponentsWidth[1][0] := round(Sender.Width / 2);
      Sender.ComponentsWidth[1][1] := round(Sender.Width / 2);
    end;

    if (Max(Sender.ComponentsWidth[1][0], Sender.ComponentsWidth[2][0]) >=
      round(Sender.Width / 2)) and
      (Max(Sender.ComponentsWidth[1][1], Sender.ComponentsWidth[2][1]) <
      round(Sender.Width / 2)) then
      Sender.ComponentsWidth[2][1] := Sender.Width -
        Max(Sender.ComponentsWidth[1][0], Sender.ComponentsWidth[2][0]);

    if (Max(Sender.ComponentsWidth[1][0], Sender.ComponentsWidth[2][0]) <
      round(Sender.Width / 2)) and
      (Max(Sender.ComponentsWidth[1][1], Sender.ComponentsWidth[2][1]) >=
      round(Sender.Width / 2)) then
    begin
      Sender.ComponentsWidth[2][0] := Sender.Width -
        Max(Sender.ComponentsWidth[1][1], Sender.ComponentsWidth[2][1]);

      Sender.ComponentsLeft[2][1] := Max(Sender.ComponentsWidth[1][0],
        Sender.ComponentsWidth[2][0]);
    end;

    Sender.ComponentsLeft[1][1] := Sender.Width - MainForm.Canvas.TextWidth
      (TMyComponent(Sender.Components[1][1]).Caption) -
      round(Sender.ComponentsHeight[1][1] / 4);

    if round(Sender.ComponentsWidth[0][0] / 2) <
      Max(Sender.ComponentsWidth[1][1], Sender.ComponentsWidth[2][1]) then
      Sender.ComponentsLeft[0][0] := Max(Sender.ComponentsWidth[1][0],
        Sender.ComponentsWidth[2][0]) - round(Sender.ComponentsWidth[0][0] / 2)
    else
      Sender.ComponentsLeft[0][0] := Sender.Width -
        Sender.ComponentsWidth[0][0];
  end;

  if Sender.Typee = tSwitch then
  begin
    Sender.Width := TMyGrid(TMyComponent(Sender.Components[0][0])
      .ClickParent).Width;

    a := Sender.Width;
    b := 0;

    for i := 0 to Sender.ColumnCount - 1 do
    begin
      m := Max(Sender.ComponentsWidth[1][i], Sender.ComponentsWidth[2][i]);

      if m > Sender.Width / Sender.ColumnCount then
        a := a - m
      else
        inc(b);
    end;

    c := round(Sender.Width / Sender.ColumnCount);

    if b <> 0 then
      c := round(a / b);

    a := Sender.Width;
    b := 0;

    for i := 0 to Sender.ColumnCount - 1 do
    begin
      m := Max(Sender.ComponentsWidth[1][i], Sender.ComponentsWidth[2][i]);

      if m > c then
        a := a - m
      else
        inc(b);
    end;

    c := round(Sender.Width / Sender.ColumnCount);

    if b <> 0 then
      c := round(a / b);

    for i := 0 to Sender.ColumnCount - 1 do
    begin
      m := Max(Sender.ComponentsWidth[1][i], Sender.ComponentsWidth[2][i]);

      if m < c then
      begin
        Sender.ComponentsWidth[1][i] := c;
        Sender.ComponentsWidth[2][i] := c;
      end;

      if i > 0 then
      begin
        Sender.ComponentsLeft[1][i] := Sender.ComponentsLeft[1][i - 1] +
          Max(Sender.ComponentsWidth[1][i - 1],
          Sender.ComponentsWidth[2][i - 1]);
        Sender.ComponentsLeft[2][i] := Sender.ComponentsLeft[2][i - 1] +
          Max(Sender.ComponentsWidth[1][i - 1],
          Sender.ComponentsWidth[2][i - 1]);
      end;
    end;

    Sender.ComponentsLeft[1][Sender.ColumnCount - 1] := Sender.Width -
      MainForm.Canvas.TextWidth
      (TMyComponent(Sender.Components[1][Sender.ColumnCount - 1]).Caption) -
      round(Sender.ComponentsHeight[1][Sender.ColumnCount - 1] / 3);

    Sender.ComponentsWidth[2][Sender.ColumnCount - 1] := Sender.Width -
      Sender.ComponentsLeft[2][Sender.ColumnCount - 1];

    if (round(Sender.ComponentsWidth[0][0] / 2) <
      Max(Sender.ComponentsWidth[2][Sender.ColumnCount - 1],
      Sender.ComponentsWidth[1][Sender.ColumnCount - 1])) then
      Sender.ComponentsLeft[0][0] := Sender.ComponentsLeft[2]
        [Sender.ColumnCount - 1] - round(Sender.ComponentsWidth[0][0] / 2)
    else
      Sender.ComponentsLeft[0][0] := Sender.Width -
        Sender.ComponentsWidth[0][0];
  end;
  
  for i := 0 to (Sender.RowCount - 1) do
  begin
    if (Sender.Typee <> tIf) and (Sender.Typee <> tSwitch) then
    begin
      Sender.ComponentsWidth[i][Sender.ColumnCount - 1] := Sender.Width -
        Sender.ComponentsLeft[i][Sender.ColumnCount - 1];

      if Sender.Components[i][Sender.ColumnCount - 1].ClassType = TMyGrid then
      begin
        TMyGrid(Sender.Components[i][Sender.ColumnCount - 1]).Width :=
          Sender.ComponentsWidth[i][Sender.ColumnCount - 1];

        CalcWidth2(TMyGrid(Sender.Components[i][Sender.ColumnCount - 1]));
      end;
    end;

    for j := 0 to (Sender.ColumnCount - 1) do
      if Sender.Components[i][j].ClassType = TMyGrid then
      begin
        TMyGrid(Sender.Components[i][j]).Width := Sender.ComponentsWidth[i][j];

        CalcWidth2(TMyGrid(Sender.Components[i][j]));
      end;
  end;
end;

procedure CalcHeight2(const Sender: TMyGrid);
var
  i, j: Integer;

begin
  for i := 0 to (Sender.ColumnCount - 1) do
  begin
    Sender.ComponentsHeight[Sender.RowCount - 1][i] := Sender.Height -
      Sender.ComponentsTop[Sender.RowCount - 1][i];

    if Sender.Components[Sender.RowCount - 1][i].ClassType = TMyGrid then
    begin
      TMyGrid(Sender.Components[Sender.RowCount - 1][i]).Height :=
        Sender.ComponentsHeight[Sender.RowCount - 1][i];

      CalcHeight2(TMyGrid(Sender.Components[Sender.RowCount - 1][i]));
    end;

    for j := 0 to (Sender.RowCount - 1) do
      if Sender.Components[j][i].ClassType = TMyGrid then
      begin
        TMyGrid(Sender.Components[j][i]).Height :=
          Sender.ComponentsHeight[j][i];

        CalcHeight2(TMyGrid(Sender.Components[j][i]));
      end;
  end;
end;

procedure TMainForm.DrawGrid(const Sender: TMyGrid; const x, y: Integer);
var
  i, j, k: Integer;

begin
  with Image.Canvas do
  begin

    Pen.Color := clBlack;
    Pen.Width := 1;

    Brush.Style := bsSolid;
    Brush.Color := clBlack;

    if (Sender.Typee = tBase) or (Sender.Typee = tBase2) then
    begin

      for i := 0 to Sender.RowCount - 1 do
      begin
        Brush.Color := clBlack;

        FillRect(Trect.Create(TPoint.Create(x, y + Sender.ComponentsTop[i][0]),
          Sender.Width, Sender.ComponentsHeight[i][0]));

        Brush.Color := clWhite;

        if i = 0 then
          FillRect(Trect.Create(TPoint.Create(Pen.Width + x,
            Pen.Width + y + Sender.ComponentsTop[i][0]),
            Sender.Width - 1 * Pen.Width, Sender.ComponentsHeight[i][0] - 2 *
            Pen.Width))
        else
          FillRect(Trect.Create(TPoint.Create(Pen.Width + x,
            y + Sender.ComponentsTop[i][0]), Sender.Width - 1 * Pen.Width,
            Sender.ComponentsHeight[i][0] - 1 * Pen.Width));

      end;

      Brush.Color := clBlack;

      FillRect(Trect.Create(TPoint.Create(x + Sender.Width, y), Pen.Width,
        Sender.Height));

      Pen.Color := clWhite;

      if Sender.Typee = tBase2 then
      begin
        MoveTo(Pen.Width + x, y);
        LineTo(x + Sender.Width, y);
      end;
    end;

    for i := 0 to (Sender.RowCount - 1) do
    begin
      for j := 0 to (Sender.ColumnCount - 1) do
      begin

        if Sender.Components[i][j].ClassType = TMyGrid then
          DrawGrid(TMyGrid(Sender.Components[i][j]),
            x + Sender.ComponentsLeft[i][j], y + Sender.ComponentsTop[i][j]);

        if Sender.Components[i][j].ClassType = TMyComponent then
        begin

          Pen.Color := clGreen;

          Brush.Style := bsSolid;
          Brush.Color := clGreen;

          if (TMyComponent(Sender.Components[i][j]).Typee = tAdd) then
          begin

            Ellipse(x + Sender.ComponentsLeft[i][j] + round(h / 8),
              y + Sender.ComponentsTop[i][j] + round(h / 8),
              x + Sender.ComponentsLeft[i][j] + h - round(h / 8),
              y + Sender.ComponentsTop[i][j] + h - round(h / 8));

            Pen.Color := clWhite;
            Pen.Width := 1;

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + round(h / 4));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + h - round(h / 4));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 4),
              y + Sender.ComponentsTop[i][j] + round(h / 2));
            LineTo(x + Sender.ComponentsLeft[i][j] + h - round(h / 4),
              y + Sender.ComponentsTop[i][j] + round(h / 2));

          end

          else if (TMyComponent(Sender.Components[i][j]).Typee = tUp) then
          begin
            Pen.Color := clGreen;

            Brush.Style := bsSolid;
            Brush.Color := clGreen;

            Ellipse(x + Sender.ComponentsLeft[i][j] + round(h / 8),
              y + Sender.ComponentsTop[i][j] + round(h / 8),
              x + Sender.ComponentsLeft[i][j] + h - round(h / 8),
              y + Sender.ComponentsTop[i][j] + h - round(h / 8));

            Pen.Color := clWhite;

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + round(h / 4));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + h - round(h / 4));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + round(h / 4));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) -
              round(h / 4), y + Sender.ComponentsTop[i][j] + round(h / 4) +
              round(h / 4));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + round(h / 4));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) +
              round(h / 4), y + Sender.ComponentsTop[i][j] + round(h / 4) +
              round(h / 4));

          end

          else if (TMyComponent(Sender.Components[i][j]).Typee = tDown) then
          begin
            Pen.Color := clGreen;
            Pen.Width := 1;

            Brush.Style := bsSolid;
            Brush.Color := clGreen;

            Ellipse(x + Sender.ComponentsLeft[i][j] + round(h / 8),
              y + Sender.ComponentsTop[i][j] + round(h / 8),
              x + Sender.ComponentsLeft[i][j] + h - round(h / 8),
              y + Sender.ComponentsTop[i][j] + h - round(h / 8));

            Pen.Color := clWhite;

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + round(h / 4));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + h - round(h / 4));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + h - round(h / 4));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) -
              round(h / 4), y + Sender.ComponentsTop[i][j] + h - round(h / 4) -
              round(h / 4));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2),
              y + Sender.ComponentsTop[i][j] + h - round(h / 4));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) +
              round(h / 4), y + Sender.ComponentsTop[i][j] + h - round(h / 4) -
              round(h / 4));

          end

          else if (TMyComponent(Sender.Components[i][j]).Typee = tLeft) then
          begin
            Pen.Color := clGreen;

            Brush.Style := bsSolid;
            Brush.Color := clGreen;

            Ellipse(x + Sender.ComponentsLeft[i][j] + round(h / 8),
              y + Sender.ComponentsTop[i][j] + round(h / 8),
              x + Sender.ComponentsLeft[i][j] + h - round(h / 8),
              y + Sender.ComponentsTop[i][j] + h - round(h / 8));

            Pen.Color := clWhite;

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 4),
              y + Sender.ComponentsTop[i][j] + round(h / 2));
            LineTo(x + Sender.ComponentsLeft[i][j] + h - round(h / 4),
              y + Sender.ComponentsTop[i][j] + round(h / 2));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 4),
              y + Sender.ComponentsTop[i][j] + round(h / 2));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 4) +
              round(h / 4), y + Sender.ComponentsTop[i][j] + round(h / 2) +
              round(h / 4));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 4),
              y + Sender.ComponentsTop[i][j] + round(h / 2));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 4) +
              round(h / 4), y + Sender.ComponentsTop[i][j] + round(h / 2) -
              round(h / 4));

          end

          else if (TMyComponent(Sender.Components[i][j]).Typee = tClose) then
          begin
            Pen.Color := clRed;

            Brush.Style := bsSolid;
            Brush.Color := clRed;

            Ellipse(x + Sender.ComponentsLeft[i][j] + round(h / 8),
              y + Sender.ComponentsTop[i][j] + round(h / 8),
              x + Sender.ComponentsLeft[i][j] + h - round(h / 8),
              y + Sender.ComponentsTop[i][j] + h - round(h / 8));

            Pen.Color := clWhite;

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) -
              round(h / 6), y + Sender.ComponentsTop[i][j] + round(h / 2) -
              round(h / 6));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) +
              round(h / 6), y + Sender.ComponentsTop[i][j] + round(h / 2) +
              round(h / 6));

            MoveTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) +
              round(h / 6), y + Sender.ComponentsTop[i][j] + round(h / 2) -
              round(h / 6));
            LineTo(x + Sender.ComponentsLeft[i][j] + round(h / 2) -
              round(h / 6), y + Sender.ComponentsTop[i][j] + round(h / 2) +
              round(h / 6));

          end;

          if (TMyComponent(Sender.Components[i][j]).Typee = tText) then
          begin
            Pen.Color := clBlack;

            Brush.Style := bsSolid;
            Brush.Color := clWhite;

            TextOut(x + Sender.ComponentsLeft[i][j] + 4,
              y + Sender.ComponentsTop[i][j] + 2,
              TMyComponent(Sender.Components[i][j]).Caption);

          end;
        end;
      end;
    end;

    if Sender.Typee = tIf then
    begin
      Pen.Color := clBlack;

      MoveTo(x, y + round(Sender.ComponentsHeight[0][0] / 2));
      LineTo(x + Sender.ComponentsLeft[2][1],
        y + Sender.ComponentsHeight[0][0]);

      LineTo(x + Sender.Width, y + round(Sender.ComponentsHeight[0][0] / 2));

      MoveTo(x + Sender.ComponentsLeft[2][1],
        y + Sender.ComponentsHeight[0][0]);
      LineTo(x + Sender.ComponentsLeft[2][1], y + Sender.Height);

    end

    else if Sender.Typee = tSwitch then
    begin
      Pen.Color := clBlack;

      MoveTo(x, y + round(Sender.ComponentsHeight[0][0] / 2));
      LineTo(x + Sender.ComponentsLeft[2][Sender.ColumnCount - 1],
        y + Sender.ComponentsHeight[0][0]);

      LineTo(x + Sender.Width, y + round(Sender.ComponentsHeight[0][0] / 2));

      MoveTo(x + Sender.ComponentsLeft[2][Sender.ColumnCount - 1],
        y + Sender.ComponentsHeight[0][0]);
      LineTo(x + Sender.ComponentsLeft[2][Sender.ColumnCount - 1],
        y + Sender.Height);

      for k := 1 to Sender.ColumnCount - 1 do
      begin
        MoveTo(x + Sender.ComponentsLeft[2][k],
          y + round(Sender.ComponentsHeight[0][0] / 2 +
          (Sender.ComponentsLeft[2][k] / Sender.ComponentsLeft[2]
          [Sender.ColumnCount - 1]) * (Sender.ComponentsHeight[0][0] / 2)));
        LineTo(x + Sender.ComponentsLeft[2][k], y + Sender.Height);

      end;
    end

    else if Sender.Typee = tBase then
    begin
      Pen.Color := clBlack;

      MoveTo(x, y);
      LineTo(x + Sender.Width, y);
      LineTo(x + Sender.Width, y + Sender.Height);
    end;
  end;
end;

procedure TMainForm.Calc(const Sender: TMyGrid);
var
  tempX, tempY: Integer;

begin

  tempX := HorzScrollBar.Position;
  tempY := VertScrollBar.Position;

  Image.Visible := false;

  Grid.Width := CalcWidth(Grid);
  Grid.Height := CalcHeight(Grid);

  CalcWidth2(Grid);
  CalcHeight2(Grid);

  Image.Canvas.Brush.Color := clWhite;
  Image.Canvas.FillRect(Trect.Create(TPoint.Create(0, 0), Grid.Width,
    Grid.Height));

  Image.Picture.Bitmap.SetSize(Grid.Width, Grid.Height);

  DrawGrid(Grid, 0, 0);

  Image.Canvas.Pen.Color := clBlack;
  Image.Canvas.Pen.Width := 1;
  Image.Canvas.MoveTo(0, 0);
  Image.Canvas.LineTo(Grid.Width - Image.Canvas.Pen.Width, 0);
  Image.Canvas.LineTo(Grid.Width - Image.Canvas.Pen.Width, Grid.Height);

  Image.Width := Grid.Width;
  Image.Height := Grid.Height;

  Image.Visible := True;

  HorzScrollBar.Position := tempX;
  VertScrollBar.Position := tempY;
end;

function InsertGrid(const Sender: TMyGrid; const Typee: TMyGridType): tObject;
var
  Grid1, Grid2, Grid3, Grid4: TMyGrid;
  Comp: TMyComponent;

begin

  if Typee = tWhile then
  begin
    Grid2 := TMyGrid.Create(tWhile, 2, 2);

    Comp := TMyComponent.Create(tSpace, Grid2);
    Grid2.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tSpace, Grid2);
    Grid2.Components[1][0] := Comp;

    Comp := TMyComponent.Create(tAdd, Grid2);
    Grid2.Components[1][1] := Comp;

    Grid3 := TMyGrid.Create(tNone, 1, 4);

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := '<While instruction>';
    Grid3.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tUp, Sender);
    Grid3.Components[0][1] := Comp;

    Comp := TMyComponent.Create(tDown, Sender);
    Grid3.Components[0][2] := Comp;

    Comp := TMyComponent.Create(tClose, Sender);
    Grid3.Components[0][3] := Comp;

    Grid2.Components[0][1] := Grid3;

    result := Grid2;
  end;

  if Typee = tUntil then
  begin
    Grid2 := TMyGrid.Create(tUntil, 2, 2);

    Comp := TMyComponent.Create(tSpace, Grid2);
    Grid2.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tSpace, Grid2);
    Grid2.Components[1][0] := Comp;

    Comp := TMyComponent.Create(tAdd, Grid2);
    Grid2.Components[0][1] := Comp;

    Grid3 := TMyGrid.Create(tNone, 1, 4);

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := '<Until instruction>';
    Grid3.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tUp, Sender);
    Grid3.Components[0][1] := Comp;

    Comp := TMyComponent.Create(tDown, Sender);
    Grid3.Components[0][2] := Comp;

    Comp := TMyComponent.Create(tClose, Sender);
    Grid3.Components[0][3] := Comp;

    Grid2.Components[1][1] := Grid3;

    result := Grid2;
  end;

  if Typee = tCaption then
  begin
    Grid2 := TMyGrid.Create(tCaption, 1, 4);

    Comp := TMyComponent.Create(tText, Grid2);
    Comp.Caption := '<Process instruction>';
    Grid2.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tUp, Sender);
    Grid2.Components[0][1] := Comp;

    Comp := TMyComponent.Create(tDown, Sender);
    Grid2.Components[0][2] := Comp;

    Comp := TMyComponent.Create(tClose, Sender);
    Grid2.Components[0][3] := Comp;

    result := Grid2;
  end;

  if Typee = tIf then
  begin
    Grid2 := TMyGrid.Create(tNone, 2, 1);

    Grid3 := TMyGrid.Create(tNone, 1, 3);

    Comp := TMyComponent.Create(tUp, Sender);
    Grid3.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tDown, Sender);
    Grid3.Components[0][1] := Comp;

    Comp := TMyComponent.Create(tClose, Sender);
    Grid3.Components[0][2] := Comp;

    Grid2.Components[0][0] := Grid3;

    Grid3 := TMyGrid.Create(tIf, 3, 2);

    Comp := TMyComponent.Create(tText, Sender);
    Comp.Caption := '<If condition>';
    Grid3.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := '';
    Grid3.Components[0][1] := Comp;

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := 'True';
    Grid3.Components[1][0] := Comp;

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := 'False';
    Grid3.Components[1][1] := Comp;

    Comp := TMyComponent.Create(tAdd, Grid3);
    Grid3.Components[2][0] := Comp;

    Comp := TMyComponent.Create(tAdd, Grid3);
    Grid3.Components[2][1] := Comp;

    Grid2.Components[1][0] := Grid3;

    result := Grid2;
  end;

  if Typee = tSwitch then
  begin
    Grid2 := TMyGrid.Create(tNone, 2, 1);

    Grid3 := TMyGrid.Create(tNone, 1, 4);

    Comp := TMyComponent.Create(tLeft, Sender);
    Grid3.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tUp, Sender);
    Grid3.Components[0][1] := Comp;

    Comp := TMyComponent.Create(tDown, Sender);
    Grid3.Components[0][2] := Comp;

    Comp := TMyComponent.Create(tClose, Sender);
    Grid3.Components[0][3] := Comp;

    Grid2.Components[0][0] := Grid3;

    Grid3 := TMyGrid.Create(tSwitch, 3, 2);

    Comp := TMyComponent.Create(tText, Sender);
    Comp.Caption := '<Switch condition>';
    Grid3.Components[0][0] := Comp;

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := '';
    Grid3.Components[0][1] := Comp;

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := '...';
    Grid3.Components[1][0] := Comp;

    Comp := TMyComponent.Create(tText, Grid3);
    Comp.Caption := 'Else';
    Grid3.Components[1][1] := Comp;

    Comp := TMyComponent.Create(tAdd, Grid3);
    Grid3.Components[2][0] := Comp;

    Comp := TMyComponent.Create(tAdd, Grid3);
    Grid3.Components[2][1] := Comp;

    Grid2.Components[1][0] := Grid3;

    TMyComponent(TMyGrid(Grid2.Components[0][0]).Components[0][0])
      .ClickParent := Grid3;

    result := Grid2;
  end;

end;

function AddGrid(const Sender: TMyGrid; const Typee: TMyGridType): tObject;
var
  Grid: TMyGrid;
  Comp: TMyComponent;

begin

  if Typee = tNone then
  begin
    Sender.Typee := tNone;
    Comp := TMyComponent.Create(tAdd, Sender);

    result := Comp;
  end
  else
  begin

    Grid := TMyGrid.Create(tBase, 1, 1);

    if Sender.Typee = tUntil then
      Grid := TMyGrid.Create(tBase2, 1, 1);

    if Typee = tWhile then
    begin
      Grid.Components[0][0] := InsertGrid(Grid, tWhile);
    end;

    if Typee = tUntil then
    begin
      Grid.Components[0][0] := InsertGrid(Grid, tUntil);
    end;

    if Typee = tCaption then
    begin
      Grid.Components[0][0] := InsertGrid(Grid, tCaption);
    end;

    if Typee = tIf then
    begin
      Grid.Components[0][0] := InsertGrid(Grid, tIf);
    end;

    if Typee = tSwitch then
    begin
      Grid.Components[0][0] := InsertGrid(Grid, tSwitch);
    end;

    result := Grid;
  end;

end;

procedure GetClickParentRow(const Sender: TMyGrid; const x, y, x0, y0: Integer;
  const ClickParent: TMyGrid);
var
  i, j: Integer;

begin
  for i := 0 to Sender.RowCount - 1 do
    for j := 0 to Sender.ColumnCount - 1 do
    begin
      if Sender = ClickParent then
      begin
        if (x + Sender.ComponentsLeft[i][j] < x0) and
          (x + Sender.ComponentsLeft[i][j] + Sender.ComponentsWidth[i][j] > x0)
          and (y + Sender.ComponentsTop[i][j] < y0) and
          (y + Sender.ComponentsTop[i][j] + Sender.ComponentsHeight[i][j] > y0)
        then
          ClickParentRow := i;
      end
      else
      begin
        if Sender.Components[i][j].ClassType = TMyGrid then
        begin
          GetClickParentRow(TMyGrid(Sender.Components[i][j]),
            x + Sender.ComponentsLeft[i][j], y + Sender.ComponentsTop[i][j], x0,
            y0, ClickParent);
        end;
      end;
    end;
end;

procedure ClickGrid(const Sender: TMyGrid; const x, y, x0, y0: Integer);
var
  i, j, rand: Integer;
  tempStr: string;
  ParentGrid: TMyGrid;
  Comp: TMyComponent;
begin

  for i := 0 to Sender.RowCount - 1 do
    for j := 0 to Sender.ColumnCount - 1 do
    begin

      if (isFind = false) and (Sender.Components[i][j].ClassType = TMyGrid) then
      begin
        ClickGrid(TMyGrid(Sender.Components[i][j]),
          x + Sender.ComponentsLeft[i][j], y + Sender.ComponentsTop[i]
          [j], x0, y0);
      end;

      if (isFind = false) and (Sender.Components[i][j].ClassType = TMyComponent)
        and (x + Sender.ComponentsLeft[i][j] < x0) and
        (x + Sender.ComponentsLeft[i][j] + Sender.ComponentsWidth[i][j] > x0)
        and (y + Sender.ComponentsTop[i][j] < y0) and
        (y + Sender.ComponentsTop[i][j] + Sender.ComponentsHeight[i][j] > y0)
      then
      begin

        case TMyComponent(Sender.Components[i][j]).Typee of

          tAdd:
            begin
              isFind := True;

              rand := InputCombo;

              case rand of
                0:
                  Sender.Components[i][j] := AddGrid(Sender, tCaption);
                1:
                  Sender.Components[i][j] := AddGrid(Sender, tIf);
                2:
                  Sender.Components[i][j] := AddGrid(Sender, tSwitch);
                3:
                  Sender.Components[i][j] := AddGrid(Sender, tWhile);
                4:
                  Sender.Components[i][j] := AddGrid(Sender, tUntil);
              end;
            end;

          tClose:
            begin
              isFind := True;

              ClickParentRow := -1;

              ParentGrid := TMyGrid(TMyComponent(Sender.Components[i][j])
                .ClickParent);
              GetClickParentRow(Grid, 0, 0, x0, y0, ParentGrid);

              if ParentGrid.RowCount = 1 then
              begin
                ParentGrid.Components[0][0] := AddGrid(ParentGrid, tNone);
              end
              else
              begin
                ParentGrid.Components.Delete(ClickParentRow);
                ParentGrid.ComponentsLeft.Delete(ClickParentRow);
                ParentGrid.ComponentsTop.Delete(ClickParentRow);
                ParentGrid.ComponentsWidth.Delete(ClickParentRow);
                ParentGrid.ComponentsHeight.Delete(ClickParentRow);

                dec(ParentGrid.RowCount);
              end;
            end;

          tLeft:
            begin
              isFind := True;

              ParentGrid := TMyGrid(TMyComponent(Sender.Components[i][j])
                .ClickParent);

              Comp := TMyComponent.Create(tText, ParentGrid);
              Comp.Caption := TMyComponent(ParentGrid.Components[0][0]).Caption;
              TMyComponent(ParentGrid.Components[0][0]).Caption := '';
              ParentGrid.Components[0].Insert(0, Comp);
              ParentGrid.ComponentsLeft[0].Insert(0, 0);
              ParentGrid.ComponentsTop[0].Insert(0, 0);
              ParentGrid.ComponentsWidth[0].Insert(0, 0);
              ParentGrid.ComponentsHeight[0].Insert(0, 0);

              Comp := TMyComponent.Create(tText, ParentGrid);
              Comp.Caption := ' ... ';
              ParentGrid.Components[1].Insert(0, Comp);
              ParentGrid.ComponentsLeft[1].Insert(0, 0);
              ParentGrid.ComponentsTop[1].Insert(0, 0);
              ParentGrid.ComponentsWidth[1].Insert(0, 0);
              ParentGrid.ComponentsHeight[1].Insert(0, 0);

              Comp := TMyComponent.Create(tAdd, ParentGrid);
              ParentGrid.Components[2].Insert(0, Comp);
              ParentGrid.ComponentsLeft[2].Insert(0, 0);
              ParentGrid.ComponentsTop[2].Insert(0, 0);
              ParentGrid.ComponentsWidth[2].Insert(0, 0);
              ParentGrid.ComponentsHeight[2].Insert(0, 0);

              inc(ParentGrid.ColumnCount);
            end;

          tDown:
            begin
              isFind := True;

              ClickParentRow := -1;

              ParentGrid := TMyGrid(TMyComponent(Sender.Components[i][j])
                .ClickParent);
              GetClickParentRow(Grid, 0, 0, x0, y0, ParentGrid);

              inc(ParentGrid.RowCount);

              ParentGrid.Components.Insert(ClickParentRow + 1,
                TList<tObject>.Create);
              ParentGrid.ComponentsLeft.Insert(ClickParentRow + 1,
                TList<Integer>.Create);
              ParentGrid.ComponentsTop.Insert(ClickParentRow + 1,
                TList<Integer>.Create);
              ParentGrid.ComponentsWidth.Insert(ClickParentRow + 1,
                TList<Integer>.Create);
              ParentGrid.ComponentsHeight.Insert(ClickParentRow + 1,
                TList<Integer>.Create);

              rand := InputCombo;

              case rand of
                0:
                  ParentGrid.Components[ClickParentRow + 1]
                    .Add(InsertGrid(ParentGrid, tCaption));
                1:
                  ParentGrid.Components[ClickParentRow + 1]
                    .Add(InsertGrid(ParentGrid, tIf));
                2:
                  ParentGrid.Components[ClickParentRow + 1]
                    .Add(InsertGrid(ParentGrid, tSwitch));
                3:
                  ParentGrid.Components[ClickParentRow + 1]
                    .Add(InsertGrid(ParentGrid, tWhile));
                4:
                  ParentGrid.Components[ClickParentRow + 1]
                    .Add(InsertGrid(ParentGrid, tUntil));
              end;

              ParentGrid.ComponentsLeft[ClickParentRow + 1].Add(0);
              ParentGrid.ComponentsTop[ClickParentRow + 1].Add(0);
              ParentGrid.ComponentsWidth[ClickParentRow + 1].Add(0);
              ParentGrid.ComponentsHeight[ClickParentRow + 1].Add(0);
            end;

          tUp:
            begin
              isFind := True;

              ClickParentRow := -1;

              ParentGrid := TMyGrid(TMyComponent(Sender.Components[i][j])
                .ClickParent);
              GetClickParentRow(Grid, 0, 0, x0, y0, ParentGrid);

              inc(ParentGrid.RowCount);

              ParentGrid.Components.Insert(ClickParentRow,
                TList<tObject>.Create);
              ParentGrid.ComponentsLeft.Insert(ClickParentRow,
                TList<Integer>.Create);
              ParentGrid.ComponentsTop.Insert(ClickParentRow,
                TList<Integer>.Create);
              ParentGrid.ComponentsWidth.Insert(ClickParentRow,
                TList<Integer>.Create);
              ParentGrid.ComponentsHeight.Insert(ClickParentRow,
                TList<Integer>.Create);

              rand := InputCombo;

              case rand of
                0:
                  ParentGrid.Components[ClickParentRow]
                    .Add(InsertGrid(ParentGrid, tCaption));
                1:
                  ParentGrid.Components[ClickParentRow]
                    .Add(InsertGrid(ParentGrid, tIf));
                2:
                  ParentGrid.Components[ClickParentRow]
                    .Add(InsertGrid(ParentGrid, tSwitch));
                3:
                  ParentGrid.Components[ClickParentRow]
                    .Add(InsertGrid(ParentGrid, tWhile));
                4:
                  ParentGrid.Components[ClickParentRow]
                    .Add(InsertGrid(ParentGrid, tUntil));
              end;

              ParentGrid.ComponentsLeft[ClickParentRow].Add(0);
              ParentGrid.ComponentsTop[ClickParentRow].Add(0);
              ParentGrid.ComponentsWidth[ClickParentRow].Add(0);
              ParentGrid.ComponentsHeight[ClickParentRow].Add(0);
            end;

          tText:
            begin
              isFind := True;

              tempStr := InputBox(' Enter instruction', 'Your instruction:',
                TMyComponent(Sender.Components[i][j]).Caption);

              TMyComponent(Sender.Components[i][j]).Caption := tempStr;
            end;
        end;
      end;
    end;
end;

procedure TMainForm.SaveRes(info: TInfoToSave);
var
  pngImg: TPNGImage;
  jpegImg: TJpegimage;
  bmpimg: TBitmap;
  tifImg: TWICImage;
  hTemp: Integer;

begin

  hTemp := h;
  h := 0;

  h2 := h2 * TrackBar.Position;
  Canvas.Font.Size := MainForm.Canvas.Font.Size * TrackBar.Position;
  Image.Canvas.Font.Size := MainForm.Canvas.Font.Size;

  Calc(Grid);

  if Image.Width > 0 then
  begin

    case info.fileForm of
      png:
        begin
          info.location := info.location + '.png';
          pngImg := TPNGImage.Create;
          pngImg.Assign(Image.Picture.Graphic);
          pngImg.SaveToFile(info.location);
          pngImg.free;
        end;
      Jpeg:
        begin
          info.location := info.location + '.jpeg';
          jpegImg := TJpegimage.Create;
          jpegImg.Assign(Image.Picture.Graphic);
          jpegImg.SaveToFile(info.location);
          jpegImg.free;
        end;
      bmp:
        begin
          info.location := info.location + '.bmp';
          bmpimg := TBitmap.Create;
          bmpimg.Assign(Image.Picture.Graphic);
          bmpimg.SaveToFile(info.location);
          bmpimg.free;
        end;
      tiff:
        begin
          info.location := info.location + '.tiff';
          tifImg := TWICImage.Create;
          tifImg.Assign(Image.Picture.Graphic);
          tifImg.SaveToFile(info.location);
          tifImg.free;
        end;

    end;

    SaveLogs(info.location);
  end
  else
    showmessage('Empty diagram!');

  h := hTemp;
  h2 := round(h2 / TrackBar.Position);
  MainForm.Canvas.Font.Size :=
    round(MainForm.Canvas.Font.Size / TrackBar.Position);
  Image.Canvas.Font.Size := MainForm.Canvas.Font.Size;

  Calc(Grid);
end;

procedure ShowLogs;

type
  ptr = ^TMyStack;

  TMyStack = record
    data: TLogs;
    next: ptr;
  end;

const
  blockNum = 5;
  blockTypes: array [0 .. blockNum - 1] of string = ('DATE', 'TIME',
    'EXTENSION', 'FILENAME', 'DIRECTORY');
  dir = '\logs.ddt';

var
  tempLog: TLogs;
  logFile: file of TLogs;
  arrW: array [0 .. blockNum - 1] of Integer;
  Form: TForm;
  StringGrid: tStringGrid;
  i, j, w: Integer;
  p: ptr;

  procedure stackcreate(var head: ptr);
  begin
    head := nil;
  end;

  procedure push(var head: ptr; const x: TLogs);
  var
    tmpEl: ptr;
  begin
    new(tmpEl);
    tmpEl^.data := x;
    tmpEl^.next := head;
    head := tmpEl;
  end;

  function pop(var head: ptr): TLogs;
  var
    tmpEl: ptr;
  begin
    result := head^.data;
    tmpEl := head;
    head := head^.next;
    dispose(tmpEl);
  end;

  function empty(var head: ptr): Boolean;
  begin
    result := (head = nil);
  end;

begin

  if FileExists(ExtractFileDir(Application.ExeName) + dir) then
  begin

    Form := TForm.Create(Application);
    with Form do
    begin
      BorderStyle := bsDialog;
      Position := poScreenCenter;
      Caption := ' User logs';

      AssignFile(logFile, ExtractFileDir(Application.ExeName) + dir);
      reset(logFile);

      StringGrid := tStringGrid.Create(Form);
      with StringGrid do
      begin
        Parent := Form;
        BevelOuter := bvNone;
        Options := Options - [goRangeSelect];
        Options := Options - [goAlwaysShowEditor];

        w := 0;

        Font.Size := 10;

        ColCount := blockNum;

        Canvas.Font.Size := MainForm.Canvas.Font.Size;

        for i := 0 to blockNum - 1 do
        begin
          Cells[i, 0] := blockTypes[i];
          arrW[i] := Canvas.TextWidth(StringGrid.Cells[i, 0]);
        end;

        stackcreate(p);

        while not eof(logFile) do
        begin
          read(logFile, tempLog);
          push(p, tempLog);
        end;

        j := 1;

        while not empty(p) do
        begin

          tempLog := pop(p);

          Cells[0, j] := tempLog.data;
          Cells[1, j] := tempLog.time;
          Cells[2, j] := tempLog.fileType;
          Cells[3, j] := tempLog.fileName;
          Cells[4, j] := tempLog.fileDir;

          for i := 0 to blockNum - 1 do
          begin
            if Canvas.TextWidth(Cells[i, j]) > arrW[i] then
              arrW[i] := Canvas.TextWidth(Cells[i, j]);
          end;

          inc(j);
          StringGrid.RowCount := j;
        end;

        for i := 0 to blockNum - 1 do
        begin
          StringGrid.ColWidths[i] := arrW[i];
          w := w + arrW[i];
        end;

        Width := w + 12;
        Height := DefaultRowHeight * RowCount + 24;

        Form.Width := Width;
        Form.Height := Height + 24;

      end;

      closefile(logFile);

      ShowModal;
    end;
  end
  else
    showmessage('No logs recorded!');
end;

procedure TMainForm.SaveButtonClick(Sender: tObject);
begin
  InputInfoToSave;
end;

procedure TMainForm.ShowLogsButtonClick(Sender: tObject);
begin
  ShowLogs;
end;

procedure TMainForm.ShowAgrButtonClick(Sender: tObject);
begin
  ShowAgreement;
end;

procedure TMainForm.ExitButtonClick(Sender: tObject);
begin
  Application.Terminate;
end;

function InputComboRes: TInfoToSave;
const
  blockNum = 4;
  blockTypes: array [1 .. blockNum] of string = ('PNG', 'JPEG', 'BMP', 'TIFF');

var
  Form: TForm;
  Table: TGridPanel;
  EditText: TEdit;
  i, w, h: Integer;
begin
  Form := TForm.Create(Application);
  with Form do
  begin
    BorderStyle := bsDialog;
    Position := poScreenCenter;
    Caption := ' Choose file name and extension';

    EditText := TEdit.Create(Form);
    with EditText do
    begin
      Parent := Form;

      EditText.MaxLength := 45;

      Left := 12;
      top := 12;
    end;

    Table := TGridPanel.Create(Form);
    with Table do
    begin
      Parent := Form;
      BevelOuter := bvNone;

      RowCollection.Delete(1);
      ColumnCollection.Delete(1);
      ColumnCollection.Delete(0);

      for i := 0 to blockNum - 1 do
      begin
        ColumnCollection.Add;
        ColumnCollection[i].SizeStyle := ssAuto;
      end;

      RowCollection[0].SizeStyle := ssAuto;

      Left := 12;
      top := 24 + EditText.Height;
    end;

    w := 0;

    for i := 0 to blockNum - 1 do
    begin
      with TButton.Create(Form) do
      begin
        modalResult := -4 + i;
        Parent := Table;
        Caption := blockTypes[i + 1];
        w := w + Width;
        h := Height;
      end;
    end;

    EditText.Width := w;
    Table.Width := w;
    ClientWidth := w + 24;

    with TButton.Create(Form) do
    begin
      Parent := Form;
      Caption := 'Cancel';
      modalResult := mrCancel;
      Cancel := True;
      Left := w + 12 - Width;
      top := 36 + h + EditText.Height;
      Form.ClientHeight := top + Height + 12;
    end;

    if ShowModal < 0 then
    begin

      result.fileForm := TFileForm(modalResult + 4);
      result.location := EditText.Text;
    end;

  end;
end;

procedure TMainForm.FormKeyDown(Sender: tObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = Ord('S')) and (ssCtrl in Shift) then
    InputInfoToSave;
  if (Key = Ord('H')) and (ssCtrl in Shift) then
    ShowLogs;
  if (Key = Ord('I')) and (ssCtrl in Shift) then
    ShowAgreement;
end;

procedure TMainForm.InputInfoToSave;

  function isFileNameValid(fileNameToCheck: string): Boolean;
  var
    invalidChars: Boolean;
    ch: Char;
  begin
    invalidChars := false;
    for ch in fileNameToCheck do
    begin

      invalidChars := CharInSet(ch, ['\', '/', ':', '*', '?', '"', '<',
        '>', '|']);
      if invalidChars then
        Break;
    end;
    result := not invalidChars;
  end;

var
  input: TInfoToSave;
  temp: string;
begin

  SelectDirectory('', '', temp);

  if temp <> '' then
  begin
  
    input := InputComboRes;

    if (isFileNameValid(input.location)) then
    begin
      input.location := temp + '\' + input.location;

      SaveRes(input);
    end
    else
      showmessage('Wrong name!');
  end;
end;

procedure TMainForm.SaveLogs(info: string);
const
  dir = '\logs.ddt';

var
  tempLog: TLogs;
  logFile: file of TLogs;

begin

  tempLog.data := DateToStr(Now);
  tempLog.time := TimeToStr(Now);
  tempLog.fileName := extractfilename(info);
  tempLog.fileDir := ExtractFileDir(info);
  tempLog.fileType := ExtractFileExt(info);
  AssignFile(logFile, ExtractFileDir(Application.ExeName) + dir);

  if FileExists(ExtractFileDir(Application.ExeName) + dir) then
  begin
    reset(logFile);
    seek(logFile, filesize(logFile));
  end
  else
    Rewrite(logFile);

  Write(logFile, tempLog);

  closefile(logFile);

end;

procedure TMainForm.FormResize(Sender: tObject);
begin
  ToolBar1.Width := MainForm.Width;
end;

procedure TMainForm.ScrollBoxMouseWheel(Sender: tObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  ScrollBox: TScrollBox;
  NewPos: Integer;
begin
  ScrollBox := TScrollBox(Sender);

  NewPos := ScrollBox.VertScrollBar.Position - WheelDelta div 3;
  NewPos := Max(NewPos, 0);
  NewPos := Min(NewPos, ScrollBox.VertScrollBar.Range);

  ScrollBox.VertScrollBar.Position := NewPos;
  Handled := True;
end;

procedure TMainForm.FormCreate(Sender: tObject);
begin

  h := 30;
  h2 := 30;

  Panel.Width := MainForm.Width;
  ToolBar1.Width := Panel.Width;

  Image.Canvas.Font.Size := 12;
  Canvas.Font.Size := 12;

  Image.top := Panel.Height;
  Image.Left := 0;
  Image.Width := MainForm.Width;
  Image.Height := MainForm.Height;

  Grid := TMyGrid.Create(tBase, 1, 1);

  Grid.Components[0][0] := TMyComponent.Create(tAdd, Grid);

  Calc(Grid);
end;

procedure TMainForm.ShowAgreement;
const
  dir = '\agrm.htm';

var
  Form: TForm;
  WebBrowser: TWebBrowser;
  tempS: string;

begin
  Form := TForm.Create(Application);
  with Form do
  begin
    BorderStyle := bsDialog;
    Position := poScreenCenter;
    Caption := 'Agreement';

    tempS := ExtractFileDir(Application.ExeName) + dir;

    WebBrowser := TWebBrowser.Create(Form);
    with WebBrowser do
    begin
      TWinControl(WebBrowser).Parent := Form;

      WebBrowser.Resizable := True;
      Width := 1000;
      Height := 600;

      Form.Height := Height + 24;
      Form.Width := Width + 5;

      Navigate('file:///' + tempS);
    end;

    ShowModal;
  end;
end;

procedure TMainForm.ShowReadME;
const
  dir = '\readme.txt';

var
  Form: TForm;
  Memo: TMemo;

begin
  Form := TForm.Create(Application);
  with Form do
  begin
    BorderStyle := bsDialog;
    Position := poScreenCenter;
    Caption := ' README';

    Memo := TMemo.Create(Form);
    with Memo do
    begin
      Memo.Parent := Form;
      
      Width := 1000;
      Height := 550;

      Font.Name := 'Comfortaa';
      Font.Size := 10;

      Memo.ReadOnly := True;

      Form.Height := Height + 24;
      Form.Width := Width + 5;

      Memo.Lines.LoadFromFile(ExtractFileDir(Application.ExeName) + dir);
    end;

    ShowModal;
  end;
end;

procedure TMainForm.ShowReadMeBtnClick(Sender: TObject);
begin
  ShowReadME;
end;

procedure TMainForm.ImageClick(const Sender: tObject);
var
  pt: TPoint;
begin
  pt := TPanel(Sender).ScreenToClient(Mouse.CursorPos);

  isFind := false;

  ClickGrid(Grid, 0, 0, pt.x, pt.y);

  Calc(Grid);
end;

end.

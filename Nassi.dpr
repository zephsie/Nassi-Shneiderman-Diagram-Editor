program Nassi;

uses
  Vcl.Forms,
  NassiEditor in 'NassiEditor.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

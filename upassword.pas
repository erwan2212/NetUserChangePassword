unit upassword;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, windows, inifiles;

type

  { TForm1 }

  TForm1 = class(TForm)
    btngo: TButton;
    chkpwd: TCheckBox;
    chkcred: TCheckBox;
    StaticText1: TStaticText;
    StaticText2: TStaticText;
    StaticText3: TStaticText;
    StaticText4: TStaticText;
    StatusBar1: TStatusBar;
    txtusername: TEdit;
    txtoldpwd: TEdit;
    txtnewpwd: TEdit;
    txttarget: TEdit;
    procedure btngoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

type

PCREDENTIAL_ATTRIBUTEW = ^_CREDENTIAL_ATTRIBUTEW;
_CREDENTIAL_ATTRIBUTEW =  record
  Keyword: LPWSTR;
  Flags: DWORD;
  ValueSize: DWORD;
  Value: PBYTE; //LPBYTE
end;


PCREDENTIALW = ^_CREDENTIALW;
_CREDENTIALW =  record
  Flags: DWORD;
  Type_: DWORD;
  TargetName: LPWSTR;
  Comment: LPWSTR;
  LastWritten: FILETIME;
  CredentialBlobSize: DWORD;
  dummy : dword;
  CredentialBlob: PBYTE; //LPBYTE
  Persist: DWORD;
  AttributeCount: DWORD;
  Attributes: PCREDENTIAL_ATTRIBUTEW;
  TargetAlias: LPWSTR;
  UserName: LPWSTR;
end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

function NetUserChangePassword(Domain: PWideChar; UserName: PWideChar; OldPassword: PWideChar;
  NewPassword: PWideChar): Longint; stdcall; external 'netapi32.dll'
  Name 'NetUserChangePassword';

function CredWriteW( Credential:PCREDENTIALW;Flags:DWORD): BOOL; stdcall; external 'advapi32.dll';

// Changes a user's password for a specified network server or domain.
// Requirements:  Windows NT/2000/XP
// Windows 95/98/Me: You can use the PwdChangePassword function to change a user's
// Windows logon password on these platforms

function credwrite(target,username,password:widestring):boolean;
const
  CRED_PERSIST_NONE: DWORD = 0;
  CRED_PERSIST_SESSION: DWORD = 1;
  CRED_PERSIST_LOCAL_MACHINE: DWORD = 2;
  CRED_PERSIST_ENTERPRISE: DWORD = 3;
//
  CRED_TYPE_GENERIC                 = 1;
  CRED_TYPE_DOMAIN_PASSWORD         = 2;
  CRED_TYPE_DOMAIN_CERTIFICATE      = 3;
  CRED_TYPE_DOMAIN_VISIBLE_PASSWORD = 4;

var
  credsToAdd: _CREDENTIALW;
begin
  result:=false;
  //showmessage('target:'+target);
  //showmessage('username:'+username);
  //showmessage('password:'+password);
  ZeroMemory(@credsToAdd, SizeOf(_CREDENTIALW));
    credsToAdd.Flags := 0;
  	credsToAdd.Type_ := CRED_TYPE_DOMAIN_PASSWORD; //CRED_TYPE_GENERIC;
  	credsToAdd.TargetName := pwidechar(target);
    credsToAdd.UserName  := pwidechar(username);
  	credsToAdd.CredentialBlob := PByte(password);
  	credsToAdd.CredentialBlobSize := 2*(Length(Password)); //By convention no trailing null. Cannot be longer than CRED_MAX_CREDENTIAL_BLOB_SIZE (512) bytes
  	credsToAdd.Persist := CRED_PERSIST_LOCAL_MACHINE;
    result:= CredWritew(@credsToAdd, 0);
    if result=false then showmessage('credwrite:'+inttostr(getlasterror)) else Form1.StatusBar1.SimpleText:=Form1.StatusBar1.SimpleText+ ' ' + 'Credentials OK' ;
end;

procedure writeini(section,ident,value:string);
var
ini:tinifile;
Attrs:word;
currentdir:string;
begin
//currentdir:=upsapi.GetCurrentExeDir;
    if currentdir='' then currentdir:=ExtractFilePath(application.ExeName ) ;
if FileExists(currentdir + '\config.INI') then
  begin
  Attrs := FileGetAttr(currentdir + '\config.INI');
  if Attrs and fareadonly <> 0 then exit;
  end;

//if FileExists(GetCurrentDir + '\config.INI')=false then exit;
try
  ini:=tinifile.Create (currentdir + '\config.INI');
  ini.WriteString(section,ident,value);
finally
  freeandnil(ini);
end;
end;

function readini(section,ident,default:string;config:string=''):string;
var
ini:tinifile;
currentdir,fname:string;
begin
//currentdir:=upsapi.GetCurrentExeDir;
if currentdir='' then currentdir:=ExtractFilePath(application.ExeName ) ;
if config<>'' then fname:=config else fname:=currentdir + '\config.INI';
if FileExists(fname) then
  begin
    ini:=tinifile.Create (fname);
    result:=ini.ReadString (section,ident,default  );
    freeandnil(ini);
  end
  else result:=default;

end;



procedure TForm1.btngoClick(Sender: TObject);
var
ret:longint;
domain,target:string;
begin
if chkpwd.Checked then
begin
  try
  ret:=NetUserChangePassword(PWideChar(WideString(txttarget.text)), // should it be '\\'+server?
    PWideChar(WideString(txtusername.Text )),
    PWideChar(WideString(txtoldpwd.Text )),
    PWideChar(WideString(txtnewpwd.Text )));
  if ret<>0 then showmessage(SysErrorMessage(ret)) else StatusBar1.SimpleText := 'Password OK';
  writeini('setup','username',txtusername.Text );
    except
    on e:exception do showmessage(e.Message);
    end;
end;

if chkcred.Checked then
  begin
  domain:=readini('setup','domain','');
  if domain<>'' then domain:=domain+'\';
  target:=readini('setup','host','');
  if target='' then target:=txttarget.Text;
  if credwrite(widestring(target),WideString(domain+txtusername.Text ),WideString(txtnewpwd.Text ))=false
    then ; //showmessage('credwrite failed');
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
txttarget.Text :=readini('setup','server','.');
txtusername.Text :=readini('setup','username','');
txtusername.SetFocus ;
end;




end.


--Programilla para aprender el funcionamiento de index y head; y poder hacer el parseo
-- SÓLO ÚTIL EN FASE DE DISEÑO(no tienen porque funcionar en la versión final)


with Ada.Strings.Unbounded;
with Ada.Text_Io;

procedure Test_parseo is

   package ASU renames Ada.Strings.Unbounded;

   use type ASU.Unbounded_String;

   Cad: ASU.Unbounded_String;
   Pos: Natural;
   Fich:ASU.Unbounded_String;
   Ip: ASU.Unbounded_String;
   Port: ASU.Unbounded_String;
   Port_Natural: natural;

begin

   Cad:=ASU.To_Unbounded_String("aaaaaaaaaa");
   Pos:=ASU.Index(Cad,"b");
   Ada.Text_Io.Put_Line("valor de pos con busq vacia" & Natural'Image(Pos));


   --Vamos a comprobar como funciona index y head
   Cad:=ASU.To_Unbounded_String("fichero 127.0.0.1 3000");

   Pos:= ASU.Index(Cad," ");
   Fich:=ASU.Head(Cad,Pos-1);
   Ada.Text_Io.Put_Line("nombre_fich:" & ASU.To_String(Fich) &"#");
   Ada.Text_Io.Put_Line("valor de cad:" & ASU.To_String(cad));

   --recortamos de pos + 1 a fin..
   Cad:= ASU.To_Unbounded_String(ASU.To_String(Cad)(Pos + 1..ASU.Length(Cad)));

   Pos:=ASU.Index(Cad," ");
   Ip:=ASU.Head(Cad,Pos-1);
   Ada.Text_Io.Put_Line("nombre_ip:" & ASU.To_String(ip)&"#");
   Ada.Text_Io.Put_Line("valor de cad:" & ASU.To_String(cad));

   Port:=  ASU.To_Unbounded_String(ASU.To_String(Cad)(Pos + 1..ASU.Length(Cad)));
   Port_Natural:= Natural'Value(ASU.To_String(Port));

   Ada.Text_Io.Put_Line("port:" & ASU.To_String(port)&"#");
   Ada.Text_Io.Put_Line("port_natural:" & Natural'Image(Port_Natural)&"#");
   Ada.Text_Io.Put_Line("valor de cad:" & ASU.To_String(cad));


end;

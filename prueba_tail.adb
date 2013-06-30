-- Programilla para aprender el uso de tail y index
-- SÓLO ÚTIL EN FASE DE DISEÑO(no tiene porque funcionar con la versión final)

with Ada.Text_IO;
with Ada.Strings.Unbounded;
--with Ada.Maps;

procedure test_tail is
   package ASU renames Ada.Strings.Unbounded;
   Mi_Cadena: ASU.Unbounded_String;
   --Nombre_Fich: Ada.Strings.String;
   Cadena_Res: ASU.Unbounded_String;
   Pos: Natural:=0;
   Pos_Fin: Natural;
   --Direccion: Direction := Forward;
  -- Mapa: Maps.Character_Mapping := Maps.Identity;
begin

   Mi_Cadena:=ASU.To_Unbounded_String("/bin/tmp/lalala/david.txt");

   loop
   Pos:=ASU.Index(Mi_cadena,"/");
   Pos_Fin:= ASU.Length(Mi_Cadena);
   Mi_Cadena:= ASU.To_Unbounded_String(ASU.To_String(Mi_Cadena)(Pos+1..Pos_Fin));
   exit when (Pos=0);
   end loop;

   --ASU.tail(Mi_Cadena,Pos,'a');
   --Ada.Text_io.Put_Line("el valor de pos es : " & Natural'Image(Pos));
   --Ada.Text_Io.Put_Line("el valor de cadena res es : " & ASU.To_STring(Cadena_Res));
   Ada.Text_Io.Put_Line("el valor de mi_cadena es:" & ASU.To_String(Mi_Cadena));



end test_tail;

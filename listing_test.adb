with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Command_Line;

with Listing;



procedure Listing_Test is
   package ASU renames Ada.Strings.Unbounded;

   Usage_Error: exception;

   function Get_Nombre_Fichero (Ruta: in ASU.Unbounded_string) return ASU.Unbounded_String is
      -- Devuelve el nombre del fichero, a partir de la ruta completa
      Nombre_Fich: Asu.Unbounded_String;
      Pos: Natural:=0;
      Pos_Fin: Natural;
   begin

      Nombre_Fich:=Ruta;
      loop
         Pos:=ASU.Index(Nombre_fich,"/");
         Pos_Fin:= ASU.Length(Nombre_fich);
         Nombre_fich:= ASU.To_Unbounded_String(ASU.To_String(Nombre_fich)(Pos+1..Pos_Fin));
         exit when (Pos=0);
      end loop;
      return Nombre_Fich;
   end;

   Result: Listing.File_List_Type;
   Last: Natural := 0;
   Mi_Cadena: ASU.Unbounded_String;
   Pos: Natural;
begin


   Catalogo_Ficheros.Indice:=0;   if Ada.Command_Line.Argument_Count /= 1 then
     raise Usage_Error;
   end if;

   Listing.Get_Listing (Ada.Command_Line.Argument(1), Result, Last);

   Ada.Text_IO.Put_Line ("Contenido del directorio:");
   for I in 1..Last loop

      Ada.Text_Io.Put_Line(ASU.To_String(Get_Nombre_Fichero(Result(I))));
      Ada.Text_IO.Put_Line (ASU.To_String(Result(I)));
   end loop;

exception
   when Usage_Error =>
     Ada.Text_IO.Put_Line ("Uso: listing_test directorio");
   when Except:others =>
      Ada.Text_IO.Put_Line ("Excepción inesperada: " &
                            Ada.Exceptions.Exception_Name (Except));
end Listing_Test;

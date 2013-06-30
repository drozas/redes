--Programilla para comprobar el correcto funcionamiento de la importación de directorios
-- SÓLO ÚTIL EN FASE DE DISEÑO(no tiene porque funcionar con la versión final)

with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
with Paquetes; use Paquetes;
with Listing;

procedure Test_Importar_directorios is

   package ASU renames Ada.Strings.Unbounded;

   use type ASU.Unbounded_String;

   N_Total:Natural;
   Lista_Fich: tListaFicheros;
   Result: Listing.File_List_Type;

begin

   Listing.Get_Listing (Ada.Command_Line.Argument(1), Result,N_Total);
   Ada.Text_IO.Put_Line ("Contenido del directorio:");
   for I in 1..N_total loop

      Ada.Text_IO.Put_Line (ASU.To_String(Result(I)));
   end loop;

   Paquetes.ExportarDirectorio(Lista_Fich,
                               ASU.To_Unbounded_String(ADA.Command_Line.Argument(1)));
   Paquetes.PintaListaFicheros(Lista_Fich);




end Test_Importar_Directorios;

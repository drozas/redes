--Programilla para aprender el uso de paquetes GDO y GOL
-- SÓLO ÚTIL EN FASE DE DISEÑO(no tiene porque funcionar con la versión final)
with Ada.Strings.Unbounded;
with Gnat.Directory_Operations;
with Gnat.OS_Lib;
with Ada.Text_IO;
with Ada.Exceptions;


procedure Test_directorios is

   package GDO renames Gnat.Directory_Operations;
   package GOL renames Gnat.OS_Lib;



   Dir: GDO.Dir_Type;
begin

   begin
   --Capturamos la excepcion, para crearlo si no existe
   Ada.Text_Io.Put_Line("vamos a probar a abrirlo");
   GDO.Open(Dir,"/home/drozas/redes/prueba1/incoming");
   end;

exception
   when Except:GDO.Directory_Error =>
      Ada.Text_IO.Put_Line ("Se ha lanzado la excepcion.Si no existe, lo creamos");
      GDO.Make_Dir("/home/drozas/redes/prueba1/incoming");

      Ada.Text_Io.Put_Line("fuera de bloque de excep");
end;

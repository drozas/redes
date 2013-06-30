--Programilla para probar que funciona correctamente el protocolo catalogo<>exportadir
-- SÓLO ÚTIL EN FASE DE DISEÑO(no tiene porque funcionar con la versión final)


with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_Io;
with Ada.Strings.Unbounded.Text_IO;
with Ada.Command_Line;
--with Ada.Integer_Text_io;
with Ada.Streams.Stream_Io;
with Ada.Streams;
--with Ficheros;
with Paquetes;use Paquetes;

procedure Test_catalogo is

   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package SSIO renames Ada.Streams.Stream_IO;

   use type ASU.Unbounded_String;

   --Valores de conexion real
   EP_test: LLU.End_Point_Type;
   Buffer: aliased LLU.Buffer_Type(20000);
   Ip_test: ASU.Unbounded_String;
   Port_Test: Natural;
   Nombre_Catalogo: ASU.Unbounded_String;
   Ip_Catalogo: ASU.Unbounded_String;
   Port_Catalogo: Natural;
   EP_Catalogo: LLU.End_Point_Type;

   Id_Paquete: Natural:=1;
   Lista_Ficheros: TListaFicheros;
   --Array con falsas ips
   type TArrayIp is array(1..8) of ASU.Unbounded_String;
   Ip_Prueba: tArrayIp;

begin
   --Vamos a enviar 6 paquetes con distintas ips. Aunque en realidad lo hacemos desde el
   --mismo Ep, el valor que comparada el catalogo es el de la ip
   Ip_test:=ASU.To_Unbounded_String(LLU.To_Ip(LLU.Get_Host_Name));
   Port_Test:= Natural'Value(ADA.Command_Line.Argument(1));
   EP_test:= LLU.Build (ASU.To_String(Ip_test), Port_test);

   Nombre_Catalogo:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(2));
   Ip_Catalogo:= ASU.To_Unbounded_String(LLU.To_Ip(ASU.To_String(Nombre_Catalogo)));

   Port_Catalogo:= Natural'Value(Ada.Command_Line.Argument(3));

   --Nos atamos
   LLU.Bind (EP_test);

   --Construimos el end_point del catalogo
   EP_Catalogo:= LLU.Build(ASU.To_String(Ip_Catalogo), Port_Catalogo);

   --Exportamos el mismo directorio para todos(da igual)
   ExportarDirectorio(Lista_Ficheros,ASU.To_Unbounded_String("serverd"));
   --Y metemos ips ficticias
   Ip_Prueba(1):= ASU.To_Unbounded_String("212.123.4.2");

   Ip_Prueba(2):= ASU.To_Unbounded_String("212.123.4.3");

   Ip_Prueba(3):= ASU.To_Unbounded_String("212.123.4.77");

   Ip_Prueba(4):= ASU.To_Unbounded_String("212.123.4.69");

   Ip_Prueba(5):= ASU.To_Unbounded_String("69.69.69.69");

   -- Estas dos nos tienen que decir que esta saturado
   Ip_Prueba(6):= ASU.To_Unbounded_String("212.123.4.35");

   Ip_Prueba(7):= ASU.To_Unbounded_String("XXX.XXX.XXX.XXX");

   -- y esta tiene que refrescar...
   Ip_Prueba(8):= ASU.To_Unbounded_String("212.123.4.77");

   --El formato a enviar sera: id=1, EP_exportadir+ip_exportadir+port_exportadir+lista_ficheros
   for I in 1..8 loop
      LLU.Reset(Buffer);
      Ada.Text_Io.Put_line("probando catalogo con ip..." & ASU.To_String(Ip_Prueba(I)));
      Natural'Output(Buffer'Access,Id_Paquete);
      LLU.End_Point_Type'Output(Buffer'Access,Ep_test);
      ASU.Unbounded_String'Output(Buffer'Access,Ip_prueba(I));
      Natural'Output(Buffer'Access,Port_test);
      TListaFicheros'Output(Buffer'Access,Lista_Ficheros);
      --Enviamos el buffer
      LLU.Send(EP_Catalogo,Buffer'Access);
   end loop;


end Test_Catalogo;

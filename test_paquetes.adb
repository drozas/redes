--Programilla para comprobar el funcionamiento de las funciones de paquete.adb
-- SÓLO ÚTIL EN FASE DE DISEÑO(no tienen porque funcionar con la version final)

with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
with Paquetes; use Paquetes;
with Listing;

procedure Test_paquetes is

   package ASU renames Ada.Strings.Unbounded;

   use type ASU.Unbounded_String;


   Lista_Fich: TListaFicheros;
   --    Lista_Servers: TListaServers;
   --    Nodo_Fich1, Nodo_fich2: TNodoFichero;
   ListaServers: TListaServers;
   ListaBusq: TListaBusq;

begin

 --   PintaListaFicheros(Lista_Fich);

   --Comprobamos el funcionamiento de la insercion y pintar en lista_fich
   Ada.Text_Io.Put_Line("prueba el uso de insertar y pintar en tListaFicheros");
   InsertarNodoFichero(Lista_Fich, ASU.To_Unbounded_String("a.b")
                       ,ASU.To_Unbounded_String("lalalala/lelele/a.b"));


   InsertarNodoFichero(Lista_Fich,ASU.To_Unbounded_String("tralaritralara"),
                       ASU.To_Unbounded_String("ñañañaña"));

   InsertarNodoFichero(Lista_Fich,ASU.To_Unbounded_String("abc.b"),
                          ASU.To_Unbounded_String("lalalala/ñañaña/abc.b"));

   PintaListaFicheros(Lista_Fich);

   if ExisteFichero(Lista_Fich,ASU.To_Unbounded_String("lalalala/ñañaña/abc.b")) then
      Ada.Text_Io.Put_Line("existefichero funciona!");
   else
      Ada.Text_Io.Put_Line("revisar existeFichero!");
   end if;

--    PintaListaServers(ListaServers);
--    --Comprobamos el funcionamiento de la insercion y pintar en lista_servers
--    Ada.Text_Io.Put_Line("vamos a probar insertar y pintar en tListaServers");

--    InsertarNodoServer(ListaServers,
--                        ASU.To_Unbounded_String("212,121,1,1"),
--                        3000,
--                        Lista_Fich);
--     InsertarNodoServer(ListaServers,
--                         ASU.To_Unbounded_String("120.2.1.2"),
--                         666,
--                         Lista_Fich);

--    --     PintaListaServers(ListaServers);

--    --Vamos a comprobar el correcto funcionamiento de exportarDirectorio
--    Ada.Text_Io.Put_Line("Contenido previo de lista_fich:");
--    PintaListaFicheros(Lista_Fich);

--    Ada.Text_Io.Put_Line("llamamos a exportarDir con el param de entrada");
--    ExportarDirectorio(Lista_Fich,ASU.To_Unbounded_String(Ada.Command_Line.Argument(1)));

--    Ada.Text_Io.Put_Line("Contenido posterior de lista_fich:");
--    PintaListaFicheros(Lista_Fich);


--    InicializarListaBusq(ListaBusq);

--    Ada.Text_Io.Put_Line("Contenido previo de list_busq");
--    PintaListaBusq(ListaBusq);

--    if EsVacia(ListaBusq) then
--       Ada.Text_Io.Put_Line("la lista esta vacia...la funcion funciona");
--    end if;

--    --Ahora comprobaremos que funcionan correctamente los indices en las funciones de insercion
--    for I in 1..MAX_BUSQ + 3 loop
--       InsertarNodoBusq(ListaBusq,ASU.To_Unbounded_String("69.69.69.69"),666
--                        ,ASU.To_Unbounded_String("/bin/bash/tralara"));
--    end loop;

--    PintaListaBusq(ListaBusq);

--    if EsVacia(ListaBusq) then
--       Ada.Text_Io.Put_Line("¡este mensaje no debe salir!");
--    end if;

end Test_Paquetes;


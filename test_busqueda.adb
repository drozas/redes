--Programilla para comprobar el funcionamiento del procedimiento busqueda
-- SÓLO ÚTIL EN FASE DE DISEÑO(no tiene porque funcionar con la versión final)

with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Strings.Unbounded;
with Ada.Command_Line;
with Paquetes; use Paquetes;
with Listing;

procedure Test_busqueda is

   package ASU renames Ada.Strings.Unbounded;

   use type ASU.Unbounded_String;


   Lista_Fich1,Lista_Fich2,Lista_fich3: TListaFicheros;
   --    Lista_Servers: TListaServers;
   --    Nodo_Fich1, Nodo_fich2: TNodoFichero;
   ListaServers: TListaServers;
   ListaBusq: TListaBusq;
   CatalogoLleno: Boolean;

begin


   Ada.Text_Io.Put_Line("probando insercion en listaBusq a palo seko!");
   InicializarListaBusq(ListaBusq);
   for I in 1..MAX_BUSQ + 3 loop
      InsertarNodoBusq(ListaBusq,ASU.To_Unbounded_String("1.1.1.1"), 666,
                       ASU.To_Unbounded_STring("/lalala/prueba"));
   end loop;
   PintaListaBusq(ListaBusq);
   InicializarListaBusq(ListaBusq);

   --Para ver que muestra dos veces el mismo en el mismo server
   InsertarNodoFichero(Lista_Fich1,ASU.To_Unbounded_String("hola.txt"),
                       ASU.To_Unbounded_String("/tmp/dir1/hola.txt"));
   InsertarNodoFichero(Lista_Fich1, ASU.To_Unbounded_String("hola.txt")
                       ,ASU.To_Unbounded_String("/tmp/hola.txt"));

   InsertarNodoServer(ListaServers,ASU.To_Unbounded_String("server_dos_holas"),666,
                      Lista_Fich1, catalogoLLeno);

   --Para ver que se puede mostrar un mismo resultado desde distintos servers
   InsertarNodoFichero(Lista_Fich2, ASU.To_Unbounded_String("hola.txt"),
                       ASU.To_Unbounded_String("/ñañaña/hola.txt"));
   InsertarNodoServer(ListaServers,ASU.To_Unbounded_String("server_un_hola"),1234
                      ,Lista_Fich2,catalogolleno);

   --Para ver que no se pasa de rango
   for I in 1..MAX_BUSQ + 3 loop
      InsertarNodoFichero(Lista_Fich3,ASU.To_Unbounded_String("saturado.mp3"),
                          ASU.To_Unbounded_String("/pepe/saturado.mp3"));
   end loop;

   InsertarNodoServer(ListaServers,ASU.To_Unbounded_String("server_q_satura"),7777,
                      Lista_Fich3, catalogoLLeno);

   Ada.Text_Io.Put_Line("estado de server...");
   PintaListaServers(ListaServers);


   Ada.Text_Io.Put_Line("nos disponemos a hacer las busquedas...");

   InicializarListaBusq(ListaBusq);
   Ada.Text_Io.Put_Line("esta nos tiene que dar tres resultados en dos servers...");
   BuscarArchivo(ListaServers,ListaBusq,ASU.To_Unbounded_String("hola.txt"));
   PintaListaBusq(ListaBusq);

   InicializarListaBusq(ListaBusq);
   Ada.Text_Io.Put_Line("esta nos tiene que dar 5 resultados en 1 server...");
   Ada.Text_Io.Put_Line("ademas se tienen que mostrar 3 avisos de sobrepasar lim");
   BuscarArchivo(ListaServers,ListaBusq,ASU.To_Unbounded_String("saturado.mp3"));
   PintaListaBusq(ListaBusq);

   InicializarListaBusq(ListaBusq);
   Ada.Text_Io.Put_Line("esta nos deberia devolver una lista vacia");
   BuscarArchivo(ListaServers,ListaBusq,ASU.To_Unbounded_String("no_existe.mp4"));
   PintaListaBusq(ListaBusq);

   if EsVacia(ListaBusq) then
      Ada.Text_Io.Put_Line("la busqueda vacia se hace correctamente");
   else
      Ada.Text_Io.Put_Line("la busqueda vacia no se hace correctamente, o la funcion no funciona");
   end if;

end Test_Busqueda;

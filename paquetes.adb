-- *---------------------------------------------------------------------
--´       Práctica de Redes (3º ITIS)
--        ---------------------------
--
--        Servicio de intercambio de ficheros en internet (versión_final)
--                           #paquetes.adb#
--
--        Autor: David Rozas
-- ----------------------------------------------------------------------


package body Paquetes is

   procedure InicializarListaFicheros (Lista_Fich: in out TListaFicheros) is
      --Inicializa el tListaFicheros
   begin
      for I in 1..MAX_FICHEROS loop
        Lista_Fich.Ficheros(I).Nombre:=ASU.Null_Unbounded_String;
        Lista_Fich.Ficheros(I).Ruta:= ASU.Null_Unbounded_String;
      end loop;

      Lista_Fich.sig:=1;
   end InicializarListaFicheros;


   procedure PintaListaFicheros (Lista_Fich: in TListaFicheros) is
      --Pinta la informacion de la lista de ficheros (para las trazas)

   begin
      Ada.Text_Io.Put_Line("Nº de sig fichero :" & Natural'Image(Lista_Fich.sig));

      for I in 1..(Lista_Fich.sig -1) loop
         Ada.Text_Io.Put_Line("---------- Fichero nº" & Integer'Image(I) & " ------------");
         Ada.Text_Io.Put_Line("Nombre:" & ASU.To_String(Lista_Fich.Ficheros(I).Nombre));
         Ada.Text_Io.Put_Line("Ruta:" & ASU.To_String(Lista_Fich.Ficheros(I).ruta));
      end loop;
   end PintaListaFicheros;

   procedure InsertarNodoFichero (Lista_Fich: in out TListaFicheros;
                                  Nombre: in ASU.Unbounded_String;
                                  Ruta: in ASU.Unbounded_String) is
      --Introduce un nodo fichero en la lista de ficheros
   begin
      if (Lista_Fich.sig) <= MAX_FICHEROS then
         --Actualizamos indice, e insertamos informacion

         Lista_Fich.ficheros(Lista_Fich.sig).Nombre:= Nombre;
         Lista_Fich.ficheros(Lista_Fich.sig).Ruta:= Ruta;
         Lista_Fich.sig:= Lista_Fich.sig + 1;
      else
         Ada.Text_Io.Put_Line("Superado limite de ficheros");
      end if;

   end InsertarNodoFichero;


   function ExisteFichero (ListaFich: in TListaFicheros;
                           Fich: in ASU.Unbounded_String) return Boolean is
      -- Busca si el fichero existe en la lista
      encontrado: Boolean := False;
      I:Natural:=1;
   begin
      while (I<=(ListaFich.sig -1) ) and (not Encontrado) loop
         if ListaFich.Ficheros(I).Ruta = Fich then
            Encontrado:= True;
         end if;
         I:= I+1;
      end loop;
      return Encontrado;
   end ExisteFichero;
   --------------------------------------------------------------------------------------

   function ServerYaInsertado (Ip_Server: in ASU.Unbounded_String;
                               Port_Server: in Natural;
                               Lista_Servers: in TListaServers) return  Natural is
      -- Devuelve un integer con la posicion en la que fue insertado. Si no fue insertado, devuelve 0
      -- Un server es identificado por su ip
      Encontrado: Boolean := False;
      I: Natural:=1;
   begin
      while (I<= (Lista_Servers.sig -1)) and (not Encontrado) loop
         if (Lista_Servers.Servers(I).Ip= Ip_Server) and (Lista_Servers.Servers(I).Port=Port_Server) then
            Encontrado:=True;
         else
            I:= I + 1;
         end if;
      end loop;

      if not Encontrado then
         I:=0;
      end if;

      return i;
   end ServerYaInsertado;

   procedure InicializarListaServers (Lista_Servers: in out tListaServers) is
      --Inicializa la lista de servers
   begin
      for I in 1..MAX_SERVERS loop
         Lista_Servers.Servers(I).Ip:= ASU.Null_Unbounded_String;
         Lista_Servers.Servers(I).Port:= 0;
         InicializarListaFicheros(Lista_Servers.Servers(I).Ficheros);
      end loop;
      Lista_Servers.sig := 1;
   end InicializarListaServers;

   procedure PintaListaServers (Lista_Servers: in TListaServers) is
      --Pinta la informacion de todos los archivos de todos los servers
   begin
      Ada.Text_Io.Put_Line("nº de siguiente server:" & Natural'Image(Lista_Servers.sig));
      for I in 1..(Lista_Servers.sig -1) loop
         Ada.Text_Io.Put_Line("Ip del server:" & ASU.To_String(Lista_Servers.Servers(I).Ip));
         Ada.Text_Io.Put_Line("Port del server:" & Natural'Image(Lista_Servers.Servers(I).Port));
         Ada.Text_Io.Put_Line("##############################################################");
         PintaListaFicheros(Lista_Servers.Servers(I).Ficheros);
         Ada.Text_Io.Put_Line("##############################################################");
      end loop;

   end PintaListaServers;

   procedure InsertarNodoServer (Lista_Servers: in out TListaServers;
                                 Ip_Server: in ASU.Unbounded_String;
                                 Port_Server: in Natural;
                                 Lista_Ficheros: in TListaFicheros;
                                 EstaLleno: in out Boolean) is
      --Introduce un nodo server en la lista de servers. Controla que no se repita
      --identificandolo por su ip; y avisa de si esta lleno por el boolean.
      Pos : Natural;
   begin

      --Miramos si ya está registrado
      Pos:= ServerYaInsertado(Ip_Server,Port_Server,Lista_Servers);

      --Si no está registrado...
      if Pos=0 then

         if (Lista_Servers.sig) <= MAX_SERVERS then
            Ada.Text_Io.Put("petición  de catalogar recibida de  " & ASU.To_String(Ip_Server)
                            & ":" & Natural'Image(Port_Server) & " (nuevo registro), ficheros : ");
            --Actualizamos el indice, e insertamos la info
            Lista_Servers.Servers(Lista_Servers.sig).Ip:= Ip_Server;
            Lista_Servers.Servers(Lista_Servers.sig).port:= port_Server;
            for I in 1..(Lista_Ficheros.sig -1) loop
               --Insertamos la información, y lo mostramos por pantalla
               InsertarNodoFichero(Lista_Servers.Servers(Lista_Servers.sig).Ficheros,
                                   Lista_Ficheros.Ficheros(I).Nombre,
                                   Lista_Ficheros.Ficheros(I).Ruta);
               Ada.Text_Io.Put_Line(ASU.To_String(Lista_Ficheros.Ficheros(I).Ruta));
            end loop;
            Lista_Servers.sig:= Lista_Servers.sig + 1;
            Ada.Text_Io.Put_Line("");
         else
            Ada.Text_Io.Put_Line("Aviso: no se pueden registrar más server. El exportadir será avisado");
            Ada.Text_Io.Put_Line("");
            EstaLleno:=True;
         end if;
      else
         --Si ya está registrado...
         Ada.Text_Io.Put("petición  de catalogar recibida de  " & ASU.To_String(Ip_Server) & ":" &
                         Natural'Image(Port_Server) & " (ya registrado, refrescando información), ficheros : ");
         --Mantenemos su ip, modificamos el puerto (ha podido cambiar)
         Lista_Servers.Servers(Pos).port:= Port_Server;
         --Eliminamos su antigua lista de ficheros
         InicializarListaFicheros(Lista_Servers.Servers(Pos).Ficheros);
         --Y meteremos todos los posibles
         for I in 1..(Lista_Ficheros.sig - 1 ) loop
            --Refrescamos información de lista, y mostramos rutas por pantalla
            InsertarNodoFichero(Lista_Servers.Servers(Pos).Ficheros,
                                Lista_Ficheros.Ficheros(I).Nombre,
                                Lista_Ficheros.Ficheros(I).Ruta);
            Ada.Text_Io.Put_Line(ASU.To_String(Lista_Ficheros.Ficheros(I).Ruta));
         end loop;
         Ada.Text_Io.Put_Line("");
      end if;


   end InsertarNodoServer;

   -------------------------------------------------------------------------------------

   procedure InicializarListaBusq (Lista_Busq : in out TListaBusq) is
      -- Inicializa una lista de Busqueda
   begin
      for I in 1..MAX_BUSQ loop
        Lista_Busq.busquedas(I).Ip_exportadir:=ASU.Null_Unbounded_String;
        Lista_Busq.busquedas(I).port_exportadir:=0;
        Lista_Busq.busquedas(I).Ruta_fich:=ASU.Null_Unbounded_String;
      end loop;

      Lista_busq.sig:=1;
   end InicializarListaBusq;

   procedure PintaListaBusq (Lista_busq: in TListaBusq) is
      --Pinta la informacion de la lista de busquedas (para las trazas)

   begin
      Ada.Text_Io.Put_Line("Nº de sig busq :" & Natural'Image(Lista_busq.sig));

      for I in 1..(Lista_busq.sig -1) loop
         Ada.Text_Io.Put_Line("---------- Búsqueda nº" & Integer'Image(I) & " ------------");
         Ada.Text_Io.Put_Line("ip_server:" & ASU.To_String(Lista_busq.busquedas(I).Ip_exportadir));
         Ada.Text_Io.Put_Line("port_server:" & Natural'Image(Lista_busq.busquedas(I).Port_exportadir));
         Ada.Text_Io.Put_Line("ruta_dir:" & ASU.To_String(Lista_busq.busquedas(I).Ruta_Fich));
      end loop;
   end PintaListaBusq;

   procedure MuestraBusqueda (ListaBusq: in TListaBusq) is
      --Muestra los resultados de la busqueda con el formato especificado.
   begin
      for I in 1..(ListaBusq.Sig - 1) loop
         Ada.Text_Io.Put(ASU.To_String(ListaBusq.Busquedas(I).Ip_Exportadir));
         Ada.Text_Io.Put(":" & Natural'image(ListaBusq.Busquedas(I).Port_Exportadir));
         Ada.Text_Io.Put(" "& ASU.To_String(ListaBusq.Busquedas(I).Ruta_Fich));
         Ada.Text_Io.Put_Line("");
      end loop;
   end MuestraBusqueda;

   procedure InsertarNodoBusq (Lista_Busq: in out TListaBusq;
                               ip: in ASU.Unbounded_String;
                               port: in Natural;
                               Ruta : in ASU.Unbounded_String) is
      --Introduce la info de un nodo busqueda en la lista
   begin
      --Si no rebasamos el limite
      if (Lista_busq.sig) <= MAX_BUSQ then
         --Actualizamos indice, e insertamos informacion
         Lista_busq.busquedas(Lista_busq.sig).Ip_exportadir:= ip;
         Lista_busq.busquedas(Lista_busq.sig).port_exportadir:= port;
         Lista_busq.busquedas(Lista_busq.sig).ruta_fich:= ruta;
         Lista_Busq.Sig:= Lista_Busq.Sig + 1;

      else
         Ada.Text_Io.Put_Line("Aviso: superado limite de aciertos de busqueda");
      end if;



   end InsertarNodoBusq;

   function EsVacia (Lista_Busq: in TListaBusq) return Boolean is
      --Devuelve un booleano indicando si hay algun resultado
      EstaVacia:Boolean;
   begin
      EstaVacia:= Lista_Busq.Sig=1;
      return EstaVacia;
   end EsVacia;

   -------------------------------------------------------------------------------------
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

   procedure ExportarDirectorio (Lista_Ficheros: in out TListaFicheros;
                                 Directorio: ASU.Unbounded_String) is
      --Introduce en la lista de ficheros todos los archivos con su ruta hasta el lim de la lista
      Result: Listing.File_List_Type;
      Last: Natural := 0;

   begin
      --Llamamos a la funcion get_listing
      Listing.Get_Listing (ASU.To_String(Directorio), Result, Last);

      --Controlamos que haya algo que exportar
      if Last/=0 then
         --Insertamos todos los valores posibles, hasta MAX_FICHEROS  si lo rebasamos
         --o hasta last, si el nº es menor o igual (el indice se aumenta en la propia funcion)
         if Last>MAX_FICHEROS then
            for I in 1..MAX_FICHEROS loop
               InsertarNodoFichero(Lista_Ficheros,
                                   Get_Nombre_Fichero(Result(I)),
                                   Result(I));
            end loop;
         else
            for I in 1..Last loop
               InsertarNodoFichero(Lista_Ficheros,
                                   Get_Nombre_Fichero(Result(I)),
                                   Result(I));
            end loop;
         end if;
      else
         Ada.Text_Io.Put_Line("Aviso: El directorio exportado no contiene ningun archivo");
      end if;
   end ExportarDirectorio;


   ---------------------------------------------------------------------------------------
   procedure BuscarArchivo(Lista_Servers: in TListaServers;
                           Lista_Busq: in out TListaBusq;
                           Nombre_Arch: in ASU.Unbounded_String) is
      --Realiza la busqueda de un archivo en la lista de servidores.
      --Lo devuelve en una lista de busqueda, con la info de server y la ruta

   begin

      for I in 1..MAX_SERVERS loop
         for J in 1..(Lista_Servers.Servers(i).Ficheros.sig-1) loop
            if Lista_Servers.Servers(I).Ficheros.Ficheros(J).Nombre = Nombre_Arch then
               --Si el nombre es igual, guardaremos la info en nuestra lista de busqueda
               InsertarNodoBusq(Lista_Busq,Lista_Servers.Servers(I).Ip,
                               Lista_Servers.Servers(I).Port,
                               Lista_Servers.Servers(I).Ficheros.Ficheros(J).Ruta);
            end if;
         end loop;
      end loop;

   end BuscarArchivo;

   --------------------------------------------------------------------------------------
   function Get_T_Caducidad (Min_Ms : in Natural;
                             Max_Ms : in Natural) return float is
      --Devuelve el tiempo que tarda en caducarse una peticion en una ventana
      T_Espera:float;
      --Usamos float pq si no se pierde mucha precisión
      Min_Float: Float;
      Max_Float: Float;
   begin
      Min_Float:= Float(Min_Ms);
      Max_Float:= Float(Max_Ms);
      --Usamos un poco más del doble de las medias, y lo pasamos a sg
      T_Espera:=(((Max_Float-Min_Float)/2.0)*2.1)/1000.0;
      return T_Espera;
   end;
end Paquetes;

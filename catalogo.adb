-- *---------------------------------------------------------------------
--´       Práctica de Redes (3º ITIS)
--        ---------------------------
--
--        Servicio de intercambio de ficheros en internet (versión_final)
--                           #catalogo.adb#
--
--        Autor: David Rozas
-- ----------------------------------------------------------------------

with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_Io;
with Ada.Strings.Unbounded.Text_IO;
with Ada.Command_Line;
with Ada.Streams.Stream_Io;
with Ada.Streams;
with Paquetes;use Paquetes;
with Ada.Exceptions;

procedure Catalogo is

   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package SSIO renames Ada.Streams.Stream_IO;

   --Variables de catalogo
   EP_Catalogo: LLU.End_Point_Type;
   Buffer, buffer2: aliased LLU.Buffer_Type(20000);
   Expired : Boolean;
   Port_catalogo: natural;
   Ip_Catalogo: ASU.Unbounded_String;

   --Variables de config., recogida de parámetros y resto
   Retardo_Min,Retardo_Max,Porcentaje_perdidas: Natural;
   Lista_Servers: TListaServers;
   Id_Peticion: Natural;
   EstaLleno: Boolean;

   --Variables para recoger  peticiones de exportadir
   Ep_Exportadir: LLU.End_Point_Type;
   Ip_Exportadir: ASU.Unbounded_String;
   Port_Exportadir: Natural;
   Ficheros_Exportadir: TListaFicheros;

   --Variables para recoger peticiones de clientes napsyc
   Ep_napsyc: LLU.End_Point_Type;
   Nombre_Fich_Busq: ASU.Unbounded_String;
   listaBusq: TListaBusq;
   Busq_Vacia: Boolean;


begin

   --------------- Recogida de parámetros  y construcción de EP_catalogo----------
   --Obtengo la ip del catalogo
   Ip_catalogo:=ASU.To_Unbounded_String(LLU.To_Ip(LLU.Get_Host_Name));

   --Recojo el numero de puerto al que me tengo que atar
   Port_catalogo:= Natural'Value(Ada.Command_Line.Argument(1));

   -- construye un End_Point en una dirección y puerto concretos
   EP_catalogo:= LLU.Build (ASU.To_String(Ip_catalogo), Port_catalogo);

   --Y por último, los referentes a la configuración de la simulación de errrores
   Retardo_Min:= Natural'Value(Ada.Command_Line.Argument(2));
   Retardo_Max:= Natural'Value(Ada.Command_Line.Argument(3));
   Porcentaje_perdidas:= Natural'Value(Ada.Command_Line.Argument(4));

   ----------------------------------------------------------------------------------------

   --Nos atamos al EP
   LLU.Bind(Ep_Catalogo);

   -------- Configuración: parám. de simulación de retardos y inicializacio de variables---
   Put_Line("catalogo arrancado...");

   -- Simulador de pérdidas y retardos de propagación
   LLU.Set_Faults_Percent(Porcentaje_perdidas);
   LLU.Set_Random_Propagation_Delay(Retardo_min,Retardo_max);
   Put_Line("retardos de propagación entre" & Natural'Image(Retardo_Min) &
            " y" & Natural'Image(Retardo_Max) & " milisegundos.");
   Put_Line("porcentaje de pérdidas del" & Natural'Image(Porcentaje_Perdidas) & " %");
   Put_Line("aceptando peticiones en el puerto" & Natural'Image(Port_Catalogo));

   --Inicialización previa al bucle
   InicializarListaServers(Lista_Servers);
   EstaLleno:= false;
   InicializarListaBusq(ListaBusq);
   Busq_Vacia:= False;

   -----------------------------------------------------------------------------
   ------Conexion EXPORTADIR<>CATALOGO y NAPSYC<>CATALOGO-----------------------
   -- . Nos bloqueamos esperando recibir peticiones. Pueden llegarnos peticiones
   --   de tipos 1 y 5
   -- . Leemos de buffer. Respondemos en buffer2

   loop
      LLU.Reset(Buffer);
      --Nos bloqueamos a esperar peticiones
      LLU.Receive(Ep_Catalogo,Buffer'Access,1000.0,Expired);

      if Expired then
         Put(".");
      else
         --Si nos llegó algo...
         --Primero tenemos que comprobar que tipo de peticion.
         Id_Peticion:= Natural'Input(Buffer'Access);

         if Id_Peticion=EXP2CAT then
            --Si es una petición de exportadir...

            -- Leemos el buffer
            EP_Exportadir:= LLU.End_Point_Type'Input(Buffer'Access);
            IP_Exportadir:= ASU.Unbounded_String'Input(Buffer'Access);
            Port_Exportadir:= Natural'input(Buffer'Access);
            Ficheros_Exportadir:=TListaFicheros'Input(Buffer'Access);
            LLU.Reset(Buffer);

            --Ahora registraremos sus contenidos. La propia funcion se encarga
            --de ver si ya estaba registrado para refrescarlo, y de informar
            --en caso de que la lista de servers estuviera llena
            Put_Line("");
            InsertarNodoServer (Lista_Servers,Ip_Exportadir, Port_Exportadir,
                                Ficheros_Exportadir, EstaLleno);

            --Ahora solo nos queda contestar al server indicando si la
            -- operacion se realizo satisfactoriamente o no. le enviamos
            -- el valor del booleano indicando si esta o no lleno
            LLU.Reset(Buffer2);
            Natural'Output(Buffer2'Access,CAT2EXP);
            ASU.Unbounded_String'Output(Buffer2'Access,Ip_Exportadir);
            Boolean'Output(Buffer2'Access,Estalleno);
            LLU.Send(Ep_Exportadir,Buffer2'Access);
            LLU.Reset(Buffer2);


         elsif (Id_Peticion=NAP2CAT) then
            -- Si es una petición de napsyc...

            --Inicializamos variables de respuesta
            InicializarListaBusq(ListaBusq);
            Busq_Vacia:= False;

            -- Leemos el buffer
            EP_Napsyc:= LLU.End_Point_Type'Input(Buffer'access);
            Nombre_Fich_Busq:= ASU.Unbounded_String'Input(Buffer'access);
            LLU.Reset(Buffer);

            --Mostramos información de lo que nos piden
            Put("buscando " & ASU.To_String(Nombre_Fich_Busq) &"...");

            --Ahora realizamos la búsqueda en el catalogo
            BuscarArchivo(Lista_Servers,ListaBusq,Nombre_Fich_busq);

            --Comprobamos si hubo algun resultado, para avisar al napsyc si no en la resp.
            --El paquete de respuesta llevar la lista de res, solo si hubo algun resultado
            Busq_Vacia := EsVacia(ListaBusq);
            LLU.Reset(Buffer2);
            Natural'Output(Buffer2'Access,CAT2NAP);
            ASU.Unbounded_String'Output(Buffer2'Access,Nombre_Fich_Busq);
            Boolean'Output(Buffer2'Access,Busq_vacia);
            if Busq_Vacia then
               Put("no se han encontrado resultados..., enviando respuesta...");
            else
               Put(",enviando respuesta...");
               tListaBusq'Output(Buffer2'Access,listaBusq);
            end if;

            --y se la enviamos
            LLU.Send(EP_Napsyc,Buffer2'access);
            Put("hecho");
            Put_Line("");
            Put_Line("");
            LLU.Reset(Buffer2);

         else
            --si no corresponde con el formato
            Put_Line(".");
         end if;
      end if;

   end loop;

exception
   when Except: Constraint_Error =>
      Ada.Text_Io.Put_Line("uso : catalogo <puerto> <min_ms> <max_ms> <%_pérdidas>");
      Ada.Text_Io.Put_Line("");
   when Except: Others=>
     Ada.Text_Io.Put_Line("Saltó una excepcion: " & Ada.Exceptions.Exception_Name(Except));
     Ada.Text_Io.Put_Line("");

end Catalogo;

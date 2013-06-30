-- *---------------------------------------------------------------------
--´       Práctica de Redes (3º ITIS)
--        ---------------------------
--
--        Servicio de intercambio de ficheros en internet (versión_final)
--                           #exportadir.adb#
--
--        Autor: David Rozas
-- ----------------------------------------------------------------------

with Lower_Layer_UDP;
with Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_Io;
with Ada.Strings.Unbounded.Text_IO;
with Ada.Command_Line;
with Ada.Integer_Text_io;
with Ada.Streams.Stream_Io;
with Ada.Streams;
with Ficheros;
with Paquetes;use Paquetes;
with Ada.Exceptions;

procedure exportadir is
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package SSIO renames Ada.Streams.Stream_IO;

   use type ASU.Unbounded_String;

   -- Variables propias del exportadir
   EP_exportadir: LLU.End_Point_Type;
   Buffer, buffer2: aliased LLU.Buffer_Type(20000);
   Expired : Boolean;
   Port_exportadir: natural;
   Fd_FichOrig: SSIO.File_Type;
   Ip_exportadir: ASU.Unbounded_String;
   Retardo_Min,Retardo_Max,Porcentaje_perdidas: Natural;
   Id_Paquete_Recibido: Natural;
   Tam_Fich: SSIO.Count;

   -- Variables para recoger el paquete de petición del cliente
   Client_EP: LLU.End_Point_Type;
   RutaFichAux: ASU.Unbounded_String;
   NBloqueAux: Natural:=1;
   Directorio_servido: ASU.Unbounded_String;

   -- Variables para creacion del paquete de respuesta al cliente
   Desde: SSIO.Positive_Count;
   LongAux: Ada.Streams.Stream_Element_offset;
   DatosAux: Ada.Streams.Stream_Element_Array(1..Ficheros.TAM_BLOQUE);

   --Variables para conexion exportadir<>catalogo
   Nombre_Catalogo: ASU.Unbounded_String;
   Ip_Catalogo: ASU.Unbounded_String;
   Port_Catalogo: Natural;
   Ep_Catalogo: LLU.End_Point_Type;
   Catalogo_Lleno: Boolean;
   IpAux: ASU.Unbounded_String;

   --Variable con la lista de ficheros servidos en ese directorio
   Lista_Ficheros: TListaFicheros;



begin

   --------------- Recogida de parámetros  y construcción de EP_exportadir----------
   --Obtengo la ip del exportadir
   Ip_Exportadir:=ASU.To_Unbounded_String(LLU.To_Ip(LLU.Get_Host_Name));

   --Recojo el numero de puerto al que me tengo que atar
   Port_Exportadir:= Natural'Value(Ada.Command_Line.Argument(1));

   --Recojo el directorio que vamos a exportar
   Directorio_servido:=ASU.To_Unbounded_String(Ada.Command_Line.Argument(2));

   -- construye un End_Point en una dirección y puerto concretos
   EP_exportadir:= LLU.Build (ASU.To_String(Ip_Exportadir), Port_exportadir);

   --Recogemos parámetros referentes al catálogo
   Nombre_Catalogo:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(3));
   Ip_Catalogo:= ASU.To_Unbounded_String(LLU.To_Ip(ASU.To_String(Nombre_Catalogo)));
   Port_Catalogo:= Natural'Value(Ada.Command_Line.Argument(4));

   --Y por último, los referentes a la configuración de la simulación de errrores
   Retardo_Min:= Natural'Value(Ada.Command_Line.Argument(5));
   Retardo_Max:= Natural'Value(Ada.Command_Line.Argument(6));
   Porcentaje_perdidas:= Natural'Value(Ada.Command_Line.Argument(7));
   ----------------------------------------------------------------------------------------


   -------- Configuración: exportar directorio y parám. de simulación --------------
   Put_Line("exportadir arrancado, exportando " & ASU.To_String(Directorio_servido));
   --Llamamos a la funcion de exportar ficheros
   ExportarDirectorio(Lista_Ficheros,Directorio_servido);

   -- Simulador de pérdidas y retardos de propagación
   LLU.Set_Faults_Percent(Porcentaje_perdidas);
   LLU.Set_Random_Propagation_Delay(Retardo_min,Retardo_max);
   Put_Line("retardos de propagación entre" & Natural'Image(Retardo_Min) &
            " y" & Natural'Image(Retardo_Max) & " milisegundos.");
   Put_Line("porcentaje de pérdidas del" & Natural'Image(Porcentaje_Perdidas) & " %");
   ---------------------------------------------------------------------------------------

   --Nos atamos a nuestro end point
   LLU.Bind (EP_exportadir);

   ----------------Conexion EXPORTADIR<>CATALOGO-----------------------------
   -- . Preparamos el paquete de peticion y lo enviamos por Buffer
   -- . Parada y espera. Esperamos ACK en Buffer2

   --Ahora hay que enviarle dicha lista al catalogo
   Put("informando al catálogo en " & ASU.To_String(Nombre_Catalogo) &":"
            & Natural'Image(Port_Catalogo) & "...");
   --Construimos el end_point del catalogo
   EP_Catalogo:= LLU.Build(ASU.To_String(Ip_Catalogo), Port_Catalogo);

   --Preparamos el paquete peticion de registro en el catalogo
   LLU.Reset(Buffer);
   Natural'Output(Buffer'Access,EXP2CAT);
   LLU.End_Point_Type'Output(Buffer'Access,Ep_exportadir);
   ASU.Unbounded_String'Output(Buffer'Access,Ip_Exportadir);
   Natural'Output(Buffer'Access,Port_Exportadir);
   TListaFicheros'Output(Buffer'Access,Lista_Ficheros);

   loop
      --Enviamos el buffer
      LLU.Send(EP_Catalogo,Buffer'Access);

      --Nos bloqueamos esperando la respuesta
      --Usamos un segundo buffer, para no tener que rellenar el
      --otro en caso de tener que volver a solicitar el registro
      LLU.Reset(Buffer2);
      LLU.Receive(EP_Exportadir,Buffer2'Access,Duration(Get_T_Caducidad(Retardo_min,Retardo_max)),Expired);

      --Si llego algo, analizamos el paquete
      if not Expired then

         Id_Paquete_Recibido:= Natural'Input(Buffer2'Access);
         if Id_Paquete_Recibido=CAT2EXP then

            IpAux:=ASU.Unbounded_String'Input(Buffer2'Access);
            --Tenemos que comprobar que el Ack es para nosotros
            if IpAux=Ip_Exportadir then
               --Si la respuesta es del catalogo, vaciamos el buffer
               Put("el catalogo ha respondido...");
               Catalogo_Lleno:= Boolean'Input(Buffer2'Access);
            else
               --Si no era nuestra ip lo descartamos
               Put(".");
               --si no forzamos el expired para seguir pidiendolo
               Expired:=True;
               LLU.Reset(Buffer2);
            end if;--if comprobacion ip

         else
            Put(".");
            --Asi que reseteamos el buffer, y forzamos expired para que vuelva a pedirlo
            LLU.Reset(Buffer2);
            Expired:=True;
         end if;--if formato correcto
      else
         --Si no, reiniciamos el buffer para volver a recibir en el
         Put(".");
         LLU.Reset(Buffer2);
      end if; --if expired

      --Volvemos a solicitarlo si expiro, o si no era un paquete correcto
      exit when (not Expired);
   end loop;

   if Catalogo_Lleno then
      Put("AVISO: El catalogo estaba lleno.  ¡ No ha sido posible registrar la lista de ficheros !");
      Put_Line("");
   else
      Put("catalogo actualizado");
      Put_Line("");
   end if;

   ----------------------------------------------------------------------------------------


   --------------------- CONEXION EXPORTADIR<>NAPSYC ------------------------------------
   -- . Bucle infinito para implementar protocolo de ventanas
   -- . Envia y recibe por la misma variable buffer

   Ada.Text_Io.Put("esperando peticiones de clientes napsyc...");
   loop
      LLU.Reset(Buffer);
      LLU.Receive (EP_exportadir, Buffer'Access, 1000.0, Expired);

      --Si no llegan peticiones
      if Expired then
         Ada.Text_IO.Put(".");
         LLU.Reset(Buffer);
      else
         -- Si recibimos algo, analizamos el id de paquete
         Id_Paquete_Recibido:= Natural'Input(Buffer'Access);
         if Id_Paquete_Recibido=NAP2EXP then

            --Si es del napsyc, vaciamos el buffer
            Client_EP := LLU.End_Point_Type'Input (Buffer'Access);
            RutaFichAux:= ASU.Unbounded_String'Input(Buffer'Access);
            NBloqueAux:= Natural'Input(Buffer'Access);
            LLU.Reset(Buffer);

            --Mostramos informacion del bloque solicitado por pantalla
            Put_Line("");
            Put("petición de " & ASU.To_STring(RutaFichAux)
                     &", bloque " & Positive'Image(NBloqueAux) & " ... ");

            --Comprobamos si servimos el fichero
            if ExisteFichero(Lista_Ficheros,RutaFichAux) then

               --Si existe el fichero, lo abrimos y leemos de él
               SSIO.Open(Fd_FichOrig, SSIO.In_File, (ASU.To_String(Directorio_servido)&
                                                     "/" & ASU.To_String(RutaFichAux)));
               Tam_Fich:=SSIO.Size(Fd_FichOrig);

               -- Vamos a hacer la llamada al read de 4 param, para ahorrarnos el set_index:
               -- fichero+datos+ultimo a leer+ desde donde empezar a leer
               -- Así que primero, calculamos el desplazamiento
               Desde:= Ficheros.PosicionAnterior(NBloqueAux);
               SSIO.Read(Fd_FichOrig,DatosAux,longAux,Desde);
               SSIO.Close(Fd_FichOrig);

               -- Preparamos el paquete de respuesta al cliente
               Natural'Output(Buffer'Access,EXP2NAP);
               ASU.Unbounded_String'Output(Buffer'Access,rutaFichAux);
               Boolean'Output(Buffer'Access,True);
               SSIO.Count'Output(Buffer'Access,Tam_Fich);
               Natural'Output(Buffer'Access,NBloqueAux);
               Ada.streams.Stream_Element_Offset'Output(Buffer'Access,LongAux);
               Ada.Streams.Stream_Element_Array'Output(Buffer'Access,DatosAux(1..longAux));

               --Y enviamos...
               LLU.Send(Client_EP,Buffer'Access);
               Put("enviado.");
               Put_Line("");
               LLU.Reset(Buffer);

            else
               --Si no existe el fichero, avisaremos al cliente napsyc a traves del booleano
               Natural'Output(Buffer'Access,EXP2NAP);
               ASU.Unbounded_String'Output(Buffer'Access,rutaFichAux);
               Boolean'Output(Buffer'Access,false);
               Natural'Output(Buffer'Access,NBloqueAux);
               LLU.Send(Client_EP,Buffer'Access);
               LLU.Reset(Buffer);
               put("no disponemos de ese fichero. El napsyc será advertido.");
               Put_Line("");
            end if;
         else
            Put(".");
            LLU.Reset(Buffer);
         end if;--id_paquete
      end if;--expired
   end loop;

exception
   when Except: Constraint_Error =>
      Ada.Text_Io.Put_Line("uso : exportadir <puerto> <directorio> <host_catalogo> <port_catalogo> <min_ms> <max_ms> <%_pérdidas>");
      Ada.Text_Io.Put_Line("");
   when Except: Others=>
     Ada.Text_Io.Put_Line("Salto una excepcion: " & Ada.Exceptions.Exception_Name(Except));
     Ada.Text_Io.Put_Line("");

end exportadir;

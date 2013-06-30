-- *---------------------------------------------------------------------
--´       Práctica de Redes (3º ITIS)
--        ---------------------------
--
--        Servicio de intercambio de ficheros en internet (versión_final)
--                           #napsyc.adb#
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
with Ada.Calendar;
with Ficheros;
with Ventanas;
with Paquetes; use Paquetes;
with Ada.Exceptions;
with Gnat.Directory_Operations;

procedure napsyc is
   use type Ada.Calendar.Time;
   package LLU renames Lower_Layer_UDP;
   package ASU renames Ada.Strings.Unbounded;
   package SSIO renames Ada.Streams.Stream_IO;
   package AC renames Ada.Calendar;
   package GDO renames Gnat.Directory_Operations;

   use type ASU.Unbounded_String;

   ---------------------------------------------------------------
   --      Procedimiento Descarga (mediante protocolo de ventanas)
   ---------------------------------------------------------------
   procedure Descarga (Client_EP,Server_EP: in LLU.End_Point_Type;
                       RutaFichero: in out ASU.Unbounded_String;
                       N_Ventanas: in Natural;
                       T_caducidad: in Float;
                       Timeout: in Natural) is

      Buffer: aliased LLU.Buffer_Type(20000);
      Expired : Boolean;
      Fd_FichDest: SSIO.File_Type;

      --Variables para cuando leemos el paquete que nos envia el server
      BloqueSig: Natural:=1; --Controla el nBloque más avanzado
      RutaFichAux : ASU.Unbounded_String;
      DatosAux: Ada.Streams.Stream_Element_Array(1..Ficheros.TAM_BLOQUE);
      Desde: SSIO.Positive_Count;
      BloqueQueLlego: Natural;
      LongBloqueQueLlego: Ada.Streams.Stream_Element_offset;
      Existe_En_server: Boolean;
      Id_Paquete_Recibido: Natural;
      Tam_Fich: SSIO.count;
      EsPrimeraVez: Boolean;
      Max_Bloques_Fich: Natural;

      --Variables para calculo de tiempo de descarga y timeout
      InicioDescarga:AC.Time;
      PlazoExpirado: Boolean;
      Hora_Actual: AC.time;
      Hora_Ult_envio: AC.Time;

      --Variables de protocolo de ventanas
      Ventana: Ventanas.TVentana;
      i,j: Positive:=1;
      HoraActual:AC.Time;
      TodosPedidos:Boolean:=FALSE;
      HaCaducado:Boolean:=FALSE;

   begin
      --Inicialización de variables previas al bucle
      PlazoExpirado:=False;
      Ventanas.InicializarVentanas(Ventana,N_ventanas);
      BloqueSig:=1;
      InicioDescarga:=AC.Clock;
      Existe_En_server:=True;
      Ada.Text_Io.Put_Line("descargando...");
      EsPrimeravez:= True;
      TodosPedidos:= False;
      Max_Bloques_Fich:= 100000;--lo forzamos con un nº mayor al de los huecos, para que arranque la primera vez

      loop

         --Bloque de envío de peticiones "nuevas": tantas como huecos libres
         -------------------------------------------------------------------
         I:=1;
         if BloqueSig<= Max_Bloques_Fich then
            --Si aun quedan bloques "nuevos" por pedir...
            while (I<=Ventana.ult) loop

               if not (Ventana.marcos(i).Ocupada) then
                  -- reinicializa el buffer para empezar a utilizarlo
                  LLU.Reset(Buffer);
                  -- Preparacion del paquete de solicitud
                  Natural'Output(Buffer'Access,NAP2EXP);
                  LLU.End_Point_Type'Output(Buffer'Access, Client_EP);
                  ASU.Unbounded_String'Output(Buffer'Access, rutaFichero);
                  Natural'Output(Buffer'Access, BloqueSig);

                  -- envía el contenido del Buffer
                  LLU.Send(Server_EP, Buffer'Access);
                  Ada.Text_Io.Put_line("Solicitando bloque" &
                                       Natural'Image(BloqueSig) & ", intento 1");

                  --Si la ocupo, ocupo hueco con el bloqueActual
                  Ventanas.OcuparNodo(Ventana,I,BloqueSig);

                  --y actualizo aquí el bloque pedido "más avanzado"
                  BloqueSig:= BloqueSig  + 1;

                  --y apuntamos la hora del ultimo envio de "nuevo bloque"
                  Hora_Ult_Envio:=AC.Clock;

               end if;
               I:=I+1;
            end loop;
         else
            TodosPedidos:=True;
         end if;
         ---------------------------------------------------------------------

         -- Recepción de paquetes de respuesta
         ----------------------------------------------------------------------
         LLU.Reset(Buffer); --lo limpiamos antes de recibir
         LLU.Receive(Client_EP, Buffer'Access,Ventanas.Get_T_Espera_Rec(Ventana), Expired);

         if Expired then
            --Si no llegó nada...
            --Comprobamos que no se haya pasado el timeout
            Hora_Actual:= AC.Clock;
            if (Hora_Actual-Hora_Ult_Envio)>Duration(Timeout) then
               Ada.Text_Io.Put_Line("plazo máximo de espera agotado");
               PlazoExpirado:=True;
            end if;
         else
            --Si hubo alguna respuesta...

            --Tratamiento de paquete de respuesta
            ------------------------------------------
            --Primero vamos a comprobar si el id es correcto
            Id_Paquete_Recibido:= Natural'Input(Buffer'Access);
            if Id_Paquete_Recibido = EXP2NAP then

               --A continuación miramos si corresponde a lo que estamos pidiendo
               rutaFichAux:= ASU.Unbounded_String'Input(Buffer'Access);
               if RutaFichAux=RutaFichAux then

                  --Despues comprobamos si el server dispone de él
                  Existe_En_Server:= Boolean'Input(Buffer'Access);
                  if Existe_En_Server then

                     tam_fich:= SSIO.count'Input(Buffer'Access);
                     BloqueQueLlego:= Natural'Input(Buffer'Access);

                     --Y comprobamos si no lo hemos escrito ya
                     if Ventanas.EstaEnVentana(Ventana,BloqueQueLlego) then
                        LongBloqueQueLlego:= Ada.Streams.Stream_Element_offset'Input(Buffer'Access);
                        --Liberamos el hueco de ese bloque
                        Ventanas.LiberarHueco(Ventana,BloqueQueLlego);

                        if EsPrimeraVez then
                           -- Si es el primer bloque que llega...
                           -- Creamos el archivo
                           SSIO.Create(Fd_FichDest, SSIO.Out_File, "./incoming/"&
                                       ASU.To_String(Get_Nombre_Fichero(RutaFichero)));
                           --Y calculamos el n_total de bloques
                           Max_Bloques_Fich:= Ficheros.NTotalBloques(Tam_Fich);
                           --Este es el valor que servirá de tope al bucle de "peticiones nuevas", y que forzamos al inicio
                           EsPrimeraVez:=False;
                        else
                           --Si no, simplemente lo abrimos
                           SSIO.Open(Fd_FichDest, SSIO.Append_File,"./incoming/"&
                                     ASU.To_String(Get_Nombre_Fichero(RutaFichero)));
                        end if;

                        DatosAux(1..LongBloqueQueLlego):= Ada.Streams.Stream_Element_Array'Input(Buffer'Access);
                        Desde:= Ficheros.PosicionAnterior(BloqueQueLlego);
                        LLU.Reset(Buffer); -- aqui habra q limpiarlo de nuevo

                        -- Escritura del paquete de datos de respuesta, solo si hay datos
                        if Ficheros.AlgoQueEscribir(LongBloqueQueLlego) then
                           SSIO.Write(Fd_FichDest,DatosAux(1..LongBloqueQueLlego),desde);
                        end if;

                        -- Cerramos en cada vuelta de bucle, y luego volvemos a abrir desde la pos. anterior
                        SSIO.Close(Fd_FichDest);

                     end if;--controlar BloqueQueLlego
                  end if;--existe en server
               end if;--comprobacion nombre
            end if;--id_paquete_recibido
         end if;-- no expiro


         -- Reenvio de peticiones caducadas
         -- ----------------------------------
         if (not PlazoExpirado) then
            if not Ventanas.EsVacia(Ventana) then
               for J in 1..Ventana.ult loop

                  HoraActual:= AC.Clock;

                  HaCaducado:= Float(HoraActual-Ventana.marcos(J).HoraPeticion)>=T_caducidad;
                  if (Ventana.marcos(J).Ocupada) and haCaducado then
                     --Apuntamos que ha sido pedido una vez mas
                     Ventana.Marcos(J).NVecesPedido:=Ventana.Marcos(J).NVecesPedido+1;
                     --Si se cumplio el plazo, la volvemos a pedir
                     Put_Line("Solicitando bloque" & Natural'Image(Ventana.Marcos(J).NBloquePedido)
                              & ", intento" & Natural'Image(Ventana.Marcos(J).NVecesPedido));
                     --Preparación de paquete de solicitud
                     LLU.Reset(Buffer);
                     Natural'Output(Buffer'Access,NAP2EXP);
                     LLU.End_Point_Type'Output(Buffer'Access, Client_EP);
                     ASU.Unbounded_String'Output(Buffer'Access, rutaFichero);
                     Integer'Output(Buffer'Access,Ventana.marcos(j).NBloquePedido);

                     --Nueva hora de petición
                     Ventana.marcos(J).HoraPeticion:=AC.Clock;

                     -- envía el contenido del Buffer
                     LLU.Send(Server_EP, Buffer'Access);
                     LLU.Reset(Buffer);
                  end if;
               end loop;
            end if;
         end if;

         -- Salimos si:
         -- . Si hemos pedido todo y las ventanas estan vacias ->todo llego: transmitido correctamente
         -- . Si no existe en el server, o si se cumplió el plazo máximo de espera
         exit when (Ventanas.EsVacia(Ventana) and TodosPedidos) or (not Existe_En_server) or (PlazoExpirado);
      end loop;

      if not PlazoExpirado then
         if Existe_En_Server then
            HoraActual:=AC.Clock;
            Put_Line("descarga finalizada. Tiempo : " & Standard.Duration'Image(HoraActual - InicioDescarga));
            if Max_Bloques_fich= 0 then
               Put_Line("Aviso: el contenido del fichero que has descargado es un fichero vacio.");
            end if;
         else
            Put_Line("fichero inexistente en ester server. Descarga cancelada. ");
         end if;
      end if;
   end Descarga;
   --------------------------------------------------------------------------------------------------------


   procedure ParseoComandoDescarga (comando: in ASU.Unbounded_String;
                                     Server: in out ASU.Unbounded_String;
                                     Port: in out Natural;
                                     Nombre_Fich: in out ASU.Unbounded_String;
                                     Correcto: in out Boolean) is
      -- Se utiliza para parsear la linea de entrada de la ejecucion del comando descarga
      Pos:Natural;
      Port_Asu: ASU.Unbounded_String;
      Cad: ASU.Unbounded_String;

   begin
      Cad:= Comando;

      --Con el primer if evitamos que se cuelgue si meten solo "descarga"
      --y comprobando la pos nos aseguramos de que al menos haya ese nº de parametros

      if ASU.Length(Cad)>0 then
         Pos:= ASU.Index(Cad," ");
         if Pos>0 then
            server:=ASU.Head(Cad,Pos-1);

            --recortamos de pos + 1 a fin..
            cad:= ASU.To_Unbounded_String(ASU.To_String(Cad)(Pos + 1..ASU.Length(Cad)));

            Pos:=ASU.Index(Cad," ");

            if Pos>0 then
               Port_asu:=ASU.Head(Cad,Pos-1);
               Port:= Natural'Value(ASU.To_String(Port_asu));
               Nombre_fich:=  ASU.To_Unbounded_String(ASU.To_String(Cad)(Pos + 1..ASU.Length(Cad)));
               Correcto:=True;
            else
               Correcto:=False;
            end if;
         else
            Correcto:=False;
         end if;
      else
         Correcto:=False;
      end if;


   end;
   -------------------------------------------------------------------

   --VARIABLES DE PROGRAMA PRINCIPAL

   --Variables de Napsyc
   EP_Napsyc: LLU.End_Point_Type;
   Buffer1,Buffer2:aliased LLU.Buffer_Type(20000);

   --Variables de exportadir
   EP_Exportadir: LLU.End_Point_Type;
   Ip_Exportadir: ASU.Unbounded_String;
   Port_Exportadir: Natural;
   Fich_Desc: ASU.Unbounded_String;

   --Variables de catalogo
   EP_catalogo: LLU.End_Point_Type;
   Port_Catalogo: Natural;
   Ip_Catalogo: ASU.Unbounded_String;
   Nombre_Catalogo: ASU.Unbounded_String;
   ListaBusq: TListaBusq;
   Fich_Busq: ASU.Unbounded_String;
   Busq_Vacia: Boolean;
   Primer_Envio_Catalogo, Plazo_Agotado: Boolean;
   Hora_Primer_Envio_Catalogo, HoraActual: AC.Time;
   NombreFichAux: ASU.Unbounded_String;

   --Variables de configuracion
   Min_Ms,Max_Ms,Porc_Perdidas,Tam_Ventana, timeout: Natural;

   --Variables para la interfaz
   Comando_aux: String(1..100);
   Car_Leidos: Integer;
   Comando: ASU.Unbounded_String;
   Terminar: Boolean:=False;

   --otras...
   Expired:Boolean;
   Id_Paquete_Recibido: Natural;
   Parseo_Correcto: Boolean;
   Dir_incoming: GDO.Dir_Type;
begin


   --------------- Recogida de parámetros -----------------------------
   --Recogemos el nombre y el puerto del catalogo
   nombre_catalogo:= ASU.To_Unbounded_String(Ada.Command_Line.Argument(1));
   Port_Catalogo:= Natural'Value(Ada.Command_Line.Argument(2));
   Ip_Catalogo:= ASU.To_Unbounded_String(LLU.To_Ip(ASU.To_String(Nombre_Catalogo)));

   --Y los parametros de configuracion: tam_ventana , timeout y simulacion de errores
   Tam_Ventana:=Natural'Value(Ada.Command_Line.Argument(3));
   if Tam_Ventana>Ventanas.LIM_VENTANAS then
      Tam_Ventana:=Ventanas.LIM_VENTANAS;
      Ada.Text_Io.Put_Line("Aviso: El tamaño de las ventanas excede el máximo permitido. Se ha fijo el nº de ventanas a"
                           & Natural'Image(Tam_Ventana));
   end if;
   Min_Ms:=Natural'Value(Ada.Command_Line.Argument(4));
   Max_Ms:=Natural'Value(Ada.Command_Line.Argument(5));
   Porc_Perdidas:= Natural'Value(Ada.Command_Line.Argument(6));
   Timeout:= Natural'Value(Ada.Command_Line.Argument(7));
   ---------------------------------------------------------------------


   --Construimos el EP del catalogo
   EP_Catalogo:= LLU.Build(ASU.To_String(Ip_Catalogo),Port_Catalogo);

   --Y construye un EP para el y se ata, en un puerto cualquiera
   LLU.Bind_Any(EP_Napsyc);

   -- Simulador de pérdidas y retardos de propagación
   LLU.Set_Faults_Percent(Porc_perdidas);
   LLU.Set_Random_Propagation_Delay(Min_ms,Max_ms);

   --Motramos información de configuración
   Ada.Text_Io.Put_Line("napsyc arrancado");
   Ada.Text_Io.Put_Line("usando el catalogo en " & ASU.To_String(Nombre_Catalogo)
                        & ":" & Natural'Image(Port_Catalogo));
   Ada.Text_Io.Put_Line("ventana de" & Natural'Image(Tam_Ventana) & " posiciones");
   Ada.Text_Io.Put_Line("retardos de propagacion entre" & Natural'Image(Min_Ms)
                        & " y" & Natural'Image(Max_Ms) & " milisegundos");
   Ada.Text_Io.Put_Line("porcentaje de pérdidas del " & Natural'Image(Porc_Perdidas) &"%");
   Ada.Text_Io.Put_Line("plazo máximo de espera de" & Natural'Image(Timeout) & " segundos");

   begin
      GDO.Open(Dir_Incoming,"./incoming");
   exception when Except:GDO.Directory_Error =>
      Ada.Text_IO.Put_Line ("creado directorio incoming por primera vez");
      GDO.Make_Dir("./incoming");
   end;

   Ada.Text_Io.Put_Line("los ficheros se guardarán en la carpeta incoming");

   loop
      LLU.Reset(Buffer1);
      LLU.Reset(Buffer2);
      --Inicializamos la variable con la que trabajaremos
      Comando:= ASU.Null_Unbounded_String;
      Parseo_Correcto:= false;
      Fich_Busq:= ASU.Null_Unbounded_String;
      Fich_Desc:= ASU.Null_Unbounded_String;


      Ada.Text_Io.Put("napsyc> ");
      --Recogemos en un string, pero luego trabajamos con un unbounded
      Ada.Text_Io.Get_Line(Comando_Aux,Car_Leidos);
      Comando:= ASU.To_Unbounded_String(Comando_Aux(1..Car_Leidos));

      --Análisis de cadena de entrada
      if ASU.Head(Comando,7)= ASU.To_Unbounded_String("termina") then
         -- Finalización del programa
         Terminar:=True;
      elsif ASU.Head(Comando,6)= ASU.To_Unbounded_String("busca ") then
         --Búsqueda

         -- Conexion napsyc<>catalogo
         ----------------------------

         InicializarListaBusq(ListaBusq);
         Expired:=False;

         --Recogemos el nombre del fichero a buscar de la interfaz
         Fich_Busq:= ASU.To_Unbounded_String(ASU.To_String(Comando)(7..ASU.Length(Comando)));
         --Comprobamos que no este vacio
         if Fich_Busq=ASU.Null_Unbounded_String then
            Ada.Text_Io.Put_Line("uso: busca <fichero>");
         else

            --Preparamos la peticion de búsqueda.
            LLU.Reset(Buffer1);
            Natural'output(Buffer1'Access,NAP2CAT);
            LLU.End_Point_Type'output(Buffer1'Access,EP_Napsyc);
            ASU.Unbounded_String'Output(Buffer1'Access,Fich_Busq);
            Ada.Text_Io.Put("consultando al catalogo...");
            Primer_Envio_Catalogo:= True;
            Plazo_Agotado:= False;

            --Nos metemos en un bucle para hacer parada/espera
            loop
               --Enviamos la peticion al catalogo
               LLU.Send(EP_Catalogo,Buffer1'Access);

               --Apuntamos la hora del primer envio, para comprobar si hubo timeout
               if Primer_Envio_Catalogo then
                  Primer_Envio_Catalogo:=False;
                  Hora_Primer_Envio_Catalogo:= AC.Clock;
               end if;

               LLU.Reset(Buffer2);
               --Y nos bloquearemos esperando.
               LLU.Receive(EP_Napsyc,Buffer2'Access,
                           Duration(Get_T_Caducidad(Min_Ms,Max_Ms)),Expired);

               --Si expiró el plazo, no saldremos del bucle
               if Expired then

                  HoraActual:= AC.Clock;
                  if (HoraActual-Hora_Primer_Envio_catalogo) > Duration(Timeout) then
                     Ada.Text_Io.Put_Line("plazo máximo de espera agotado");
                     Plazo_Agotado:=True;
                  else
                     Ada.Text_Io.Put(".");
                  end if;

               else
                  --Si llegó algo

                  --Primero comprobamos que sea un paquete de tcAt2Nap
                  Id_Paquete_Recibido:= Natural'Input(Buffer2'Access);
                  if Id_Paquete_Recibido = CAT2NAP then

                     --Si es de ese tipo, comprobamos que sea del fichero que hemos pedido
                     NombreFichAux:= ASU.Unbounded_String'Input(Buffer2'Access);
                     if NombreFichAux=Fich_Busq then

                        Busq_Vacia:=Boolean'Input(Buffer2'Access);
                        --Sacaremos la lista, solo si hubo algun resultado
                        if not Busq_Vacia then

                           --Si hay resultados los mostramos
                           ListaBusq:= TListaBusq'Input(Buffer2'Access);
                           Ada.Text_Io.Put_Line("resultado de la búsqueda : ");
                           MuestraBusqueda(ListaBusq);
                        else
                           --Y si no informamos de que no se encontró nada
                           Ada.Text_Io.Put_Line("La búsqueda no ha devuelto ningún resultado");
                        end if;
                     else
                        Ada.Text_Io.Put(".");
                        --Reseteamos el buffer, y forzamos el expired para no salir
                        LLU.Reset(Buffer2);
                        Expired:=True;
                     end if;--comprobacion nombre_fich
                  else
                     ADA.Text_Io.Put(".");
                     --Reseteamos el buffer, y forzamos el expired para no salir
                     LLU.Reset(Buffer2);
                     Expired:=True;
                  end if;--id_paquete
               end if;--expired

               --Y saldremos, solo cuando hayamos recibido la respuesta correctamente
               exit when (not Expired) or (Plazo_Agotado);
            end loop;
         end if;

      elsif ASU.Head(Comando,9)= ASU.To_Unbounded_String("descarga ") then
         --recortamos "descarga " y llamamos a la funcion de parseo
         comando:= ASU.To_Unbounded_String(ASU.To_String(comando)(10..ASU.Length(comando)));

         ParseoComandoDescarga(Comando,Ip_Exportadir,Port_Exportadir, Fich_desc,Parseo_Correcto);

         if (not Parseo_Correcto) then
            ADA.Text_Io.Put_Line("uso: descarga <server> <puerto> <fich_con_ruta>");
         else
            --Si el parseo se hizo correctamente, preparamos el EP del exportadir
            EP_exportadir:= LLU.Build(ASU.To_String(Ip_exportadir), Port_exportadir);
            --y llamamos a la funcion de descarga
            Descarga(Ep_napsyc,Ep_exportadir,Fich_Desc,Tam_Ventana,Get_T_Caducidad(Min_Ms,Max_Ms),timeout);
         end if;

      elsif ASU.Head(Comando,5)= ASU.To_Unbounded_String("ayuda") then
         Ada.Text_Io.Put_Line("");
         Ada.Text_Io.Put_Line("     busca <fichero>");
         Ada.Text_Io.Put_Line("     >>>descripción: busca servidores donde este albergado ese fichero<<<");
         Ada.Text_Io.Put_Line("");
         Ada.Text_Io.Put_Line("     descarga <server> <puerto> <fich_con_ruta>");
         Ada.Text_Io.Put_Line("     >>>descripción:descarga un fichero del server especificado<<<");
         Ada.Text_Io.Put_Line("");
         Ada.Text_Io.Put_Line("     termina");
         Ada.Text_Io.Put_Line("     >>>descripción: finaliza la ejecución del programa<<<");
         Ada.Text_Io.Put_Line("");
      else
         Ada.Text_Io.Put_Line("Comando desconocido. Escribe ayuda para ver los comandos disponibles.");
      end if;

      exit when(Terminar);
   end loop;

   --Nos desatamos
   LLU.Unbind (EP_napsyc);
   LLU.Finalize;

exception
   when Except: Constraint_Error =>
      Ada.Text_Io.Put_Line("uso : napsyc <host_catalogo> <port_catalogo> <tam_ventanas> <min_ms> <max_ms> <%_pérdidas> <plazo_max_espera>");
      Ada.Text_Io.Put_Line("");
   when Except: Others=>
     Ada.Text_Io.Put_Line("Saltó una excepcion: " & Ada.Exceptions.Exception_Name(Except));
     Ada.Text_Io.Put_Line("");


end napsyc;

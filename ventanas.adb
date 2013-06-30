-- *---------------------------------------------------------------------
--´       Práctica de Redes (3º ITIS)
--        ---------------------------
--
--        Servicio de intercambio de ficheros en internet (versión_final)
--                           #ventanas.adb#
--
--        Autor: David Rozas
-- ----------------------------------------------------------------------


package body Ventanas is

   function EsVacia(Ventana: in TVentana) return Boolean is
      -- Recorre todos los marcos y nos dice si existe alguno
      AlgunaOcupada: Boolean:=FALSE;
      I: Positive:=1;
   begin
      while  I<= Ventana.ult and not algunaOcupada loop
         -- si hay alguna q este ocupada-> ya no estará vacía
         if (Ventana.marcos(I).Ocupada=TRUE) then
            AlgunaOcupada:=TRUE;
         end if;
         I:=I+1;
      end loop;

      return not AlgunaOcupada;
   end EsVacia;

   procedure LiberarHueco(Ventana: in out TVentana; NBloqueABorrar: in Natural) is
      -- Libera el hueco de la ventana con el nBloque que le pasamos
      I: Positive:=1;
   begin
      for I in 1..Ventana.ult loop
         if Ventana.marcos(I).NBloquePedido=NBloqueABorrar then
            Ventana.marcos(I).Ocupada:=FALSE;
            Ventana.marcos(I).NBloquePedido:=0;
            Ventana.marcos(I).HoraPeticion:=AC.Clock;
            Ventana.Marcos(I).NVecesPedido:=0;
         end if;
      end loop;
   end LiberarHueco;


   procedure OcuparNodo (Ventana: in out TVentana; Pos: in Positive; BloquePedidoAux: in Natural) is
      --Rellena un nodo de la ventana cuya posición le pasamos, con la info del bloque q le pasamos
   begin
      Ventana.marcos(Pos).NBloquePedido:=BloquePedidoAux;
      Ventana.marcos(Pos).Ocupada:=TRUE;
      Ventana.marcos(Pos).HoraPeticion:=AC.Clock;
      Ventana.Marcos(Pos).NVecesPedido:=1;
   end;

   procedure InicializarVentanas(Ventana: in out TVentana; Lim: in natural) is
      --Inicializa las ventanas desocupando y poniendo la hora actual
      I: Positive :=1;
   begin
      --Inicializamos toda la estructura; pero la tenemos acotada por un parametro
      for I in 1..LIM_VENTANAS loop
         Ventana.marcos(I).NBloquePedido:=0;
         Ventana.marcos(I).Ocupada:=FALSE;
         Ventana.marcos(I).HoraPeticion:=AC.CLOCK;
         Ventana.Marcos(I).NVecesPedido:=0;
      end loop;
      --Ademas marcamos el limite, que será un parametro a recoger desde el prompt
      Ventana.Ult:= Lim;

   end InicializarVentanas;

   function estaEnVentana (Ventana: in TVentana; BloqueAConsultar: in Natural) return Boolean is
      -- Recorremos todas las ventanas para ver si este bloque ha sido o no pedido
      -- Se pone a true, con que lo encuentre una vez
      I:Positive:=1;
      Esta: Boolean:=FALSE;
   begin
      for I in 1..Ventana.ult loop
         if Ventana.marcos(I).Ocupada and (Ventana.marcos(I).NbloquePedido=BloqueAConsultar) then
            Esta:=TRUE;
         end if;
      end loop;
      return Esta;
   end estaEnVentana;

   procedure PintarEstadoVentanas(Ventana: in TVentana) is
   --Generamos la traza con el bloque actual que esta albergando ese marco
   I:Positive:=1;
   begin
      Put_Line("---(Marcos)---");
      for I in 1..Ventana.ult loop
         Put("|" &Positive'Image(Ventana.marcos(I).NBloquePedido)& ":"& Natural'Image(Ventana.Marcos(I).NVecesPedido));
      end loop;
      Put("|");
      Put_Line(" ");
   end PintarEstadoVentanas;

   function Get_Hora_Minima (Ventana: in TVentana) return AC.Time is
      --Obtiene la "menor hora" de las peticiones pendientes
      Hora_Min: AC.Time := AC.Clock;--Lo inicializamos con la hora actual
   begin
      for I in 1..Ventana.Ult loop
         --Cogemos el menor de las que esten pendientes
         if Ventana.Marcos(I).Ocupada and Ventana.Marcos(I).HoraPeticion<Hora_min then
            Hora_Min:=Ventana.Marcos(I).HoraPeticion;
         end if;
      end loop;
      return hora_Min;
   end Get_Hora_Minima;


   function Get_T_Espera_rec(Ventana: in TVentana) return Duration is
      --Devuelve el tiempo de bloqueo en receive del protocolo de ventanas
      --desde la hora actual hasta que se cumpla la primera "caducidad" de peticiones pendientes
      Hora_Min: AC.Time;
      T_Espera_Min: Duration;
   begin
      hora_Min:= Get_Hora_Minima(Ventana);
      T_Espera_Min:= (AC.Clock - Hora_Min);
      return T_Espera_Min;
   end Get_T_Espera_rec;

end Ventanas;

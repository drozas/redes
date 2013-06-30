-- *---------------------------------------------------------------------
--�       Pr�ctica de Redes (3� ITIS)
--        ---------------------------
--
--        Servicio de intercambio de ficheros en internet (versi�n_final)
--                           #ficheros.adb#
--
--        Autor: David Rozas
-- ----------------------------------------------------------------------


package body Ficheros is

   -------------------------------------------------------------------------------------------------
   function AlgoQueEscribir(LongPaquete: in Ada.Streams.Stream_Element_Offset) return Boolean is
   -- Observa la longitud del paquete, y devuelve un boolean cuyo valor depende de si es o no paquete vac�o
     HayAlgo:Boolean:=TRUE;
   begin
      if (Integer(LongPaquete)>0) then
         HayAlgo:=TRUE;
      else
        HayAlgo:=FALSE;
      end if;
      return HayAlgo;
   end AlgoQueEscribir;

   ---------------------------------------------------------------------------------------------------

   function PosicionAnterior (NBloque: in Natural) return  SSIO.Positive_Count is
   -- Dado un numero de bloque, nos devuelve la posicion anterior para escribir a partir de ah�
      EscribirAPartirDe: SSIO.Positive_Count:=1;
   begin
      EscribirAPartirDe:= SSIO.Positive_Count(((NBloque-1)*TAM_BLOQUE)+1);
      return EscribirAPartirDe;
   end PosicionAnterior;

   -------------------------------------------------------------------------------------------------

   function EsUltimoPaquete (LongPaquete: in Ada.Streams.Stream_Element_Offset) return Boolean is
   -- Dada la longitud del paquete, devuelve un boolean en funcion de si es o no ultimo paquete
     EsUltimo:Boolean:=FALSE;
   begin
      if (Integer(LongPaquete)<1024) then
         EsUltimo:=TRUE;
      end if;
      return EsUltimo;
   end EsUltimoPaquete;

   -----------------------------------------------------------------------------------------------

   function NTotalBloques (Tam_Fich: in SSIO.count) return Natural is
      --Calcula el n� total de bloques que componen un fichero
      N_Total: Natural;
   begin
      --Si no es multiplo de TAM_BLOQUE, le sumamos uno mas a la division
      if (Integer(Tam_Fich) mod TAM_BLOQUE) /= 0 then
         N_Total:= (Integer(Tam_Fich)/TAM_BLOQUE) + 1;
      else
         N_Total:= (Integer(Tam_Fich)/TAM_BLOQUE);
      end if;
      return N_Total;
   end NTotalBloques;
   ---------------------------------------------------------------------------------------------
end Ficheros;

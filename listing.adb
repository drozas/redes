with Ada.Strings.Unbounded;
with Gnat.Directory_Operations;
with Gnat.OS_Lib;
with Ada.Text_IO;
with Ada.Exceptions;


package body Listing is

   package GDO renames Gnat.Directory_Operations;
   package GOL renames Gnat.OS_Lib;

   Format_Error: exception;

   procedure Get_Listing_With_Prefix (Dir_Name: in String;
                                      List: in out File_List_Type;
                                      Last_File: in out Natural) is
      Dir: GDO.Dir_Type;
      File_Name: String(1..1024);
      Last_Char: Natural;

   begin
      GDO.Open(Dir, Dir_Name);
      loop
         GDO.Read(Dir, File_Name, Last_Char);
         if Last_Char /= 0 then
            if GOL.Is_Directory (Dir_Name & "/" & File_Name(1..Last_Char)) then
               if File_Name(1..Last_Char) /= "." and File_Name(1..Last_Char) /= ".." then
                  Get_Listing_With_Prefix (Dir_Name & "/" & File_Name(1..Last_Char),
                                           List, Last_File);
               end if;
            else
               Last_File := Last_File + 1;
               if Last_File > Max_Files then
                  raise Too_Many_Files;
               else
                  List(Last_File) :=  ASU.To_Unbounded_String
                    (Dir_Name & "/" &File_Name(1..Last_Char));
               end if;
            end if;
         end if;
         exit when Last_Char = 0;
      end loop;

   exception
      when Except:others =>
         Ada.Text_IO.Put_Line ("Excepción al obtener listado: " &
                               Ada.Exceptions.Exception_Name (Except));
   end Get_Listing_With_Prefix;




   procedure Get_Listing (Dir_Name: in String;
                          List: in out File_List_Type;
                          Last_File: in out Natural) is
   begin
      Get_Listing_With_Prefix (Dir_Name, List, Last_File);

       for I in 1..Last_File loop
          ASU.Tail (List(I), ASU.Length(List(I))-Dir_Name'Length-1);
       end loop;

   end Get_Listing;

end Listing;

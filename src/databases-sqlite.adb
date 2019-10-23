--  Databases - A simple database library for Ada applications
--  (c) Kristian Klomsten Skordal 2019 <kristian.skordal@wafflemail.net>
--  Report bugs and issues on <https://github.com/skordal/databases/issues>
--  vim:ts=3:sw=3:et:si:sta

with Ada.Text_IO;
with Interfaces.C.Pointers;

package body Databases.Sqlite is

   function Get_Value (This : in Column_Data) return Databases.Sql_Integer is
      function Sqlite3_Value_Int (Value : in Sqlite_Value_Pointer) return C.long;
      pragma Import (C, Sqlite3_Value_Int);

      Value : constant C.long := Sqlite3_Value_Int (This.Value_Object);
   begin
      return Databases.Sql_Integer (Value);
   end Get_Value;

   function Get_Value (This : in Column_Data) return Databases.Sql_Float is
      function Sqlite3_Value_Double (Value : in Sqlite_Value_Pointer) return C.double;
      pragma Import (C, Sqlite3_Value_Double);

      Value : constant C.double := Sqlite3_Value_Double (This.Value_Object);
   begin
      return Databases.Sql_Float (Value);
   end Get_Value;

   function Get_Value (This : in Column_Data) return Databases.Sql_Data_Array is
      package Byte_Array_Pointers is new Interfaces.C.Pointers (
         Index => Natural, Element => Interfaces.Unsigned_8, Element_Array => Databases.Sql_Data_Array, Default_Terminator => 0);

      function Sqlite3_Value_Bytes (Value : in Sqlite_Value_Pointer) return C.ptrdiff_t;
      pragma Import (C, Sqlite3_Value_Bytes);
      function Sqlite3_Value_Blob (Value : in Sqlite_Value_Pointer) return Byte_Array_Pointers.Pointer;
      pragma Import (C, Sqlite3_Value_Blob);

      Blob_Pointer : constant Byte_Array_Pointers.Pointer := Sqlite3_Value_Blob (This.Value_Object);
   begin
      return Byte_Array_Pointers.Value (Blob_Pointer, Sqlite3_Value_Bytes (This.Value_Object));
   end Get_Value;

   function Get_Value (This : in Column_Data) return String is
      package Char_Array_Pointers is new Interfaces.C.Pointers (
         Index => C.size_t, Element => C.char, Element_Array => C.char_array, Default_Terminator => C.nul);

      function Sqlite3_Value_Text (Value : in Sqlite_Value_Pointer) return Char_Array_Pointers.Pointer;
      pragma Import (C, Sqlite3_Value_Text);

      Text_Pointer : constant Char_Array_Pointers.Pointer := Sqlite3_Value_Text (This.Value_Object);
   begin
      return C.To_Ada (Char_Array_Pointers.Value (Text_Pointer));
   end Get_Value;

   procedure Finalize (This : in out Column_Data) is
      procedure Sqlite3_Value_Free (Value : in Sqlite_Value_Pointer);
      pragma Import (C, Sqlite3_Value_Free);
   begin
      Sqlite3_Value_Free (This.Value_Object);
   end Finalize;

   function Get_Column_Count (This : in Row_Data) return Natural is
   begin
      return Natural (This.Columns.Length);
   end Get_Column_Count;

   function Get_Column (This : in Row_Data; Index : in Positive) return Column_Data_Access is
   begin
      if Index > Natural (This.Columns.Length) then
         raise Databases.Invalid_Column_Index;
      else
         return This.Columns.Element (Index);
      end if;
   end Get_Column;

   procedure Finalize (This : in out Row_Data) is
   begin
      for Col of This.Columns loop
         Databases.Free (Col);
      end loop;
   end Finalize;

   function Get_Row (This : in Statement_Result; Row : in Positive) return Row_Data_Access is
   begin
      if Row > Natural (This.Rows.Length) then
         raise Invalid_Row_Index;
      else
         return This.Rows.Element (Row);
      end if;
   end Get_Row;

   function Get_Status (This : in Statement_Result) return Databases.Statement_Execution_Status is
   begin
      return This.Result_Status;
   end Get_Status;

   function Get_Returned_Row_Count (This : in Statement_Result) return Natural is
   begin
      return Natural (This.Rows.Length);
   end Get_Returned_Row_Count;

   procedure Finalize (This : in out Statement_Result) is
   begin
      for Row of This.Rows loop
         Databases.Free (Row);
      end loop;
   end Finalize;

   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Sql_Integer) is
      function Sqlite3_Bind_Int64 (Statement : in Sqlite_Prepared_Statement_Pointer;
                                   Index : in C.int;
                                   Value : in C.long)
         return Sqlite_Status_Code;
      pragma Import (C, Sqlite3_Bind_Int64);

      Status_Code : constant Sqlite_Status_Code := Sqlite3_Bind_Int64 (
         This.Stmt_Instance, C.int (Index), C.long (Value));
   begin
      Handle_Sqlite_Status_Code (Status_Code);
   end Bind;

   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Sql_Float) is
      function Sqlite3_Bind_Double (Statement : in Sqlite_Prepared_Statement_Pointer;
                                    Index : in C.int;
                                    Value : in C.double)
         return Sqlite_Status_Code;
      pragma Import (C, Sqlite3_Bind_Double);

      Status_Code : constant Sqlite_Status_Code := Sqlite3_Bind_Double (
         This.Stmt_Instance, C.int (Index), C.double (Value));
   begin
      Handle_Sqlite_Status_Code (Status_Code);
   end Bind;

   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Boolean) is
   begin
      if Value then
         Bind (This, Index, 1);
      else
         Bind (This, Index, 0);
      end if;
   end Bind;

   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in String) is
      function Sqlite_Wrapper_Bind_String (Statement : in Sqlite_Prepared_Statement_Pointer;
                                           Index : in C.int;
                                           Value : in C.char_array)
         return Sqlite_Status_Code;
      pragma Import (C, Sqlite_Wrapper_Bind_String);

      Status_Code : constant Sqlite_Status_Code := Sqlite_Wrapper_Bind_String (
         This.Stmt_Instance, C.int (Index), C.To_C (Value));
   begin
      Handle_Sqlite_Status_Code (Status_Code);
   end Bind;

   procedure Clear (This : in out Prepared_Statement) is
      function Sqlite3_Clear_Bindings (Statement : in Sqlite_Prepared_Statement_Pointer) return Sqlite_Status_Code;
      pragma Import (C, Sqlite3_Clear_Bindings);

      Status_Code : constant Sqlite_Status_Code := Sqlite3_Clear_Bindings (This.Stmt_Instance);
   begin
      Handle_Sqlite_Status_Code (Status_Code);
   end Clear;

   procedure Reset (This : in out Prepared_Statement) is
      function Sqlite3_Reset (Statement : in Sqlite_Prepared_Statement_Pointer) return Sqlite_Status_Code;
      pragma Import (C, Sqlite3_Reset);

      Status_Code : constant Sqlite_Status_Code := Sqlite3_Reset (This.Stmt_Instance);
   begin
      Handle_Sqlite_Status_Code (Status_Code);
   end Reset;

   function Execute (This : in out Prepared_Statement) return Statement_Result_Access is
      use type Interfaces.C.int;

      function Sqlite3_Step (Statement : in Sqlite_Prepared_Statement_Pointer) return Sqlite_Status_Code;
      pragma Import (C, Sqlite3_Step);

      function Sqlite3_Column_Count (Statement : in Sqlite_Prepared_Statement_Pointer) return C.int;
      pragma Import (C, Sqlite3_Column_Count);

      function Sqlite3_Column_Value (Statement : in Sqlite_Prepared_Statement_Pointer; Col : in C.int) return Sqlite_Value_Pointer;
      pragma Import (C, Sqlite3_Column_Value);

      function Sqlite3_Value_Dup (Value : in Sqlite_Value_Pointer) return Sqlite_Value_Pointer;
      pragma Import (C, Sqlite3_Value_Dup);

      Status_Code  : Sqlite_Status_Code;
      Return_Value : constant Statement_Result_Access := new Statement_Result'(Ada.Finalization.Controlled
         with Result_Status => Failure, Rows => Row_Data_Vectors.Empty_Vector);
   begin
      loop
         Status_Code := Sqlite3_Step (This.Stmt_Instance);
         case Status_Code is
            when Sqlite_Done =>
               Statement_Result (Return_Value.all).Result_Status := Success;
               exit;
            when Sqlite_Row =>
               --  FIXME: For SQLite, all results must be read and stored here to be accessible, as the SQLite API does
               --  FIXME: not provide a separate results object that allows reading objects separately from the statement.
               declare
                  Row : constant Row_Data_Access := new Row_Data;
               begin
                  for Col in 0 .. Sqlite3_Column_Count(This.Stmt_Instance) - 1 loop
                     declare
                        Column : constant Column_Data_Access := new Column_Data;
                     begin
                        Column_Data (Column.all).Value_Object := Sqlite3_Value_Dup (Sqlite3_Column_Value (This.Stmt_Instance, Col));
                        Row_Data (Row.all).Columns.Append (Column);
                     end;
                  end loop;
                  Statement_Result (Return_Value.all).Rows.Append (Row);
               end;
            when others =>
               Handle_Sqlite_Status_Code (Status_Code);
         end case;
      end loop;

      return Return_Value;
   end Execute;

   function Execute (This : in out Prepared_Statement) return Statement_Execution_Status is
      Results : Statement_Result_Access := This.Execute;
      Return_Value : constant Statement_Execution_Status := Results.Get_Status;
   begin
      Databases.Free (Results);
      return Return_Value;
   end Execute;

   procedure Finalize (This : in out Prepared_Statement) is
      procedure Sqlite_Wrapper_Free_Prepared_Statement (Statement : in Sqlite_Prepared_Statement_Pointer);
      pragma Import (C, Sqlite_Wrapper_Free_Prepared_Statement);
   begin
      Sqlite_Wrapper_Free_Prepared_Statement (This.Stmt_Instance);
   end Finalize;

   function Open (Filename : in String; Create : in Boolean := False) return Databases.Database_Access is

      function Sqlite_Wrapper_Open (Filename    : in C.char_array;
                                    Create_File : in C.int;
                                    Status      : out Sqlite_Status_Code)
         return Sqlite_Instance_Pointer;
      pragma Import (C, Sqlite_Wrapper_Open);

      Create_File : constant C.int := (if Create then 1 else 0);
      Status_Code : Sqlite_Status_Code;
      Db_Instance : constant Sqlite_Instance_Pointer := Sqlite_Wrapper_Open (C.To_C (Filename), Create_File, Status_Code);
   begin
      Handle_Sqlite_Status_Code (Status_Code);
      return new Database'(Instance => Db_Instance);
   end Open;

   procedure Close (This : in out Database) is

      procedure Sqlite_Wrapper_Close (Instance : in Sqlite_Instance_Pointer);
      pragma Import (C, Sqlite_Wrapper_Close);

   begin
      Sqlite_Wrapper_Close (This.Instance);
      This.Instance := null;
   end Close;

   function Is_Open (This : in Database) return Boolean is
   begin
      return This.Instance /= null;
   end Is_Open;

   function Prepare (This : in out Database; Statement : in String)
      return Databases.Prepared_Statement_Access is

      function Sqlite_Wrapper_Prepare (Instance         : in Sqlite_Instance_Pointer;
                                       Statement        : in C.char_array;
                                       Statement_Length : in C.int;
                                       Status_Code      : out Sqlite_Status_Code)
         return Sqlite_Prepared_Statement_Pointer;
      pragma Import (C, Sqlite_Wrapper_Prepare);

      Status_Code : Sqlite_Status_Code;
      Statement_Instance : constant Sqlite_Prepared_Statement_Pointer :=
         Sqlite_Wrapper_Prepare (This.Instance, C.To_C (Statement), C.int (Statement'Length), Status_Code);
   begin
      Handle_Sqlite_Status_Code (Status_Code);
      return new Prepared_Statement'(Ada.Finalization.Controlled with Db_Instance => This.Instance,
                                                                      Stmt_Instance => Statement_Instance);
   end Prepare;

   procedure Handle_Sqlite_Status_Code (Status : in Sqlite_Status_Code) is
   begin
      case Status is
         when Sqlite_Ok =>
            return;
         when Sqlite_IOErr =>
            raise Databases.IO_Error;
         when Sqlite_Cant_Open =>
            raise Databases.File_Error;
         when others =>
            Ada.Text_IO.Put_Line ("Databases.Sqlite: Got unknown error code: " & Sqlite_Status_Code'Image (Status));
            raise Databases.Unspecified_Error;
      end case;
   end Handle_Sqlite_Status_Code;

end Databases.Sqlite;


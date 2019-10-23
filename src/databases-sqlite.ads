--  Databases - A simple database library for Ada applications
--  (c) Kristian Klomsten Skordal 2019 <kristian.skordal@wafflemail.net>
--  Report bugs and issues on <https://github.com/skordal/databases/issues>
--  vim:ts=3:sw=3:et:si:sta

with Databases;

with Ada.Containers.Vectors;
with Ada.Finalization;

with Interfaces.C;

package Databases.Sqlite is

   --  Sqlite-specific column data implementation:
   type Column_Data is new Ada.Finalization.Controlled and Databases.Column_Data with private;

   --  Gets the data from a column:
   overriding
   function Get_Value (This : in Column_Data) return Databases.Sql_Integer;
   overriding
   function Get_Value (This : in Column_Data) return Databases.Sql_Float;
   overriding
   function Get_Value (This : in Column_Data) return Databases.Sql_Data_Array;
   overriding
   function Get_Value (This : in COlumn_Data) return String;

   --  Frees the generic value object allocated by Sqlite:
   overriding
   procedure Finalize (This : in out Column_Data);

   --  Sqlite-specific row data implementation:
   type Row_Data is new Ada.Finalization.Controlled and Databases.Row_Data with private;

   --  Gets the number of available columns for a row:
   function Get_Column_Count (This : in Row_Data) return Natural;

   --  Gets the value of a column:
   overriding
   function Get_Column (This : in Row_Data; Index : in Positive) return Column_Data_Access;

   --  Frees all stored column data:
   overriding
   procedure Finalize (This : in out Row_Data);

   --  Sqlite-specific statement result implementation:
   type Statement_Result is new Ada.Finalization.Controlled and Databases.Statement_Result with private;

   --  Gets the data for a row:
   function Get_Row (This : in Statement_Result; Row : in Positive) return Row_Data_Access;

   --  Gets the result of executing a statement:
   overriding
   function Get_Status (This : in Statement_Result) return Databases.Statement_Execution_Status with Inline;

   --  Gets the number of returned rows:
   overriding
   function Get_Returned_Row_Count (This : in Statement_Result) return Natural with Inline;

   --  Frees the stored result rows:
   overriding
   procedure Finalize (This : in out Statement_Result);

   --  Sqlite-specific prepared statement implementation:
   type Prepared_Statement is new Ada.Finalization.Controlled and Databases.Prepared_Statement with private;

   --  Value binding functions:
   overriding
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Sql_Integer);
   overriding
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Sql_Float);
   overriding
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Boolean);
   overriding
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in String);

   --  Clears bindings from the prepared statement:
   overriding
   procedure Clear (This : in out Prepared_Statement);

   --  Resets the prepared statement:
   overriding
   procedure Reset (This : in out Prepared_Statement);

   --  Executes the prepared statement:
   overriding
   function Execute (This : in out Prepared_Statement) return Statement_Result_Access;
   overriding
   function Execute (This : in out Prepared_Statement) return Statement_Execution_Status;

   --  Cleans up the prepared statement:
   overriding
   procedure Finalize (This : in out Prepared_Statement);

   --  Sqlite-specific database object implementation:
   type Database is limited new Databases.Database with private;

   --  Opens a database file:
   function Open (Filename : in String; Create : in Boolean := False) return Databases.Database_Access;

   --  Closes a database file:
   overriding
   procedure Close (This : in out Database);

   --  Checks if a database is open:
   overriding
   function Is_Open (This : in Database) return Boolean with Inline;

   --  Creates a prepared statement from an SQL statement:
   overriding
   function Prepare (This : in out Database; Statement : in String)
      return Databases.Prepared_Statement_Access;

private

   package C renames Interfaces.C;

   package Column_Data_Vectors is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Databases.Column_Data_Access);
   package Row_Data_Vectors is new Ada.Containers.Vectors (Index_Type => Positive, Element_Type => Databases.Row_Data_Access);

   --  Sqlite instance object type:
   type Sqlite_Instance is null record;
   type Sqlite_Instance_Pointer is access Sqlite_Instance;
   pragma Convention (C, Sqlite_Instance_Pointer);

   --  Sqlite value object type:
   type Sqlite_Value is null record;
   type Sqlite_Value_Pointer is access Sqlite_Value;
   pragma Convention (C, Sqlite_Value_Pointer);

   --  Sqlite column data object type:
   type Column_Data is new Ada.Finalization.Controlled and Databases.Column_Data with record
      Value_Object : Sqlite_Value_Pointer;
   end record;

   --  Sqlite row data object type:
   type Row_Data is new Ada.Finalization.Controlled and Databases.Row_Data with record
      Columns : Column_Data_Vectors.Vector;
   end record;

   --  Sqlite statement result object type:
   type Statement_Result is new Ada.Finalization.Controlled and Databases.Statement_Result with record
      Rows          : Row_Data_Vectors.Vector;
      Result_Status : Databases.Statement_Execution_Status;
   end record;

   --  Sqlite prepared statement object type:
   type Sqlite_Prepared_Statement is null record;
   type Sqlite_Prepared_Statement_Pointer is access Sqlite_Prepared_Statement;
   pragma Convention (C, Sqlite_Prepared_Statement_Pointer);

   --  Sqlite-specific prepared statement implementation:
   type Prepared_Statement is new Ada.Finalization.Controlled and Databases.Prepared_Statement with record
      Db_Instance   : Sqlite_Instance_Pointer;
      Stmt_Instance : Sqlite_Prepared_Statement_Pointer;
   end record;

   --  Sqlite-specific database object:
   type Database is limited new Databases.Database with record
      Instance : Sqlite_Instance_Pointer := null;
   end record;
   type Database_Access is not null access all Database;

   --  Sqlite status code type:
   type Sqlite_Status_Code is new C.int;

   --  SQLite return values:
   Sqlite_Ok        : constant Sqlite_Status_Code :=   0;
   Sqlite_Error     : constant Sqlite_Status_Code :=   1;
   Sqlite_Busy      : constant Sqlite_Status_Code :=   5;
   Sqlite_IOErr     : constant Sqlite_Status_Code :=  10;
   Sqlite_Cant_Open : constant Sqlite_Status_Code :=  14;
   Sqlite_Row       : constant Sqlite_Status_Code := 100;
   Sqlite_Done      : constant Sqlite_Status_Code := 101;

   --  Sqlite data types:
   Sqlite_Integer   : constant := 1;
   Sqlite_Float     : constant := 2;
   Sqlite_Text      : constant := 3;
   Sqlite_Blob      : constant := 4;
   Sqlite_Null      : constant := 5;

   --  Decodes an Sqlite status code and raises the appropriate exception:
   procedure Handle_Sqlite_Status_Code (Status : in Sqlite_Status_Code) with Inline;

end Databases.Sqlite;


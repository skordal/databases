--  Databases - A simple database library for Ada applications
--  (c) Kristian Klomsten Skordal 2019 <kristian.skordal@wafflemail.net>
--  Report bugs and issues on <https://github.com/skordal/databases/issues>
--  vim:ts=3:sw=3:et:si:sta

with Ada.Unchecked_Deallocation;
with Interfaces;

package Databases is
   pragma Preelaborate;

   --  Exceptions:
   Unspecified_Error : exception;
   File_Error        : exception;
   IO_Error          : exception;

   Invalid_Column_Index : exception;
   Invalid_Row_Index    : exception;

   --  SQL/database specific types:
   type Sql_Integer is mod 2**64;
   type Sql_Float is new Long_Float;
   type Sql_Data_Array is array (Natural range <>) of aliased Interfaces.Unsigned_8;

   --  Column data field:
   type Column_Data is interface;
   type Column_Data_Access is access Column_Data'Class;

   --  Gets the value of a data field:
   function Get_Value (This : in Column_Data) return Sql_Integer is abstract;
   function Get_Value (This : in Column_Data) return Sql_Float is abstract;
   function Get_Value (This : in Column_Data) return Sql_Data_Array is abstract;
   function Get_Value (This : in COlumn_Data) return String is abstract;

   --  Row data:
   type Row_Data is interface;
   type Row_Data_Access is access Row_Data'Class;

   --  Gets the number of available columns:
   function Get_Column_Count (This : in Row_Data) return Natural is abstract;

   --  Gets the value of a column:
   function Get_Column (This : in Row_Data; Index : in Positive) return Column_Data_Access is abstract;

   --  Statement execution status:
   type Statement_Execution_Status is (Success, Failure);

   --  Statement result interface:
   type Statement_Result is interface;
   type Statement_Result_Access is access Statement_Result'Class;

   --  Gets the data for a row of data:
   function Get_Row (This : in Statement_Result; Row : in Positive) return Row_Data_Access is abstract;

   --  Gets the result of executing a statement:
   function Get_Status (This : in Statement_Result) return Statement_Execution_Status is abstract;

   --  Gets the number of returned rows:
   function Get_Returned_Row_Count (This : in Statement_Result) return Natural is abstract;

   --  Prepared statement interface:
   type Prepared_Statement is interface;
   type Prepared_Statement_Access is access Prepared_Statement'Class;

   --  Binds a value to a parameter in a prepared statement. This parameter index starts at 1.
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Sql_Integer) is abstract;
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Sql_Float) is abstract;
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in Boolean) is abstract;
   procedure Bind (This : in out Prepared_Statement; Index : in Positive; Value : in String) is abstract;

   --  Clears all bound values from a prepared statement:
   procedure Clear (This : in out Prepared_Statement) is abstract;

   --  Resets a prepared statement so it can be executed again:
   procedure Reset (This : in out Prepared_Statement) is abstract;

   --  Executes a prepared statement:
   function Execute (This : in out Prepared_Statement) return Statement_Result_Access is abstract;
   function Execute (This : in out Prepared_Statement) return Statement_Execution_Status is abstract; -- Discards any results

   --  Database interface:
   type Database is limited interface;
   type Database_Access is access Database'Class;

   --  Closes an open database connection:
   procedure Close (This : in out Database) is abstract;
   --  Checks if a database connection is open:
   function Is_Open (This : in Database) return Boolean is abstract;

   --  Creates a prepared statement from an SQL statement:
   function Prepare (This : in out Database; Statement : in String)
      return Prepared_Statement_Access is abstract;

   --  Functions for freeing the various object types:
   procedure Free is new Ada.Unchecked_Deallocation
      ( Object => Database'Class, Name => Database_Access);
   procedure Free is new Ada.Unchecked_Deallocation
      ( Object => Prepared_Statement'Class, Name => Prepared_Statement_Access);
   procedure Free is new Ada.Unchecked_Deallocation
      ( Object => Statement_Result'Class, Name => Statement_Result_Access);
   procedure Free is new Ada.Unchecked_Deallocation
      ( Object => Column_Data'Class, Name => Column_Data_Access);
   procedure Free is new Ada.Unchecked_Deallocation
      ( Object => Row_Data'Class, Name => Row_Data_Access);

end Databases;


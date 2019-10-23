--  Databases - A simple database library for Ada applications
--  (c) Kristian Klomsten Skordal 2019 <kristian.skordal@wafflemail.net>
--  Report bugs and issues on <https://github.com/skordal/databases/issues>
--  vim:ts=3:sw=3:et:si:sta

with Databases;
with Databases.Sqlite;

with Ada.Numerics.Discrete_Random;
with Ada.Text_IO;

procedure Testapp is
   use type Databases.Statement_Execution_Status;

   Database : Databases.Database_Access := null;

   package Sql is
      Create_Table : constant String :=
         "CREATE TABLE test" &
         "(" &
         "   id   INTEGER PRIMARY KEY," &
         "   item VARYING CHARACTER (127)," &
         "   count INTEGER" &
         ");";
      Insert_Data : constant String :=
         "INSERT INTO test VALUES (:id, :name, :count);";
      Select_Data : constant String :=
         "SELECT * FROM test;";
   end Sql;

   package Random_Number_Generators is new Ada.Numerics.Discrete_Random (Result_Subtype => Natural);
   RNG : Random_Number_Generators.Generator;
begin
   Database := Databases.Sqlite.Open ("test.db", Create => True);

   --  Create database tables:
   declare
      Statement : Databases.Prepared_Statement_Access := Database.Prepare (Sql.Create_Table);
      Status    : constant Databases.Statement_Execution_Status := Statement.Execute;
   begin
      if Status /= Databases.Success then
         Ada.Text_IO.Put_Line ("Error: failed to create database tables!");
      end if;

      Databases.Free (Statement);
   end;

   --  Insert database values:
   declare
      Insert_Statement : Databases.Prepared_Statement_Access := Database.Prepare (Sql.Insert_Data);
      Status : Databases.Statement_Execution_Status;
   begin
      for Counter in 1..10 loop
         Insert_Statement.Clear;
         Insert_Statement.Bind (1, Databases.Sql_Integer (Counter));
         Insert_Statement.Bind (2, "Item number " & Integer'Image (Counter));
         Insert_Statement.Bind (3, Databases.Sql_Integer (Random_Number_Generators.Random (RNG) mod 1000));

         Status := Insert_Statement.Execute;
         if Status /= Databases.Success then
            Ada.Text_IO.Put_Line ("Warning: failed to insert item number " & Integer'Image (Counter)
               & " into the database");
         end if;
         Insert_Statement.Reset;
      end loop;

      Databases.Free (Insert_Statement);
   end;

   --  Print database values:
   declare
      Select_Statement : Databases.Prepared_Statement_Access := Database.Prepare (Sql.Select_Data);
      Result : Databases.Statement_Result_Access := Select_Statement.Execute;
   begin
      Ada.Text_IO.Put_Line ("Got " & Integer'Image (Result.Get_Returned_Row_Count) & " results");

      if Result.Get_Returned_Row_Count > 0 then
         for I in 1 .. Result.Get_Returned_Row_Count loop
            Ada.Text_IO.Put_Line ("ID" & Databases.Sql_Integer'Image (Result.Get_Row (I).Get_Column (1).Get_Value));
            Ada.Text_IO.Put_Line ("    Item name:  " & Result.Get_Row (I).Get_Column (2).Get_Value);
            Ada.Text_IO.Put_Line ("    Item count: " & Databases.Sql_Integer'Image (Result.Get_Row (I).Get_Column (3).Get_Value));
         end loop;
      end if;

      Databases.Free (Result);
      Databases.Free (Select_Statement);
   end;

   Database.Close;
   Databases.Free (Database);
exception
   when Databases.File_Error =>
      Ada.Text_IO.Put_Line ("Error: Could not open the test database file!");
   when Databases.IO_Error =>
      Ada.Text_IO.Put_Line ("Error: An I/O error occurred!");
   when Databases.Unspecified_Error =>
      Ada.Text_IO.Put_Line ("Error: An unspecified error occurred!");
end Testapp;


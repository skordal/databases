--  Databases - A simple database library for Ada applications
--  (c) Kristian Klomsten Skordal 2019 <kristian.skordal@wafflemail.net>
--  Report bugs and issues on <https://github.com/skordal/databases/issues>
--  vim:ts=3:sw=3:et:si:sta

package body Databases.Utilities is

   function Execute (Database : in Databases.Database_Access; Statement : in String)
      return Databases.Statement_Execution_Status
   is
      Prepared : Databases.Prepared_Statement_Access := Database.Prepare (Statement);
      Retval   : constant Databases.Statement_Execution_Status := Prepared.Execute;
   begin
      Databases.Free (Prepared);
      return Retval;
   end Execute;

end Databases.Utilities;


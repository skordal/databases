--  Databases - A simple database library for Ada applications
--  (c) Kristian Klomsten Skordal 2019 <kristian.skordal@wafflemail.net>
--  Report bugs and issues on <https://github.com/skordal/databases/issues>
--  vim:ts=3:sw=3:et:si:sta

with Databases;

package Databases.Utilities is

   --  Directly executes a statement and returns only the status:
   function Execute (Database : in Databases.Database_Access; Statement : in String)
      return Databases.Statement_Execution_Status;

end Databases.Utilities;


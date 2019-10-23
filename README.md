# Databases

*Databases* is a simple database library for Ada 2012 applications. It aims to
provide the basic functionality necessary for running SQL queries, but leaves
advanced and database-specific functionality to other libraries.

# Usage

Usage of the library is described in this section. All code that uses library
functions need to include the `Databases` package. To see prototypes for all
functions, procedures and types that are available in the library, take a
look at the `Databases.ads` file.

```Ada
with Databases;
```

In general, most functions return access types to objects. These can all be
freed by calling `Databases.Free`.

## Opening a database connection

Opening a database connection requires a call to a database-specific function.
Database connections are closed with the `Databases.Close` procedure, and then
freed using `Databases.Free`.

The following sections lists how to connect/open a connection to the supported
database engines.

A database connection is returned as a `Databases.Database_Access` object.

### SQLite 3

Include the Sqlite database driver package:

```Ada
with Databases;
with Databases.Sqlite;
```

The connection is made by calling `Databases.Sqlite.Open`. An optional `Create`
parameter can be passed to the function to cause the specified database file to
be created if it does not exist.


```Ada
declare
   Db : Databases.Database_Access := Databases.Sqlite.Open ("database.db", Create => True);
begin
   Db.Close;
   Databases.Free (Db);
end;
```

## Running an SQL query

To run an SQL query, a prepared statement must be createdand values bound to any
parameters before the query can be executed. To create a new prepared statement,
use the `Prepare` function on the database object.

Binding values to parameters in the query is done by using the `Bind` function
of the prepared statement object. Functions to bind various types of data to
indexed parameters are provided.

Results can be returned as `Databases.Statement_Result_Access` objects, or, if no
data is expected to be returned from a query, as a
`Databases.Statement_Execution_Status` value.

When you have a `Statement_Result_Access`, the number of rows returned can be
obtained using the `Get_Returned_Row_Count` function. Each row can be accesses
by using the `Get_Row` function, which returns a `Column_Data_Access`.
`Column_Data_Access` objects *do not need to be freed.*

Data from a column is obtained by calling the `Get_Value` function of a column.
Different versions are provided which return different data types.

```Ada
declare
   Select_Statement : Databases.Prepared_Statement_Access := Db.Prepare ("SELECT * FROM testdata WHERE testvalue = ?;");
   Result : Databases.Statement_Result_Access := null;
begin
   Select_Statement.Bind (1, Databases.Sql_Integer (42));
   Result := Select_Statement.Execute;

   for I in 1 .. Result.Get_Returned_Row_Count loop
         Ada.Text_IO.Put_Line ("Processing row " & Integer'Image (I));
         for C in 1 .. Result.Get_Row (I).Get_Column_Count loop
            Ada.Text_IO.Put_Line ("Row " & Integer'Image (I) & ", Column " & Integer'Image (C) &
               ": " Result.Get_Row (I).Get_Column (C).Get_Value);
         end loop;
   end loop;

   Databases.Free (Result);
   Databases.Free (Select_Statement);
end;
```

## Utilities

The `Databases.Utilities` package provides convenient functions to make life
easier for database developers.

`Databases.Utilities.Execute` is a function for directly executing a single
SQL statement. It hides the complexity of setting up a prepared statement.
It returns a `Databases.Statement_Execution_Status` value to notify of whether
the statement was successfully executed or not.


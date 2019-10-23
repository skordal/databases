// Databases - A simple database library for Ada applications
// (c) Kristian Klomsten Skordal 2019 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/databases/issues>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>

//#define PRINT_STATUS_CODES

#ifdef PRINT_STATUS_CODES
#define PRINT_STATUS_CODE(n) printf("%s: status_code = %d\n", __func__, (n))
#else
#define PRINT_STATUS_CODE(n) (void) n
#endif

// This file contains the glue layer between the SQLite C API and the Databases
// library.

sqlite3 * sqlite_wrapper_open(const char * filename, int create_file, int * status_code)
{
   sqlite3 * db;

   int flags = SQLITE_OPEN_READWRITE;
   if(create_file)
      flags |= SQLITE_OPEN_CREATE;

   *status_code = sqlite3_open_v2(filename, &db, flags, NULL);
   PRINT_STATUS_CODE(*status_code);
   return db;
}

void sqlite_wrapper_close(sqlite3 * instance)
{
   int status_code = sqlite3_close(instance);
   if(status_code == SQLITE_BUSY)
   {
      printf("Warning: sqlite3_close() returned SQLITE_BUSY! Check that all prepared statements are freed during program execution.");
   }
   PRINT_STATUS_CODE(status_code);
}

sqlite3_stmt * sqlite_wrapper_prepare(sqlite3 * instance, const char * statement, int statement_length, int * status_code)
{
   sqlite3_stmt * prepared_statement;
   *status_code = sqlite3_prepare_v2(instance, statement, statement_length + 1, &prepared_statement, NULL);
   PRINT_STATUS_CODE(*status_code);
   return prepared_statement;
}

void sqlite_wrapper_free_prepared_statement(sqlite3_stmt * statement)
{
   int status_code = sqlite3_finalize(statement);
   PRINT_STATUS_CODE(status_code);
}

int sqlite_wrapper_bind_string(sqlite3_stmt * statement, int index, const char * string)
{
   char * string_copy = strdup(string);
   int status_code = sqlite3_bind_text(statement, index, string_copy, -1, free);
   PRINT_STATUS_CODE(status_code);
   return status_code;
}


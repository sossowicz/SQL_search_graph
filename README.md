Group assignment of 9 people to create an SQL procedure to solve the shortest path problem on a cyclic graph. SQL was used exclusively.

How to run?

Open SSMS

1. Run the query inside filename "createDatabase.sql"
2. Run queries inside the file "createTables.sql"


The database is now created named "factory"
Tables named "device" and "path" have also been created.
NOTE: MAKE SURE THAT YOU HAVE THE FACTORY DATABASE SELECTED WHEN RUNNING QUERRIES.

Now we need to create some stored procedures (functions)

To create these stored procedures run all queries listed accordingly:
1. insertDevice.sql
2. insertDeviceForced.sql
3. insertPath.sql
4. addDevices.sql
5. recursiveSearch.sql
6. runSearch.sql


Again run the "createTables.sql" just in case.

READY TO GO.

You can find some simple test querries in the filename: testCaseQueries.sql
The commands for the provided dataset is in filename "givenDataSet.sql" so you can simply copy and paste and run the queries to insert the database inside the created "factory" database
  

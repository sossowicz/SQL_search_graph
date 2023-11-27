--Some useful commands:
USE factory
GO

select * from device;
select * from path;

SELECT * FROM device WHERE type LIKE '%SOURCE%';
SELECT * FROM device WHERE type LIKE '%DES%';




--SMALL GRAPH TEST CASE:                      --PASSED
--command used to run
-- EXEC runSearch <id of MySOURCE>, <id of MyDEST>;



--TEST 1:
EXEC AddDevice PATH2, FALSE, FALSE, PATH1, PATH3;
EXEC AddDevice MySOURCE, TRUE, FALSE, NULL, PATH1;
EXEC AddDevice MyDEST, FALSE, TRUE, PATH3, NULL;


--OUTPUT SHOULD BE--
--MySOURCE -> PATH1 -> PATH2 -> PATH3 -> MyDEST  







--TEST1.2 (ADDING A Shorter path):
EXEC AddDevice PATH2, FALSE, FALSE, PATH1, PATH3;
EXEC AddDevice MySOURCE, TRUE, FALSE, NULL, PATH1;
EXEC AddDevice MyDEST, FALSE, TRUE, PATH3, NULL;
EXEC AddDevice PATH2, FALSE, FALSE, MySOURCE, PATH3;
--OUTPUT SHOULD BE--
--MySOURCE -> PATH2 -> PATH3 -> MyDEST  








--TEST2 (ADDING A FEW OTHER PATHS AS WELL): --FAILED
EXEC AddDevice PATH2, FALSE, FALSE, PATH1, PATH3;
EXEC AddDevice MySOURCE, TRUE, FALSE, NULL, PATH1;
EXEC AddDevice MyDEST, FALSE, TRUE, PATH3, NULL;
--ADDING ALTERNATE LONGER PATH (no loops)
EXEC AddDevice PATH5, FALSE, FALSE, PATH3, PATH4;    
EXEC AddDevice PATH6, FALSE, FALSE, PATH5, PATH7;
EXEC AddDevice MyDEST, FALSE, TRUE, PATH7, NULL;
--ADDING a loop:
EXEC AddDevice PATH7, FALSE, FALSE, PATH1, PATH3;

--OUTPUT SHOULD BE--
--MySOURCE -> PATH1 -> PATH2 -> PATH3 -> MyDEST   







--TEST3 (ADDING A FEW OTHER PATHS AS WELL):                        PASSED
EXEC AddDevice PATH2, FALSE, FALSE, PATH1, PATH3;
EXEC AddDevice MySOURCE, TRUE, FALSE, NULL, PATH1;
EXEC AddDevice MyDEST, FALSE, TRUE, PATH3, NULL;
--ADDING ALTERNATE LONGER PATH (no loops)
EXEC AddDevice PATH5, FALSE, FALSE, PATH3, PATH4;    
EXEC AddDevice PATH6, FALSE, FALSE, PATH5, PATH7;
EXEC AddDevice MyDEST, FALSE, TRUE, PATH7, NULL;
--OUTPUT SHOULD BE--
--MySOURCE -> PATH1 -> PATH2 -> PATH3 -> MyDEST   










--TEST4 (Testing Comvergent and divergent nodes):           PASSED
EXEC AddDevice MySOURCE, TRUE, FALSE, NULL, PATH1;
EXEC AddDevice MyDEST, FALSE, TRUE, PATH9, NULL;

--ADDING ALTERNATE LONGER PATH ()
--middle part:
EXEC AddDevice PATH3, FALSE, FALSE, PATH1, PATH6;
EXEC AddDevice PATH7, FALSE, FALSE, PATH6, PATH8;  
EXEC AddDevice PATH8, FALSE, FALSE, PATH7, PATH9;

--lower path of the diagram:
EXEC AddDevice PATH4, FALSE, FALSE, PATH1, PATH9;

--upper path of the diagram:
EXEC AddDevice PATH2, FALSE, FALSE, PATH1, PATH5;  
EXEC AddDevice PATH9, FALSE, FALSE, PATH5, MyDEST;  



--TEST 5
-- STORY 4 GRAPH
EXEC AddDevice A, TRUE, FALSE, NULL, B;
EXEC AddDevice B, FALSE, FALSE, C, E;
EXEC AddDevice C, FALSE, FALSE, A, D;
EXEC AddDevice Z, FALSE, TRUE, C, NULL;
EXEC AddDevice Y, FALSE, TRUE, D, NULL;
EXEC AddDevice E, FALSE, FALSE, B, D;
EXEC AddDevice X, FALSE, TRUE, E, NULL;
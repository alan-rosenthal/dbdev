CREATE OR REPLACE PACKAGE BODY test_dbdev
AS
   C_TAGNAME CONSTANT VARCHAR2(10) := 'test_dbdev';

   -----------------------------------------------------------------------------
   -- global_setup
   -----------------------------------------------------------------------------
   PROCEDURE global_setup
   IS
      PROCEDURE l_delete_all_rows
      IS
         PRAGMA AUTONOMOUS_TRANSACTION;
         
      BEGIN
         DELETE FROM dbdev_log
               WHERE tag = C_TAGNAME;

         COMMIT;
      END l_delete_all_rows;
      
   BEGIN
      l_delete_all_rows;
      
   END global_setup;

   -----------------------------------------------------------------------------
   -- test_empty
   -----------------------------------------------------------------------------
   PROCEDURE test_empty
   IS
      cur            SYS_REFCURSOR;
      
   BEGIN
      OPEN cur FOR SELECT *
                     FROM dbdev_log
                    WHERE tag = C_TAGNAME;

      ut.expect(cur).to_be_empty();

      IF cur%ISOPEN THEN
         CLOSE cur;
      END IF;
      
   END test_empty;

   -----------------------------------------------------------------------------
   -- test_enable_logging
   -----------------------------------------------------------------------------
   PROCEDURE test_enable_logging
   IS
      rowcount       NUMBER := 0;
      row            dbdev_log%ROWTYPE;
      
   BEGIN
      dbdev.log_enable(C_TAGNAME);

      SELECT COUNT(*)
        INTO rowcount
        FROM dbdev_log
       WHERE tag = C_TAGNAME;
      ut.expect( rowcount ).to_equal(1);
      
      SELECT *
        INTO row
        FROM dbdev_log
       WHERE tag = C_TAGNAME; 
      ut.expect( row.action ).to_equal( 'Start Logging' );  
      ut.expect( row.current_user ).to_equal( 'DBDEV_USER' );
      ut.expect( row.v$session_module ).to_equal( 'utPLSQLx' );

   END test_enable_logging;

END test_dbdev;
/
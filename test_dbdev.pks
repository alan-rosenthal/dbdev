CREATE OR REPLACE PACKAGE test_dbdev as

   -- %suite(DBDEV_PKG Logging System)
   
   -- %beforeall
   procedure global_setup;
   
   -- %test(********** test empty logging table)
   procedure test_empty;
   
   -- %test(********** test enable logging, should create just one row)
   procedure test_enable_logging;
   
END test_dbdev;
/


CREATE TABLE dbdev_log
(
   dbdev_log_id            NUMBER,
   tag                     VARCHAR2 (100),
   ctime                   DATE,
   timer                   NUMBER,
   module                  VARCHAR2 (100),
   action                  VARCHAR2 (100),
   notes                   VARCHAR2 (4000),
   current_user            VARCHAR2 (100),
   terminal                VARCHAR2 (100),
   ip_address              VARCHAR2 (100),
   os_user                 VARCHAR2 (100),
   current_schema          VARCHAR2 (100),
   server_host             VARCHAR2 (100),
   service_name            VARCHAR2 (100),
   session_user            VARCHAR2 (100),
   instance_name           VARCHAR2 (100),
   v$session_module        VARCHAR2 (64),
   v$session_action        VARCHAR2 (64),
   v$session_client_info   VARCHAR2 (64)
)
/


CREATE SEQUENCE dbdev_log_seq;


CREATE INDEX x1_dbdev_log
   ON dbdev_log (tag, dbdev_log_id)
/

CREATE OR REPLACE TRIGGER before_row_dbdev_log_trg
   BEFORE INSERT OR UPDATE
   ON dbdev_log
   FOR EACH ROW
BEGIN
   IF :new.dbdev_log_id IS NULL THEN
      :new.dbdev_log_id   := dbdev_log_seq.NEXTVAL;
      :new.ctime          := SYSDATE;
   END IF;

   :new.mtime   := SYSDATE;
END before_row_dbdev_log_trg;
/


CREATE OR REPLACE PUBLIC SYNONYM dbdev FOR dbdev_user.dbdev
/

CREATE OR REPLACE PUBLIC SYNONYM dbdev_log FOR dbdev_user.dbdev_log
/



GRANT DELETE, INSERT, SELECT, UPDATE ON dbdev_user.dbdev_log TO PUBLIC
/


-- AFTER PACKAGE HAS BEEN COMPILED, EXECUTE THIS LINE TO GRANT ACCESS

GRANT EXECUTE ON dbdev_user.dbdev TO PUBLIC;
/

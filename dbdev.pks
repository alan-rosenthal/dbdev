CREATE OR REPLACE PACKAGE dbdev 
       AUTHID CURRENT_USER
IS

   PROCEDURE log_enable (p_tag           IN VARCHAR2 DEFAULT NULL,
                         p_append_flag   IN BOOLEAN  DEFAULT FALSE,
                         p_errnbr        IN NUMBER   DEFAULT NULL,
                         p_errmsg        IN VARCHAR2 DEFAULT NULL);

   PROCEDURE log_disable (p_tag                IN VARCHAR2 DEFAULT NULL);

   PROCEDURE log_msg (p_notes         IN VARCHAR2 DEFAULT NULL,
                      p_module        IN VARCHAR2 DEFAULT NULL,
                      p_action        IN VARCHAR2 DEFAULT NULL,
                      p_signon_id     IN NUMBER   DEFAULT NULL,
                      p_sessid        IN NUMBER   DEFAULT NULL,
                      p_tag           IN VARCHAR2 DEFAULT NULL,
                      p_errnbr        IN NUMBER   DEFAULT NULL,
                      p_errmsg        IN VARCHAR2 DEFAULT NULL,
                      p_whoami_flag   IN BOOLEAN  DEFAULT FALSE);

   PROCEDURE log_whoami (p_notes   IN VARCHAR2 DEFAULT NULL);

   -- Intentionally commented out.  See comments in package body for this procedure.
   -- PROCEDURE log_collection (p_collection IN v_id_varray, p_notes IN CLOB DEFAULT NULL, p_tag IN VARCHAR2 DEFAULT NULL);

   PROCEDURE log_format_call_stack (p_tag   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE log_format_error_backtrace (p_tag   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE log_format_error_stack (p_tag   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE timer_start (p_msg   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE timer_lap (p_msg   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE timer_end (p_msg   IN VARCHAR2 DEFAULT NULL);

END dbdev;
/
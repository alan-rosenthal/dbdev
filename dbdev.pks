CREATE OR REPLACE PACKAGE NCOWN.dbdev_pkg
IS
TYPE t_refcur IS REF CURSOR;
PROCEDURE log_enable(p_tag                   IN VARCHAR2 DEFAULT NULL,
                     p_append_flag           IN BOOLEAN  DEFAULT FALSE,
                     p_errnbr                IN NUMBER   DEFAULT NULL,
                     p_errmsg                IN VARCHAR2 DEFAULT NULL);

PROCEDURE log_disable(p_tag                  IN VARCHAR2 DEFAULT NULL);

PROCEDURE log(p_notes                        IN CLOB     DEFAULT NULL,
              p_module                       IN VARCHAR2 DEFAULT NULL,
              p_action                       IN VARCHAR2 DEFAULT NULL,
              p_signon_id                    IN NUMBER   DEFAULT NULL,
              p_sessid                       IN NUMBER   DEFAULT NULL,
              p_tag                          IN VARCHAR2 DEFAULT NULL,
              p_errnbr                       IN NUMBER   DEFAULT NULL,
              p_errmsg                       IN VARCHAR2 DEFAULT NULL,
              p_whoami_flag                  IN BOOLEAN  DEFAULT FALSE);

PROCEDURE log_append (p_notes                IN CLOB DEFAULT NULL,
                      p_tag                  IN VARCHAR2 DEFAULT NULL);

                          
PROCEDURE log_whoami (p_notes                IN CLOB DEFAULT NULL);

PROCEDURE log_collection (p_collection       IN v_id_varray,
                          p_notes            IN CLOB     DEFAULT NULL,
                          p_tag              IN VARCHAR2 DEFAULT NULL);
                          
PROCEDURE log_collection (p_collection       IN v_text_id_varray,
                          p_notes            IN CLOB     DEFAULT NULL,
                          p_tag              IN VARCHAR2 DEFAULT NULL);
                          
PROCEDURE log_collection (p_collection       IN v_user_label_varray,
                          p_notes            IN CLOB     DEFAULT NULL,
                          p_tag              IN VARCHAR2 DEFAULT NULL);
                          
PROCEDURE log_collection (p_collection       IN v_veh_group_varray1,
                          p_notes            IN CLOB     DEFAULT NULL,
                          p_tag              IN VARCHAR2 DEFAULT NULL);
                          
PROCEDURE log_collection (p_collection       IN v_veh_group_varray,
                          p_notes            IN CLOB     DEFAULT NULL,
                          p_tag              IN VARCHAR2 DEFAULT NULL);
                          
PROCEDURE log_collection (p_collection       IN v_upd_addr_varray,
                          p_notes            IN CLOB     DEFAULT NULL,
                          p_tag              IN VARCHAR2 DEFAULT NULL);

PROCEDURE log_collection (p_collection       IN v_upd_phone_varray,
                          p_notes            IN CLOB     DEFAULT NULL,
                          p_tag              IN VARCHAR2 DEFAULT NULL);
                          
 PROCEDURE log_collection (p_collection  IN v_prefs_varray,
                           p_notes       IN CLOB     DEFAULT NULL,
                           p_tag         IN VARCHAR2 DEFAULT NULL);                 
                                                   
 PROCEDURE log_collection (p_collection  IN v_label_varray,
                           p_notes       IN CLOB     DEFAULT NULL,
                           p_tag         IN VARCHAR2 DEFAULT NULL);                 
                                                   
PROCEDURE log_collection (p_collection  IN v_id_plus_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL);
                          
PROCEDURE log_format_call_stack (p_tag       IN VARCHAR2 DEFAULT NULL);

PROCEDURE log_format_error_backtrace (p_tag  IN VARCHAR2 DEFAULT NULL);

PROCEDURE log_format_error_stack (p_tag      IN VARCHAR2 DEFAULT NULL);
                            
PROCEDURE timer_start(p_msg                  IN VARCHAR2 DEFAULT NULL);

PROCEDURE timer_lap(p_msg                    IN VARCHAR2 DEFAULT NULL);

PROCEDURE timer_end(p_msg                    IN VARCHAR2 DEFAULT NULL);

END dbdev_pkg;
/

CREATE OR REPLACE PACKAGE BODY NCOWN.dbdev_pkg
IS
  g_log_enabled_flag          BOOLEAN := FALSE;
  g_log_default_tag           VARCHAR2(1000) := NULL;
  g_log_g_start_timer         NUMBER := NULL;
  g_log_latest_dbdev_log_id   NUMBER := NULL;
  g_start_time                NUMBER := NULL;

PROCEDURE l_handle_others_exception (p_proc_name    VARCHAR2,
                                     p_sqlerrm      VARCHAR2)
IS
BEGIN
  DBMS_OUTPUT.PUT_LINE('Error in DBDEV_PKG, ' || p_proc_name || p_sqlerrm);
  
END l_handle_others_exception;
/*----------------------------------------------------------------------------*/

PROCEDURE l_log_multi_line_msg(p_tag              IN VARCHAR2,
                               p_action           IN VARCHAR2,
                               p_msg              IN VARCHAR2) 
IS
  ptr1                   pls_integer;
  ptr2                   pls_integer;
  len                    pls_integer;
  v_msg                  VARCHAR2(4000) := p_msg;
  v_proc                 VARCHAR2(30)   := 'L_LOG_MULTI_LINE_MSG';
    
BEGIN
  IF SUBSTR(p_msg, -1, 1) != CHR(10) THEN
    v_msg := v_msg || CHR(10);
  END IF;
    
  ptr1 := 1;
  len  := LENGTH(v_msg);
    
  WHILE ptr1 < len
  LOOP
    ptr2 := INSTR(v_msg, CHR(10), ptr1);
    EXIT WHEN ptr2 = 0;
      
    log(p_tag    => p_tag,
        p_action => p_action,
        p_notes  => SUBSTR(v_msg, ptr1, ptr2 - ptr1));
    ptr1 := ptr2 + 1;
  END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      l_handle_others_exception(v_proc, SQLERRM);
END l_log_multi_line_msg;
/*----------------------------------------------------------------------------*/

PROCEDURE l_delete_from_log(p_tag                 IN VARCHAR2)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
    
  v_proc                 VARCHAR2(30) := 'L_DELETE_FROM_LOG';
    
BEGIN
  DELETE FROM dbdev_log
   WHERE tag = p_tag;
     
  COMMIT;
    
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END l_delete_from_log;
/*----------------------------------------------------------------------------*/
  
PROCEDURE log_enable(p_tag                        IN VARCHAR2 DEFAULT NULL,
                     p_append_flag                IN BOOLEAN  DEFAULT FALSE,
                     p_errnbr                     IN NUMBER   DEFAULT NULL,
                     p_errmsg                     IN VARCHAR2 DEFAULT NULL)
IS
  v_tag                  dbdev_log.tag%TYPE;
  v_action               dbdev_log.action%TYPE;
  v_proc                 VARCHAR2(30) := 'LOG_ENABLE';
    
BEGIN
  g_log_enabled_flag := TRUE;
  
  v_tag := NVL(p_tag, SYS_CONTEXT('USERENV', 'OS_USER'));
  g_log_default_tag := v_tag;

  IF NOT p_append_flag THEN
    l_delete_from_log(g_log_default_tag);
  END IF;

  g_log_g_start_timer := DBMS_UTILITY.get_time;

  v_action := 'Start Logging';

  log(p_tag         => v_tag,
      p_action      => v_action,
      p_whoami_flag => TRUE);

EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_enable;
/*----------------------------------------------------------------------------*/

PROCEDURE log_disable (p_tag                      IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_DISABLE';
    
BEGIN
  g_log_enabled_flag        := FALSE;
  g_log_default_tag         := NULL;
  g_log_g_start_timer       := NULL;
  g_log_latest_dbdev_log_id := NULL;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_disable;
/*----------------------------------------------------------------------------*/

PROCEDURE log(p_notes                   IN CLOB     DEFAULT NULL,
              p_module                  IN VARCHAR2 DEFAULT NULL,
              p_action                  IN VARCHAR2 DEFAULT NULL,
              p_signon_id               IN NUMBER   DEFAULT NULL,
              p_sessid                  IN NUMBER   DEFAULT NULL,
              p_tag                     IN VARCHAR2 DEFAULT NULL,
              p_errnbr                  IN NUMBER   DEFAULT NULL,
              p_errmsg                  IN VARCHAR2 DEFAULT NULL,
              p_whoami_flag             IN BOOLEAN  DEFAULT FALSE)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_tag                     VARCHAR2(1000);
  v_v$session_module        VARCHAR2(64);
  v_v$session_action        VARCHAR2(64);
  v_v$session_client_info   VARCHAR2(64);
  v_proc                    VARCHAR2(30) := 'LOG';
    
BEGIN
  IF g_log_enabled_flag THEN
    v_tag := NVL(p_tag, g_log_default_tag);
    g_log_default_tag := v_tag;

    IF p_whoami_flag THEN   
      DBMS_APPLICATION_INFO.READ_MODULE(v_v$session_module, v_v$session_action);
      DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_v$session_client_info);   
      
      INSERT INTO dbdev_log(tag,
                            module,
                            action,
                            notes,
                            signon_id,
                            sessid,
                            errnbr,
                            errmsg,
                            timer,
                            current_user,
                            terminal,
                            ip_address,
                            os_user,
                            current_schema,
                            server_host,
                            service_name,
                            session_user,
                            instance_name,
                            v$session_module,
                            v$session_action,
                            v$session_client_info)
                    VALUES (v_tag,
                            p_module,
                            p_action,
                            p_notes,
                            p_signon_id,
                            p_sessid,
                            p_errnbr,
                            p_errmsg,
                            (DBMS_UTILITY.get_time - g_log_g_start_timer)/100,
                            SYS_CONTEXT('USERENV', 'CURRENT_USER'),
                            SYS_CONTEXT('USERENV', 'TERMINAL'),
                            SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
                            SYS_CONTEXT('USERENV', 'OS_USER'),
                            SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
                            SYS_CONTEXT('USERENV', 'SERVER_HOST'),
                            SYS_CONTEXT('USERENV', 'SERVICE_NAME'),
                            SYS_CONTEXT('USERENV', 'SESSION_USER'),
                            SYS_CONTEXT('USERENV', 'INSTANCE_NAME'),
                            v_v$session_module,
                            v_v$session_action,
                            v_v$session_client_info)
                            RETURNING dbdev_log_id INTO g_log_latest_dbdev_log_id;
    ELSE
      INSERT INTO dbdev_log(tag,
                            module,
                            action,
                            notes,
                            signon_id,
                            sessid,
                            errnbr,
                            errmsg,
                            timer)
                    VALUES (v_tag,
                            p_module,
                            p_action,
                            p_notes,
                            p_signon_id,
                            p_sessid,
                            p_errnbr,
                            p_errmsg,
                            (DBMS_UTILITY.get_time - g_log_g_start_timer)/100)
                            RETURNING dbdev_log_id INTO g_log_latest_dbdev_log_id;
    END IF;      

    COMMIT;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log;
/*----------------------------------------------------------------------------*/

PROCEDURE log_append (p_notes           IN CLOB DEFAULT NULL,
                      p_tag             IN VARCHAR2 DEFAULT NULL)
IS
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_tag                  VARCHAR2(1000);
  v_proc                 VARCHAR2(30) := 'LOG_APPEND';

BEGIN
  IF g_log_enabled_flag THEN
    v_tag := NVL(p_tag, g_log_default_tag);
    g_log_default_tag := v_tag;
  
    IF g_log_latest_dbdev_log_id IS NULL THEN
      log(p_notes => p_notes);
    ELSE
      UPDATE dbdev_log
        SET notes = notes || ' ' || p_notes
      WHERE dbdev_log_id = g_log_latest_dbdev_log_id;
    END IF;
      
    COMMIT;
  END IF;      
      
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_append;          
/*----------------------------------------------------------------------------*/

PROCEDURE log_whoami (p_notes           IN CLOB DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG';
  
BEGIN
  log(p_notes       => p_notes,
      p_whoami_flag => TRUE);
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_whoami;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_id_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_id_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_id_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => p_tag, 
          p_notes => '(' || TO_CHAR(i) || ') is [' || p_collection(i).an_id || ']');
      i := p_collection.NEXT(i);
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_text_id_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_text_id_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_text_id_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => 
          p_tag, p_notes => '(' || TO_CHAR(i) || ') is [' || p_collection(i).text_id || ']');
      i := p_collection.NEXT(i);
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_user_label_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_user_labels_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_user_labels_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => p_tag, 
          p_notes => '(' || TO_CHAR(i) || ') is ' ||
                     'veh_label_id = [' || p_collection(i).veh_label_id || '] ' ||
                     'label_value = ['  || p_collection(i).label_value  || '] ' ||
                     'ws_key      = ['  || p_collection(i).ws_key       || '] ' ||
                     'status = ['       || p_collection(i).status       || '] ' ||
                     'errnbr = ['       || p_collection(i).errnbr       || '] ');
      i := p_collection.NEXT(i);                                                            
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_veh_group_varray1,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_veh_group_varray1 ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_veh_group_varray1 ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => p_tag, 
          p_notes => '(' || TO_CHAR(i) || ') is ' ||
                     'vehid = ['             || TO_CHAR(p_collection(i).vehid)      || '] ' ||
                     'nickname = ['          || p_collection(i).nickname            || '] ' ||
                     'acctgrp_id = ['        || TO_CHAR(p_collection(i).acctgrp_id) || '] ' ||
                     'group_name = ['        || p_collection(i).group_name          || '] ' ||
                     'group_desc = ['        || p_collection(i).group_desc          || '] ' ||
                     'group_type = ['        || p_collection(i).group_name          || '] ' ||
                     'parent_group_name = [' || p_collection(i).parent_group_name   || '] ' ||
                     'user_count = ['        || TO_CHAR(p_collection(i).user_count) || '] ' ||
                     'veh_labels = ['        || TO_CHAR(p_collection(i).veh_labels) || '] ' ||
                     'vin= ['                || p_collection(i).vin                 || '] ' ||
                     'license = ['           || p_collection(i).license             || '] ' );
      i := p_collection.NEXT(i);                                                            
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_veh_group_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_veh_group_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_veh_group_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => p_tag, 
          p_notes => '(' || TO_CHAR(i) || ') is ' ||
                     'vehid = ['             || TO_CHAR(p_collection(i).vehid)      || '] ' ||
                     'nickname = ['          || p_collection(i).nickname            || '] ' ||
                     'acctgrp_id = ['        || TO_CHAR(p_collection(i).acctgrp_id) || '] ' ||
                     'group_name = ['        || p_collection(i).group_name          || '] ' ||
                     'group_desc = ['        || p_collection(i).group_desc          || '] ' ||
                     'group_type = ['        || p_collection(i).group_name          || '] ' ||
                     'parent_group_name = [' || p_collection(i).parent_group_name   || '] ' ||
                     'user_count = ['        || TO_CHAR(p_collection(i).user_count) || '] ' );
      i := p_collection.NEXT(i);                                                            
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_upd_addr_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_upd_addr_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_upd_addr_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => p_tag, 
          p_notes => '(' || TO_CHAR(i) || ') is ' ||
                     'addrid = ['                 || TO_CHAR(p_collection(i).addrid)   || '] ' ||
                     'addrtype = ['               || p_collection(i).addrtype          || '] ' ||
                     'addr1 = ['                  || TO_CHAR(p_collection(i).addr1)    || '] ' ||
                     'addr2 = ['                  || p_collection(i).addr2             || '] ' ||
                     'city = ['                   || p_collection(i).city              || '] ' ||
                     'state = ['                  || p_collection(i).state             || '] ' ||
                     'postal = ['                 || p_collection(i).postal            || '] ' ||
                     'ctrycode = ['               || TO_CHAR(p_collection(i).ctrycode) || '] ' );  
      i := p_collection.NEXT(i);                                                            
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_upd_phone_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_upd_phone_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_upd_phone_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => p_tag, 
          p_notes => '(' || TO_CHAR(i) || ') is ' ||
                     'phoneid = ['                 || TO_CHAR(p_collection(i).phoneid)   || '] ' ||
                     'phonetype = ['               || p_collection(i).phonetype          || '] ' ||
                     'phonenbr = ['                  || TO_CHAR(p_collection(i).phonenbr)    || '] ' ||
                     'phoneext = ['                  || p_collection(i).phoneext             || '] ' );  
      i := p_collection.NEXT(i);                                                            
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_prefs_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_prefs_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_prefs_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => 
          p_tag, p_notes => '(' || TO_CHAR(i) || ') is ' ||
                            '[' || p_collection(i).prefcode || ']' ||
                            '[' || p_collection(i).prefval  || ']');
      i := p_collection.NEXT(i);
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_label_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_labels_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_labels_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => 
          p_tag, p_notes => '(' || TO_CHAR(i) || ') is '          ||
                            '[' || p_collection(i).veh_label_id   || ']' ||
                            '[' || p_collection(i).veh_label_name || ']' ||
                            '[' || p_collection(i).label_value    || ']' ||
                            '[' || p_collection(i).vehid          || ']');
      i := p_collection.NEXT(i);
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_collection (p_collection  IN v_id_plus_varray,
                          p_notes       IN CLOB     DEFAULT NULL,
                          p_tag         IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_COLLECTION';
  i                      PLS_INTEGER;
  
BEGIN
  IF p_collection IS NULL THEN
    log(p_tag, 
        p_action => 'Logging v_id_plus_varray ' || p_notes || ', Ptr is NULL');
  ELSE
    log(p_tag, 
        p_action => 'Logging v_id_plus_varray ' || p_notes || ', Count is ' || TO_CHAR(p_collection.COUNT));
  
    i := p_collection.FIRST;
    WHILE i IS NOT NULL
    LOOP
      log(p_tag => 
          p_tag, p_notes => '(' || TO_CHAR(i) || ') is '          ||
                            '[' || p_collection(i).an_id   || ']' ||
                            '[' || p_collection(i).text    || ']');
      i := p_collection.NEXT(i);
    END LOOP; 
  END IF;
  
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_collection;
/*----------------------------------------------------------------------------*/

PROCEDURE log_format_call_stack (p_tag  IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_FORMAT_CALL_STACK';
    
BEGIN
  IF g_log_enabled_flag THEN
    l_log_multi_line_msg(p_tag    => p_tag,
                         p_action => 'Format Call Stack',
                         p_msg    => DBMS_UTILITY.format_call_stack);
  END IF;
               
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_format_call_stack;
/*----------------------------------------------------------------------------*/
  
PROCEDURE log_format_error_backtrace (p_tag   IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_FORMAT_ERROR_BACKTRACE';
    
BEGIN
  IF g_log_enabled_flag THEN
    l_log_multi_line_msg(p_tag    => p_tag,
                         p_action => 'Format Error Backtrace',
                         p_msg    => DBMS_UTILITY.format_error_backtrace);
  END IF;
            
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_format_error_backtrace;
/*----------------------------------------------------------------------------*/
  
PROCEDURE log_format_error_stack (p_tag IN VARCHAR2 DEFAULT NULL)
IS
  v_proc                 VARCHAR2(30) := 'LOG_FORMAT_ERROR_STACK';
    
BEGIN
  IF g_log_enabled_flag THEN
    l_log_multi_line_msg(p_tag    => p_tag,
                         p_action => 'Format Error Stack',
                         p_msg    => DBMS_UTILITY.format_error_stack);
  END IF;
            
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END log_format_error_stack;
/*----------------------------------------------------------------------------*/

PROCEDURE timer_start(p_msg             IN VARCHAR2)
IS
  v_proc                 VARCHAR2(30) := 'TIMER_START';
    
BEGIN
  IF p_msg IS NOT NULL THEN
    DBMS_OUTPUT.PUT_LINE(p_msg);
  END IF;
    
  g_start_time := DBMS_UTILITY.get_time;
EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END timer_start;
/*----------------------------------------------------------------------------*/

PROCEDURE timer_lap(p_msg               IN VARCHAR2)
IS
  lap_time               NUMBER;
  v_proc                 VARCHAR2(30) := 'TIMER_LAP';
    
BEGIN
  IF g_start_time IS NULL THEN
    g_start_time := DBMS_UTILITY.get_time;
    lap_time := 0.00;
  ELSE
    lap_time := (DBMS_UTILITY.get_time - g_start_time) / 100;
  END IF;
    
  IF p_msg IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Lap time ' || TO_CHAR(lap_time, '999,990.99'));
  ELSE
    DBMS_OUTPUT.PUT_LINE(p_msg || TO_CHAR(lap_time, '999,990.99'));
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END timer_lap;
/*----------------------------------------------------------------------------*/

PROCEDURE timer_end(p_msg               IN VARCHAR2)
IS
  elapsed_time           NUMBER;
  v_proc                 VARCHAR2(30) := 'TIMER_END';
    
BEGIN
  IF g_start_time IS NULL THEN
    elapsed_time := NULL;
  ELSE
    elapsed_time := (DBMS_UTILITY.get_time - g_start_time) / 100;
    g_start_time := NULL;
  END IF;
    
  IF p_msg IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Elapsed time ' || TO_CHAR(elapsed_time, '999,990.99'));
  ELSE
    DBMS_OUTPUT.PUT_LINE(p_msg || TO_CHAR(elapsed_time, '999,990.99'));
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    l_handle_others_exception(v_proc, SQLERRM);
END timer_end;
/*----------------------------------------------------------------------------*/

END dbdev_pkg;
/

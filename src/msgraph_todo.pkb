set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_todo AS

FUNCTION json_object_to_todo_task ( p_json JSON_OBJECT_T ) RETURN todo_task_rt IS

    v_todo_task todo_task_rt;

BEGIN

    v_todo_task.id := p_json.get_string ( 'id' );
    v_todo_task.importance := p_json.get_string ( 'importance' );
    v_todo_task.is_reminder_on := p_json.get_string ( 'isReminderOn' );
    v_todo_task.status := p_json.get_string ( 'status' );
    v_todo_task.title := p_json.get_string ( 'title' );
    v_todo_task.body_content := p_json.get_object ( 'body' ).get_string ( 'content' );
    v_todo_task.body_content_type := p_json.get_object ( 'body' ).get_string ( 'contentType' );
    v_todo_task.due_date_time := p_json.get_object ( 'dueDateTime' ).get_string ( 'dateTime' );
    v_todo_task.due_time_zone := p_json.get_object ( 'dueDateTime' ).get_string ( 'timeZone' );
    v_todo_task.reminder_date_time := p_json.get_object ( 'reminderDateTime' ).get_string ( 'dateTime' );
    v_todo_task.reminder_time_zone := p_json.get_object ( 'reminderDateTime' ).get_string ( 'timeZone' );

    RETURN v_todo_task;

END;


FUNCTION json_object_to_todo_list ( p_json JSON_OBJECT_T ) RETURN todo_list_rt IS

    v_todo_list todo_list_rt;

BEGIN

    v_todo_list.id := p_json.get_string ( 'id' );
    v_todo_list.display_name := p_json.get_string ( 'display_name' );

    RETURN v_todo_list;

END;

FUNCTION todo_task_to_json_object ( p_task IN todo_task_rt ) RETURN JSON_OBJECT_T IS
    
    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_object JSON_OBJECT_T;

BEGIN

    v_json.put ( 'importance', p_task.importance );
    v_json.put ( 'isReminderOn', p_task.is_reminder_on );
    v_json.put ( 'status', p_task.status );
    v_json.put ( 'title', p_task.title );

    v_object := JSON_OBJECT_T ();
    v_object.put ( 'content', p_task.body_content );
    v_object.put ( 'contentType', p_task.body_content_type );
    v_json.put ( 'body', v_object );
    
    IF p_task.due_date_time IS NOT NULL THEN
        v_object := JSON_OBJECT_T ();
        v_object.put ( 'dateTime', p_task.due_date_time );
        v_object.put ( 'timeZone', p_task.due_time_zone );
        v_json.put ( 'dueDateTime', v_object );
    END IF;
    
    IF p_task.is_reminder_on = 'true' THEN
        v_object := JSON_OBJECT_T ();
        v_object.put ( 'dateTime', p_task.due_date_time );
        v_object.put ( 'timeZone', p_task.due_time_zone );
        v_json.put ( 'reminderDateTime', v_object );
    END IF;

    RETURN v_json;

END;

FUNCTION list_todo_lists ( p_user_principal_name IN VARCHAR2 ) RETURN todo_lists_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_lists todo_lists_tt := todo_lists_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_todo_lists_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_lists.extend;
        v_lists (nI) := json_object_to_todo_list ( v_value );

    END LOOP;
    
    RETURN v_lists;
    
END list_todo_lists;

FUNCTION pipe_list_todo_lists ( p_user_principal_name IN VARCHAR2 ) RETURN todo_lists_tt PIPELINED IS
    
    v_lists todo_lists_tt;

    nI PLS_INTEGER;

BEGIN

    v_lists := list_todo_lists ( p_user_principal_name );

    nI := v_lists.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_lists (nI) );

        nI := v_lists.NEXT ( nI );

    END LOOP;

END pipe_list_todo_lists;

FUNCTION create_todo_list ( p_user_principal_name IN VARCHAR2, p_display_name IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_todo_lists_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request.put ( 'displayName', p_display_name );  

    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );
    
    RETURN v_response.get_string ( 'id' );
    
END create_todo_list;

FUNCTION list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_tasks todo_tasks_tt := todo_tasks_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_todo_list_tasks_url, '{id}', p_list_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );
    
    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_tasks.extend;
        v_tasks ( nI ) := json_object_to_todo_task ( v_value );

    END LOOP;
    
    RETURN v_tasks;
    
END list_todo_list_tasks;

FUNCTION pipe_list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt PIPELINED IS
    
    v_tasks todo_tasks_tt;

    nI PLS_INTEGER;

BEGIN

    v_tasks := list_todo_list_tasks ( p_list_id );

    nI := v_tasks.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_tasks (nI) );

        nI := v_tasks.NEXT ( nI );

    END LOOP;

END pipe_list_todo_list_tasks;

FUNCTION create_todo_list_task ( p_list_id IN VARCHAR2, p_task IN todo_task_rt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_todo_list_tasks_url, '{id}', p_list_id );
    
    -- generate request
    v_request := todo_task_to_json_object ( p_task );

    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );
    
    RETURN v_response.get_string ( 'id' );
    
END create_todo_list_task;

END msgraph_todo;

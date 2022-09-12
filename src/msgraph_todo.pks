CREATE OR REPLACE PACKAGE msgraph_todo AS

    -- endpoint urls
    gc_todo_lists_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/todo/lists';
    gc_todo_list_tasks_url CONSTANT VARCHAR2 (57) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/todo/lists/{id}/tasks';

    -- type definitions
    TYPE todo_list_rt IS RECORD (
        id VARCHAR2 (2000),
        display_name VARCHAR2 (2000)
    );
    
    TYPE todo_lists_tt IS TABLE OF todo_list_rt;
    
    TYPE todo_task_rt IS RECORD (
        id VARCHAR2 (2000),
        importance VARCHAR2 (2000),
        is_reminder_on VARCHAR2 (2000),
        status VARCHAR2 (2000),
        title VARCHAR2 (2000),
        body_content CLOB,
        body_content_type VARCHAR2 (2000),
        due_date_time DATE,
        due_time_zone VARCHAR2 (2000),
        reminder_date_time DATE,
        reminder_time_zone VARCHAR2 (2000)
    );
    
    TYPE todo_tasks_tt IS TABLE OF todo_task_rt;

    -- todo
    FUNCTION list_todo_lists ( p_user_principal_name IN VARCHAR2 ) RETURN todo_lists_tt;
    FUNCTION pipe_list_todo_lists ( p_user_principal_name IN VARCHAR2 ) RETURN todo_lists_tt PIPELINED;
    FUNCTION create_todo_list ( p_user_principal_name IN VARCHAR2, p_display_name IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt;
    FUNCTION pipe_list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt PIPELINED;
    FUNCTION create_todo_list_task ( p_list_id IN VARCHAR2, p_task IN todo_task_rt ) RETURN VARCHAR2;
    
END msgraph_todo;
/

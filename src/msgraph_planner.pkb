set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_planner AS

FUNCTION json_object_to_plan ( p_json JSON_OBJECT_T ) RETURN plan_rt IS

    v_plan plan_rt;

BEGIN

    v_plan.id := p_json.get_string ( 'id' );
    v_plan.title := p_json.get_string ( 'title' );
    v_plan.owner := p_json.get_string ( 'owner' );

    RETURN v_plan;

END;

FUNCTION json_object_to_bucket ( p_json JSON_OBJECT_T ) RETURN plan_bucket_rt IS

    v_plan_bucket plan_bucket_rt;

BEGIN

    v_plan_bucket.id := p_json.get_string ( 'id' );
    v_plan_bucket.plan_id := p_json.get_string ( 'planId' );
    v_plan_bucket.name := p_json.get_string ( 'name' );
    v_plan_bucket.order_hint := p_json.get_string ( 'orderHint' );

    RETURN v_plan_bucket;

END;

FUNCTION json_object_to_plan_task ( p_json JSON_OBJECT_T ) RETURN plan_task_rt IS

    v_plan_task plan_task_rt;

BEGIN

    v_plan_task.id := p_json.get_string ( 'id' );
    v_plan_task.plan_id := p_json.get_string ( 'planId' );
    v_plan_task.bucket_id := p_json.get_string ( 'bucketId' );
    v_plan_task.title := p_json.get_string ( 'title' );
    v_plan_task.order_hint := p_json.get_string ( 'orderHint' );
    v_plan_task.percent_complete := p_json.get_number ( 'percentComplete' );
    v_plan_task.start_date_time := p_json.get_date ( 'startDateTime' );
    v_plan_task.due_date_time := p_json.get_date ( 'dueDateTime' );
    v_plan_task.has_description := p_json.get_string ( 'hasDescription' );
    v_plan_task.preview_type := p_json.get_string ( 'previewType' );
    v_plan_task.completed_date_time := p_json.get_date ( 'completedDateTime' );
    v_plan_task.completed_by := p_json.get_string ( 'completedBy' );
    v_plan_task.reference_count := p_json.get_number ( 'referenceCount' );
    v_plan_task.checklist_item_count := p_json.get_number ( 'checklistItemCount' );
    v_plan_task.active_checklist_item_count := p_json.get_number ( 'activeChecklistItemCount' );
    v_plan_task.converation_thread_id := p_json.get_string ( 'conversationThreadId' );

    RETURN v_plan_task;

END;

FUNCTION list_group_plans ( p_group_id VARCHAR2 ) RETURN plans_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_plans plans_tt := plans_tt ();
    
BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_group_plans_url, '{id}', p_group_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );   

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_plans.extend;
        v_plans (nI) := json_object_to_plan ( v_value );

    END LOOP;
    
    RETURN v_plans;
    
END list_group_plans;

FUNCTION pipe_list_group_plans ( p_group_id VARCHAR2 ) RETURN plans_tt PIPELINED IS
    
    v_plans plans_tt;

BEGIN

    v_plans := list_group_plans ( p_group_id );
    
    FOR nI IN v_plans.FIRST .. v_plans.LAST LOOP
        PIPE ROW ( v_plans (nI) );
    END LOOP;    

END pipe_list_group_plans;

FUNCTION create_group_plan ( p_group_id VARCHAR2, p_title VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;

BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;
    msgraph_utils.set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_plans_url;
    
    -- generate request
    v_request.put ( 'owner', p_group_id );
    v_request.put ( 'title', p_title ); 

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    
    RETURN v_json.get_string ( 'id' );

END create_group_plan;

FUNCTION list_plan_buckets ( p_plan_id VARCHAR2 ) RETURN plan_buckets_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_buckets plan_buckets_tt := plan_buckets_tt ();
    
BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_plan_buckets_url, '{id}', p_plan_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_buckets.extend;
        v_buckets (nI) := json_object_to_bucket ( v_value );

    END LOOP;
    
    RETURN v_buckets;
    
END list_plan_buckets;

FUNCTION pipe_list_plan_buckets ( p_plan_id VARCHAR2 ) RETURN plan_buckets_tt PIPELINED IS
    
    v_buckets plan_buckets_tt;

BEGIN

    v_buckets := list_plan_buckets ( p_plan_id );
    
    FOR nI IN v_buckets.FIRST .. v_buckets.LAST LOOP
        PIPE ROW ( v_buckets (nI) );
    END LOOP;  
    
END pipe_list_plan_buckets;

FUNCTION create_plan_bucket ( p_plan_id VARCHAR2, p_name VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;

BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;
    msgraph_utils.set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_buckets_url;
    
    -- generate request
    v_request.put ( 'planId', p_plan_id );
    v_request.put ( 'name', p_name );

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    
    RETURN v_json.get_string ( 'id' );

END create_plan_bucket;

FUNCTION list_plan_tasks ( p_plan_id VARCHAR2 ) RETURN plan_tasks_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_tasks plan_tasks_tt := plan_tasks_tt ();
    
BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_plan_tasks_url, '{id}', p_plan_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );   
        
    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_tasks.extend;
        v_tasks (nI) := json_object_to_plan_task ( v_value );

    END LOOP;
    
    RETURN v_tasks;
    
END list_plan_tasks;

FUNCTION pipe_list_plan_tasks ( p_plan_id VARCHAR2 ) RETURN plan_tasks_tt PIPELINED IS
    
    v_tasks plan_tasks_tt;

BEGIN

    v_tasks := list_plan_tasks ( p_plan_id );
    
    FOR nI IN v_tasks.FIRST .. v_tasks.LAST LOOP
        PIPE ROW ( v_tasks (nI) );
    END LOOP;    

END pipe_list_plan_tasks;

FUNCTION create_plan_task ( p_plan_id VARCHAR2, p_bucket_id VARCHAR2, p_title VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;

BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;
    msgraph_utils.set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_tasks_url;
    
    -- generate request
    v_request.put ( 'planId', p_plan_id );
    v_request.put ( 'bucketId', p_bucket_id );
    v_request.put ( 'title', p_title );

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    
    RETURN v_json.get_string ( 'id' );
    
END create_plan_task;

END msgraph_planner;

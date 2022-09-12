CREATE OR REPLACE PACKAGE msgraph_planner AS

    -- endpoint urls
    gc_group_plans_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/groups/{id}/planner/plans';
    gc_plans_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/planner/plans';
    gc_plan_tasks_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/planner/plans/{id}/tasks';
    gc_tasks_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/planner/tasks';
    gc_plan_buckets_url CONSTANT VARCHAR2 (59) := 'https://graph.microsoft.com/v1.0/planner/plans/{id}/buckets';
    gc_buckets_url CONSTANT VARCHAR2 (48) := 'https://graph.microsoft.com/v1.0/planner/buckets';

    -- type definitions
    TYPE plan_rt IS RECORD (
        id VARCHAR2 (2000),
        title VARCHAR2 (2000),
        owner VARCHAR2 (2000)
    );
    
    TYPE plans_tt IS TABLE OF plan_rt;
    
    TYPE plan_bucket_rt IS RECORD (
        id VARCHAR2 (2000),
        plan_id VARCHAR2 (2000),
        name VARCHAR2 (2000),
        order_hint VARCHAR2 (2000)
    );
    
    TYPE plan_buckets_tt IS TABLE OF plan_bucket_rt;
    
    TYPE plan_task_rt IS RECORD (
        id VARCHAR2 (2000),
        plan_id VARCHAR2 (2000),
        bucket_id VARCHAR2 (2000),
        title VARCHAR2 (2000),
        order_hint VARCHAR2 (2000),
        percent_complete INTEGER,
        start_date_time DATE,
        due_date_time DATE,
        has_description VARCHAR2 (2000),
        preview_type VARCHAR2 (2000),
        completed_date_time DATE,
        completed_by VARCHAR2 (2000),
        reference_count INTEGER,
        checklist_item_count INTEGER,
        active_checklist_item_count INTEGER,
        converation_thread_id VARCHAR2 (2000)
    );
    
    TYPE plan_tasks_tt IS TABLE OF plan_task_rt;

    -- planner
    FUNCTION list_group_plans ( p_group_id VARCHAR2 ) RETURN plans_tt;
    FUNCTION pipe_list_group_plans ( p_group_id VARCHAR2 ) RETURN plans_tt PIPELINED;
    FUNCTION create_group_plan ( p_group_id VARCHAR2, p_title VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION list_plan_buckets ( p_plan_id VARCHAR2 ) RETURN plan_buckets_tt;
    FUNCTION pipe_list_plan_buckets ( p_plan_id VARCHAR2 ) RETURN plan_buckets_tt PIPELINED;
    FUNCTION create_plan_bucket ( p_plan_id VARCHAR2, p_name VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION list_plan_tasks ( p_plan_id VARCHAR2 ) RETURN plan_tasks_tt;
    FUNCTION pipe_list_plan_tasks ( p_plan_id VARCHAR2 ) RETURN plan_tasks_tt PIPELINED;
    FUNCTION create_plan_task ( p_plan_id VARCHAR2, p_bucket_id VARCHAR2, p_title VARCHAR2 ) RETURN VARCHAR2;
    
END msgraph_planner;
/

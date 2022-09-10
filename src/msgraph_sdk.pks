CREATE OR REPLACE PACKAGE msgraph_sdk AS

    -- endpoint urls
    gc_user_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}';
    gc_users_url CONSTANT VARCHAR2 (38) := 'https://graph.microsoft.com/v1.0/users';
    gc_user_contacts_url CONSTANT VARCHAR2 (67) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/contacts';
    gc_user_calendar_events_url CONSTANT VARCHAR2 (74) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/calendar/events';
    gc_user_direct_reports_url CONSTANT VARCHAR2 (72) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/directReports';
    gc_user_manager_url CONSTANT VARCHAR2 (66) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/manager';
    gc_groups_url CONSTANT VARCHAR2 (39) := 'https://graph.microsoft.com/v1.0/groups';
    gc_group_members_url CONSTANT VARCHAR2 (52) := 'https://graph.microsoft.com/v1.0/groups/{id}/members';
    gc_group_plans_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/groups/{id}/planner/plans';
    gc_plans_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/planner/plans';
    gc_plan_tasks_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/planner/plans/{id}/tasks';
    gc_tasks_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/planner/tasks';
    gc_plan_buckets_url CONSTANT VARCHAR2 (59) := 'https://graph.microsoft.com/v1.0/planner/plans/{id}/buckets';
    gc_buckets_url CONSTANT VARCHAR2 (48) := 'https://graph.microsoft.com/v1.0/planner/buckets';
    gc_team_channels_url CONSTANT VARCHAR2 (52) := 'https://graph.microsoft.com/v1.0/teams/{id}/channels';
    gc_user_activities_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/me/activities';
    gc_todo_lists_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/me/todo/lists';
    gc_todo_list_tasks_url CONSTANT VARCHAR2 (57) := 'https://graph.microsoft.com/v1.0/me/todo/lists/{id}/tasks';

    -- global variables
    gv_access_token CLOB;
    gv_access_token_expiration DATE;

    -- type definitions
    TYPE user_rt IS RECORD (
        business_phones VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        given_name VARCHAR2 (2000),
        job_title VARCHAR2 (2000),
        mail VARCHAR2 (2000),
        mobile_phone VARCHAR2 (2000),
        office_location VARCHAR2 (2000),
        preferred_language VARCHAR2 (2000),
        surname VARCHAR2 (2000),
        user_principal_name VARCHAR2 (2000),
        id VARCHAR2 (2000)
    );
    
    TYPE users_tt IS TABLE OF user_rt;
    
    TYPE contact_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE,
        categories VARCHAR2 (2000),
        parent_folder_id VARCHAR2 (2000),
        birthday DATE,
        file_as VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        given_name VARCHAR2 (2000),
        nick_name VARCHAR2 (2000),
        surname VARCHAR2 (2000),
        title VARCHAR2 (2000),
        im_addresses VARCHAR2 (2000),
        job_title VARCHAR2 (2000),
        company_name VARCHAR2 (2000),
        department VARCHAR2 (2000),
        office_location VARCHAR2 (2000),
        business_home_page VARCHAR2 (2000),
        mobile_phone VARCHAR2 (2000),
        home_phones VARCHAR2 (2000),
        business_phones VARCHAR2 (2000),
        personal_notes VARCHAR2 (2000),
        email_address VARCHAR2 (2000),
        home_address_street VARCHAR2 (2000),
        home_address_city VARCHAR2 (2000),
        home_address_state VARCHAR2 (2000),
        home_address_country_or_region VARCHAR2 (2000),
        home_address_postal_code VARCHAR2 (2000),
        business_address_street VARCHAR2 (2000),
        business_address_city VARCHAR2 (2000),
        business_address_state VARCHAR2 (2000),
        business_address_country_or_region VARCHAR2 (2000),
        business_address_postal_code VARCHAR2 (2000)
    );
    
    TYPE contacts_tt IS TABLE OF contact_rt;

    TYPE event_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE,
        categories VARCHAR2 (2000),
        original_start_time_zone VARCHAR2 (2000),
        original_end_time_zone VARCHAR2 (2000),
        reminder_minutes_before_start INTEGER,
        is_reminder_on VARCHAR2(5),
        has_attachments VARCHAR2(5),
        subject VARCHAR2 (2000),
        body_preview VARCHAR2 (2000),
        importance VARCHAR2 (2000),
        sensitivity VARCHAR2 (2000),
        is_all_day VARCHAR2(5),
        is_cancelled VARCHAR2(5),
        is_organizer VARCHAR2(5),
        response_requested VARCHAR2(5),
        series_master_id VARCHAR2 (2000),
        show_as VARCHAR2 (2000),
        type VARCHAR2 (2000),
        web_link VARCHAR2 (2000),
        online_meeting_url VARCHAR2 (2000),
        is_online_meeting VARCHAR2(5),
        online_meeting_provider VARCHAR2 (2000),
        allow_new_time_proposals VARCHAR2(5),
        recurrence VARCHAR2 (2000),
        response_status_response VARCHAR2 (2000),
        response_status_time DATE,
        body_content_type VARCHAR2 (2000),
        body_content CLOB,
        start_date_time DATE,
        start_time_zone VARCHAR2 (2000),
        end_date_time DATE,
        end_time_zone VARCHAR2 (2000),
        location_display_name VARCHAR2 (2000),
        location_location_type VARCHAR2 (2000),
        location_unique_id VARCHAR2 (2000),
        location_unique_id_type VARCHAR2 (2000),
        organizer_email_address_name VARCHAR2 (2000),
        organizer_email_address_address VARCHAR2 (2000),
        online_meeting_join_url VARCHAR2 (2000)
    );
    
    TYPE events_tt IS TABLE OF event_rt;
    
    TYPE attendee_rt IS RECORD (
        type VARCHAR2 (2000),
        status_response VARCHAR2 (2000),
        status_time DATE,
        email_address_name VARCHAR2 (2000),
        email_address_address VARCHAR2 (2000)
    );
    
    TYPE attendees_tt IS TABLE OF attendee_rt;
    
    TYPE group_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        description VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        mail VARCHAR2 (2000),
        visibility VARCHAR2 (2000),
        resource_provisioning_options VARCHAR2(2000)
    );
    
    TYPE groups_tt IS TABLE OF group_rt;

    TYPE channel_rt IS RECORD (
        id VARCHAR2 (2000),
        description VARCHAR2 (2000),
        display_name VARCHAR2 (2000)
    );
    
    TYPE channels_tt IS TABLE OF channel_rt;
    
    TYPE attachment_rt IS RECORD (
        id VARCHAR2 (2000),
        content_type VARCHAR2 (2000),
        content_url VARCHAR2 (2000),
        content CLOB,
        name VARCHAR2 (2000),
        thumbnail_url VARCHAR2 (2000)
    );
    
    TYPE attachments_tt IS TABLE OF attachment_rt;
    
    TYPE activity_rt IS RECORD (
        id VARCHAR2 (2000),
        app_activity_id VARCHAR2 (2000),
        activity_source_host VARCHAR2 (2000),
        user_timezone VARCHAR2 (2000),
        app_display_name VARCHAR2 (2000),
        activation_url VARCHAR2 (2000),
        content_url VARCHAR2 (2000),
        fallback_url VARCHAR2 (2000),
        content_info_context VARCHAR2 (2000),
        content_info_type VARCHAR2 (2000),
        content_info_author VARCHAR2 (2000),
        content_info_name VARCHAR2 (2000),
        icon_url VARCHAR2 (2000),
        alternate_text VARCHAR2 (2000),
        add_image_query VARCHAR2 (2000),
        description VARCHAR2 (2000),
        background_color VARCHAR2 (8),
        display_text VARCHAR2 (2000),
        content_schema VARCHAR2 (2000),
        content_type VARCHAR2 (2000),
        body_type VARCHAR2 (2000),
        body_text VARCHAR2 (2000)
    );
    
    TYPE activities_tt IS TABLE OF activity_rt;
    
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

    -- users
    FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt; 
    FUNCTION list_users RETURN users_tt;
    FUNCTION pipe_list_users RETURN users_tt PIPELINED;
    
    -- contacts
    FUNCTION get_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) RETURN contact_rt;
    FUNCTION create_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt ) RETURN VARCHAR2;
    PROCEDURE update_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt );
    PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 );
    FUNCTION list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt;
    FUNCTION pipe_list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt PIPELINED;
    
    -- calendar events
    FUNCTION get_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN event_rt;
    FUNCTION create_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) RETURN VARCHAR2;
    PROCEDURE update_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt );
    PROCEDURE delete_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 );
    FUNCTION list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt;
    FUNCTION pipe_list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt PIPELINED;
    FUNCTION list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt;
    FUNCTION pipe_list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt PIPELINED;

    -- direct reports
    FUNCTION list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt;
    FUNCTION pipe_list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt PIPELINED;
    
    -- manager
    FUNCTION get_user_manager ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt; 
    
    -- groups
    FUNCTION list_groups RETURN groups_tt;
    FUNCTION pipe_list_groups RETURN groups_tt PIPELINED;
    FUNCTION list_group_members ( p_group_id IN VARCHAR2 ) RETURN users_tt;
    FUNCTION pipe_list_group_members ( p_group_id IN VARCHAR2 ) RETURN users_tt PIPELINED;
    PROCEDURE add_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 );
    PROCEDURE remove_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 );
    
    -- teams
    FUNCTION list_team_groups RETURN groups_tt;
    FUNCTION pipe_list_team_groups RETURN groups_tt PIPELINED;
    FUNCTION list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt;
    FUNCTION pipe_list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt PIPELINED;
    FUNCTION create_team_channel ( p_team_id IN VARCHAR2, p_display_name IN VARCHAR2, p_description IN VARCHAR2 ) RETURN VARCHAR2;
    PROCEDURE delete_team_channel ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 );
    
    -- requires user login
    PROCEDURE send_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL );
    FUNCTION create_user_activity ( p_activity IN activity_rt ) RETURN VARCHAR2;
    FUNCTION list_user_activities RETURN activities_tt;
    FUNCTION pipe_list_user_activities RETURN activities_tt PIPELINED;
    
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
    
    -- todo
    FUNCTION list_todo_lists RETURN todo_lists_tt;
    FUNCTION pipe_list_todo_lists RETURN todo_lists_tt PIPELINED;
    FUNCTION create_todo_list ( p_display_name IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt;
    FUNCTION pipe_list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt PIPELINED;
    FUNCTION create_todo_list_task ( p_list_id IN VARCHAR2, p_task IN todo_task_rt ) RETURN VARCHAR2;
    
END msgraph_sdk;
/

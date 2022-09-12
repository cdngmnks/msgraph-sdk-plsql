CREATE OR REPLACE PACKAGE msgraph_me AS

    -- endpoint urls
    gc_user_activities_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/me/activities';

    -- type definitions    
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

    -- requires user login
    FUNCTION create_user_activity ( p_activity IN activity_rt ) RETURN VARCHAR2;
    FUNCTION list_user_activities RETURN activities_tt;
    FUNCTION pipe_list_user_activities RETURN activities_tt PIPELINED;
    
END msgraph_me;
/

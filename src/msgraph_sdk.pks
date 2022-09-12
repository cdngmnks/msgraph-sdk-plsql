CREATE OR REPLACE PACKAGE msgraph_sdk AS

    -- endpoint urls
    gc_team_channels_url CONSTANT VARCHAR2 (52) := 'https://graph.microsoft.com/v1.0/teams/{id}/channels';
    gc_user_activities_url CONSTANT VARCHAR2 (46) := 'https://graph.microsoft.com/v1.0/me/activities';

    -- type definitions
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
    
    -- teams
    FUNCTION list_team_groups RETURN msgraph_groups.groups_tt;
    FUNCTION pipe_list_team_groups RETURN msgraph_groups.groups_tt PIPELINED;
    FUNCTION list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt;
    FUNCTION pipe_list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt PIPELINED;
    FUNCTION create_team_channel ( p_team_id IN VARCHAR2, p_display_name IN VARCHAR2, p_description IN VARCHAR2 ) RETURN VARCHAR2;
    PROCEDURE delete_team_channel ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 );
    
    -- requires user login
    PROCEDURE send_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL );
    FUNCTION create_user_activity ( p_activity IN activity_rt ) RETURN VARCHAR2;
    FUNCTION list_user_activities RETURN activities_tt;
    FUNCTION pipe_list_user_activities RETURN activities_tt PIPELINED;
    
END msgraph_sdk;
/

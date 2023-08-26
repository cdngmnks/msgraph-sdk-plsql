CREATE OR REPLACE PACKAGE msgraph_teams AS

    -- endpoint urls
    gc_team_members_url CONSTANT VARCHAR2 (51) := 'https://graph.microsoft.com/v1.0/teams/{id}/members';
    gc_team_channels_url CONSTANT VARCHAR2 (52) := 'https://graph.microsoft.com/v1.0/teams/{id}/channels';

    -- type definitions
    TYPE member_rt IS RECORD (
        id VARCHAR2 (2000),
        display_name VARCHAR2 (2000)
    );

    TYPE members_tt IS TABLE OF member_rt;

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
    
    -- teams
    FUNCTION list_team_members ( p_team_id IN VARCHAR2 ) RETURN members_tt;
    FUNCTION pipe_list_team_members ( p_team_id IN VARCHAR2 ) RETURN members_tt PIPELINED;
    PROCEDURE add_team_member ( p_team_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 );
    FUNCTION list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt;
    FUNCTION pipe_list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt PIPELINED;
    FUNCTION create_team_channel ( p_team_id IN VARCHAR2, p_display_name IN VARCHAR2, p_description IN VARCHAR2 ) RETURN VARCHAR2;
    PROCEDURE delete_team_channel ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 );
    PROCEDURE send_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL );
    
END msgraph_teams;
/

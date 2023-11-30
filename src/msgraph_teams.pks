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

    TYPE mention_rt IS RECORD (
        id VARCHAR2 (2000),
        user_id VARCHAR2 (2000),
        user_display_name VARCHAR2 (2000),
        mention_text VARCHAR2 (2000)
    );

    TYPE mentions_tt IS TABLE OF mention_rt;

    TYPE reaction_rt IS RECORD (
        created_date_time DATE,
        reaction_type VARCHAR2 (2000),
        user_id VARCHAR2 (2000),
        user_display_name VARCHAR2 (2000)
    );

    TYPE reactions_tt IS TABLE OF reaction_rt;

    TYPE attachment_rt IS RECORD (
        id VARCHAR2 (2000),
        content_type VARCHAR2 (2000),
        content_url VARCHAR2 (2000),
        content CLOB,
        name VARCHAR2 (2000),
        thumbnail_url VARCHAR2 (2000)
    );
    
    TYPE attachments_tt IS TABLE OF attachment_rt;

    TYPE message_rt IS RECORD (
        id VARCHAR2 (2000),
        reply_to_id VARCHAR2(2000),
        etag VARCHAR2 (2000),
        message_type VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE,
        last_edited_date_time DATE,
        deleted_date_time DATE,
        subject VARCHAR2 (2000),
        summary VARCHAR2 (2000),
        chat_id VARCHAR2 (2000),
        importance VARCHAR2 (2000),
        locale VARCHAR2 (2000),
        web_url VARCHAR2 (2000),
        from_user_id  VARCHAR2 (2000),
        from_user_display_name VARCHAR2 (2000),
        body_content_type VARCHAR2 (2000),
        body_content CLOB,
        channel_identity_team_id VARCHAR2 (2000),
        channel_identity_channel_id VARCHAR2 (2000)
    );

    TYPE messages_tt IS TABLE OF message_rt;

    -- teams
    FUNCTION list_team_members ( p_team_id IN VARCHAR2 ) RETURN members_tt;
    FUNCTION pipe_list_team_members ( p_team_id IN VARCHAR2 ) RETURN members_tt PIPELINED;
    FUNCTION get_team_member ( p_team_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) RETURN member_rt;
    PROCEDURE add_team_member ( p_team_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 );
    PROCEDURE remove_team_member ( p_team_id IN VARCHAR2, p_member_id IN VARCHAR2 );
    FUNCTION list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt;
    FUNCTION pipe_list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt PIPELINED;
    FUNCTION create_team_channel ( p_team_id IN VARCHAR2, p_display_name IN VARCHAR2, p_description IN VARCHAR2 ) RETURN VARCHAR2;
    PROCEDURE delete_team_channel ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 );
    FUNCTION list_team_channel_messages ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 ) RETURN messages_tt;
    FUNCTION pipe_list_team_channel_messages ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 ) RETURN messages_tt PIPELINED;
    PROCEDURE send_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL );
    PROCEDURE send_team_channel_message_reply ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reply_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL);
    PROCEDURE update_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL );
    PROCEDURE update_team_channel_message_reply ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reply_id IN VARCHAR2, p_reply_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL );
    PROCEDURE set_team_channel_message_reaction ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reaction_type IN VARCHAR2 );
    PROCEDURE unset_team_channel_message_reaction ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reaction_type IN VARCHAR2 );

END msgraph_teams;
/

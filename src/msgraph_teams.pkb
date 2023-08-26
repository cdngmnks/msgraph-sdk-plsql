set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_teams AS

FUNCTION json_object_to_member ( p_json JSON_OBJECT_T ) RETURN member_rt IS

    v_member member_rt;

BEGIN

    v_member.display_name := p_json.get_string ( 'displayName' );
    v_member.id := p_json.get_string ( 'id' );

    RETURN v_member;

END;

FUNCTION json_object_to_channel ( p_json JSON_OBJECT_T ) RETURN channel_rt IS

    v_channel channel_rt;

BEGIN

    v_channel.description := p_json.get_string ( 'description' );
    v_channel.display_name := p_json.get_string ( 'displayName' );
    v_channel.id := p_json.get_string ( 'id' );

    RETURN v_channel;

END;

FUNCTION list_team_members ( p_team_id IN VARCHAR2 ) RETURN members_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_members members_tt := members_tt ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_team_members_url, '{id}', p_team_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_members.extend;
        v_members (nI) := json_object_to_member ( v_value );

    END LOOP;
    
    RETURN v_members;

END;

FUNCTION pipe_list_team_members ( p_team_id IN VARCHAR2 ) RETURN members_tt PIPELINED IS
    
    v_members members_tt;

    nI PLS_INTEGER;

BEGIN

    v_members := list_team_members ( p_team_id );

    nI := v_members.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_members (nI) );

        nI := v_members.NEXT ( nI );

    END LOOP;

END pipe_list_team_members;

PROCEDURE add_team_member ( p_team_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;
    
    v_user msgraph_users.user_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_members_url, '{id}', p_team_id );
    
    -- generate request
    v_request.put ( 'user@odata.bind', 'https://graph.microsoft.com/v1.0/users('''|| p_user_principal_name || '''' );
    
    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

END;

FUNCTION list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_channels channels_tt := channels_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_team_channels_url, '{id}', p_team_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_channels.extend;
        v_channels (nI) := json_object_to_channel ( v_value );

    END LOOP;
    
    RETURN v_channels;

END list_team_channels;

FUNCTION pipe_list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt PIPELINED IS
    
    v_channels channels_tt;

    nI PLS_INTEGER;

BEGIN

    v_channels := list_team_channels ( p_team_id );

    nI := v_channels.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_channels (nI) );

        nI := v_channels.NEXT ( nI );

    END LOOP;

END pipe_list_team_channels;

FUNCTION create_team_channel ( p_team_id IN VARCHAR2, p_display_name IN VARCHAR2, p_description IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id );
    
    -- generate request
    v_request.put ( 'displayName', p_display_name );
    v_request.put ( 'description', p_description );
    
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );
    
    RETURN v_response.get_string ( 'id' );

END create_team_channel;

PROCEDURE delete_team_channel ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN
    
    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id;
    
    -- make request
    msgraph_utils.make_delete_request ( v_request_url );
    
END delete_team_channel;

PROCEDURE send_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();
    v_array JSON_ARRAY_T := JSON_ARRAY_T ();
    v_object JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

    nI PLS_INTEGER;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages';
    
    -- generate request
    v_object.put ( 'contentType', 'html' );
    v_object.put ( 'content', p_message_content );
    v_request.put ( 'body', v_object );

    -- add attachments
    IF p_attachments IS NOT NULL THEN

        nI := p_attachments.FIRST;

        WHILE (nI IS NOT NULL) LOOP

            v_object := JSON_OBJECT_T ();
            v_object.put ( 'id', p_attachments (nI).id );
            v_object.put ( 'contentType', p_attachments (nI).content_type );
            v_object.put ( 'contentUrl', p_attachments (nI).content_url );
            v_object.put ( 'content', p_attachments (nI).content );
            v_object.put ( 'name', p_attachments (nI).name );
            v_object.put ( 'thumbnailUrl', p_attachments (nI).thumbnail_url );
            v_array.append ( v_object );

        END LOOP;

        v_request.put ( 'attachments', v_array );

    END IF;
    
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                     v_request.to_clob );

END send_team_channel_message;

END msgraph_teams;

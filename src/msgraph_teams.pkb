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

FUNCTION json_object_to_message ( p_json JSON_OBJECT_T ) RETURN message_rt IS

    v_message message_rt;

BEGIN

    v_message.id := p_json.get_string ( 'id' );
    v_message.reply_to_id := p_json.get_string ( 'replyToId' );
    v_message.etag := p_json.get_string ( 'etag' );
    v_message.message_type := p_json.get_string ( 'messageType' );
    v_message.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_message.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );
    v_message.last_edited_date_time := p_json.get_date ( 'lastEditedDateTime' );
    v_message.deleted_date_time := p_json.get_date ( 'deletedDateTime' );
    v_message.subject := p_json.get_string ( 'subject' );
    v_message.summary := p_json.get_string ( 'summary' );
    v_message.chat_id := p_json.get_string ( 'chatId' );
    v_message.importance := p_json.get_string ( 'importance' );
    v_message.locale := p_json.get_string ( 'locale' );
    v_message.web_url := p_json.get_string ( 'webUrl' );
    v_message.from_user_id := p_json.get_object ( 'from' ).get_object ( 'user' ).get_string ( 'id' );
    v_message.from_user_display_name := p_json.get_object ( 'from' ).get_object ( 'user' ).get_string ( 'displayName' );
    v_message.body_content_type := p_json.get_object ( 'body' ).get_string ( 'contentType' );
    v_message.body_content := p_json.get_object ( 'body' ).get_string ( 'content' );
    v_message.channel_identity_team_id := p_json.get_object ( 'channelIdentity' ).get_string ( 'teamId' );
    v_message.channel_identity_channel_id := p_json.get_object( 'channelIdentity' ).get_string ( 'channelId' );

    RETURN v_message;

END;

FUNCTION attachment_to_json_object ( p_attachment IN attachment_rt ) RETURN JSON_OBJECT_T IS
    
    v_json JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    v_json.put ( 'contentType', p_attachment.content_type );
    v_json.put ( 'contentUrl', p_attachment.content_url );
    v_json.put ( 'content', p_attachment.content );
    v_json.put ( 'name', p_attachment.name );
    v_json.put ( 'thumbnailUrl', p_attachment.thumbnail_url );
    v_json.put ( 'id', p_attachment.id );

    RETURN v_json;

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

FUNCTION get_team_member ( p_team_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) RETURN member_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;
    v_member member_rt;

BEGIN
    -- generate request URL
    v_request_url := REPLACE( gc_team_members_url, '{id}', p_team_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( p_url => v_request_url,
                                                   p_parm_name => '$filter',
                                                   p_parm_value => 'microsoft.graph.aadUserConversationMember/email eq ''' || p_user_principal_name || '''');

    v_member := json_object_to_member ( TREAT (v_response.get_array ('value').get(0) as json_object_t) );

    RETURN v_member;

END get_team_member;

PROCEDURE add_team_member ( p_team_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_members_url, '{id}', p_team_id );
    
    -- generate request
    v_request.put ( '@odata.type', '#microsoft.graph.aadUserConversationMember');
    v_request.put ( 'user@odata.bind', 'https://graph.microsoft.com/v1.0/users('''|| p_user_principal_name || ''')' );

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

END add_team_member;

PROCEDURE remove_team_member ( p_team_id IN VARCHAR2, p_member_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_members_url, '{id}', p_team_id ) || '/' || p_member_id;
    
    -- make request
    msgraph_utils.make_delete_request ( v_request_url );

END remove_team_member;

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

FUNCTION get_team_channel ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 ) RETURN channel_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;
    
    v_channel channel_rt;

BEGIN

    v_request_url := REPLACE( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id;

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );
    v_channel := json_object_to_channel ( v_response );

    RETURN v_channel;

END get_team_channel;

FUNCTION get_team_channel ( p_team_id IN VARCHAR2, p_display_name IN VARCHAR2 ) RETURN channel_rt is

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;
    
    v_channel channel_rt;

BEGIN
    v_request_url := REPLACE( gc_team_channels_url, '{id}', p_team_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( p_url => v_request_url,
                                                   p_parm_name => '$filter',
                                                   p_parm_value => 'displayName eq ''' || p_display_name || '''');

    v_channel := json_object_to_channel ( TREAT (v_response.get_array ('value').get(0) as json_object_t) );

    RETURN v_channel;

END get_team_channel;

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

PROCEDURE add_team_channel_tab ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_display_name IN VARCHAR2, p_teams_app_id IN VARCHAR2, p_entity_id IN VARCHAR2, p_content_url IN VARCHAR2, p_remove_url IN VARCHAR2, p_website_url IN VARCHAR2) IS

    v_request_url VARCHAR2 (255);
    v_object JSON_OBJECT_T := JSON_OBJECT_T ();
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/tabs';

    -- generate request
    v_object.put ( 'entityId', p_entity_id );
    v_object.put ( 'contentUrl', p_content_url );
    v_object.put ( 'removeUrl', p_remove_url );
    v_object.put ( 'websiteUrl', p_website_url );

    v_request.put ( 'displayName', p_display_name );
    v_request.put ( 'teamsApp@odata.bind', 'https://graph.microsoft.com/v1.0/appCatalogs/teamsApps/' || p_teams_app_id );
    v_request.put ( 'configuration', v_object );

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url );

END add_team_channel_tab;

PROCEDURE add_team_channel_website_tab ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_display_name IN VARCHAR2, p_website_url IN VARCHAR2 ) IS
BEGIN

    add_team_channel_tab ( p_team_id => p_team_id, 
                           p_channel_id => p_channel_id, 
                           p_display_name => p_display_name, 
                           p_teams_app_id => gc_website_app_id, 
                           p_entity_id => null,
                           p_content_url => p_website_url,
                           p_remove_url => null,
                           p_website_url => p_website_url );

END add_team_channel_website_tab;

PROCEDURE add_team_channel_sharepoint_tab ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_display_name IN VARCHAR2, p_content_url IN VARCHAR2 ) IS
BEGIN

    add_team_channel_tab ( p_team_id => p_team_id, 
                           p_channel_id => p_channel_id, 
                           p_display_name => p_display_name, 
                           p_teams_app_id => gc_sharepoint_app_id, 
                           p_entity_id => '',
                           p_content_url => p_content_url,
                           p_remove_url => null,
                           p_website_url => null );

END add_team_channel_sharepoint_tab;

FUNCTION list_team_channel_messages ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 ) RETURN messages_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_messages messages_tt := messages_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages';

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_messages.extend;
        v_messages (nI) := json_object_to_message ( v_value );

    END LOOP;
    
    RETURN v_messages;

END list_team_channel_messages;

FUNCTION pipe_list_team_channel_messages ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 ) RETURN messages_tt PIPELINED IS

    v_messages messages_tt;

    nI PLS_INTEGER;

BEGIN

    v_messages := list_team_channel_messages ( p_team_id, p_channel_id );

    nI := v_messages.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_messages (nI) );

        nI := v_messages.NEXT ( nI );

    END LOOP;

END pipe_list_team_channel_messages;

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
            v_object := attachment_to_json_object ( p_attachments(nI) );
            v_array.append ( v_object );

            nI := p_attachments.NEXT ( nI );

        END LOOP;

        v_request.put ( 'attachments', v_array );

    END IF;
    
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

END send_team_channel_message;

PROCEDURE send_team_channel_message_reply ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reply_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();
    v_array JSON_ARRAY_T := JSON_ARRAY_T ();
    v_object JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

    nI PLS_INTEGER;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages/' || p_message_id || '/replies';
    
    -- generate request
    v_object.put ( 'contentType', 'html' );
    v_object.put ( 'content', p_reply_content );
    v_request.put ( 'body', v_object );

    -- add attachments
    IF p_attachments IS NOT NULL THEN

        nI := p_attachments.FIRST;

        WHILE (nI IS NOT NULL) LOOP

            v_object := JSON_OBJECT_T ();
            v_object := attachment_to_json_object ( p_attachments(nI) );
            v_array.append ( v_object );

            nI := p_attachments.NEXT ( nI );

        END LOOP;

        v_request.put ( 'attachments', v_array );

    END IF;
    
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

END send_team_channel_message_reply;

PROCEDURE update_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();
    v_array JSON_ARRAY_T := JSON_ARRAY_T ();
    v_object JSON_OBJECT_T := JSON_OBJECT_T ();

    nI PLS_INTEGER;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages/' || p_message_id;
    
    -- generate request
    v_object.put ( 'contentType', 'html' );
    v_object.put ( 'content', p_message_content );
    v_request.put ( 'body', v_object );

    -- add attachments
    IF p_attachments IS NOT NULL THEN

        nI := p_attachments.FIRST;

        WHILE (nI IS NOT NULL) LOOP

            v_object := JSON_OBJECT_T ();
            v_object := attachment_to_json_object ( p_attachments(nI) );
            v_array.append ( v_object );

            nI := p_attachments.NEXT ( nI );

        END LOOP;

        v_request.put ( 'attachments', v_array );

    END IF;
    
    msgraph_utils.make_patch_request ( v_request_url,
                                       v_request.to_clob );

END update_team_channel_message;

PROCEDURE update_team_channel_message_reply ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reply_id IN VARCHAR2, p_reply_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();
    v_array JSON_ARRAY_T := JSON_ARRAY_T ();
    v_object JSON_OBJECT_T := JSON_OBJECT_T ();

    nI PLS_INTEGER;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages/' || p_message_id || '/replies/' || p_reply_id;
    
    -- generate request
    v_object.put ( 'contentType', 'html' );
    v_object.put ( 'content', p_reply_content );
    v_request.put ( 'body', v_object );

    -- add attachments
    IF p_attachments IS NOT NULL THEN

        nI := p_attachments.FIRST;

        WHILE (nI IS NOT NULL) LOOP

            v_object := JSON_OBJECT_T ();
            v_object := attachment_to_json_object ( p_attachments(nI) );
            v_array.append ( v_object );

            nI := p_attachments.NEXT ( nI );

        END LOOP;

        v_request.put ( 'attachments', v_array );

    END IF;
    
    msgraph_utils.make_patch_request ( v_request_url,
                                       v_request.to_clob );

END update_team_channel_message_reply;

PROCEDURE set_team_channel_message_reaction ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reaction_type IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages/' || p_message_id || '/setReaction';

    v_request.put ( 'reactionType', p_reaction_type );

    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

END set_team_channel_message_reaction;

PROCEDURE unset_team_channel_message_reaction ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_id IN VARCHAR2, p_reaction_type IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages/' || p_message_id || '/unsetReaction';

    v_request.put ( 'reactionType', p_reaction_type );

    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

END unset_team_channel_message_reaction;


END msgraph_teams;
/

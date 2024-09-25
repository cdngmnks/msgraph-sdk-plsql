CREATE OR REPLACE PACKAGE BODY msgraph_mail AS

FUNCTION json_object_to_message ( p_json IN JSON_OBJECT_T ) RETURN message_rt IS

    v_message message_rt;

BEGIN

    v_message.id := p_json.get_string ( 'id' );
    v_message.subject := p_json.get_string ( 'subject' );
    v_message.body_content := p_json.get_string ( 'displayName' );
    v_message.body_content_type := p_json.get_string ( 'webUrl' );
    v_message.importance := p_json.get_string ( 'importance' );
    v_message.has_attachments := p_json.get_string ( 'hasAttachments' );
    v_message.conversation_id := p_json.get_string ( 'conversationId' );
    v_message.sender_name := p_json.get_object ( 'sender' ).get_object ( 'emailAddress' ).get_string ( 'name' );
    v_message.sender_email_address := p_json.get_object ( 'sender' ).get_object ( 'emailAddress' ).get_string ( 'name' );
--    v_message.to_recipients_names := p_json.get_array ( 'toRecipients' );
--    v_message.to_recipients_email_addresses := p_json.get_array ( 'toRecipients' );
--    v_message.cc_recipients_names := p_json.get_array ( 'ccRecipients' );
--    v_message.cc_recipients_email_addresses := p_json.get_array ( 'ccRecipients' );
    v_message.received_date_time := p_json.get_date ( 'receivedDateTime' );

    RETURN v_message;

END json_object_to_message;

FUNCTION list_messages ( p_user_principal_name IN VARCHAR2, p_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN messages_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_messages messages_tt := messages_tt ();
    
BEGIN

    -- generate request URL
    IF p_folder_id IS NOT NULL THEN
        v_request_url := REPLACE( gc_folder_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_folder_id || '/messages';
    ELSE
        v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    END IF;

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_messages.extend;
        v_messages (nI) := json_object_to_message ( v_value );

    END LOOP;

    RETURN v_messages;

END list_messages;

FUNCTION pipe_list_messages ( p_user_principal_name IN VARCHAR2, p_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN messages_tt PIPELINED IS

    v_messages messages_tt;

    nI PLS_INTEGER;

BEGIN

    v_messages := list_messages ( p_user_principal_name, p_folder_id );

    nI := v_messages.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_messages (nI) );

        nI := v_messages.NEXT ( nI );

    END LOOP;

END pipe_list_messages;

END msgraph_mail;

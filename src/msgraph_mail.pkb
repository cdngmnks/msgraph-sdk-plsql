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

FUNCTION json_object_to_attachment ( p_json IN JSON_OBJECT_T ) RETURN attachment_rt IS

    v_attachment attachment_rt;

BEGIN

    v_attachment.id := p_json.get_string ( 'id' );
    v_attachment.name := p_json.get_string ( 'name' );
    v_attachment.content_type := p_json.get_string ( 'contentType' );
    v_attachment.content_size := p_json.get_number ( 'size' );
    v_attachment.content_bytes := p_json.get_clob ( 'contentBytes' );
    v_attachment.is_inline := p_json.get_string ( 'isInline' );

    RETURN v_attachment;

END json_object_to_attachment;

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

FUNCTION create_forward_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id || '/createForward';

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url );

    RETURN v_response.get_string ( 'id' );

END create_forward_message_draft;

FUNCTION create_reply_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id || '/createReply';

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url );

    RETURN v_response.get_string ( 'id' );

END create_reply_message_draft;

FUNCTION create_reply_all_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id || '/createReplyAll';

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url );

    RETURN v_response.get_string ( 'id' );

END create_reply_all_message_draft;

PROCEDURE delete_message ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id;

    -- make request
    msgraph_utils.make_delete_request ( v_request_url );

END delete_message;

FUNCTION list_attachments ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN attachments_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_attachments attachments_tt := attachments_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id || '/attachments';

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_attachments.extend;
        v_attachments (nI) := json_object_to_attachment ( v_value );

    END LOOP;

    RETURN v_attachments;

END list_attachments;

FUNCTION pipe_list_attachments ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN attachments_tt PIPELINED IS

    v_attachments attachments_tt;

    nI PLS_INTEGER;

BEGIN

    v_attachments := list_attachments ( p_user_principal_name, p_message_id );

    nI := v_attachments.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_attachments (nI) );

        nI := v_attachments.NEXT ( nI );

    END LOOP;

END pipe_list_attachments;


END msgraph_mail;

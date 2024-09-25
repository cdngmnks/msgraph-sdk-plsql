CREATE OR REPLACE PACKAGE BODY msgraph_mail AS

FUNCTION json_object_to_message ( p_json IN JSON_OBJECT_T ) RETURN message_rt IS

    v_message message_rt;

BEGIN

    v_message.id := p_json.get_string ( 'id' );
    v_message.subject := p_json.get_string ( 'subject' );
    v_message.body_content := p_json.get_object ( 'body' ).get_clob ( 'content' );
    v_message.body_content_type := p_json.get_object ( 'body' ).get_string ( 'contentType' );
    v_message.importance := p_json.get_string ( 'importance' );
    v_message.has_attachments := p_json.get_string ( 'hasAttachments' );
    v_message.conversation_id := p_json.get_string ( 'conversationId' );
    v_message.sender_name := p_json.get_object ( 'sender' ).get_object ( 'emailAddress' ).get_string ( 'name' );
    v_message.sender_email_address := p_json.get_object ( 'sender' ).get_object ( 'emailAddress' ).get_string ( 'address' );
    v_message.received_date_time := p_json.get_date ( 'receivedDateTime' );

    RETURN v_message;

END json_object_to_message;

FUNCTION json_object_to_recipient ( p_json IN JSON_OBJECT_T, p_recipient_type IN VARCHAR2 ) RETURN recipient_rt IS

    v_recipient recipient_rt;

BEGIN

    v_recipient.recipient_type := p_recipient_type;
    v_recipient.email_address_name := p_json.get_object ( 'emailAddress' ).get_string ( 'name' );
    v_recipient.email_address_address := p_json.get_object ( 'emailAddress' ).get_string ( 'address' );

    RETURN v_recipient;

END json_object_to_recipient;

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

FUNCTION message_to_json_object ( p_message IN message_rt, p_recipients IN recipients_tt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_object JSON_OBJECT_T;
    v_recipient JSON_OBJECT_T;
    v_to_array JSON_ARRAY_T;
    v_cc_array JSON_ARRAY_T;
    v_bcc_array JSON_ARRAY_T;
    
    nI PLS_INTEGER;

BEGIN

    v_json.put ( 'subject', p_message.subject );
    v_json.put ( 'importance', p_message.importance );

    v_object := JSON_OBJECT_T ();
    v_object.put ( 'contentType', p_message.body_content_type );
    v_object.put ( 'content', p_message.body_content );
    v_json.put ( 'body', v_object );
    
    -- add to recipients
    nI := p_recipients.FIRST;
    WHILE (nI IS NOT NULL) LOOP

        v_recipient := JSON_OBJECT_T ();

        v_object := JSON_OBJECT_T ();
        v_object.put ( 'name', p_recipients (nI).email_address_name );
        v_object.put ( 'address', p_recipients (nI).email_address_address );
        v_recipient.put ( 'emailAddress', v_object );

        CASE p_recipients (nI).recipient_type
        WHEN 'to' THEN
            v_to_array.append ( v_recipient );
        WHEN 'cc' THEN
            v_cc_array.append ( v_recipient );
        WHEN 'bcc' THEN
            v_bcc_array.append ( v_recipient );
        END CASE;

        nI := p_recipients.NEXT ( nI );

    END LOOP;

    v_json.put ( 'toRecipients', v_to_array );
    v_json.put ( 'ccRecipients', v_cc_array );
    v_json.put ( 'bccRecipients', v_bcc_array );

    RETURN v_json;

END message_to_json_object;

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

PROCEDURE update_message_draft ( p_user_principal_name IN VARCHAR2, p_message IN message_rt, p_recipients IN recipients_tt ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message.id;
    
    -- generate request
    v_request := message_to_json_object ( p_message, p_recipients );
    
    -- make request
    msgraph_utils.make_patch_request ( v_request_url,
                                       v_request.to_clob );

END update_message_draft;

PROCEDURE send_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id || '/send';

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url );

END send_message_draft;

PROCEDURE delete_message ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id;

    -- make request
    msgraph_utils.make_delete_request ( v_request_url );

END delete_message;

FUNCTION list_recipients ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN recipients_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_recipients recipients_tt := recipients_tt ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id;
    
    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    -- add toRecipients
    v_values := v_response.get_array ( 'toRecipients' );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_recipients.extend;
        v_recipients (nI) := json_object_to_recipient ( v_value, 'to' );

    END LOOP;

    -- add ccRecipients
    v_values := v_response.get_array ( 'ccRecipients' );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_recipients.extend;
        v_recipients (nI) := json_object_to_recipient ( v_value, 'cc' );

    END LOOP;
    
    -- add bccRecipients
    v_values := v_response.get_array ( 'bccRecipients' );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_recipients.extend;
        v_recipients (nI) := json_object_to_recipient ( v_value, 'bcc' );

    END LOOP;

    RETURN v_recipients;

END list_recipients;

FUNCTION pipe_list_recipients ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN recipients_tt PIPELINED IS

    v_recipients recipients_tt;

    nI PLS_INTEGER;

BEGIN

    v_recipients := list_recipients ( p_user_principal_name, p_message_id );

    nI := v_recipients.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_recipients (nI) );

        nI := v_recipients.NEXT ( nI );

    END LOOP;

END pipe_list_recipients;



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

FUNCTION add_file_attachment ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2, p_file_name IN VARCHAR2, p_file_blob BLOB ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id || '/attachments';

    -- generate request
    v_request.put ( '@odata.type', '#microsoft.graph.fileAttachment' );
    v_request.put ( 'name', p_file_name );
    v_request.put ( 'contentBytes', apex_web_service.blob2clobbase64 ( p_file_blob) );

    v_response := msgraph_utils.make_post_request ( v_request_url, v_request.to_clob );

    RETURN v_response.get_string ( 'id' );

END add_file_attachment;

PROCEDURE delete_attachment ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2, p_attachment_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_messages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_message_id || '/attachments/' || p_attachment_id;

    -- make request
    msgraph_utils.make_delete_request ( v_request_url );

END delete_attachment;

END msgraph_mail;

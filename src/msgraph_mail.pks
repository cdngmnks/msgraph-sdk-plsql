CREATE OR REPLACE PACKAGE msgraph_mail AS

    -- endpoint urls
    gc_messages_url CONSTANT VARCHAR2 (67) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/messages';
    gc_folder_messages_url CONSTANT VARCHAR2 (70) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/mailFolders';

    -- type definitions
    TYPE message_rt IS RECORD (
        id VARCHAR2 (2000),
        subject VARCHAR2 (2000),
        body_content CLOB,
        body_content_type VARCHAR2 (2000),
        has_attachments VARCHAR2 (2000),
        importance VARCHAR2 (2000),
        conversation_id VARCHAR2 (2000),
        sender_name VARCHAR2 (2000),
        sender_email_address VARCHAR2 (2000),
        received_date_time DATE
    );

    TYPE messages_tt IS TABLE OF message_rt;

    TYPE recipient_rt IS RECORD (
        recipient_type VARCHAR2 (2000),
        email_address_name VARCHAR2 (2000),
        email_address_address VARCHAR2 (2000)
    );

    TYPE recipients_tt IS TABLE OF recipient_rt;

    TYPE attachment_rt IS RECORD (
        id VARCHAR2 (2000),
        name VARCHAR2 (2000),
        content_type VARCHAR2(2000),
        content_size INTEGER,
        content_bytes CLOB,
        is_inline VARCHAR2(2000)
    );

    TYPE attachments_tt IS TABLE OF attachment_rt;

    -- messages
    FUNCTION list_messages ( p_user_principal_name IN VARCHAR2, p_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN messages_tt;
    FUNCTION pipe_list_messages ( p_user_principal_name IN VARCHAR2, p_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN messages_tt PIPELINED;
--    FUNCTION get_message ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN message_rt;
--    FUNCTION download_message ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN BLOB;
    FUNCTION create_forward_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION create_reply_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION create_reply_all_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN VARCHAR2;
    PROCEDURE update_message_draft ( p_user_principal_name IN VARCHAR2, p_message IN message_rt, p_recipients IN recipients_tt );
    PROCEDURE send_message_draft ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 );
    PROCEDURE delete_message ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 );

    -- recipients
    FUNCTION list_recipients ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN recipients_tt;
    FUNCTION pipe_list_recipients ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN recipients_tt PIPELINED;

    -- attachments
    FUNCTION list_attachments ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN attachments_tt;
    FUNCTION pipe_list_attachments ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN attachments_tt PIPELINED;
    FUNCTION add_file_attachment ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2, p_file_name IN VARCHAR2, p_file_blob BLOB ) RETURN VARCHAR2;
    PROCEDURE delete_attachment ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2, p_attachment_id IN VARCHAR2 );
--    FUNCTION download_attachment ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2, p_attachment_id IN VARCHAR2 ) RETURN BLOB;

END msgraph_mail;
/

CREATE OR REPLACE PACKAGE msgraph_mail AS

    -- endpoint urls
    gc_messages_url CONSTANT VARCHAR2 (67) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/messages';
    gc_folder_messages_url CONSTANT VARCHAR2 (70) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/mailFolders';
    gc_attachments_url CONSTANT VARCHAR2 (84) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/messages/{id}/attachments';

    -- type definitions
    TYPE email_address_rt IS RECORD (
        name VARCHAR2 (2000),
        address VARCHAR2 (2000)
    );

    TYPE email_addresses_tt IS TABLE OF email_address_rt;

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
        to_recipients_names VARCHAR2 (2000),
        to_recipients_email_addresses VARCHAR2 (2000),
        cc_recipients_names VARCHAR2 (2000),
        cc_recipients_email_addresses VARCHAR2 (2000),
        received_date_time DATE
    );

    TYPE messages_tt IS TABLE OF message_rt;

    TYPE attachment_rt IS RECORD (
        id VARCHAR2 (2000),
        name VARCHAR2 (2000),
        content_type VARCHAR2(2000),
        content_size INTEGER,
        is_inline VARCHAR2(2000),
        content_bytes CLOB
    );

    TYPE attachments_tt IS TABLE OF attachment_rt;

    -- messages
    FUNCTION list_messages ( p_user_principal_name IN VARCHAR2, p_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN messages_tt;
    FUNCTION pipe_list_messages ( p_user_principal_name IN VARCHAR2, p_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN messages_tt PIPELINED;
--    FUNCTION get_message ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN message_rt;
--    FUNCTION download_message ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN BLOB;

    -- attachments
--    FUNCTION list_attachments ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN attachments_tt;
--    FUNCTION pipe_list_attachments ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2 ) RETURN attachments_tt PIPELINED;
--    FUNCTION download_attachment ( p_user_principal_name IN VARCHAR2, p_message_id IN VARCHAR2, p_attachment_id IN VARCHAR2 ) RETURN BLOB;

END msgraph_mail;
/
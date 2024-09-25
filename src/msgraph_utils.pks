CREATE OR REPLACE PACKAGE msgraph_utils AS

    -- endpoint urls
    gc_token_url CONSTANT VARCHAR2 (88) := 'https://login.microsoftonline.com/' || msgraph_config.gc_tenant_id || '/oauth2/v2.0/token';

    -- global variables
    gv_access_token CLOB;
    gv_access_token_expiration DATE;

    -- function definitions
    PROCEDURE set_authorization_header;
    PROCEDURE set_content_type_header ( p_content_type IN VARCHAR2  DEFAULT 'application/json' );
    PROCEDURE set_content_length_header ( p_content_length IN INTEGER DEFAULT 0 );
    PROCEDURE check_response_error ( p_response IN CLOB );
    FUNCTION get_access_token RETURN CLOB;
    FUNCTION json_array_to_csv ( p_array IN JSON_ARRAY_T, p_delimiter IN VARCHAR2 DEFAULT ';' ) RETURN VARCHAR2;
    FUNCTION csv_to_json_array ( p_csv IN VARCHAR2, p_delimiter IN VARCHAR2 DEFAULT ';' ) RETURN JSON_ARRAY_T;

    FUNCTION make_get_request ( p_url IN VARCHAR2, p_parm_name IN VARCHAR2 DEFAULT NULL, p_parm_value IN VARCHAR2 DEFAULT NULL ) RETURN JSON_OBJECT_T;
    FUNCTION make_get_request_clob ( p_url IN VARCHAR2 ) RETURN CLOB;
    FUNCTION make_get_request_blob ( p_url IN VARCHAR2 ) RETURN BLOB;
    FUNCTION make_post_request ( p_url IN VARCHAR2, p_body IN CLOB DEFAULT EMPTY_CLOB() ) RETURN JSON_OBJECT_T;
    FUNCTION make_put_request ( p_url IN VARCHAR2, p_body IN CLOB DEFAULT EMPTY_CLOB(), p_body_blob IN BLOB DEFAULT EMPTY_BLOB() ) RETURN JSON_OBJECT_T;
    PROCEDURE make_patch_request ( p_url IN VARCHAR2, p_body IN CLOB );
    PROCEDURE make_delete_request ( p_url IN VARCHAR2 );

END msgraph_utils;
/

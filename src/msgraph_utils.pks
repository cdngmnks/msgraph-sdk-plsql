CREATE OR REPLACE PACKAGE msgraph_utils AS

    -- endpoint urls
    gc_token_url CONSTANT VARCHAR2 (88) := 'https://login.microsoftonline.com/' || msgraph_config.gc_tenant_id || '/oauth2/v2.0/token';

    -- global variables
    gv_access_token CLOB;
    gv_access_token_expiration DATE;

    -- function definitions
    PROCEDURE set_authorization_header;
    PROCEDURE set_content_type_header;
    PROCEDURE check_response_error ( p_response IN CLOB );
    FUNCTION get_access_token RETURN CLOB;
    FUNCTION json_array_to_csv ( p_array IN JSON_ARRAY_T, p_delimiter IN VARCHAR2 DEFAULT ';' ) RETURN VARCHAR2;
    FUNCTION csv_to_json_array ( p_csv IN VARCHAR2, p_delimiter IN VARCHAR2 DEFAULT ';' ) RETURN JSON_ARRAY_T;

END msgraph_utils;
/

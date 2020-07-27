CREATE OR REPLACE PACKAGE msgraph_sdk AS

    -- global constants
    gc_wallet_path CONSTANT VARCHAR2 (255) := '';
    gc_wallet_pwd CONSTANT VARCHAR2 (255) := '';

    gc_tenant_id CONSTANT VARCHAR2 (37) := '24e98fb7-3488-4171-9a69-69883213da64';
    gc_client_id CONSTANT VARCHAR2 (37) := '0b243a9c-efa4-4084-9736-945ee833ad9d';
    gc_client_secret CONSTANT VARCHAR2 (37) := 'kf_K2~eXDRamE2fjMw4-65L8~xwMT..58a';

    gc_token_url CONSTANT VARCHAR2 (88) := 'https://login.microsoftonline.com/' || gc_tenant_id || '/oauth2/v2.0/token';
    gc_user_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}';
    gc_users_url CONSTANT VARCHAR2 (38) := 'https://graph.microsoft.com/v1.0/users';

    -- global variables
    gv_access_token CLOB;
    gv_access_token_expiration DATE;

    -- type definitions
    TYPE user_rt IS RECORD (
        business_phones VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        given_name VARCHAR2 (2000),
        job_title VARCHAR2 (2000),
        mail VARCHAR2 (2000),
        mobile_phone VARCHAR2 (2000),
        office_location VARCHAR2 (2000),
        preferred_language VARCHAR2 (2000),
        surname VARCHAR2 (2000),
        user_principal_name VARCHAR2 (2000),
        id VARCHAR2 (2000)
    );
    
    TYPE users_tt IS TABLE OF user_rt;

    -- function definitions
    FUNCTION get_access_token RETURN CLOB;

    FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt;
    
    FUNCTION list_users RETURN users_tt;
    
    FUNCTION pipe_list_users RETURN users_tt PIPELINED;

END msgraph_sdk;
/

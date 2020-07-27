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
    gc_user_contacts_url CONSTANT VARCHAR2 (67) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/contacts';

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
    
    TYPE contact_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE,
        categories VARCHAR2 (2000),
        parent_folder_id VARCHAR2 (2000),
        birthday DATE,
        file_as VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        given_name VARCHAR2 (2000),
        nick_name VARCHAR2 (2000),
        surname VARCHAR2 (2000),
        title VARCHAR2 (2000),
        im_addresses VARCHAR2 (2000),
        job_title VARCHAR2 (2000),
        company_name VARCHAR2 (2000),
        department VARCHAR2 (2000),
        office_location VARCHAR2 (2000),
        business_home_page VARCHAR2 (2000),
        mobile_phone VARCHAR2 (2000),
        home_phones VARCHAR2 (2000),
        business_phones VARCHAR2 (2000),
        personal_notes VARCHAR2 (2000),
        email_address VARCHAR2 (2000),
        home_address_street VARCHAR2 (2000),
        home_address_city VARCHAR2 (2000),
        home_address_state VARCHAR2 (2000),
        home_address_country_or_region VARCHAR2 (2000),
        home_address_postal_code VARCHAR2 (2000),
        business_address_street VARCHAR2 (2000),
        business_address_city VARCHAR2 (2000),
        business_address_state VARCHAR2 (2000),
        business_address_country_or_region VARCHAR2 (2000),
        business_address_postal_code VARCHAR2 (2000)
    );
    
    TYPE contacts_tt IS TABLE OF contact_rt;

    -- function definitions
    FUNCTION get_access_token RETURN CLOB;

    -- users
    FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt; 
    FUNCTION list_users RETURN users_tt;
    FUNCTION pipe_list_users RETURN users_tt PIPELINED;
    
    -- contacts
    FUNCTION get_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) RETURN contact_rt;
    FUNCTION create_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt ) RETURN VARCHAR2;
    PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 );
    FUNCTION list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt;
    FUNCTION pipe_list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt PIPELINED;

END msgraph_sdk;
/

CREATE OR REPLACE PACKAGE msgraph_contacts AS

    -- endpoint urls
    gc_user_contacts_url CONSTANT VARCHAR2 (67) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/contacts';
    gc_user_contact_folders_url CONSTANT VARCHAR2 (73) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/contactFolders';

    -- type definitions
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

    TYPE contact_folder_rt IS RECORD (
        id VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        parent_folder_id VARCHAR2 (2000)
    );

    TYPE contact_folders_tt IS TABLE OF contact_folder_rt;

    -- contacts
    FUNCTION get_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) RETURN contact_rt;
    FUNCTION create_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt, p_contact_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN VARCHAR2;
    PROCEDURE update_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt );
    PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 );
    FUNCTION list_user_contacts ( p_user_principal_name IN VARCHAR2, p_contact_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN contacts_tt;
    FUNCTION pipe_list_user_contacts ( p_user_principal_name IN VARCHAR2, p_contact_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN contacts_tt PIPELINED;

    -- contact folders
    FUNCTION create_user_contact_folder ( p_user_principal_name IN VARCHAR2, p_contact_folder IN contact_folder_rt, p_parent_folder_id IN VARCHAR2 ) RETURN VARCHAR2;
    PROCEDURE delete_user_contact_folder ( p_user_principal_name IN VARCHAR2, p_contact_folder_id IN VARCHAR2 );
    FUNCTION list_user_contact_folders ( p_user_principal_name IN VARCHAR2, p_parent_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN contact_folders_tt;
    FUNCTION pipe_list_user_contact_folders ( p_user_principal_name IN VARCHAR2, p_parent_folder_id IN VARCHAR2 DEFAULT NULL ) RETURN contact_folders_tt PIPELINED;

END msgraph_contacts;
/

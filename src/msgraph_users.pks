CREATE OR REPLACE PACKAGE msgraph_users AS

    -- endpoint urls
    gc_user_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}';
    gc_users_url CONSTANT VARCHAR2 (38) := 'https://graph.microsoft.com/v1.0/users';
    gc_user_direct_reports_url CONSTANT VARCHAR2 (72) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/directReports';
    gc_user_manager_url CONSTANT VARCHAR2 (66) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/manager';

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

    -- users
    FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt; 
    FUNCTION list_users RETURN users_tt;
    FUNCTION pipe_list_users RETURN users_tt PIPELINED;
    FUNCTION list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt;
    FUNCTION pipe_list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt PIPELINED;
    FUNCTION get_user_manager ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt; 
 
END msgraph_users;
/

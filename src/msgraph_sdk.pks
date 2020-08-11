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
    gc_user_calendar_events_url CONSTANT VARCHAR2 (74) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/calendar/events';
    gc_user_direct_reports_url CONSTANT VARCHAR2 (72) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/directReports';
    gc_user_manager_url CONSTANT VARCHAR2 (66) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/manager';
    gc_groups_url CONSTANT VARCHAR2 (39) := 'https://graph.microsoft.com/v1.0/groups';
    gc_group_members_url CONSTANT VARCHAR2 (52) := 'https://graph.microsoft.com/v1.0/groups/{id}/members';

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

    TYPE event_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE,
        categories VARCHAR2 (2000),
        original_start_time_zone VARCHAR2 (2000),
        original_end_time_zone VARCHAR2 (2000),
        reminder_minutes_before_start INTEGER,
        is_reminder_on VARCHAR2(5),
        has_attachments VARCHAR2(5),
        subject VARCHAR2 (2000),
        body_preview VARCHAR2 (2000),
        importance VARCHAR2 (2000),
        sensitivity VARCHAR2 (2000),
        is_all_day VARCHAR2(5),
        is_cancelled VARCHAR2(5),
        is_organizer VARCHAR2(5),
        response_requested VARCHAR2(5),
        series_master_id VARCHAR2 (2000),
        show_as VARCHAR2 (2000),
        type VARCHAR2 (2000),
        web_link VARCHAR2 (2000),
        online_meeting_url VARCHAR2 (2000),
        is_online_meeting VARCHAR2(5),
        online_meeting_provider VARCHAR2 (2000),
        allow_new_time_proposals VARCHAR2(5),
        recurrence VARCHAR2 (2000),
        response_status_response VARCHAR2 (2000),
        response_status_time DATE,
        body_content_type VARCHAR2 (2000),
        body_content CLOB,
        start_date_time DATE,
        start_time_zone VARCHAR2 (2000),
        end_date_time DATE,
        end_time_zone VARCHAR2 (2000),
        location_display_name VARCHAR2 (2000),
        location_location_type VARCHAR2 (2000),
        location_unique_id VARCHAR2 (2000),
        location_unique_id_type VARCHAR2 (2000),
        organizer_email_address_name VARCHAR2 (2000),
        organizer_email_address_address VARCHAR2 (2000),
        online_meeting_join_url VARCHAR2 (2000)
    );
    
    TYPE events_tt IS TABLE OF event_rt;
    
    TYPE attendee_rt IS RECORD (
        type VARCHAR2 (2000),
        status_response VARCHAR2 (2000),
        status_time DATE,
        email_address_name VARCHAR2 (2000),
        email_address_address VARCHAR2 (2000)
    );
    
    TYPE attendees_tt IS TABLE OF attendee_rt;
    
    TYPE group_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        description VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        mail VARCHAR2 (2000),
        visibility VARCHAR2 (2000)
    );
    
    TYPE groups_tt IS TABLE OF group_rt;
    
    -- function definitions
    FUNCTION get_access_token RETURN CLOB;
    FUNCTION get_access_token ( p_username IN VARCHAR2, p_password IN VARCHAR2, p_scope IN VARCHAR2 ) RETURN CLOB;

    -- users
    FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt; 
    FUNCTION list_users RETURN users_tt;
    FUNCTION pipe_list_users RETURN users_tt PIPELINED;
    
    -- contacts
    FUNCTION get_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) RETURN contact_rt;
    FUNCTION create_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt ) RETURN VARCHAR2;
    PROCEDURE update_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt );
    PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 );
    FUNCTION list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt;
    FUNCTION pipe_list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt PIPELINED;
    
    -- calendar events
    FUNCTION get_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN event_rt;
    FUNCTION create_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) RETURN VARCHAR2;
    PROCEDURE update_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt );
    PROCEDURE delete_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 );
    FUNCTION list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt;
    FUNCTION pipe_list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt PIPELINED;
    FUNCTION list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt;
    FUNCTION pipe_list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt PIPELINED;

    -- direct reports
    FUNCTION list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt;
    FUNCTION pipe_list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt PIPELINED;
    
    -- manager
    FUNCTION get_user_manager ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt; 
    
    -- groups
    FUNCTION list_groups RETURN groups_tt;
    FUNCTION pipe_list_groups RETURN groups_tt PIPELINED;
    FUNCTION list_group_members ( p_group_id IN VARCHAR2 ) RETURN users_tt;
    FUNCTION pipe_list_group_members ( p_group_id IN VARCHAR2 ) RETURN users_tt PIPELINED;
    
END msgraph_sdk;
/

CREATE OR REPLACE PACKAGE BODY msgraph_sdk AS

PROCEDURE check_response_error ( p_response IN CLOB ) IS

    v_values apex_json.t_values;

BEGIN

    apex_json.parse ( p_values => v_values, p_source => p_response );

    IF apex_json.does_exist ( p_path => gc_error_json_path ) THEN
       
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => gc_error_json_path ) );
        
    END IF;

END check_response_error;

FUNCTION get_access_token RETURN CLOB IS

    v_response CLOB;
    v_expires_in INTEGER;

BEGIN

    -- request new token
    IF gv_access_token IS NULL OR gv_access_token_expiration < sysdate THEN

        -- set request headers
        apex_web_service.g_request_headers.delete();
        apex_web_service.g_request_headers(1).name := 'Content-Type';
        apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';

        -- make token request
        v_response := apex_web_service.make_rest_request ( p_url => gc_token_url,
                                                           p_http_method => 'POST',
                                                           p_body => 'client_id=' || gc_client_id || 
                                                                     '&client_secret=' || gc_client_secret || 
                                                                     '&scope=https://graph.microsoft.com/.default' ||
                                                                     '&grant_type=client_credentials',
                                                           p_wallet_path => gc_wallet_path,
                                                           p_wallet_pwd => gc_wallet_pwd );

        -- parse response
        apex_json.parse ( p_source => v_response );

        -- check if error occurred
        check_response_error ( p_response => v_response );

        -- set global variables
        gv_access_token := apex_json.get_varchar2 ( p_path => 'access_token' );
        
        v_expires_in := apex_json.get_number ( p_path => 'expires_in' );
        gv_access_token_expiration := sysdate + (1/24/60/60) * v_expires_in;
        
    END IF;

    RETURN gv_access_token;

END get_access_token;

FUNCTION get_access_token ( p_username IN VARCHAR2, p_password IN VARCHAR2, p_scope IN VARCHAR2 ) RETURN CLOB IS

    v_response CLOB;
    v_expires_in INTEGER;

BEGIN

    -- set request headers
    apex_web_service.g_request_headers.delete();
    apex_web_service.g_request_headers(1).name := 'Content-Type';
    apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded';

    -- make token request
    v_response := apex_web_service.make_rest_request ( p_url => gc_token_url,
                                                       p_http_method => 'POST',
                                                       p_body => 'client_id=' || gc_client_id || 
                                                                 '&client_secret=' || gc_client_secret ||
                                                                 '&username=' || p_username || 
                                                                 '&password=' || p_password || 
                                                                 '&scope=' || p_scope ||
                                                                 '&grant_type=password',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- set global variables
    gv_access_token := apex_json.get_varchar2 ( p_path => 'access_token' );
    
    v_expires_in := apex_json.get_number ( p_path => 'expires_in' );
    gv_access_token_expiration := sysdate + (1/24/60/60) * v_expires_in;

    RETURN gv_access_token;

END get_access_token;

PROCEDURE set_authorization_header IS

    v_token CLOB := get_access_token;
    
BEGIN 
    
    apex_web_service.g_request_headers.delete();
    apex_web_service.g_request_headers(1).name := 'Authorization';
    apex_web_service.g_request_headers(1).value := 'Bearer ' || v_token;

END set_authorization_header;

PROCEDURE set_content_type_header IS
BEGIN 

    apex_web_service.g_request_headers(2).name := 'Content-Type';
    apex_web_service.g_request_headers(2).value := 'application/json';

END set_content_type_header;

FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_user user_rt;

BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_user_url, gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- populate user record
    v_user.business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'businessPhones' ), ';' );
    v_user.display_name := apex_json.get_varchar2 ( p_path => 'displayName' );
    v_user.given_name := apex_json.get_varchar2 ( p_path => 'givenName' );
    v_user.job_title := apex_json.get_varchar2 ( p_path => 'jobTitle' );
    v_user.mail := apex_json.get_varchar2 ( p_path => 'mail' );
    v_user.mobile_phone := apex_json.get_varchar2 ( p_path => 'mobilePhone' );
    v_user.office_location := apex_json.get_varchar2 ( p_path => 'officeLocation' );
    v_user.preferred_language := apex_json.get_varchar2 ( p_path => 'preferredLanguage' );
    v_user.surname := apex_json.get_varchar2 ( p_path => 'surname' );
    v_user.user_principal_name := apex_json.get_varchar2 ( p_path => 'userPrincipalName' );
    v_user.id := apex_json.get_varchar2 ( p_path => 'id' );

    RETURN v_user;

END get_user;

FUNCTION list_users RETURN users_tt IS

    v_response CLOB;
    
    v_users users_tt := users_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => gc_users_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_users.extend;

        v_users (nI).business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].businessPhones', p0 => nI ) , ';' );
        v_users (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI );
        v_users (nI).given_name := apex_json.get_varchar2 ( p_path => 'value[%d].givenName', p0 => nI );
        v_users (nI).job_title := apex_json.get_varchar2 ( p_path => 'value[%d].jobTitle', p0 => nI );
        v_users (nI).mail := apex_json.get_varchar2 ( p_path => 'value[%d].mail', p0 => nI );
        v_users (nI).mobile_phone := apex_json.get_varchar2 ( p_path => 'value[%d].mobilePhone', p0 => nI );
        v_users (nI).office_location := apex_json.get_varchar2 ( p_path => 'value[%d].officeLocation', p0 => nI );
        v_users (nI).preferred_language := apex_json.get_varchar2 ( p_path => 'value[%d].preferredLanguage', p0 => nI );
        v_users (nI).surname := apex_json.get_varchar2 ( p_path => 'value[%d].surname', p0 => nI );
        v_users (nI).user_principal_name := apex_json.get_varchar2 ( p_path => 'value[%d].userPrincipalName', p0 => nI );
        v_users (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );

    END LOOP;
    
    RETURN v_users;

END list_users;

FUNCTION pipe_list_users RETURN users_tt PIPELINED IS

    v_users users_tt;

BEGIN

    v_users := list_users;

    FOR nI IN v_users.FIRST .. v_users.LAST LOOP
        PIPE ROW ( v_users (nI) );
    END LOOP;

END;

FUNCTION get_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) RETURN contact_rt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_contact contact_rt;

BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_contact_id;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- populate contact record
    v_contact.id := apex_json.get_varchar2 ( p_path => 'id' );
    v_contact.created_date_time := apex_json.get_date ( p_path => 'createdDateTime' );
    v_contact.last_modified_date_time := apex_json.get_date ( p_path => 'lastModifiedDateTime' );
    v_contact.categories := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'categories' ), ';' );
    v_contact.parent_folder_id := apex_json.get_varchar2 ( p_path => 'parentFolderId' );
    v_contact.birthday := apex_json.get_date ( p_path => 'birthday' );
    v_contact.file_as := apex_json.get_varchar2 ( p_path => 'fileAs' );
    v_contact.display_name := apex_json.get_varchar2 ( p_path => 'displayName' );
    v_contact.given_name := apex_json.get_varchar2 ( p_path => 'givenName' );
    v_contact.nick_name := apex_json.get_varchar2 ( p_path => 'nickName' );
    v_contact.surname := apex_json.get_varchar2 ( p_path => 'surname' );
    v_contact.title := apex_json.get_varchar2 ( p_path => 'title' );
    v_contact.im_addresses := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'imAddresses' ), ';' );
    v_contact.job_title := apex_json.get_varchar2 ( p_path => 'jobTitle' );
    v_contact.company_name := apex_json.get_varchar2 ( p_path => 'companyName' );
    v_contact.department := apex_json.get_varchar2 ( p_path => 'department' );
    v_contact.office_location := apex_json.get_varchar2 ( p_path => 'officeLocation' );
    v_contact.business_home_page := apex_json.get_varchar2 ( p_path => 'businessHomePage' );
    v_contact.home_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'homePhones' ), ';' );
    v_contact.mobile_phone := apex_json.get_varchar2 ( p_path => 'mobilePhone' );
    v_contact.business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'businessPhones' ), ';' );
    v_contact.personal_notes := apex_json.get_varchar2 ( p_path => 'personalNotes' );
    v_contact.email_address := apex_json.get_varchar2 ( p_path => 'emailAddresses[1].address' );
    v_contact.home_address_street := apex_json.get_varchar2 ( p_path => 'homeAddress.street' );
    v_contact.home_address_city := apex_json.get_varchar2 ( p_path => 'homeAddress.city' );
    v_contact.home_address_state := apex_json.get_varchar2 ( p_path => 'homeAddress.state' );
    v_contact.home_address_country_or_region := apex_json.get_varchar2 ( p_path => 'homeAddress.countryOrRegion' );
    v_contact.home_address_postal_code := apex_json.get_varchar2 ( p_path => 'homeAddress.postal_code' );
    v_contact.business_address_street := apex_json.get_varchar2 ( p_path => 'businessAddress.street' );
    v_contact.business_address_city := apex_json.get_varchar2 ( p_path => 'businessAddress.city' );
    v_contact.business_address_state := apex_json.get_varchar2 ( p_path => 'businessAddress.state' );
    v_contact.business_address_country_or_region := apex_json.get_varchar2 ( p_path => 'businessAddress.countryOrRegion' );
    v_contact.business_address_postal_code := apex_json.get_varchar2 ( p_path => 'businessAddress.postal_code' );
    
    RETURN v_contact;
 
END get_user_contact;

FUNCTION create_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_id VARCHAR2 (2000);
    
BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'givenName', p_contact.given_name );
    apex_json.write ( 'surname', p_contact.surname );
    apex_json.write ( 'nickName', p_contact.nick_name );
    apex_json.write ( 'title', p_contact.title );
    apex_json.write ( 'jobTitle', p_contact.job_title );
    apex_json.write ( 'companyName', p_contact.company_name );
    apex_json.write ( 'department', p_contact.department );
    apex_json.write ( 'officeLocation', p_contact.office_location );
    apex_json.write ( 'jobTitle', p_contact.job_title );
    apex_json.write ( 'businessHomePage', p_contact.business_home_page );
    apex_json.write ( 'personalNotes', p_contact.personal_notes );
    apex_json.write ( 'mobilePhone', p_contact.mobile_phone );
    apex_json.open_array ( 'homePhones' );
    apex_json.write ( p_contact.home_phones );
    apex_json.close_array;
    apex_json.open_array ( 'businessPhones' );
    apex_json.write ( p_contact.business_phones );
    apex_json.close_array;    
    apex_json.open_array ( 'emailAddresses' );
    apex_json.open_object;
    apex_json.write ( 'address', p_contact.email_address );
    apex_json.write ( 'name', p_contact.email_address );
    apex_json.close_object;
    apex_json.close_array;
    apex_json.open_object ( 'homeAddress' );
    apex_json.write ( 'street', p_contact.home_address_street );
    apex_json.write ( 'city', p_contact.home_address_city );
    apex_json.write ( 'state', p_contact.home_address_state );
    apex_json.write ( 'countryOrRegion', p_contact.home_address_country_or_region );
    apex_json.write ( 'postalCode', p_contact.home_address_postal_code );
    apex_json.close_object;
    apex_json.open_object ( 'businessAddress' );
    apex_json.write ( 'street', p_contact.business_address_street );
    apex_json.write ( 'city', p_contact.business_address_city );
    apex_json.write ( 'state', p_contact.business_address_state );
    apex_json.write ( 'countryOrRegion', p_contact.business_address_country_or_region );
    apex_json.write ( 'postalCode', p_contact.business_address_postal_code );
    apex_json.close_object;
    apex_json.close_object;   
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    apex_json.free_output;
    
    -- parse response
    apex_json.parse ( p_source => v_response );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );                                                                                             
    
    RETURN v_id;

END create_user_contact;

PROCEDURE update_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_contact.id;
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'givenName', p_contact.given_name );
    apex_json.write ( 'surname', p_contact.surname );
    apex_json.write ( 'nickName', p_contact.nick_name );
    apex_json.write ( 'title', p_contact.title );
    apex_json.write ( 'jobTitle', p_contact.job_title );
    apex_json.write ( 'companyName', p_contact.company_name );
    apex_json.write ( 'department', p_contact.department );
    apex_json.write ( 'officeLocation', p_contact.office_location );
    apex_json.write ( 'jobTitle', p_contact.job_title );
    apex_json.write ( 'businessHomePage', p_contact.business_home_page );
    apex_json.write ( 'personalNotes', p_contact.personal_notes );
    apex_json.write ( 'mobilePhone', p_contact.mobile_phone );
    apex_json.open_array ( 'homePhones' );
    apex_json.write ( p_contact.home_phones );
    apex_json.close_array;
    apex_json.open_array ( 'businessPhones' );
    apex_json.write ( p_contact.business_phones );
    apex_json.close_array;    
    apex_json.open_array ( 'emailAddresses' );
    apex_json.open_object;
    apex_json.write ( 'address', p_contact.email_address );
    apex_json.write ( 'name', p_contact.email_address );
    apex_json.close_object;
    apex_json.close_array;
    apex_json.open_object ( 'homeAddress' );
    apex_json.write ( 'street', p_contact.home_address_street );
    apex_json.write ( 'city', p_contact.home_address_city );
    apex_json.write ( 'state', p_contact.home_address_state );
    apex_json.write ( 'countryOrRegion', p_contact.home_address_country_or_region );
    apex_json.write ( 'postalCode', p_contact.home_address_postal_code );
    apex_json.close_object;
    apex_json.open_object ( 'businessAddress' );
    apex_json.write ( 'street', p_contact.business_address_street );
    apex_json.write ( 'city', p_contact.business_address_city );
    apex_json.write ( 'state', p_contact.business_address_state );
    apex_json.write ( 'countryOrRegion', p_contact.business_address_country_or_region );
    apex_json.write ( 'postalCode', p_contact.business_address_postal_code );
    apex_json.close_object;
    apex_json.close_object;   
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'PATCH',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    apex_json.free_output;
    
    -- parse response
    apex_json.parse ( p_source => v_response );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );   

END update_user_contact;

PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

BEGIN

    -- set headers
    set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_contact_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'DELETE',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );   

END delete_user_contact;

FUNCTION list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_contacts contacts_tt := contacts_tt ();
    
BEGIN 
    -- set headers
    set_authorization_header;
   
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
   
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   

        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_contacts.extend;

        v_contacts (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_contacts (nI).created_date_time := apex_json.get_date ( p_path => 'value[%d].createdDateTime', p0 => nI );
        v_contacts (nI).last_modified_date_time := apex_json.get_date ( p_path => 'value[%d].lastModifiedDateTime', p0 => nI );
        v_contacts (nI).categories := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].categories', p0 => nI ), ';' );
        v_contacts (nI).parent_folder_id := apex_json.get_varchar2 ( p_path => 'value[%d].parentFolderId', p0 => nI );
        v_contacts (nI).birthday := apex_json.get_date ( p_path => 'value[%d].birthday', p0 => nI );
        v_contacts (nI).file_as := apex_json.get_varchar2 ( p_path => 'value[%d].fileAs', p0 => nI );
        v_contacts (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI );
        v_contacts (nI).given_name := apex_json.get_varchar2 ( p_path => 'value[%d].givenName', p0 => nI );
        v_contacts (nI).nick_name := apex_json.get_varchar2 ( p_path => 'value[%d].nickName', p0 => nI );
        v_contacts (nI).surname := apex_json.get_varchar2 ( p_path => 'value[%d].surname', p0 => nI );
        v_contacts (nI).title := apex_json.get_varchar2 ( p_path => 'value[%d].title', p0 => nI );
        v_contacts (nI).im_addresses := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].imAddresses', p0 => nI ), ';' );
        v_contacts (nI).job_title := apex_json.get_varchar2 ( p_path => 'value[%d].jobTitle', p0 => nI );
        v_contacts (nI).company_name := apex_json.get_varchar2 ( p_path => 'value[%d].companyName', p0 => nI );
        v_contacts (nI).department := apex_json.get_varchar2 ( p_path => 'value[%d].department', p0 => nI );
        v_contacts (nI).office_location := apex_json.get_varchar2 ( p_path => 'value[%d].officeLocation', p0 => nI );
        v_contacts (nI).business_home_page := apex_json.get_varchar2 ( p_path => 'value[%d].businessHomePage', p0 => nI );
        v_contacts (nI).home_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].homePhones', p0 => nI ), ';' );
        v_contacts (nI).mobile_phone := apex_json.get_varchar2 ( p_path => 'value[%d].mobilePhone', p0 => nI );
        v_contacts (nI).business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].businessPhones', p0 => nI ), ';' );
        v_contacts (nI).personal_notes := apex_json.get_varchar2 ( p_path => 'value[%d].personalNotes', p0 => nI );
        v_contacts (nI).email_address := apex_json.get_varchar2 ( p_path => 'value[%d].emailAddresses[1].address', p0 => nI );
        v_contacts (nI).home_address_street := apex_json.get_varchar2 ( p_path => 'value[%d].homeAddress.street', p0 => nI );
        v_contacts (nI).home_address_city := apex_json.get_varchar2 ( p_path => 'value[%d].homeAddress.city', p0 => nI );
        v_contacts (nI).home_address_state := apex_json.get_varchar2 ( p_path => 'value[%d].homeAddress.state', p0 => nI );
        v_contacts (nI).home_address_country_or_region := apex_json.get_varchar2 ( p_path => 'value[%d].homeAddress.countryOrRegion', p0 => nI );
        v_contacts (nI).home_address_postal_code := apex_json.get_varchar2 ( p_path => 'value[%d].homeAddress.postalCode', p0 => nI );
        v_contacts (nI).business_address_street := apex_json.get_varchar2 ( p_path => 'value[%d].businessAddress.street', p0 => nI );
        v_contacts (nI).business_address_city := apex_json.get_varchar2 ( p_path => 'value[%d].businessAddress.city', p0 => nI );
        v_contacts (nI).business_address_state := apex_json.get_varchar2 ( p_path => 'value[%d].businessAddress.state', p0 => nI );
        v_contacts (nI).business_address_country_or_region := apex_json.get_varchar2 ( p_path => 'value[%d].businessAddress.countryOrRegion', p0 => nI );
        v_contacts (nI).business_address_postal_code := apex_json.get_varchar2 ( p_path => 'value[%d].businessAddress.postalCode', p0 => nI );

    END LOOP;
    
    RETURN v_contacts;

END list_user_contacts;

FUNCTION pipe_list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt PIPELINED IS

    v_contacts contacts_tt;

BEGIN

    v_contacts := list_user_contacts ( p_user_principal_name );

    FOR nI IN v_contacts.FIRST .. v_contacts.LAST LOOP
        PIPE ROW ( v_contacts (nI) );
    END LOOP;

END pipe_list_user_contacts;

FUNCTION get_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN event_rt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_event event_rt;

BEGIN

    -- set headers
    set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
    
   -- populate event record
    v_event.id := apex_json.get_varchar2 ( p_path => 'id' );
    v_event.created_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'createdDateTime' ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
    v_event.last_modified_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'lastModifiedDateTime' ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
    v_event.categories := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'categories' ), ';' );        
    v_event.original_start_time_zone := apex_json.get_varchar2 ( p_path => 'originalStartTimeZone' );
    v_event.original_end_time_zone := apex_json.get_varchar2 ( p_path => 'originalEndTimeZone' );
    v_event.reminder_minutes_before_start := apex_json.get_number ( p_path => 'reminderMinutesBeforeStart' );
    v_event.is_reminder_on := apex_json.get_varchar2 ( p_path => 'isReminderOn' );
    v_event.has_attachments := apex_json.get_varchar2 ( p_path => 'hasAttachments' );
    v_event.subject := apex_json.get_varchar2 ( p_path => 'subject' );
    v_event.body_preview := apex_json.get_varchar2 ( p_path => 'bodyPreview' );
    v_event.importance := apex_json.get_varchar2 ( p_path => 'importance' );
    v_event.sensitivity := apex_json.get_varchar2 ( p_path => 'sensitivity' );
    v_event.is_all_day := apex_json.get_varchar2 ( p_path => 'isAllDay' );
    v_event.is_cancelled := apex_json.get_varchar2 ( p_path => 'isCancelled' );
    v_event.is_organizer := apex_json.get_varchar2 ( p_path => 'isOrganizer' );
    v_event.response_requested := apex_json.get_varchar2 ( p_path => 'responseRequested' );
    v_event.series_master_id := apex_json.get_varchar2 ( p_path => 'seriesMasterId' );
    v_event.show_as := apex_json.get_varchar2 ( p_path => 'showAs' );
    v_event.type := apex_json.get_varchar2 ( p_path => 'type' );
    v_event.web_link := apex_json.get_varchar2 ( p_path => 'webLink' );
    v_event.online_meeting_url := apex_json.get_varchar2 ( p_path => 'onlineMeetingUrl' );
    v_event.is_online_meeting := apex_json.get_varchar2 ( p_path => 'isOnlineMeeting' );
    v_event.online_meeting_provider := apex_json.get_varchar2 ( p_path => 'onlineMeetingProvider' );
    v_event.allow_new_time_proposals := apex_json.get_varchar2 ( p_path => 'allowNewTimeProposals' );
    v_event.recurrence := apex_json.get_varchar2 ( p_path => 'recurrence' );
    v_event.response_status_response := apex_json.get_varchar2 ( p_path => 'responseStatus.response' );
    v_event.response_status_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'responseStatus.time' ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
    v_event.body_content_type := apex_json.get_varchar2 ( p_path => 'body.contentType' );
    v_event.body_content := apex_json.get_clob ( p_path => 'body.content');
    v_event.start_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'start.dateTime' ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
    v_event.start_time_zone := apex_json.get_varchar2 ( p_path => 'start.timeZone' );
    v_event.end_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'end.dateTime' ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
    v_event.end_time_zone := apex_json.get_varchar2 ( p_path => 'end.dateTimeZone' );
    v_event.location_display_name := apex_json.get_varchar2 ( p_path => 'location.displayName' );
    v_event.location_location_type := apex_json.get_varchar2 ( p_path => 'location.locationType' );
    v_event.location_unique_id := apex_json.get_varchar2 ( p_path => 'location.uniqueId' );
    v_event.location_unique_id_type := apex_json.get_varchar2 ( p_path => 'location.uniqueIdType' );
    v_event.organizer_email_address_name := apex_json.get_varchar2 ( p_path => 'organizer.emailAddress.name' );
    v_event.organizer_email_address_address := apex_json.get_varchar2 ( p_path => 'organizer.emailAddress.address' );
    v_event.online_meeting_join_url := apex_json.get_varchar2 ( p_path => 'onlineMeeting.joinUrl' );
    
    RETURN v_event;

END get_user_calendar_event;

FUNCTION create_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_id VARCHAR2 (2000);
    
BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'subject', p_event.subject );
    apex_json.open_object ( 'body' );
    apex_json.write ( 'contentType', p_event.body_content_type );
    apex_json.write ( 'content', p_event.body_content );
    apex_json.close_object;
    apex_json.open_object ( 'start' );
    apex_json.write ( 'dateTime', p_event.start_date_time );
    apex_json.write ( 'timeZone', p_event.start_time_zone );
    apex_json.close_object;
    apex_json.open_object ( 'end' );
    apex_json.write ( 'dateTime', p_event.end_date_time );
    apex_json.write ( 'timeZone', p_event.end_time_zone );    
    apex_json.close_object;
    apex_json.write ( 'reminderMinutesBeforeStart', p_event.reminder_minutes_before_start );
    apex_json.write ( 'isReminderOn', p_event.is_reminder_on );
    apex_json.write ( 'importance', p_event.importance );
    apex_json.write ( 'sensitivity', p_event.sensitivity ); 
    apex_json.write ( 'showAs', p_event.show_as );
    apex_json.open_object ( 'location' );
    apex_json.write ( 'displayName', p_event.location_display_name );
    apex_json.close_object;
    apex_json.open_array ( 'attendees' );
    
    -- add attendees    
    FOR nI IN p_attendees.FIRST .. p_attendees.LAST LOOP
        apex_json.open_object;
        apex_json.write ( 'type', p_attendees (nI).type );
        apex_json.open_object ( 'emailAddress' );
        apex_json.write ( 'name', p_attendees (nI).email_address_name );
        apex_json.write ( 'address', p_attendees (nI).email_address_address );
        apex_json.close_object;
        apex_json.close_object;
    END LOOP;
        
    apex_json.close_array;
    apex_json.close_object;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    apex_json.free_output;
    
    -- parse response
    apex_json.parse ( p_source => v_response );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;

END create_user_calendar_event;

PROCEDURE update_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event.id;
    
    -- generate request
    apex_json.initialize_clob_output;
    
    apex_json.open_object;
    apex_json.write ( 'subject', p_event.subject );
    apex_json.open_object ( 'body' );
    apex_json.write ( 'contentType', p_event.body_content_type );
    apex_json.write ( 'content', p_event.body_content );
    apex_json.close_object;
    apex_json.open_object ( 'start' );
    apex_json.write ( 'dateTime', p_event.start_date_time );
    apex_json.write ( 'timeZone', p_event.start_time_zone );
    apex_json.close_object;
    apex_json.open_object ( 'end' );
    apex_json.write ( 'dateTime', p_event.end_date_time );
    apex_json.write ( 'timeZone', p_event.end_time_zone );    
    apex_json.close_object;
    apex_json.write ( 'reminderMinutesBeforeStart', p_event.reminder_minutes_before_start );
    apex_json.write ( 'isReminderOn', p_event.is_reminder_on );
    apex_json.write ( 'importance', p_event.importance );
    apex_json.write ( 'sensitivity', p_event.sensitivity ); 
    apex_json.write ( 'showAs', p_event.show_as );
    apex_json.open_object ( 'location' );
    apex_json.write ( 'displayName', p_event.location_display_name );
    apex_json.close_object;
    apex_json.open_array ( 'attendees' );
    
    -- add attendees    
    FOR nI IN p_attendees.FIRST .. p_attendees.LAST LOOP
        apex_json.open_object;
        apex_json.write ( 'type', p_attendees (nI).type );
        apex_json.open_object ( 'emailAddress' );
        apex_json.write ( 'name', p_attendees (nI).email_address_name );
        apex_json.write ( 'address', p_attendees (nI).email_address_address );
        apex_json.close_object;
        apex_json.close_object;
    END LOOP;
        
    apex_json.close_array;
    apex_json.close_object;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'PATCH',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    apex_json.free_output;
    
    -- parse response
    apex_json.parse ( p_source => v_response );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );                                                                                              

END update_user_calendar_event;

PROCEDURE delete_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

BEGIN

    -- set headers
    set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'DELETE',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );   

END delete_user_calendar_event;

FUNCTION list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_events events_tt := events_tt ();

BEGIN

    -- set headers
    set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_events.extend;

        v_events (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_events (nI).created_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].createdDateTime', p0 => nI ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' ); 
        v_events (nI).last_modified_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].lastModifiedDateTime', p0 => nI ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' ); 
        v_events (nI).categories := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].categories', p0 => nI ), ';' );
        v_events (nI).original_start_time_zone := apex_json.get_varchar2 ( p_path => 'value[%d].originalStartTimeZone', p0 => nI );
        v_events (nI).original_end_time_zone := apex_json.get_varchar2 ( p_path => 'value[%d].originalEndTimeZone', p0 => nI );
        v_events (nI).reminder_minutes_before_start := apex_json.get_number ( p_path => 'value[%d].reminderMinutesBeforeStart', p0 => nI );
        v_events (nI).is_reminder_on := apex_json.get_varchar2 ( p_path => 'value[%d].isReminderOn', p0 => nI );
        v_events (nI).has_attachments := apex_json.get_varchar2 ( p_path => 'value[%d].hasAttachments', p0 => nI );
        v_events (nI).subject := apex_json.get_varchar2 ( p_path => 'value[%d].subject', p0 => nI );
        v_events (nI).body_preview := apex_json.get_varchar2 ( p_path => 'value[%d].bodyPreview', p0 => nI );
        v_events (nI).importance := apex_json.get_varchar2 ( p_path => 'value[%d].importance', p0 => nI );
        v_events (nI).sensitivity := apex_json.get_varchar2 ( p_path => 'value[%d].sensitivity', p0 => nI );
        v_events (nI).is_all_day := apex_json.get_varchar2 ( p_path => 'value[%d].isAllDay', p0 => nI );
        v_events (nI).is_cancelled := apex_json.get_varchar2 ( p_path => 'value[%d].isCancelled', p0 => nI );
        v_events (nI).is_organizer := apex_json.get_varchar2 ( p_path => 'value[%d].isOrganizer', p0 => nI );
        v_events (nI).response_requested := apex_json.get_varchar2 ( p_path => 'value[%d].responseRequested', p0 => nI );
        v_events (nI).series_master_id := apex_json.get_varchar2 ( p_path => 'value[%d].seriesMasterId', p0 => nI );
        v_events (nI).show_as := apex_json.get_varchar2 ( p_path => 'value[%d].showAs', p0 => nI );
        v_events (nI).type := apex_json.get_varchar2 ( p_path => 'value[%d].type', p0 => nI );
        v_events (nI).web_link := apex_json.get_varchar2 ( p_path => 'value[%d].webLink', p0 => nI );
        v_events (nI).online_meeting_url := apex_json.get_varchar2 ( p_path => 'value[%d].onlineMeetingUrl', p0 => nI );
        v_events (nI).is_online_meeting := apex_json.get_varchar2 ( p_path => 'value[%d].isOnlineMeeting', p0 => nI );
        v_events (nI).online_meeting_provider := apex_json.get_varchar2 ( p_path => 'value[%d].onlineMeetingProvider', p0 => nI );
        v_events (nI).allow_new_time_proposals := apex_json.get_varchar2 ( p_path => 'value[%d].allowNewTimeProposals', p0 => nI );
        v_events (nI).recurrence := apex_json.get_varchar2 ( p_path => 'value[%d].recurrence', p0 => nI );
        v_events (nI).response_status_response := apex_json.get_varchar2 ( p_path => 'value[%d].responseStatus.response', p0 => nI );
        v_events (nI).response_status_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].responseStatus.time', p0 => nI ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
        v_events (nI).body_content_type := apex_json.get_varchar2 ( p_path => 'value[%d].body.contentType', p0 => nI );
        v_events (nI).body_content := apex_json.get_clob ( p_path => 'value[%d].body.content', p0 => nI );
        v_events (nI).start_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].start.dateTime', p0 => nI ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' ); 
        v_events (nI).start_time_zone := apex_json.get_varchar2 ( p_path => 'value[%d].start.timeZone', p0 => nI );
        v_events (nI).end_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].end.dateTime', p0 => nI ), 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' ); 
        v_events (nI).end_time_zone := apex_json.get_varchar2 ( p_path => 'value[%d].end.dateTimeZone', p0 => nI );
        v_events (nI).location_display_name := apex_json.get_varchar2 ( p_path => 'value[%d].location.displayName', p0 => nI );
        v_events (nI).location_location_type := apex_json.get_varchar2 ( p_path => 'value[%d].location.locationType', p0 => nI );
        v_events (nI).location_unique_id := apex_json.get_varchar2 ( p_path => 'value[%d].location.uniqueId', p0 => nI );
        v_events (nI).location_unique_id_type := apex_json.get_varchar2 ( p_path => 'value[%d].location.uniqueIdType', p0 => nI );
        v_events (nI).organizer_email_address_name := apex_json.get_varchar2 ( p_path => 'value[%d].organizer.emailAddress.name', p0 => nI );
        v_events (nI).organizer_email_address_address := apex_json.get_varchar2 ( p_path => 'value[%d].organizer.emailAddress.address', p0 => nI );
        v_events (nI).online_meeting_join_url := apex_json.get_varchar2 ( p_path => 'value[%d].onlineMeeting.joinUrl', p0 => nI );

    END LOOP;
    
    RETURN v_events;
 
END list_user_calendar_events;

FUNCTION pipe_list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt PIPELINED IS

    v_events events_tt;

BEGIN

    v_events := list_user_calendar_events ( p_user_principal_name );

    FOR nI IN v_events.FIRST .. v_events.LAST LOOP
        PIPE ROW ( v_events (nI) );
    END LOOP;

END pipe_list_user_calendar_events;

FUNCTION list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_attendees attendees_tt := attendees_tt ();

BEGIN

    -- set headers
    set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => 'attendees' ) LOOP
    
        v_attendees.extend;

        v_attendees (nI).type := apex_json.get_varchar2 ( p_path => 'attendees[%d].type', p0 => nI );
        v_attendees (nI).status_response := apex_json.get_varchar2 ( p_path => 'attendees[%d].status.response', p0 => nI );
        v_attendees (nI).status_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'attendees[%d].status.time', p0 => nI ) , 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' ); 
        v_attendees (nI).email_address_name := apex_json.get_varchar2 ( p_path => 'attendees[%d].emailAddress.name', p0 => nI );
        v_attendees (nI).email_address_address := apex_json.get_varchar2 ( p_path => 'attendees[%d].emailAddress.address', p0 => nI );

    END LOOP;
    
    RETURN v_attendees;

END list_user_calendar_event_attendees;

FUNCTION pipe_list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt PIPELINED IS

    v_attendees attendees_tt;

BEGIN

    v_attendees := list_user_calendar_event_attendees ( p_user_principal_name, p_event_id );
    
    FOR nI IN v_attendees.FIRST .. v_attendees.LAST LOOP
        PIPE ROW ( v_attendees (nI) );
    END LOOP;    

END pipe_list_user_calendar_event_attendees;

FUNCTION list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_users users_tt := users_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_user_direct_reports_url, gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_users.extend;

        v_users (nI).business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].businessPhones', p0 => nI ) , ';' );
        v_users (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI );
        v_users (nI).given_name := apex_json.get_varchar2 ( p_path => 'value[%d].givenName', p0 => nI );
        v_users (nI).job_title := apex_json.get_varchar2 ( p_path => 'value[%d].jobTitle', p0 => nI );
        v_users (nI).mail := apex_json.get_varchar2 ( p_path => 'value[%d].mail', p0 => nI );
        v_users (nI).mobile_phone := apex_json.get_varchar2 ( p_path => 'value[%d].mobilePhone', p0 => nI );
        v_users (nI).office_location := apex_json.get_varchar2 ( p_path => 'value[%d].officeLocation', p0 => nI );
        v_users (nI).preferred_language := apex_json.get_varchar2 ( p_path => 'value[%d].preferredLanguage', p0 => nI );
        v_users (nI).surname := apex_json.get_varchar2 ( p_path => 'value[%d].surname', p0 => nI );
        v_users (nI).user_principal_name := apex_json.get_varchar2 ( p_path => 'value[%d].userPrincipalName', p0 => nI );
        v_users (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );

    END LOOP;
    
    RETURN v_users;

END list_user_direct_reports;

FUNCTION pipe_list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt PIPELINED IS

    v_users users_tt;

BEGIN

    v_users := list_user_direct_reports ( p_user_principal_name );

    FOR nI IN v_users.FIRST .. v_users.LAST LOOP
        PIPE ROW ( v_users (nI) );
    END LOOP;

END pipe_list_user_direct_reports;

FUNCTION get_user_manager ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_user user_rt;

BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_user_manager_url, gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
    
    -- populate user record
    v_user.business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'businessPhones' ), ';' );
    v_user.display_name := apex_json.get_varchar2 ( p_path => 'displayName' );
    v_user.given_name := apex_json.get_varchar2 ( p_path => 'givenName' );
    v_user.job_title := apex_json.get_varchar2 ( p_path => 'jobTitle' );
    v_user.mail := apex_json.get_varchar2 ( p_path => 'mail' );
    v_user.mobile_phone := apex_json.get_varchar2 ( p_path => 'mobilePhone' );
    v_user.office_location := apex_json.get_varchar2 ( p_path => 'officeLocation' );
    v_user.preferred_language := apex_json.get_varchar2 ( p_path => 'preferredLanguage' );
    v_user.surname := apex_json.get_varchar2 ( p_path => 'surname' );
    v_user.user_principal_name := apex_json.get_varchar2 ( p_path => 'userPrincipalName' );
    v_user.id := apex_json.get_varchar2 ( p_path => 'id' );

    RETURN v_user;
    
END get_user_manager;

FUNCTION list_groups RETURN groups_tt IS

    v_response CLOB;
    
    v_groups groups_tt := groups_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => gc_groups_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_groups.extend;

        v_groups (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_groups (nI).created_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].createdDateTime', p0 => nI ) , 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
        v_groups (nI).description := apex_json.get_varchar2 ( p_path => 'value[%d].description', p0 => nI );
        v_groups (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI );
        v_groups (nI).mail := apex_json.get_varchar2 ( p_path => 'value[%d].mail', p0 => nI );
        v_groups (nI).visibility := apex_json.get_varchar2 ( p_path => 'value[%d].visibility', p0 => nI );
        v_groups (nI).resource_provisioning_options := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].resourceProvisioningOptions', p0 => nI ), ';' );

    END LOOP;

    RETURN v_groups;

END list_groups;

FUNCTION pipe_list_groups RETURN groups_tt PIPELINED IS

    v_groups groups_tt;

BEGIN

    v_groups := list_groups;

    FOR nI IN v_groups.FIRST .. v_groups.LAST LOOP
        PIPE ROW ( v_groups (nI) );
    END LOOP;

END pipe_list_groups;

FUNCTION list_group_members ( p_group_id IN VARCHAR2 ) RETURN users_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_users users_tt := users_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_group_members_url, '{id}', p_group_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_users.extend;

        v_users (nI).business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].businessPhones', p0 => nI ) , ';' );
        v_users (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI );
        v_users (nI).given_name := apex_json.get_varchar2 ( p_path => 'value[%d].givenName', p0 => nI );
        v_users (nI).job_title := apex_json.get_varchar2 ( p_path => 'value[%d].jobTitle', p0 => nI );
        v_users (nI).mail := apex_json.get_varchar2 ( p_path => 'value[%d].mail', p0 => nI );
        v_users (nI).mobile_phone := apex_json.get_varchar2 ( p_path => 'value[%d].mobilePhone', p0 => nI );
        v_users (nI).office_location := apex_json.get_varchar2 ( p_path => 'value[%d].officeLocation', p0 => nI );
        v_users (nI).preferred_language := apex_json.get_varchar2 ( p_path => 'value[%d].preferredLanguage', p0 => nI );
        v_users (nI).surname := apex_json.get_varchar2 ( p_path => 'value[%d].surname', p0 => nI );
        v_users (nI).user_principal_name := apex_json.get_varchar2 ( p_path => 'value[%d].userPrincipalName', p0 => nI );
        v_users (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );

    END LOOP;
    
    RETURN v_users;

END list_group_members;

FUNCTION pipe_list_group_members ( p_group_id IN VARCHAR2 ) RETURN users_tt PIPELINED IS

    v_users users_tt;

BEGIN

    v_users := list_group_members ( p_group_id );

    FOR nI IN v_users.FIRST .. v_users.LAST LOOP
        PIPE ROW ( v_users (nI) );
    END LOOP;

END pipe_list_group_members;

PROCEDURE add_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_user user_rt;

BEGIN
    -- get user
    v_user := get_user ( p_user_principal_name );

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE ( gc_group_members_url, '{id}', p_group_id ) || '/$ref';
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( '@odata.id', 'https://graph.microsoft.com/v1.0/directoryObjects/'|| v_user.id );
    apex_json.close_object;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );   

END add_group_member;

PROCEDURE remove_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_user user_rt;

BEGIN
    
    -- get user
    v_user := get_user ( p_user_principal_name );

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_group_members_url, '{id}', p_group_id ) || '/' || v_user.id || '/$ref';
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'DELETE',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );
    
END remove_group_member;

FUNCTION list_team_groups RETURN groups_tt IS

    v_groups groups_tt;
    v_teams groups_tt := groups_tt ();

BEGIN

    v_groups := list_groups;

    FOR nI IN v_groups.FIRST .. v_groups.LAST LOOP

        IF instr( v_groups (nI).resource_provisioning_options, 'Team') > 0 THEN
        
            v_teams.extend;
            v_teams (v_teams.LAST) := v_groups (nI);
        
        END IF;
        
    END LOOP; 

    return v_teams;

END list_team_groups;


FUNCTION pipe_list_team_groups RETURN groups_tt PIPELINED IS

    v_teams groups_tt;

BEGIN

    v_teams := list_team_groups;

    FOR nI IN v_teams.FIRST .. v_teams.LAST LOOP
        PIPE ROW ( v_teams (nI) );
    END LOOP;

END pipe_list_team_groups;

FUNCTION list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_channels channels_tt := channels_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_team_channels_url, '{id}', p_team_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_channels.extend;

        v_channels (nI).description := apex_json.get_varchar2 ( p_path => 'value[%d].description', p0 => nI );
        v_channels (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI );
        v_channels (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );

    END LOOP;
    
    RETURN v_channels;

END list_team_channels;

FUNCTION pipe_list_team_channels ( p_team_id IN VARCHAR2 ) RETURN channels_tt PIPELINED IS
    
    v_channels channels_tt;

BEGIN

    v_channels := list_team_channels ( p_team_id );
    
    FOR nI IN v_channels.FIRST .. v_channels.LAST LOOP
        PIPE ROW ( v_channels (nI) );
    END LOOP;    

END pipe_list_team_channels;

FUNCTION create_team_channel ( p_team_id IN VARCHAR2, p_display_name IN VARCHAR2, p_description IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_id VARCHAR2 (2000);

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id );
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'displayName', p_display_name );
    apex_json.write ( 'description', p_description );
    apex_json.close_object;
    
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
                                                       
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
        
    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;

END create_team_channel;

PROCEDURE delete_team_channel ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

BEGIN
    
    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'DELETE',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );
    
END delete_team_channel;

PROCEDURE send_team_channel_message ( p_team_id IN VARCHAR2, p_channel_id IN VARCHAR2, p_message_content IN CLOB, p_attachments IN attachments_tt DEFAULT NULL ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE ( gc_team_channels_url, '{id}', p_team_id ) || '/' || p_channel_id || '/messages';
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.open_object ( 'body' );
    apex_json.write ( 'contentType', 'html' );
    apex_json.write ( 'content', p_message_content );
    apex_json.close_object;
    
    -- add attachments
    IF p_attachments IS NOT NULL THEN
        apex_json.open_array ( 'attachments' );

        FOR nI IN p_attachments.FIRST .. p_attachments.LAST LOOP
            apex_json.open_object;
            apex_json.write ( 'id', p_attachments (nI).id );
            apex_json.write ( 'contentType', p_attachments (nI).content_type );
            apex_json.write ( 'contentUrl', p_attachments (nI).content_url );
            apex_json.write ( 'content', p_attachments (nI).content );
            apex_json.write ( 'name', p_attachments (nI).name );
            apex_json.write ( 'thumbnailUrl', p_attachments (nI).thumbnail_url );
            apex_json.close_object;
        END LOOP;
                
        apex_json.close_array;
    END IF;
    
    apex_json.close_object;
    
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
                                                       
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
        
    -- check if error occurred
    check_response_error ( p_response => v_response );

END send_team_channel_message;

FUNCTION create_user_activity ( p_activity IN activity_rt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_id VARCHAR2 (2000);

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_user_activities_url || '/' || apex_util.url_encode ( p_activity.app_activity_id );
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'appActivityId', p_activity.app_activity_id );
    apex_json.write ( 'activitySourceHost', p_activity.activity_source_host );
    apex_json.write ( 'userTimezone', p_activity.user_timezone );
    apex_json.write ( 'appDisplayName', p_activity.app_display_name );
    apex_json.write ( 'activationUrl', p_activity.activation_url );
    apex_json.write ( 'contentUrl', p_activity.content_url );
    apex_json.write ( 'fallbackUrl', p_activity.fallback_url );
    apex_json.open_object ( 'contentInfo' );
    apex_json.write ( '@context', p_activity.content_info_context );
    apex_json.write ( '@type', p_activity.content_info_type );
    apex_json.write ( 'author', p_activity.content_info_author );
    apex_json.write ( 'name', p_activity.content_info_name );
    apex_json.close_object;
    apex_json.open_object ( 'visualElements' );
    apex_json.open_object ( 'attribution' );
    apex_json.write ( 'iconUrl', p_activity.icon_url );
    apex_json.write ( 'alternateText', p_activity.alternate_text );
    apex_json.write ( 'addImageQuery', p_activity.add_image_query );
    apex_json.close_object;
    apex_json.write ( 'description', p_activity.description );
    apex_json.write ( 'backgroundColor', p_activity.background_color );
    apex_json.write ( 'displayText', p_activity.display_text );
    apex_json.open_object ( 'content' );
    apex_json.write ( '$schema', p_activity.content_schema );
    apex_json.write ( 'type', p_activity.content_type );
    apex_json.open_array ( 'body' );
    apex_json.open_object;
    apex_json.write ( 'type', p_activity.body_type );
    apex_json.write ( 'text', p_activity.body_text );
    apex_json.close_object;
    apex_json.close_array;
    apex_json.close_object;
    apex_json.close_object;
    apex_json.close_object;    

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
                                                       
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
        
    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;

END create_user_activity;

FUNCTION list_user_activities RETURN activities_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_activities activities_tt := activities_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := gc_user_activities_url;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_activities.extend;

        v_activities (nI).activity_source_host := apex_json.get_varchar2 ( p_path => 'value[%d].activitySourceHost', p0 => nI );
        v_activities (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_activities (nI).app_activity_id := apex_json.get_varchar2 ( p_path => 'value[%d].appActivityId', p0 => nI );
        v_activities (nI).activation_url := apex_json.get_varchar2 ( p_path => 'value[%d].activationUrl', p0 => nI );
        v_activities (nI).app_display_name := apex_json.get_varchar2 ( p_path => 'value[%d].appDisplayName', p0 => nI );
        v_activities (nI).user_timezone := apex_json.get_varchar2 ( p_path => 'value[%d].userTimezone', p0 => nI );
        v_activities (nI).app_display_name := apex_json.get_varchar2 ( p_path => 'value[%d].appDisplayName', p0 => nI );
        v_activities (nI).fallback_url := apex_json.get_varchar2 ( p_path => 'value[%d].fallbackUrl', p0 => nI );
        v_activities (nI).content_url := apex_json.get_varchar2 ( p_path => 'value[%d].contentUrl', p0 => nI );
        v_activities (nI).content_info_context := apex_json.get_varchar2 ( p_path => 'value[%d].contentInfo.@context', p0 => nI );
        v_activities (nI).content_info_type := apex_json.get_varchar2 ( p_path => 'value[%d].contentInfo.@type', p0 => nI );
        v_activities (nI).content_info_author := apex_json.get_varchar2 ( p_path => 'value[%d].contentInfo.author', p0 => nI );
        v_activities (nI).content_info_name := apex_json.get_varchar2 ( p_path => 'value[%d].contentInfo.name', p0 => nI );
        v_activities (nI).display_text := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.displayText', p0 => nI );
        v_activities (nI).description := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.description', p0 => nI );
        v_activities (nI).background_color := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.backgroundColor', p0 => nI );
        v_activities (nI).content_schema := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.content.$schema', p0 => nI );
        v_activities (nI).content_type := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.content.type', p0 => nI );
        v_activities (nI).body_type := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.content.body.type', p0 => nI );
        v_activities (nI).body_text := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.content.body.text', p0 => nI );
        v_activities (nI).icon_url := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.attribution.iconUrl', p0 => nI );
        v_activities (nI).alternate_text := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.attribution.alternateText', p0 => nI );
        v_activities (nI).add_image_query := apex_json.get_varchar2 ( p_path => 'value[%d].visualElements.attribution.addImageQuery', p0 => nI );

    END LOOP;
    
    RETURN v_activities;
    
END list_user_activities;

FUNCTION pipe_list_user_activities RETURN activities_tt PIPELINED IS
    
    v_activities activities_tt;

BEGIN

    v_activities := list_user_activities;
    
    FOR nI IN v_activities.FIRST .. v_activities.LAST LOOP
        PIPE ROW ( v_activities (nI) );
    END LOOP;    

END pipe_list_user_activities;

FUNCTION list_group_plans ( p_group_id VARCHAR2 ) RETURN plans_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_plans plans_tt := plans_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_group_plans_url, '{id}', p_group_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_plans.extend;

        v_plans (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_plans (nI).title := apex_json.get_varchar2 ( p_path => 'value[%d].title', p0 => nI );
        v_plans (nI).owner := apex_json.get_varchar2 ( p_path => 'value[%d].owner', p0 => nI );

    END LOOP;
    
    RETURN v_plans;
    
END list_group_plans;

FUNCTION pipe_list_group_plans ( p_group_id VARCHAR2 ) RETURN plans_tt PIPELINED IS
    
    v_plans plans_tt;

BEGIN

    v_plans := list_group_plans ( p_group_id );
    
    FOR nI IN v_plans.FIRST .. v_plans.LAST LOOP
        PIPE ROW ( v_plans (nI) );
    END LOOP;    

END pipe_list_group_plans;

FUNCTION create_group_plan ( p_group_id VARCHAR2, p_title VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_id VARCHAR2 (2000);

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_plans_url;
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'owner', p_group_id );
    apex_json.write ( 'title', p_title );
    apex_json.close_object;    

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
                                                       
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
        
    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;

END create_group_plan;

FUNCTION list_plan_buckets ( p_plan_id VARCHAR2 ) RETURN plan_buckets_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_buckets plan_buckets_tt := plan_buckets_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_plan_buckets_url, '{id}', p_plan_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_buckets.extend;

        v_buckets (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_buckets (nI).plan_id := apex_json.get_varchar2 ( p_path => 'value[%d].planId', p0 => nI );
        v_buckets (nI).name := apex_json.get_varchar2 ( p_path => 'value[%d].name', p0 => nI );
        v_buckets (nI).order_hint := apex_json.get_varchar2 ( p_path => 'value[%d].orderHint', p0 => nI );

    END LOOP;
    
    RETURN v_buckets;
    
END list_plan_buckets;

FUNCTION pipe_list_plan_buckets ( p_plan_id VARCHAR2 ) RETURN plan_buckets_tt PIPELINED IS
    
    v_buckets plan_buckets_tt;

BEGIN

    v_buckets := list_plan_buckets ( p_plan_id );
    
    FOR nI IN v_buckets.FIRST .. v_buckets.LAST LOOP
        PIPE ROW ( v_buckets (nI) );
    END LOOP;  
    
END pipe_list_plan_buckets;

FUNCTION create_plan_bucket ( p_plan_id VARCHAR2, p_name VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_id VARCHAR2 (2000);

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_buckets_url;
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'planId', p_plan_id );
    apex_json.write ( 'name', p_name );
    apex_json.close_object;    

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
                                                       
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
        
    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;

END create_plan_bucket;

FUNCTION list_plan_tasks ( p_plan_id VARCHAR2 ) RETURN plan_tasks_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_tasks plan_tasks_tt := plan_tasks_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_plan_tasks_url, '{id}', p_plan_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_tasks.extend;

        v_tasks (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_tasks (nI).plan_id := apex_json.get_varchar2 ( p_path => 'value[%d].planId', p0 => nI );
        v_tasks (nI).bucket_id := apex_json.get_varchar2 ( p_path => 'value[%d].bucketId', p0 => nI );
        v_tasks (nI).title := apex_json.get_varchar2 ( p_path => 'value[%d].title', p0 => nI );
        v_tasks (nI).order_hint := apex_json.get_varchar2 ( p_path => 'value[%d].orderHint', p0 => nI );
        v_tasks (nI).percent_complete := apex_json.get_number ( p_path => 'value[%d].percentComplete', p0 => nI );
        v_tasks (nI).start_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].startDateTime', p0 => nI ) , 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
        v_tasks (nI).due_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].dueDateTime', p0 => nI ) , 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
        v_tasks (nI).has_description := apex_json.get_varchar2 ( p_path => 'value[%d].hasDescription', p0 => nI );
        v_tasks (nI).preview_type := apex_json.get_varchar2 ( p_path => 'value[%d].previewType', p0 => nI );
        v_tasks (nI).completed_date_time := to_date ( substr ( apex_json.get_varchar2 ( p_path => 'value[%d].completedDateTime', p0 => nI ) , 1, 19 ), 'YYYY-MM-DD"T"HH24:MI:SS' );
        v_tasks (nI).completed_by := apex_json.get_varchar2 ( p_path => 'value[%d].completedBy', p0 => nI );
        v_tasks (nI).reference_count := apex_json.get_number ( p_path => 'value[%d].referenceCount', p0 => nI );
        v_tasks (nI).checklist_item_count := apex_json.get_number ( p_path => 'value[%d].checklistItemCount', p0 => nI );
        v_tasks (nI).active_checklist_item_count := apex_json.get_number ( p_path => 'value[%d].activeChecklistItemCount', p0 => nI );
        v_tasks (nI).converation_thread_id := apex_json.get_varchar2 ( p_path => 'value[%d].conversationThreadId', p0 => nI );

    END LOOP;
    
    RETURN v_tasks;
    
END list_plan_tasks;

FUNCTION pipe_list_plan_tasks ( p_plan_id VARCHAR2 ) RETURN plan_tasks_tt PIPELINED IS
    
    v_tasks plan_tasks_tt;

BEGIN

    v_tasks := list_plan_tasks ( p_plan_id );
    
    FOR nI IN v_tasks.FIRST .. v_tasks.LAST LOOP
        PIPE ROW ( v_tasks (nI) );
    END LOOP;    

END pipe_list_plan_tasks;

FUNCTION create_plan_task ( p_plan_id VARCHAR2, p_bucket_id VARCHAR2, p_title VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_id VARCHAR2 (2000);

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_tasks_url;
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'planId', p_plan_id );
    apex_json.write ( 'bucketId', p_bucket_id );
    apex_json.write ( 'title', p_title );
    apex_json.close_object;    

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
                                                       
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
        
    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;
    
END create_plan_task;

FUNCTION list_todo_lists RETURN todo_lists_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_lists todo_lists_tt := todo_lists_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := gc_todo_lists_url;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_lists.extend;

        v_lists (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_lists (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].display_name', p0 => nI );

    END LOOP;
    
    RETURN v_lists;
    
END list_todo_lists;

FUNCTION pipe_list_todo_lists RETURN todo_lists_tt PIPELINED IS
    
    v_lists todo_lists_tt;

BEGIN

    v_lists := list_todo_lists;
    
    FOR nI IN v_lists.FIRST .. v_lists.LAST LOOP
        PIPE ROW ( v_lists (nI) );
    END LOOP;    

END pipe_list_todo_lists;

FUNCTION create_todo_list ( p_display_name IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_id VARCHAR2 (2000);

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_todo_lists_url;
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'displayName', p_display_name );
    apex_json.close_object;    

    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
                                                       
    apex_json.free_output;

    -- parse response
    apex_json.parse ( p_source => v_response );
        
    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;
    
END create_todo_list;

FUNCTION list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_tasks todo_tasks_tt := todo_tasks_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_todo_list_tasks_url, '{id}', p_list_id );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    FOR nI IN 1 .. apex_json.get_count( p_path => gc_value_json_path ) LOOP
    
        v_tasks.extend;

        v_tasks (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
        v_tasks (nI).importance := apex_json.get_varchar2 ( p_path => 'value[%d].importance', p0 => nI );
        v_tasks (nI).is_reminder_on := apex_json.get_varchar2 ( p_path => 'value[%d].isReminderOn', p0 => nI );
        v_tasks (nI).status := apex_json.get_varchar2 ( p_path => 'value[%d].status', p0 => nI );
        v_tasks (nI).title := apex_json.get_varchar2 ( p_path => 'value[%d].title', p0 => nI );
        v_tasks (nI).body_content := apex_json.get_varchar2 ( p_path => 'value[%d].body.content', p0 => nI );
        v_tasks (nI).body_content_type := apex_json.get_varchar2 ( p_path => 'value[%d].body.contentType', p0 => nI );
        v_tasks (nI).due_date_time := apex_json.get_varchar2 ( p_path => 'value[%d].dueDateTime.dateTime', p0 => nI );
        v_tasks (nI).due_time_zone := apex_json.get_varchar2 ( p_path => 'value[%d].dueDateTime.timeZone', p0 => nI );
        v_tasks (nI).reminder_date_time := apex_json.get_varchar2 ( p_path => 'value[%d].reminderDateTime.dateTime', p0 => nI );
        v_tasks (nI).reminder_time_zone := apex_json.get_varchar2 ( p_path => 'value[%d].reminderDateTime.timeZone', p0 => nI );

    END LOOP;
    
    RETURN v_tasks;
    
END list_todo_list_tasks;

FUNCTION pipe_list_todo_list_tasks ( p_list_id IN VARCHAR2 ) RETURN todo_tasks_tt PIPELINED IS
    
    v_tasks todo_tasks_tt;

BEGIN

    v_tasks := list_todo_list_tasks ( p_list_id );
    
    FOR nI IN v_tasks.FIRST .. v_tasks.LAST LOOP
        PIPE ROW ( v_tasks (nI) );
    END LOOP;    

END pipe_list_todo_list_tasks;

END msgraph_sdk;
/

CREATE OR REPLACE PACKAGE BODY msgraph_sdk AS

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
                                                           p_body => 'client_id=' || gc_client_id || '&client_secret=' || gc_client_secret || '&scope=https://graph.microsoft.com/.default&grant_type=client_credentials',
                                                           p_wallet_path => gc_wallet_path,
                                                           p_wallet_pwd => gc_wallet_pwd );

        -- parse response
        apex_json.parse ( p_source => v_response );

        -- check if error occureed
        IF apex_json.does_exist ( p_path => 'error' ) THEN
       
            raise_application_error ( -20001, apex_json.get_varchar2( p_path => 'error' ));
          
        ELSE

            -- set global variables
            gv_access_token := apex_json.get_varchar2 ( p_path => 'access_token' );
            
            v_expires_in := apex_json.get_number ( p_path => 'expires_in' );
            gv_access_token_expiration := sysdate + (1/24/60/60) * v_expires_in;
            
        END IF;
        
    END IF;

    RETURN gv_access_token;

END get_access_token;

PROCEDURE set_authorization_header IS
BEGIN 

    apex_web_service.g_request_headers.delete();
    apex_web_service.g_request_headers(1).name := 'Authorization';
    apex_web_service.g_request_headers(1).value := 'Bearer ' || get_access_token;

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
    v_request_url := REPLACE( gc_user_url, '{userPrincipalName}', p_user_principal_name );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd);

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
        
    ELSE
    
        -- populate user record
        v_user.business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'businessPhones'), ';');
        v_user.display_name := apex_json.get_varchar2 ( p_path => 'displayName');
        v_user.given_name := apex_json.get_varchar2 ( p_path => 'givenName');
        v_user.job_title := apex_json.get_varchar2 ( p_path => 'jobTitle');
        v_user.mail := apex_json.get_varchar2 ( p_path => 'mail');
        v_user.mobile_phone := apex_json.get_varchar2 ( p_path => 'mobilePhone');
        v_user.office_location := apex_json.get_varchar2 ( p_path => 'officeLocation');
        v_user.preferred_language := apex_json.get_varchar2 ( p_path => 'preferredLanguage');
        v_user.surname := apex_json.get_varchar2 ( p_path => 'surname');
        v_user.user_principal_name := apex_json.get_varchar2 ( p_path => 'userPrincipalName');
        v_user.id := apex_json.get_varchar2 ( p_path => 'id');
        
    END IF;

    RETURN v_user;

END get_user;

FUNCTION list_users RETURN users_tt IS

    v_response CLOB;
    
    v_users users_tt := users_tt();
    
BEGIN
    -- set headers
    set_authorization_header;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => gc_users_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd);
    
    -- parse response                                                   
    apex_json.parse ( v_response );

    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
        
    ELSE
        
        FOR nI IN 1 .. apex_json.get_count( p_path => 'value' ) LOOP
        
            v_users.extend;

            v_users ( nI ).business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].businessPhones', p0 => nI) , ';');
            v_users ( nI ).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI);
            v_users ( nI ).given_name := apex_json.get_varchar2 ( p_path => 'value[%d].givenName', p0 => nI);
            v_users ( nI ).job_title := apex_json.get_varchar2 ( p_path => 'value[%d].jobTitle', p0 => nI);
            v_users ( nI ).mail := apex_json.get_varchar2 ( p_path => 'value[%d].mail', p0 => nI);
            v_users ( nI ).mobile_phone := apex_json.get_varchar2 ( p_path => 'value[%d].mobilePhone', p0 => nI);
            v_users ( nI ).office_location := apex_json.get_varchar2 ( p_path => 'value[%d].officeLocation', p0 => nI);
            v_users ( nI ).preferred_language := apex_json.get_varchar2 ( p_path => 'value[%d].preferredLanguage', p0 => nI);
            v_users ( nI ).surname := apex_json.get_varchar2 ( p_path => 'value[%d].surname', p0 => nI);
            v_users ( nI ).user_principal_name := apex_json.get_varchar2 ( p_path => 'value[%d].userPrincipalName', p0 => nI);
            v_users ( nI ).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI);

        END LOOP;
         
    END IF;
    
    RETURN v_users;

END list_users;

FUNCTION pipe_list_users RETURN users_tt PIPELINED IS

    v_users users_tt;

BEGIN

    v_users := list_users;

    FOR nI IN v_users.FIRST .. v_users.LAST LOOP
        PIPE ROW ( v_users(nI) );
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
    v_request_url := REPLACE( gc_user_contacts_url, '{userPrincipalName}', p_user_principal_name ) || '/' || p_contact_id;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
        
    ELSE
    
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

    END IF;
    
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
    v_request_url := REPLACE( gc_user_contacts_url, '{userPrincipalName}', p_user_principal_name );
    
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
    apex_json.parse ( v_response );
    
    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
        
    ELSE
        
        v_id := apex_json.get_varchar2 ( p_path => 'id' );
    
    END IF;                                                                                             
    
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
    v_request_url := REPLACE( gc_user_contacts_url, '{userPrincipalName}', p_user_principal_name ) || '/' || p_contact.id;
    
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
                                                       p_http_method => 'jPATCH',
                                                       p_body => apex_json.get_clob_output,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    apex_json.free_output;
    
    -- parse response
    apex_json.parse ( v_response );
    
    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
    
    END IF;    

END update_user_contact;

PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

BEGIN

    -- set headers
    set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, '{userPrincipalName}', p_user_principal_name ) || '/' || p_contact_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'DELETE',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

END delete_user_contact;

FUNCTION list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    
    v_contacts contacts_tt := contacts_tt ();
    
BEGIN
    -- set headers
    set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, '{userPrincipalName}', p_user_principal_name );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response                                                   
    apex_json.parse ( v_response );

    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
        
    ELSE
        
        FOR nI IN 1 .. apex_json.get_count( p_path => 'value' ) LOOP
        
            v_contacts.extend;

            v_contacts (nI).id := apex_json.get_varchar2 ( p_path => 'value[%d].id', p0 => nI );
            v_contacts (nI).created_date_time := apex_json.get_date ( p_path => 'value[%d].createdDateTime', p0 => nI );
            v_contacts (nI).last_modified_date_time := apex_json.get_date ( p_path => 'value[%d].lastModifiedDateTime', p0 => nI );
            v_contacts (nI).categories := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].categories' ), ';' );
            v_contacts (nI).parent_folder_id := apex_json.get_varchar2 ( p_path => 'value[%d].parentFolderId', p0 => nI );
            v_contacts (nI).birthday := apex_json.get_date ( p_path => 'value[%d].birthday', p0 => nI );
            v_contacts (nI).file_as := apex_json.get_varchar2 ( p_path => 'value[%d].fileAs', p0 => nI );
            v_contacts (nI).display_name := apex_json.get_varchar2 ( p_path => 'value[%d].displayName', p0 => nI );
            v_contacts (nI).given_name := apex_json.get_varchar2 ( p_path => 'value[%d].givenName', p0 => nI );
            v_contacts (nI).nick_name := apex_json.get_varchar2 ( p_path => 'value[%d].nickName', p0 => nI );
            v_contacts (nI).surname := apex_json.get_varchar2 ( p_path => 'value[%d].surname', p0 => nI );
            v_contacts (nI).title := apex_json.get_varchar2 ( p_path => 'value[%d].title', p0 => nI );
            v_contacts (nI).im_addresses := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].imAddresses' ), ';' );
            v_contacts (nI).job_title := apex_json.get_varchar2 ( p_path => 'value[%d].jobTitle', p0 => nI );
            v_contacts (nI).company_name := apex_json.get_varchar2 ( p_path => 'value[%d].companyName', p0 => nI );
            v_contacts (nI).department := apex_json.get_varchar2 ( p_path => 'value[%d].department', p0 => nI );
            v_contacts (nI).office_location := apex_json.get_varchar2 ( p_path => 'value[%d].officeLocation', p0 => nI );
            v_contacts (nI).business_home_page := apex_json.get_varchar2 ( p_path => 'value[%d].businessHomePage', p0 => nI );
            v_contacts (nI).home_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].homePhones' ), ';' );
            v_contacts (nI).mobile_phone := apex_json.get_varchar2 ( p_path => 'value[%d].mobilePhone', p0 => nI );
            v_contacts (nI).business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'value[%d].businessPhones' ), ';' );
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
         
    END IF;
    
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
    v_request_url := REPLACE( gc_user_calendar_events_url, '{userPrincipalName}', p_user_principal_name ) || '/' || p_event_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- parse response                                                   
    apex_json.parse ( v_response );

    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
        
    ELSE
    
       -- populate event record
        v_event.id := apex_json.get_varchar2 ( p_path => 'id' );
        v_event.created_date_time := apex_json.get_date ( p_path => 'createdDateTime' );
        v_event.last_modified_date_time := apex_json.get_date ( p_path => 'lastModifiedDateTime' );
        v_event.categories := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'categories' ), ';' );        
        v_event.original_start_time_zone := apex_json.get_varchar2 ( p_path => 'originalStartTimeZone' );
        v_event.original_end_time_zone := apex_json.get_varchar2 ( p_path => 'originalEndTimeZone' );
        v_event.reminder_minutes_before_start := apex_json.get_number ( p_path => 'reminderMinutesBeforeStart' );
        v_event.is_reminder_on := apex_json.get_boolean ( p_path => 'isReminderOn' );
        v_event.has_attachments := apex_json.get_boolean ( p_path => 'hasAttachments' );
        v_event.subject := apex_json.get_varchar2 ( p_path => 'subject' );
        v_event.body_preview := apex_json.get_varchar2 ( p_path => 'bodyPreview' );
        v_event.importance := apex_json.get_varchar2 ( p_path => 'importance' );
        v_event.sensitivity := apex_json.get_varchar2 ( p_path => 'sensitivity' );
        v_event.is_all_day := apex_json.get_boolean ( p_path => 'isAllDay' );
        v_event.is_cancelled := apex_json.get_boolean ( p_path => 'isCancelled' );
        v_event.is_organizer := apex_json.get_boolean ( p_path => 'isOrganizer' );
        v_event.response_requested := apex_json.get_boolean ( p_path => 'responseRequested' );
        v_event.series_master_id := apex_json.get_varchar2 ( p_path => 'seriesMasterId' );
        v_event.show_as := apex_json.get_varchar2 ( p_path => 'showAs' );
        v_event.type := apex_json.get_varchar2 ( p_path => 'type' );
        v_event.web_link := apex_json.get_varchar2 ( p_path => 'webLink' );
        v_event.online_meeting_url := apex_json.get_varchar2 ( p_path => 'onlineMeetingUrl' );
        v_event.is_online_meeting := apex_json.get_boolean ( p_path => 'isOnlineMeeting' );
        v_event.online_meeting_provider := apex_json.get_varchar2 ( p_path => 'onlineMeetingProvider' );
        v_event.allow_new_time_proposals := apex_json.get_boolean ( p_path => 'allowNewTimeProposals' );
        v_event.recurrence := apex_json.get_varchar2 ( p_path => 'recurrence' );
        v_event.response_status_response := apex_json.get_varchar2 ( p_path => 'responseStatus.response' );
        v_event.response_status_time := apex_json.get_date ( p_path => 'responseStatus.time' );
        v_event.body_content_type := apex_json.get_varchar2 ( p_path => 'body.contentType' );
        v_event.body_content := apex_json.get_clob ( p_path => 'body.content');
        v_event.start_date_time := apex_json.get_date ( p_path => 'start.dateTime' );
        v_event.start_time_zone := apex_json.get_varchar2 ( p_path => 'start.timeZone' );
        v_event.end_date_time := apex_json.get_date ( p_path => 'end.dateTime' );
        v_event.end_date_time_zone := apex_json.get_varchar2 ( p_path => 'end.dateTimeZone' );
        v_event.location_display_name := apex_json.get_varchar2 ( p_path => 'location.displayName' );
        v_event.location_location_type := apex_json.get_varchar2 ( p_path => 'location.locationType' );
        v_event.location_unique_id := apex_json.get_varchar2 ( p_path => 'location.uniqueId' );
        v_event.location_unique_id_type := apex_json.get_varchar2 ( p_path => 'location.uniqueIdType' );
        v_event.organizer_email_address_name := apex_json.get_varchar2 ( p_path => 'organizer.emailAddress.name' );
        v_event.organizer_email_address_address := apex_json.get_varchar2 ( p_path => 'organizer.emailAddress.address' );
        v_event.online_meeting_join_url := apex_json.get_varchar2 ( p_path => 'onlineMeeting.joinUrl' );

    END IF;
    
    RETURN v_event;

END get_user_calendar_event;

END msgraph_sdk;
/

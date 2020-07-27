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

FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt IS

    v_request_url VARCHAR2(255);
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

    v_request_url VARCHAR2(255);
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
                                                       p_wallet_pwd => gc_wallet_pwd);

    -- parse response
    apex_json.parse ( p_source => v_response );

    -- check if error occurred
    IF apex_json.does_exist ( p_path => 'error' ) THEN
    
        raise_application_error ( -20001, apex_json.get_varchar2 ( p_path => 'error.message' ) );
        
    ELSE
    
        -- populate contact record
        v_contact.id := apex_json.get_varchar2 ( p_path => 'id' );
        v_contact.created_date_time := apex_json.get_date ( p_path => 'createdDateTime');
        v_contact.last_modified_date_time := apex_json.get_date ( p_path => 'lastModifiedDateTime');
        v_contact.categories := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'categories'), ';');
        v_contact.parent_folder_id := apex_json.get_varchar2 ( p_path => 'parentFolderId' );
        v_contact.birthday := apex_json.get_date ( p_path => 'birthday');
        v_contact.file_as := apex_json.get_varchar2 ( p_path => 'fileAs' );
        v_contact.display_name := apex_json.get_varchar2 ( p_path => 'displayName' );
        v_contact.given_name := apex_json.get_varchar2 ( p_path => 'givenName' );
        v_contact.nick_name := apex_json.get_varchar2 ( p_path => 'nickName' );
        v_contact.surname := apex_json.get_varchar2 ( p_path => 'surname' );
        v_contact.title := apex_json.get_varchar2 ( p_path => 'title' );
        v_contact.im_addresses := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'imAddresses'), ';');
        v_contact.job_title := apex_json.get_varchar2 ( p_path => 'jobTitle' );
        v_contact.company_name := apex_json.get_varchar2 ( p_path => 'companyName' );
        v_contact.department := apex_json.get_varchar2 ( p_path => 'department' );
        v_contact.office_location := apex_json.get_varchar2 ( p_path => 'officeLocation' );
        v_contact.business_home_page := apex_json.get_varchar2 ( p_path => 'businessHomePage' );
        v_contact.home_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'homePhones'), ';');
        v_contact.business_phones := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'businessPhones'), ';');
        v_contact.personal_notes := apex_json.get_varchar2 ( p_path => 'personalNotes' );
        v_contact.email_address := apex_string.join ( apex_json.get_t_varchar2 ( p_path => 'emailAddresses[1].address'), ';');
        v_contact.home_address.street := apex_json.get_varchar2 ( p_path => 'homeAddress.street' );
        v_contact.home_address.city := apex_json.get_varchar2 ( p_path => 'homeAddress.city' );
        v_contact.home_address.state := apex_json.get_varchar2 ( p_path => 'homeAddress.state' );
        v_contact.home_address.country_or_region := apex_json.get_varchar2 ( p_path => 'homeAddress.countryOrRegion' );
        v_contact.home_address.postal_code := apex_json.get_varchar2 ( p_path => 'homeAddress.postal_code' );
        v_contact.business_address.street := apex_json.get_varchar2 ( p_path => 'businessAddress.street' );
        v_contact.business_address.city := apex_json.get_varchar2 ( p_path => 'businessAddress.city' );
        v_contact.business_address.state := apex_json.get_varchar2 ( p_path => 'businessAddress.state' );
        v_contact.business_address.country_or_region := apex_json.get_varchar2 ( p_path => 'businessAddress.countryOrRegion' );
        v_contact.business_address.postal_code := apex_json.get_varchar2 ( p_path => 'businessAddress.postal_code' );

    END IF;
    
    RETURN v_contact;
 
END get_user_contact;

END msgraph_sdk;
/

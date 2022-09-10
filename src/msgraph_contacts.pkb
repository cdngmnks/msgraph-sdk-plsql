CREATE OR REPLACE PACKAGE BODY msgraph_contacts AS

FUNCTION json_object_to_contact ( p_json IN JSON_OBJECT_T ) RETURN contact_rt IS

    v_contact contact_rt;
    v_email JSON_OBJECT_T;

BEGIN

    v_contact.id := p_json.get_string ( 'id' );
    v_contact.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_contact.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );
    v_contact.categories := msgraph_utils.json_array_to_csv ( p_json.get_array ( 'categories' ));
    v_contact.parent_folder_id := p_json.get_string ( 'parentFolderId' );
    v_contact.birthday := p_json.get_date ( 'birthday' );
    v_contact.file_as := p_json.get_string ( 'fileAs' );
    v_contact.display_name := p_json.get_string ( 'displayName' );
    v_contact.given_name := p_json.get_string ( 'givenName' );
    v_contact.nick_name := p_json.get_string ( 'nickName' );
    v_contact.surname := p_json.get_string ( 'surname' );
    v_contact.title := p_json.get_string ( 'title' );
    v_contact.im_addresses := msgraph_utils.json_array_to_csv ( p_json.get_array ( 'imAddresses' ));
    v_contact.job_title := p_json.get_string ( 'jobTitle' );
    v_contact.company_name := p_json.get_string ( 'companyName' );
    v_contact.department := p_json.get_string ( 'department' );
    v_contact.office_location := p_json.get_string ( 'officeLocation' );
    v_contact.business_home_page := p_json.get_string ( 'businessHomePage' );
    v_contact.home_phones := msgraph_utils.json_array_to_csv ( p_json.get_array ( 'homePhones' ));
    v_contact.mobile_phone := p_json.get_string ( 'mobilePhone' );
    v_contact.business_phones := msgraph_utils.json_array_to_csv ( p_json.get_array ( 'businessPhones' ));
    v_contact.personal_notes := p_json.get_string ( 'personalNotes' );

    v_email := TREAT ( p_json.get_array ( 'emailAddresses' ).get ( 0 ) AS JSON_OBJECT_T );
    v_contact.email_address := v_email.get_string ( 'address' );

    v_contact.home_address_street := p_json.get_object ( 'homeAddress' ).get_string ( 'street' );
    v_contact.home_address_city := p_json.get_object ( 'homeAddress' ).get_string ( 'city' );
    v_contact.home_address_state := p_json.get_object ( 'homeAddress' ).get_string ( 'state' );
    v_contact.home_address_country_or_region := p_json.get_object ( 'homeAddress' ).get_string ( 'countryOrRegion' );
    v_contact.home_address_postal_code := p_json.get_object ( 'homeAddress' ).get_string ( 'postalCode' );
    v_contact.business_address_street := p_json.get_object ( 'businessAddress' ).get_string ( 'street' );
    v_contact.business_address_city := p_json.get_object ( 'businessAddress' ).get_string ( 'city' );
    v_contact.business_address_state := p_json.get_object ( 'businessAddress' ).get_string ( 'state' );
    v_contact.business_address_country_or_region := p_json.get_object ( 'businessAddress' ).get_string ( 'countryOrRegion' );
    v_contact.business_address_postal_code := p_json.get_object ( 'businessAddress' ).get_string ( 'postalCode' );

    RETURN v_contact;

END;

FUNCTION contact_to_json_object ( p_contact IN contact_rt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_array JSON_ARRAY_T;
    v_object JSON_OBJECT_T;

BEGIN

    v_json.put ( 'givenName', p_contact.given_name );
    v_json.put ( 'surname', p_contact.surname );
    v_json.put ( 'nickName', p_contact.nick_name );
    v_json.put ( 'title', p_contact.title );
    v_json.put ( 'jobTitle', p_contact.job_title );
    v_json.put ( 'companyName', p_contact.company_name );
    v_json.put ( 'department', p_contact.department );
    v_json.put ( 'officeLocation', p_contact.office_location );
    v_json.put ( 'jobTitle', p_contact.job_title );
    v_json.put ( 'businessHomePage', p_contact.business_home_page );
    v_json.put ( 'personalNotes', p_contact.personal_notes );
    v_json.put ( 'mobilePhone', p_contact.mobile_phone );
    v_json.put ( 'homePhones', msgraph_utils.csv_to_json_array ( p_contact.home_phones ));
    v_json.put ( 'businessPhones', msgraph_utils.csv_to_json_array ( p_contact.business_phones ));

    v_object := JSON_OBJECT_T ();
    v_object.put ( 'name', p_contact.email_address );
    v_object.put ( 'address', p_contact.email_address );
    v_array.append ( v_object );
    v_json.put ( 'emailAddresses', v_array );

    v_object := JSON_OBJECT_T ();
    v_object.put ( 'street', p_contact.home_address_street );
    v_object.put ( 'city', p_contact.home_address_city );
    v_object.put ( 'state', p_contact.home_address_state );
    v_object.put ( 'countryOrRegion', p_contact.home_address_country_or_region );
    v_object.put ( 'postalCode', p_contact.home_address_postal_code );
    v_json.put ( 'homeAddress', v_object );

    v_object := JSON_OBJECT_T ();
    v_object.put ( 'street', p_contact.business_address_street );
    v_object.put ( 'city', p_contact.business_address_city );
    v_object.put ( 'state', p_contact.business_address_state );
    v_object.put ( 'countryOrRegion', p_contact.business_address_country_or_region );
    v_object.put ( 'postalCode', p_contact.business_address_postal_code );
    v_json.put ( 'businessAddress', v_object );

    RETURN v_json;

END;

FUNCTION get_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) RETURN contact_rt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;

    v_contact contact_rt;

BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_contact_id;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

    -- populate contact record
    v_contact := json_object_to_contact ( v_json );
    
    RETURN v_contact;
 
END get_user_contact;

FUNCTION create_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;

BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;
    msgraph_utils.set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request := contact_to_json_object ( p_contact );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );
    
    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    
    RETURN v_json.get_string ( 'id' );

END create_user_contact;

PROCEDURE update_user_contact ( p_user_principal_name IN VARCHAR2, p_contact IN contact_rt ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;
    
BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;
    msgraph_utils.set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_contact.id;
    
    -- generate request
    v_request := contact_to_json_object ( p_contact );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'PATCH',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response ); 

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );  

END update_user_contact;

PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;

BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_contact_id;
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'DELETE',
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response ); 

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

END delete_user_contact;

FUNCTION list_user_contacts ( p_user_principal_name IN VARCHAR2 ) RETURN contacts_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_contacts contacts_tt := contacts_tt ();
    
BEGIN 
    -- set headers
    msgraph_utils.set_authorization_header;
   
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );
   
    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_contacts.extend;
        v_contacts (nI) := json_object_to_contact ( v_value );

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

END msgraph_contacts;

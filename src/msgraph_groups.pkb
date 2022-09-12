set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_groups AS

FUNCTION json_object_to_user ( p_json IN JSON_OBJECT_T ) RETURN msgraph_users.user_rt IS

    v_user msgraph_users.user_rt;

BEGIN

    v_user.business_phones := msgraph_utils.json_array_to_csv ( p_json.get_array ( 'businessPhones' ));
    v_user.display_name := p_json.get_string ( 'displayName' );
    v_user.given_name := p_json.get_string ( 'givenName' );
    v_user.job_title := p_json.get_string ( 'jobTitle' );
    v_user.mail := p_json.get_string ( 'mail' );
    v_user.mobile_phone := p_json.get_string ( 'mobilePhone' );
    v_user.office_location := p_json.get_string ( 'officeLocation' );
    v_user.preferred_language := p_json.get_string ( 'preferredLanguage' );
    v_user.surname := p_json.get_string ( 'surname' );
    v_user.user_principal_name := p_json.get_string ( 'userPrincipalName' );
    v_user.id := p_json.get_string ( 'id' );

    RETURN v_user;
END;

FUNCTION json_object_to_group ( p_json JSON_OBJECT_T ) RETURN group_rt IS

    v_group group_rt;

BEGIN

    v_group.id := p_json.get_string ( 'id' );
    v_group.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_group.description := p_json.get_string ( 'description' );
    v_group.display_name := p_json.get_string ( 'displayName' );
    v_group.mail := p_json.get_string ( 'mail' );
    v_group.visibility := p_json.get_string ( 'visibility' );
    v_group.resource_provisioning_options := msgraph_utils.json_array_to_csv ( p_json.get_array( 'resourceProvisioningOptions'));

    RETURN v_group;

END;

FUNCTION list_groups RETURN groups_tt IS

    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_groups groups_tt := groups_tt ();
    
BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => gc_groups_url,
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
    
        v_groups.extend;
        v_groups (nI) := json_object_to_group ( v_value );

    END LOOP;

    RETURN v_groups;

END list_groups;

FUNCTION pipe_list_groups RETURN groups_tt PIPELINED IS

    v_groups groups_tt;

    nI PLS_INTEGER;

BEGIN

    v_groups := list_groups;

    nI := v_groups.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_groups (nI) );

        nI := v_groups.NEXT ( nI );

    END LOOP;

END pipe_list_groups;

FUNCTION list_group_members ( p_group_id IN VARCHAR2 ) RETURN msgraph_users.users_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_users msgraph_users.users_tt := msgraph_users.users_tt ();
    
BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE( gc_group_members_url, '{id}', p_group_id );

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
    
        v_users.extend;
        v_users (nI) := json_object_to_user ( v_value );

    END LOOP;
    
    RETURN v_users;

END list_group_members;

FUNCTION pipe_list_group_members ( p_group_id IN VARCHAR2 ) RETURN msgraph_users.users_tt PIPELINED IS

    v_users msgraph_users.users_tt;

    nI PLS_INTEGER;

BEGIN

    v_users := list_group_members ( p_group_id );

    nI := v_users.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_users (nI) );

        nI := v_users.NEXT ( nI );

    END LOOP;

END pipe_list_group_members;

PROCEDURE add_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;
    
    v_user msgraph_users.user_rt;

BEGIN
    -- get user
    v_user := msgraph_users.get_user ( p_user_principal_name );

    -- set headers
    msgraph_utils.set_authorization_header;
    msgraph_utils.set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE ( gc_group_members_url, '{id}', p_group_id ) || '/$ref';
    
    -- generate request
    v_request.put ( '@odata.id', 'https://graph.microsoft.com/v1.0/directoryObjects/'|| v_user.id );
    
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

END add_group_member;

PROCEDURE remove_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

    v_response CLOB;
    v_json JSON_OBJECT_T;
    
    v_user msgraph_users.user_rt;

BEGIN
    
    -- get user
    v_user := msgraph_users.get_user ( p_user_principal_name );

    -- set headers
    msgraph_utils.set_authorization_header;

    -- generate request URL
    v_request_url := REPLACE ( gc_group_members_url, '{id}', p_group_id ) || '/' || v_user.id || '/$ref';
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'DELETE',
                                                       p_wallet_path => msgraph_config.gc_wallet_path,
                                                       p_wallet_pwd => msgraph_config.gc_wallet_pwd );

    -- check if error occurred
    msgraph_utils.check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    
END remove_group_member;

END msgraph_groups;

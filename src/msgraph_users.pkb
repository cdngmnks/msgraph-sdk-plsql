set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_users AS

FUNCTION json_object_to_user ( p_json IN JSON_OBJECT_T ) RETURN user_rt IS

    v_user user_rt;

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

FUNCTION get_user ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_user user_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    -- populate user record
    v_user := json_object_to_user ( v_response );

    RETURN v_user;

END get_user;

FUNCTION list_users RETURN users_tt IS

    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_users users_tt := users_tt ();
    
BEGIN

    -- make request
    v_response := msgraph_utils.make_get_request ( gc_users_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_users.extend;
        v_users (nI) := json_object_to_user ( v_value );

    END LOOP;
    
    RETURN v_users;

END list_users;

FUNCTION pipe_list_users RETURN users_tt PIPELINED IS

    v_users users_tt;

    nI PLS_INTEGER;

BEGIN

    v_users := list_users;

    nI := v_users.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_users (nI) );

        nI := v_users.NEXT ( nI );

    END LOOP;

END;

FUNCTION list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_users users_tt := users_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_direct_reports_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );
    
    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_users.extend;
        v_users (nI) := json_object_to_user ( v_value );

    END LOOP;

    RETURN v_users;

END list_user_direct_reports;

FUNCTION pipe_list_user_direct_reports ( p_user_principal_name IN VARCHAR2 ) RETURN users_tt PIPELINED IS

    v_users users_tt;

    nI PLS_INTEGER;

BEGIN

    v_users := list_user_direct_reports ( p_user_principal_name );

    nI := v_users.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_users (nI) );

        nI := v_users.NEXT ( nI );

    END LOOP;

END pipe_list_user_direct_reports;

FUNCTION get_user_manager ( p_user_principal_name IN VARCHAR2 ) RETURN user_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_user user_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_manager_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );
    
    -- populate user record
    v_user := json_object_to_user ( v_response );

    RETURN v_user;
    
END get_user_manager;

END msgraph_users;

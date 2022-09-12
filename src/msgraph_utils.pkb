set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_utils AS

FUNCTION json_array_to_csv ( p_array IN JSON_ARRAY_T, p_delimiter IN VARCHAR2 DEFAULT ';' ) RETURN VARCHAR2 IS

    v_ret VARCHAR2(2000);

BEGIN

    FOR nI IN 0 .. p_array.get_size - 1 LOOP
        v_ret := v_ret || p_array.get_string(nI) || p_delimiter;
    END LOOP;

    return RTRIM( v_ret, p_delimiter ) ;

END;

FUNCTION csv_to_json_array ( p_csv IN VARCHAR2, p_delimiter IN VARCHAR2 DEFAULT ';' ) RETURN JSON_ARRAY_T IS

    v_csv VARCHAR2(2000) := p_csv;
    v_ret JSON_ARRAY_T;

BEGIN

    IF INSTR ( v_csv, p_delimiter ) = 0 THEN
        v_ret.append ( v_csv );
    ELSE
        WHILE INSTR ( v_csv, p_delimiter ) > 0 LOOP
            v_ret.append ( SUBSTR ( v_csv, 1, instr ( v_csv, p_delimiter ) - 1 ));
            v_csv := SUBSTR ( v_csv, instr ( v_csv, p_delimiter ) + 1 );
        END LOOP;

        v_ret.append ( v_csv );
    END IF;

    RETURN v_ret;

END;

PROCEDURE check_response_error ( p_response IN CLOB ) IS

    v_json JSON_OBJECT_T;

BEGIN

    v_json := JSON_OBJECT_T.parse( p_response );

    IF v_json.has ( msgraph_config.gc_error_json_path ) THEN

        dbms_output.put_line(p_response);
        raise_application_error ( -20001, v_json.get_string ( msgraph_config.gc_error_json_path ) );
        
    END IF;

END check_response_error;

FUNCTION get_access_token RETURN CLOB IS

    v_response CLOB;
    v_expires_in INTEGER;
    v_json JSON_OBJECT_T;

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
                                                           p_body => 'client_id=' || msgraph_config.gc_client_id || 
                                                                     '&client_secret=' || msgraph_config.gc_client_secret || 
                                                                     '&scope=https://graph.microsoft.com/.default' ||
                                                                     '&grant_type=client_credentials',
                                                           p_wallet_path => msgraph_config.gc_wallet_path,
                                                           p_wallet_pwd => msgraph_config.gc_wallet_pwd );

        -- check if error occurred
        check_response_error ( p_response => v_response );

        -- parse response
        v_json := JSON_OBJECT_T.parse ( v_response );

        -- set global variables
        gv_access_token := v_json.get_string ( 'access_token' );
        
        v_expires_in := v_json.get_number ( 'expires_in' );
        gv_access_token_expiration := sysdate + (1/24/60/60) * v_expires_in;
        
    END IF;

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

END msgraph_utils;
CREATE OR REPLACE PACKAGE BODY msgraph_sdk AS

FUNCTION get_access_token RETURN CLOB IS
    v_response CLOB;
    v_expires_in INTEGER;
BEGIN

    -- request new token
    IF gv_access_token_expiration IS NULL OR gv_access_token_expiration < sysdate THEN

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

        if apex_json.does_exist ( p_path => 'error' ) then
          raise_application_error (-20001, apex_json.get_varchar2( p_path => 'error'));
        else

            -- set global variables
            gv_access_token := apex_json.get_varchar2 ( p_path => 'access_token');
            
            v_expires_in := apex_json.get_number (p_path => 'expires_in');
            gv_access_token_expiration := sysdate + (1/24/60/60) * v_expires_in;
            
        end if;
    END IF;

    RETURN gv_access_token;

END get_access_token;

END msgraph_sdk;
/

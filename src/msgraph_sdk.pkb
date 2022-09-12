set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_sdk AS

FUNCTION json_object_to_activity ( p_json JSON_OBJECT_T ) RETURN activity_rt IS

    v_activity activity_rt;

BEGIN

    v_activity.activity_source_host := p_json.get_string ( 'activitySourceHost' );
    v_activity.id := p_json.get_string ( 'id' );
    v_activity.app_activity_id := p_json.get_string ( 'appActivityId' );
    v_activity.activation_url := p_json.get_string ( 'activationUrl' );
    v_activity.app_display_name := p_json.get_string ( 'appDisplayName' );
    v_activity.user_timezone := p_json.get_string ( 'userTimezone' );
    v_activity.app_display_name := p_json.get_string ( 'appDisplayName' );
    v_activity.fallback_url := p_json.get_string ( 'fallbackUrl' );
    v_activity.content_url := p_json.get_string ( 'contentUrl' );
    v_activity.content_info_context := p_json.get_object ( 'contentInfo' ).get_string ( '@context' );
    v_activity.content_info_type := p_json.get_object ( 'contentInfo' ).get_string ( '@type' );
    v_activity.content_info_author := p_json.get_object ( 'contentInfo' ).get_string ( 'author' );
    v_activity.content_info_name := p_json.get_object ( 'contentInfo' ).get_string ( 'name' );
    v_activity.display_text := p_json.get_object ( 'visualElements' ).get_string ( 'displayText' );
    v_activity.description := p_json.get_object ( 'visualElements' ).get_string ( 'description' );
    v_activity.background_color := p_json.get_object ( 'visualElements' ).get_string ( 'backgroundColor' );
    v_activity.content_schema := p_json.get_object ( 'visualElements' ).get_object ( 'content' ).get_string ( '$schema' );
    v_activity.content_type := p_json.get_object ( 'visualElements' ).get_object ( 'content' ).get_string ( 'type' );
    v_activity.body_type := p_json.get_object ( 'visualElements' ).get_object ( 'content' ).get_object ( 'body' ).get_string ( 'type' );
    v_activity.body_text := p_json.get_object ( 'visualElements' ).get_object ( 'content' ).get_object ( 'body' ).get_string ( 'text' );
    v_activity.icon_url := p_json.get_object ( 'visualElements' ).get_object ( 'attribution' ).get_string ( 'iconUrl' );
    v_activity.alternate_text := p_json.get_object ( 'visualElements' ).get_object ( 'attribution' ).get_string ( 'alternateText' );
    v_activity.add_image_query := p_json.get_object ( 'visualElements' ).get_object ( 'attribution' ).get_string ( 'addImageQuery' );

    RETURN v_activity;
END;

FUNCTION activity_to_json_object ( p_activity IN activity_rt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_content_info JSON_OBJECT_T := JSON_OBJECT_T ();
    v_visual_elements JSON_OBJECT_T := JSON_OBJECT_T ();
    v_attribution JSON_OBJECT_T := JSON_OBJECT_T ();
    v_content JSON_OBJECT_T := JSON_OBJECT_T ();

    v_body JSON_ARRAY_T := JSON_ARRAY_T ();
    v_body_object JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    v_json.put ( 'appActivityId', p_activity.app_activity_id );
    v_json.put ( 'activitySourceHost', p_activity.activity_source_host );
    v_json.put ( 'userTimezone', p_activity.user_timezone );
    v_json.put ( 'appDisplayName', p_activity.app_display_name );
    v_json.put ( 'activationUrl', p_activity.activation_url );
    v_json.put ( 'contentUrl', p_activity.content_url );
    v_json.put ( 'fallbackUrl', p_activity.fallback_url );

    v_content_info.put ( '@context', p_activity.content_info_context );
    v_content_info.put ( '@type', p_activity.content_info_type );
    v_content_info.put ( 'author', p_activity.content_info_author );
    v_content_info.put ( 'name', p_activity.content_info_name );
    v_json.put ( 'contentInfo', v_content_info );

    v_attribution.put ( 'iconUrl', p_activity.icon_url );
    v_attribution.put ( 'alternateText', p_activity.alternate_text );
    v_attribution.put ( 'addImageQuery', p_activity.add_image_query );
    v_visual_elements.put ( 'attribution', v_attribution );
    v_visual_elements.put ( 'description', p_activity.description );
    v_visual_elements.put ( 'backgroundColor', p_activity.background_color );
    v_visual_elements.put ( 'displayText', p_activity.display_text );

    v_content.put ( '$schema', p_activity.content_schema );
    v_content.put ( 'type', p_activity.content_type );

    v_body_object.put ( 'type', p_activity.body_type );
    v_body_object.put ( 'text', p_activity.body_text );
    v_body.append ( v_body_object );
    v_content.put ( 'body', v_body );
    v_visual_elements.put ( 'content', v_content );
    v_json.put ( 'visualElements', v_visual_elements );

    RETURN v_json;

END;

FUNCTION create_user_activity ( p_activity IN activity_rt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;

BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;
    msgraph_utils.set_content_type_header;
    
    -- generate request URL
    v_request_url := gc_user_activities_url || '/' || apex_util.url_encode ( p_activity.app_activity_id );
    
    -- generate request
    v_request := activity_to_json_object ( p_activity );

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

END create_user_activity;

FUNCTION list_user_activities RETURN activities_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_activities activities_tt := activities_tt ();
    
BEGIN

    -- set headers
    msgraph_utils.set_authorization_header;

    -- generate request URL
    v_request_url := gc_user_activities_url;

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

        v_activities.extend;
        v_activities (nI) := json_object_to_activity ( v_value );

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

END msgraph_sdk;

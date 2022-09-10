set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_sdk AS

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

FUNCTION json_object_to_user ( p_json IN JSON_OBJECT_T ) RETURN user_rt IS

    v_user user_rt;

BEGIN

    v_user.business_phones := json_array_to_csv ( p_json.get_array ( 'businessPhones' ));
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

FUNCTION json_object_to_contact ( p_json IN JSON_OBJECT_T ) RETURN contact_rt IS

    v_contact contact_rt;
    v_email JSON_OBJECT_T;

BEGIN

    v_contact.id := p_json.get_string ( 'id' );
    v_contact.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_contact.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );
    v_contact.categories := json_array_to_csv ( p_json.get_array ( 'categories' ));
    v_contact.parent_folder_id := p_json.get_string ( 'parentFolderId' );
    v_contact.birthday := p_json.get_date ( 'birthday' );
    v_contact.file_as := p_json.get_string ( 'fileAs' );
    v_contact.display_name := p_json.get_string ( 'displayName' );
    v_contact.given_name := p_json.get_string ( 'givenName' );
    v_contact.nick_name := p_json.get_string ( 'nickName' );
    v_contact.surname := p_json.get_string ( 'surname' );
    v_contact.title := p_json.get_string ( 'title' );
    v_contact.im_addresses := json_array_to_csv ( p_json.get_array ( 'imAddresses' ));
    v_contact.job_title := p_json.get_string ( 'jobTitle' );
    v_contact.company_name := p_json.get_string ( 'companyName' );
    v_contact.department := p_json.get_string ( 'department' );
    v_contact.office_location := p_json.get_string ( 'officeLocation' );
    v_contact.business_home_page := p_json.get_string ( 'businessHomePage' );
    v_contact.home_phones := json_array_to_csv ( p_json.get_array ( 'homePhones' ));
    v_contact.mobile_phone := p_json.get_string ( 'mobilePhone' );
    v_contact.business_phones := json_array_to_csv ( p_json.get_array ( 'businessPhones' ));
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

FUNCTION json_object_to_event ( p_json IN JSON_OBJECT_T ) RETURN event_rt IS

    v_event event_rt;

BEGIN

    v_event.id := p_json.get_string ( 'id' );
    v_event.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_event.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );
    v_event.categories := json_array_to_csv ( p_json.get_array ( 'categories' ));        
    v_event.original_start_time_zone := p_json.get_string ( 'originalStartTimeZone' );
    v_event.original_end_time_zone := p_json.get_string ( 'originalEndTimeZone' );
    v_event.reminder_minutes_before_start := p_json.get_number ( 'reminderMinutesBeforeStart' );
    v_event.is_reminder_on := p_json.get_string ( 'isReminderOn' );
    v_event.has_attachments := p_json.get_string ( 'hasAttachments' );
    v_event.subject := p_json.get_string ( 'subject' );
    v_event.body_preview := p_json.get_string ( 'bodyPreview' );
    v_event.importance := p_json.get_string ( 'importance' );
    v_event.sensitivity := p_json.get_string ( 'sensitivity' );
    v_event.is_all_day := p_json.get_string ( 'isAllDay' );
    v_event.is_cancelled := p_json.get_string ( 'isCancelled' );
    v_event.is_organizer := p_json.get_string ( 'isOrganizer' );
    v_event.response_requested := p_json.get_string ( 'responseRequested' );
    v_event.series_master_id := p_json.get_string ( 'seriesMasterId' );
    v_event.show_as := p_json.get_string ( 'showAs' );
    v_event.type := p_json.get_string ( 'type' );
    v_event.web_link := p_json.get_string ( 'webLink' );
    v_event.online_meeting_url := p_json.get_string ( 'onlineMeetingUrl' );
    v_event.is_online_meeting := p_json.get_string ( 'isOnlineMeeting' );
    v_event.online_meeting_provider := p_json.get_string ( 'onlineMeetingProvider' );
    v_event.allow_new_time_proposals := p_json.get_string ( 'allowNewTimeProposals' );
    v_event.recurrence := p_json.get_string ( 'recurrence' );
    v_event.response_status_response := p_json.get_object ( 'responseStatus' ).get_string ( 'response' );
    v_event.response_status_time := p_json.get_object ( 'responseStatus' ).get_date ( 'time' );
    v_event.body_content_type := p_json.get_object ( 'body' ).get_string ( 'contentType' );
    v_event.body_content := p_json.get_object ( 'body' ).get_clob ( 'content' );
    v_event.start_date_time := p_json.get_object ( 'start' ).get_date ( 'dateTime' );
    v_event.start_time_zone := p_json.get_object ( 'start' ).get_string ( 'timeZone' );
    v_event.end_date_time := p_json.get_object ( 'end' ).get_date (  'dateTime' );
    v_event.end_time_zone := p_json.get_object ( 'end' ).get_string ( 'dateTimeZone' );
    v_event.location_display_name := p_json.get_object ( 'location' ).get_string ( 'displayName' );
    v_event.location_location_type := p_json.get_object ( 'location' ).get_string ( 'locationType' );
    v_event.location_unique_id := p_json.get_object ( 'location' ).get_string ( 'uniqueId' );
    v_event.location_unique_id_type := p_json.get_object ( 'location' ).get_string ( 'uniqueIdType' );
    v_event.organizer_email_address_name := p_json.get_object ( 'organizer' ).get_object ( 'emailAddress' ).get_string ( 'name' );
    v_event.organizer_email_address_address := p_json.get_object ( 'organizer' ).get_object ( 'emailAddress' ).get_string ( 'address' );

    IF NOT p_json.get ( 'onlineMeeting' ).is_null THEN 
        v_event.online_meeting_join_url := p_json.get_object ( 'onlineMeeting' ).get_string ( 'joinUrl' );
    END IF;
    
    RETURN v_event;

END;

FUNCTION json_object_to_attendee ( p_json JSON_OBJECT_T ) RETURN attendee_rt IS

    v_attendee attendee_rt;

BEGIN

    v_attendee.type := p_json.get_string ( 'type' );
    v_attendee.status_response := p_json.get_object ( 'status' ).get_string ( 'response' );
    v_attendee.status_time := p_json.get_object ( 'status' ).get_date ( 'time' ); 
    v_attendee.email_address_name := p_json.get_object ( 'emailAddress' ).get_string ( 'name' );
    v_attendee.email_address_address := p_json.get_object ( 'emailAddress' ).get_string ( 'address' );

    RETURN v_attendee;

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
    v_group.resource_provisioning_options := json_array_to_csv ( p_json.get_array( 'resourceProvisioningOptions'));

    RETURN v_group;

END;

FUNCTION json_object_to_channel ( p_json JSON_OBJECT_T ) RETURN channel_rt IS

    v_channel channel_rt;

BEGIN

    v_channel.description := p_json.get_string ( 'description' );
    v_channel.display_name := p_json.get_string ( 'displayName' );
    v_channel.id := p_json.get_string ( 'id' );

    RETURN v_channel;

END;

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

FUNCTION json_object_to_plan ( p_json JSON_OBJECT_T ) RETURN plan_rt IS

    v_plan plan_rt;

BEGIN

    v_plan.id := p_json.get_string ( 'id' );
    v_plan.title := p_json.get_string ( 'title' );
    v_plan.owner := p_json.get_string ( 'owner' );

    RETURN v_plan;

END;

FUNCTION json_object_to_bucket ( p_json JSON_OBJECT_T ) RETURN plan_bucket_rt IS

    v_plan_bucket plan_bucket_rt;

BEGIN

    v_plan_bucket.id := p_json.get_string ( 'id' );
    v_plan_bucket.plan_id := p_json.get_string ( 'planId' );
    v_plan_bucket.name := p_json.get_string ( 'name' );
    v_plan_bucket.order_hint := p_json.get_string ( 'orderHint' );

    RETURN v_plan_bucket;

END;

FUNCTION json_object_to_plan_task ( p_json JSON_OBJECT_T ) RETURN plan_task_rt IS

    v_plan_task plan_task_rt;

BEGIN

    v_plan_task.id := p_json.get_string ( 'id' );
    v_plan_task.plan_id := p_json.get_string ( 'planId' );
    v_plan_task.bucket_id := p_json.get_string ( 'bucketId' );
    v_plan_task.title := p_json.get_string ( 'title' );
    v_plan_task.order_hint := p_json.get_string ( 'orderHint' );
    v_plan_task.percent_complete := p_json.get_number ( 'percentComplete' );
    v_plan_task.start_date_time := p_json.get_date ( 'startDateTime' );
    v_plan_task.due_date_time := p_json.get_date ( 'dueDateTime' );
    v_plan_task.has_description := p_json.get_string ( 'hasDescription' );
    v_plan_task.preview_type := p_json.get_string ( 'previewType' );
    v_plan_task.completed_date_time := p_json.get_date ( 'completedDateTime' );
    v_plan_task.completed_by := p_json.get_string ( 'completedBy' );
    v_plan_task.reference_count := p_json.get_number ( 'referenceCount' );
    v_plan_task.checklist_item_count := p_json.get_number ( 'checklistItemCount' );
    v_plan_task.active_checklist_item_count := p_json.get_number ( 'activeChecklistItemCount' );
    v_plan_task.converation_thread_id := p_json.get_string ( 'conversationThreadId' );

    RETURN v_plan_task;

END;

FUNCTION json_object_to_todo_task ( p_json JSON_OBJECT_T ) RETURN todo_task_rt IS

    v_todo_task todo_task_rt;

BEGIN

    v_todo_task.id := p_json.get_string ( 'id' );
    v_todo_task.importance := p_json.get_string ( 'importance' );
    v_todo_task.is_reminder_on := p_json.get_string ( 'isReminderOn' );
    v_todo_task.status := p_json.get_string ( 'status' );
    v_todo_task.title := p_json.get_string ( 'title' );
    v_todo_task.body_content := p_json.get_object ( 'body' ).get_string ( 'content' );
    v_todo_task.body_content_type := p_json.get_object ( 'body' ).get_string ( 'contentType' );
    v_todo_task.due_date_time := p_json.get_object ( 'dueDateTime' ).get_string ( 'dateTime' );
    v_todo_task.due_time_zone := p_json.get_object ( 'dueDateTime' ).get_string ( 'timeZone' );
    v_todo_task.reminder_date_time := p_json.get_object ( 'reminderDateTime' ).get_string ( 'dateTime' );
    v_todo_task.reminder_time_zone := p_json.get_object ( 'reminderDateTime' ).get_string ( 'timeZone' );

    RETURN v_todo_task;

END;


FUNCTION json_object_to_todo_list ( p_json JSON_OBJECT_T ) RETURN todo_list_rt IS

    v_todo_list todo_list_rt;

BEGIN

    v_todo_list.id := p_json.get_string ( 'id' );
    v_todo_list.display_name := p_json.get_string ( 'display_name' );

    RETURN v_todo_list;

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
    v_json.put ( 'homePhones', csv_to_json_array ( p_contact.home_phones ));
    v_json.put ( 'businessPhones', csv_to_json_array ( p_contact.business_phones ));

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

FUNCTION event_to_json_object ( p_event IN contact_rt, p_attendees IN attendees_tt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_array JSON_ARRAY_T;
    v_object JSON_OBJECT_T;

BEGIN

    v_json.put ( 'subject', p_event.subject );

    v_object := JSON_OBJECT_T ();
    v_json.put ( 'contentType', p_event.body_content_type );
    v_json.put ( 'content', p_event.body_content );
    v_json.put ( 'body', v_object );

    v_object := JSON_OBJECT_T ();
    v_json.put ( 'dateTime', p_event.start_date_time );
    v_json.put ( 'timeZone', p_event.start_time_zone );
    v_json.put ( 'start', v_object );

    v_object := JSON_OBJECT_T ();
    v_json.put ( 'dateTime', p_event.start_date_time );
    v_json.put ( 'timeZone', p_event.start_time_zone );
    v_json.put ( 'end', v_object );

    v_json.put ( 'reminderMinutesBeforeStart', p_event.reminder_minutes_before_start );
    v_json.put ( 'isReminderOn', p_event.is_reminder_on );
    v_json.put ( 'importance', p_event.importance );
    v_json.put ( 'sensitivity', p_event.sensitivity ); 
    v_json.put ( 'showAs', p_event.show_as );

    v_object := JSON_OBJECT_T ();
    v_json.put ( 'displayName', p_event.location_display_name );
    v_json.put ( 'location', v_object );
    
    -- add attendees    
    FOR nI IN p_attendees.FIRST .. p_attendees.LAST LOOP
        v_attendee := JSON_OBJECT_T ();
        v_json.put ( 'type', p_attendees (nI).type );

        v_object := JSON_OBJECT_T ();
        v_json.put ( 'name', p_attendees (nI).email_address_name );
        v_json.put ( 'address', p_attendees (nI).email_address_address );
        v_attendee.put ( 'emailAddress', v_object );
        v_array.append ( v_attendee );

    END LOOP;

    v_json.put ( 'attendees', v_array );

    RETURN v_json;

END;

PROCEDURE check_response_error ( p_response IN CLOB ) IS

    v_json JSON_OBJECT_T;

BEGIN

    v_json := JSON_OBJECT_T.parse( p_response );

    IF v_json.has ( gc_error_json_path ) THEN

        dbms_output.put_line(p_response);
        raise_application_error ( -20001, v_json.get_string ( gc_error_json_path ) );
        
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
                                                           p_body => 'client_id=' || gc_client_id || 
                                                                     '&client_secret=' || gc_client_secret || 
                                                                     '&scope=https://graph.microsoft.com/.default' ||
                                                                     '&grant_type=client_credentials',
                                                           p_wallet_path => gc_wallet_path,
                                                           p_wallet_pwd => gc_wallet_pwd );

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

FUNCTION get_access_token ( p_username IN VARCHAR2, p_password IN VARCHAR2, p_scope IN VARCHAR2 ) RETURN CLOB IS

    v_response CLOB;
    v_expires_in INTEGER;
    v_json JSON_OBJECT_T;

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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

    -- set global variables
    gv_access_token := v_json.get_string ( 'access_token' );
    
    v_expires_in := v_json.get_number ( 'expires_in' );
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
    v_json JSON_OBJECT_T;

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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

    -- populate user record
    v_user := json_object_to_user ( v_json );

    RETURN v_user;

END get_user;

FUNCTION list_users RETURN users_tt IS

    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_users users_tt := users_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => gc_users_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_users.extend;
        v_users (nI) := json_object_to_user ( v_value );

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
    v_json JSON_OBJECT_T;
    v_email JSON_OBJECT_T;

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

    -- check if error occurred
    check_response_error ( p_response => v_response );

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
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request := contact_to_json_object ( p_contact );

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
    
    -- check if error occurred
    check_response_error ( p_response => v_response );

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
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_contact.id;
    
    -- generate request
    v_request := contact_to_json_object ( p_contact );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'PATCH',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- check if error occurred
    check_response_error ( p_response => v_response ); 

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );  

END update_user_contact;

PROCEDURE delete_user_contact ( p_user_principal_name IN VARCHAR2, p_contact_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;

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

    -- check if error occurred
    check_response_error ( p_response => v_response ); 

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
    set_authorization_header;
   
    -- generate request URL
    v_request_url := REPLACE( gc_user_contacts_url, gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );
   
    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

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

FUNCTION get_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN event_rt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

    -- populate event record
    v_event := json_object_to_event ( v_json );

    RETURN v_event;

END get_user_calendar_event;

FUNCTION create_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request := event_to_json_object ( p_event, p_attendees );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
    
    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

    RETURN v_json.get_string ( 'id' );

END create_user_calendar_event;

PROCEDURE update_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;
    
BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event.id;
    
    -- generate request
    v_request := event_to_json_object ( p_event, p_attendees );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'PATCH',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- check if error occurred
    check_response_error ( p_response => v_response );
    
    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

END update_user_calendar_event;

PROCEDURE delete_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;

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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

END delete_user_calendar_event;

FUNCTION list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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
    
    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_events.extend;
        v_events (nI) := json_object_to_event ( v_value );

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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response ); 

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( 'attendees' );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_attendees.extend;
        v_attendees (nI) := json_object_to_attendee ( v_value );

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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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
    
    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_users.extend;
        v_users (nI) := json_object_to_user ( v_value );

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
    v_json JSON_OBJECT_T;

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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    
    -- populate user record
    v_user := json_object_to_user ( v_json );

    RETURN v_user;
    
END get_user_manager;

FUNCTION list_groups RETURN groups_tt IS

    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_groups groups_tt := groups_tt ();
    
BEGIN

    -- set headers
    set_authorization_header;

    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => gc_groups_url,
                                                       p_http_method => 'GET',
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_groups.extend;
        v_groups (nI) := json_object_to_group ( v_value );

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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response ); 

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_users.extend;
        v_users (nI) := json_object_to_user ( v_value );

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
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response CLOB;
    v_json JSON_OBJECT_T;
    
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
    v_request.put ( '@odata.id', 'https://graph.microsoft.com/v1.0/directoryObjects/'|| v_user.id );
    
    -- make request
    v_response := apex_web_service.make_rest_request ( p_url => v_request_url,
                                                       p_http_method => 'POST',
                                                       p_body => v_request.to_clob,
                                                       p_wallet_path => gc_wallet_path,
                                                       p_wallet_pwd => gc_wallet_pwd );

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );

END add_group_member;

PROCEDURE remove_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

    v_response CLOB;
    v_json JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    
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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );

        v_channels.extend;
        v_channels (nI) := json_object_to_channel ( v_value );

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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

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

FUNCTION list_group_plans ( p_group_id VARCHAR2 ) RETURN plans_tt IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );   

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_plans.extend;
        v_plans (nI) := json_object_to_plan ( v_value );

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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_buckets.extend;
        v_buckets (nI) := json_object_to_bucket ( v_value );

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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );   
        
    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_tasks.extend;
        v_tasks (nI) := json_object_to_plan_task ( v_value );

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
    v_json JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
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

    -- check if error occurred
    check_response_error ( p_response => v_response );

    -- parse response
    v_json := JSON_OBJECT_T.parse ( v_response );
    v_values := v_json.get_array ( gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_lists.extend;
        v_lists (nI) := json_object_to_todo_list ( v_value );

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

FUNCTION create_todo_list_task ( p_list_id IN VARCHAR2, p_task IN todo_task_rt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

    v_id VARCHAR2 (2000);

BEGIN

    -- set headers
    set_authorization_header;
    set_content_type_header;
    
    -- generate request URL
    v_request_url := REPLACE ( gc_todo_list_tasks_url, '{id}', p_list_id );
    
    -- generate request
    apex_json.initialize_clob_output;

    apex_json.open_object;
    apex_json.write ( 'importance', p_task.importance );
    apex_json.write ( 'isReminderOn', p_task.is_reminder_on );
    apex_json.write ( 'status', p_task.status );
    apex_json.write ( 'title', p_task.title );
    apex_json.open_object ( 'body' );
    apex_json.write ( 'content', p_task.body_content );
    apex_json.write ( 'contentType', p_task.body_content_type );
    apex_json.close_object;
    
    IF p_task.due_date_time IS NOT NULL THEN
        apex_json.open_object ( 'dueDateTime' );
        apex_json.write ( 'dateTime', p_task.due_date_time );
        apex_json.write ( 'timeZone', p_task.due_time_zone );
        apex_json.close_object;
    END IF;
    
    IF p_task.is_reminder_on = 'true' THEN
        apex_json.open_object ( 'reminderDateTime' );
        apex_json.write ( 'dateTime', p_task.due_date_time );
        apex_json.write ( 'timeZone', p_task.due_time_zone );
        apex_json.close_object;
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
    
    v_id := apex_json.get_varchar2 ( p_path => 'id' );                                                                                          
    
    RETURN v_id;
    
END create_todo_list_task;

END msgraph_sdk;

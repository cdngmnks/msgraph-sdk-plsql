CREATE OR REPLACE PACKAGE BODY msgraph_calendar AS

FUNCTION json_object_to_calendar ( p_json JSON_OBJECT_T ) RETURN calendar_rt IS

    v_calendar calendar_rt;

BEGIN

    v_calendar.id := p_json.get_string ( 'id' );
    v_calendar.name := p_json.get_string ( 'name' );

    RETURN v_calendar;

END;

FUNCTION json_object_to_event ( p_json IN JSON_OBJECT_T ) RETURN event_rt IS

    v_event event_rt;

BEGIN

    v_event.id := p_json.get_string ( 'id' );
    v_event.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_event.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );
    v_event.categories := msgraph_utils.json_array_to_csv ( p_json.get_array ( 'categories' ));        
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

FUNCTION event_to_json_object ( p_event IN event_rt, p_attendees IN attendees_tt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_array JSON_ARRAY_T;
    v_object JSON_OBJECT_T;
    v_attendee JSON_OBJECT_T;

    nI PLS_INTEGER;

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
    nI := p_attendees.FIRST;
    WHILE (nI IS NOT NULL) LOOP

        v_attendee := JSON_OBJECT_T ();
        v_json.put ( 'type', p_attendees (nI).type );

        v_object := JSON_OBJECT_T ();
        v_json.put ( 'name', p_attendees (nI).email_address_name );
        v_json.put ( 'address', p_attendees (nI).email_address_address );
        v_attendee.put ( 'emailAddress', v_object );
        v_array.append ( v_attendee );

        nI := p_attendees.NEXT ( nI );

    END LOOP;

    v_json.put ( 'attendees', v_array );

    RETURN v_json;

END;

FUNCTION calendar_to_json_object ( p_calendar IN calendar_rt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    v_json.put ( 'name', p_calendar.name );

    RETURN v_json;

END;

FUNCTION get_user_calendar ( p_user_principal_name IN VARCHAR2, p_calendar_id IN VARCHAR2 ) RETURN calendar_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;
    
    v_calendar calendar_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendars_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_calendar_id;

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    -- populate event record
    v_calendar := json_object_to_calendar ( v_response );

    RETURN v_calendar;

END get_user_calendar;

FUNCTION create_user_calendar ( p_user_principal_name IN VARCHAR2, p_calendar IN calendar_rt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendars_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request := calendar_to_json_object ( p_calendar );
    
    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob);

    RETURN v_response.get_string ( 'id' );

END create_user_calendar;

PROCEDURE delete_user_calendar ( p_user_principal_name IN VARCHAR2, p_calendar_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendars_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_calendar_id;
    
    -- make request
    msgraph_utils.make_delete_request ( v_request_url );

END delete_user_calendar;

FUNCTION list_user_calendars ( p_user_principal_name IN VARCHAR2 ) RETURN calendars_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;
    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_calendars calendars_tt := calendars_tt ();

BEGIN
    
    -- generate request URL
    v_request_url := REPLACE( gc_user_calendars_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_calendars.extend;
        v_calendars (nI) := json_object_to_calendar ( v_value );

    END LOOP;
    
    RETURN v_calendars;
 
END list_user_calendars;

FUNCTION pipe_list_user_calendars ( p_user_principal_name IN VARCHAR2 ) RETURN calendars_tt PIPELINED IS

    v_calendars calendars_tt;

    nI PLS_INTEGER;

BEGIN

    v_calendars := list_user_calendars ( p_user_principal_name );

    nI := v_calendars.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_calendars (nI) );

        nI := v_calendars.NEXT ( nI );

    END LOOP;

END pipe_list_user_calendars;

FUNCTION get_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN event_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;
    
    v_event event_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event_id;
    
    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    -- populate event record
    v_event := json_object_to_event ( v_response );

    RETURN v_event;

END get_user_calendar_event;

FUNCTION create_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request := event_to_json_object ( p_event, p_attendees );
    
    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

    RETURN v_response.get_string ( 'id' );

END create_user_calendar_event;

PROCEDURE update_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event.id;
    
    -- generate request
    v_request := event_to_json_object ( p_event, p_attendees );
    
    -- make request
    v_response := msgraph_utils.make_patch_request ( v_request_url,
                                                     v_request.to_clob );

END update_user_calendar_event;

PROCEDURE delete_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event_id;
    
    -- make request
    msgraph_utils.make_delete_request ( v_request_url );

END delete_user_calendar_event;

FUNCTION list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_events events_tt := events_tt ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_events.extend;
        v_events (nI) := json_object_to_event ( v_value );

    END LOOP;

    RETURN v_events;
 
END list_user_calendar_events;

FUNCTION pipe_list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt PIPELINED IS

    v_events events_tt;

    nI PLS_INTEGER;

BEGIN

    v_events := list_user_calendar_events ( p_user_principal_name );

    nI := v_events.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_events (nI) );

        nI := v_events.NEXT ( nI );

    END LOOP;

END pipe_list_user_calendar_events;

FUNCTION list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_attendees attendees_tt := attendees_tt ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_calendar_events_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name ) || '/' || p_event_id;
    
    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( 'attendees' );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_attendees.extend;
        v_attendees (nI) := json_object_to_attendee ( v_value );

    END LOOP;
    
    RETURN v_attendees;

END list_user_calendar_event_attendees;

FUNCTION pipe_list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt PIPELINED IS

    v_attendees attendees_tt;

    nI PLS_INTEGER;

BEGIN

    v_attendees := list_user_calendar_event_attendees ( p_user_principal_name, p_event_id );

    nI := v_attendees.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_attendees (nI) );

        nI := v_attendees.NEXT ( nI );

    END LOOP;

END pipe_list_user_calendar_event_attendees;

END msgraph_calendar;

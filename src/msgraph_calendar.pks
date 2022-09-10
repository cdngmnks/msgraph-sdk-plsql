CREATE OR REPLACE PACKAGE msgraph_calendar AS

    -- endpoint urls
    gc_user_calendar_events_url CONSTANT VARCHAR2 (74) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/calendar/events';

    -- type definitions
    TYPE event_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE,
        categories VARCHAR2 (2000),
        original_start_time_zone VARCHAR2 (2000),
        original_end_time_zone VARCHAR2 (2000),
        reminder_minutes_before_start INTEGER,
        is_reminder_on VARCHAR2(5),
        has_attachments VARCHAR2(5),
        subject VARCHAR2 (2000),
        body_preview VARCHAR2 (2000),
        importance VARCHAR2 (2000),
        sensitivity VARCHAR2 (2000),
        is_all_day VARCHAR2(5),
        is_cancelled VARCHAR2(5),
        is_organizer VARCHAR2(5),
        response_requested VARCHAR2(5),
        series_master_id VARCHAR2 (2000),
        show_as VARCHAR2 (2000),
        type VARCHAR2 (2000),
        web_link VARCHAR2 (2000),
        online_meeting_url VARCHAR2 (2000),
        is_online_meeting VARCHAR2(5),
        online_meeting_provider VARCHAR2 (2000),
        allow_new_time_proposals VARCHAR2(5),
        recurrence VARCHAR2 (2000),
        response_status_response VARCHAR2 (2000),
        response_status_time DATE,
        body_content_type VARCHAR2 (2000),
        body_content CLOB,
        start_date_time DATE,
        start_time_zone VARCHAR2 (2000),
        end_date_time DATE,
        end_time_zone VARCHAR2 (2000),
        location_display_name VARCHAR2 (2000),
        location_location_type VARCHAR2 (2000),
        location_unique_id VARCHAR2 (2000),
        location_unique_id_type VARCHAR2 (2000),
        organizer_email_address_name VARCHAR2 (2000),
        organizer_email_address_address VARCHAR2 (2000),
        online_meeting_join_url VARCHAR2 (2000)
    );
    
    TYPE events_tt IS TABLE OF event_rt;
    
    TYPE attendee_rt IS RECORD (
        type VARCHAR2 (2000),
        status_response VARCHAR2 (2000),
        status_time DATE,
        email_address_name VARCHAR2 (2000),
        email_address_address VARCHAR2 (2000)
    );
    
    TYPE attendees_tt IS TABLE OF attendee_rt;

    -- calendar events
    FUNCTION get_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN event_rt;
    FUNCTION create_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt ) RETURN VARCHAR2;
    PROCEDURE update_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event IN event_rt, p_attendees IN attendees_tt );
    PROCEDURE delete_user_calendar_event ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 );
    FUNCTION list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt;
    FUNCTION pipe_list_user_calendar_events ( p_user_principal_name IN VARCHAR2 ) RETURN events_tt PIPELINED;
    FUNCTION list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt;
    FUNCTION pipe_list_user_calendar_event_attendees ( p_user_principal_name IN VARCHAR2, p_event_id IN VARCHAR2 ) RETURN attendees_tt PIPELINED;

END msgraph_calendar;
/

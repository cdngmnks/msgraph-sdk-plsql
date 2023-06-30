set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_sharepoint AS

FUNCTION json_object_to_site ( p_json IN JSON_OBJECT_T ) RETURN site_rt IS

    v_site site_rt;

BEGIN

    v_site.id := p_json.get_string ( 'id' );
    v_site.name := p_json.get_string ( 'name' );
    v_site.display_name := p_json.get_string ( 'displayName' );
    v_site.web_url := p_json.get_string ( 'webUrl' );
    v_site.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_site.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );

    RETURN v_site;

END json_object_to_site;

FUNCTION json_object_to_list ( p_json IN JSON_OBJECT_T ) RETURN list_rt IS

    v_list list_rt;

BEGIN

    v_list.id := p_json.get_string ( 'id' );
    v_list.name := p_json.get_string ( 'name' );
    v_list.display_name := p_json.get_string ( 'displayName' );
    v_list.web_url := p_json.get_string ( 'webUrl' );
    v_list.list_template := p_json.get_string ( 'list.template' );
    v_list.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_list.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );

    RETURN v_list;

END json_object_to_list;

FUNCTION list_sites RETURN sites_tt IS

    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_sites sites_tt := sites_tt ();
    
BEGIN

    -- make request
    v_response := msgraph_utils.make_get_request ( gc_sites_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_sites.extend;
        v_sites (nI) := json_object_to_site ( v_value );

    END LOOP;

    RETURN v_sites;

END list_sites;

FUNCTION pipe_list_sites RETURN sites_tt PIPELINED IS

    v_sites sites_tt;

    nI PLS_INTEGER;

BEGIN

    v_sites := list_sites;

    nI := v_sites.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_sites (nI) );

        nI := v_sites.NEXT ( nI );

    END LOOP;

END pipe_list_sites;

FUNCTION list_site_lists ( p_site_id IN VARCHAR2 ) RETURN lists_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_lists lists_tt := lists_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_site_lists_url, '{id}', p_site_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_lists.extend;
        v_lists (nI) := json_object_to_list ( v_value );

    END LOOP;
    
    RETURN v_lists;

END list_site_lists;

FUNCTION pipe_list_site_lists ( p_site_id IN VARCHAR2 ) RETURN lists_tt PIPELINED IS

    v_lists lists_tt;

    nI PLS_INTEGER;

BEGIN

    v_lists := list_site_lists ( p_site_id );

    nI := v_lists.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_lists (nI) );

        nI := v_lists.NEXT ( nI );

    END LOOP;

END pipe_list_site_lists;

END msgraph_sharepoint;

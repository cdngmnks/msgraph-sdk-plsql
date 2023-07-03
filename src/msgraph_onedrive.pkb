set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_sharepoint AS

FUNCTION json_object_to_drive ( p_json IN JSON_OBJECT_T ) RETURN drive_rt IS

    v_drive drive_rt;

BEGIN

    v_drive.id := p_json.get_string ( 'id' );
    v_drive.name := p_json.get_string ( 'name' );
    v_drive.display_name := p_json.get_string ( 'displayName' );
    v_drive.web_url := p_json.get_string ( 'webUrl' );
    v_drive.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_drive.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );

    RETURN v_drive;

END json_object_to_drive;

FUNCTION json_object_to_item ( p_json IN JSON_OBJECT_T ) RETURN item_rt IS

    v_item item_rt;

BEGIN

    v_item.id := p_json.get_string ( 'id' );
    v_item.name := p_json.get_string ( 'name' );
    v_item.web_url := p_json.get_string ( 'webUrl' );
    v_item.size := p_json.get_number ( 'size' );
    v_item.item_type
    v_item.folder_child_count := p_json.get_object ( 'folder' ).get_number ( 'childCount' );
    v_item.file_mime_type := p_json.get_object ( 'file' ).get_string ( 'mimeType' );
    v_item.created_by_user_email := p_json.get_object ( 'createdBy' ).get_object ( 'user' ).get_string ( 'email' );
    v_item.last_modified_by_user_email := p_json.get_object ( 'lastModifiedBy' ).get_object ( 'user' ).get_string ( 'email' );
    v_item.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_item.last_modified_date_time := p_json.get_date ( 'lastModifiedDateTime' );

    RETURN v_item;

END json_object_to_item;

FUNCTION item_to_json_object ( p_item IN item_rt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_object JSON_OBJECT_T;

BEGIN

    v_json.put ( 'name', p_folder.name );

    IF p_item.item_type = 'folder' THEN
        -- add empty folder facet
        v_object := JSON_OBJECT_T ();
        v_json.put ( 'folder', v_object );
    END IF;

    RETURN v_json;

END;

FUNCTION get_site_drive ( p_site_id IN VARCHAR2 ) RETURN drive_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_drive drive_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_site_drive_url, '{id}', p_site_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_drive := json_object_to_drive ( v_response );

    RETURN v_drive;

END get_site_drive;

FUNCTION get_group_drive ( p_group_id IN VARCHAR2 ) RETURN drive_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_drive drive_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_group_drive_url, '{id}', p_group_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_drive := json_object_to_drive ( v_response );

    RETURN v_drive;

END get_group_drive;

FUNCTION list_folder_children ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2 ) RETURN items_tt IS

    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_items items_tt := items_tt ();
    
BEGIN

    -- generate request URL
    v_request_url := REPLACE ( gc_drive_item_children_url, '{id}', p_drive_id ) || '/' || p_parent_item_id || '/children';

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_items.extend;
        v_items (nI) := json_object_to_item ( v_value );

    END LOOP;

    RETURN v_items;

END list_folder_children;

FUNCTION pipe_list_folder_children ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2 ) RETURN items_tt PIPELINED IS

    v_items items_tt;

    nI PLS_INTEGER;

BEGIN

    v_items := list_folder_children ( p_drive_id, p_parent_item_id );

    nI := v_items.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_items (nI) );

        nI := v_items.NEXT ( nI );

    END LOOP;

END pipe_list_folder_children;

FUNCTION create_folder ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_folder_name IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    v_request_url := REPLACE ( gc_drive_item_url, '{id}', p_drive_id ) || '/' || p_parent_item_id || '/children';

    -- generate request
    v_request.put ( 'name', p_folder_name );
    v_request.put ( 'folder', JSON_OBJECT_T () );

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );
    
    RETURN v_response.get_string ( 'id' );

END create_folder;

FUNCTION copy_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2, p_new_parent_item_id IN VARCHAR2, p_new_name IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_object JSON_OBJECT_T := JSON_OBJECT_T ();
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    v_request_url := REPLACE ( gc_drive_item_url, '{id}', p_drive_id ) || '/' || p_parent_item_id || '/copy';

    -- generate request
    v_object.put ( 'driveId', p_drive_id );
    v_object.put ( 'id', p_new_parent_item_id );
    v_request.put ( 'parentReference', v_object );
    v_request.put := ('name', p_new_name);

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

    RETURN v_response.get_string ( 'id' );

END copy_item;

PROCEDURE rename_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2, p_new_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_item item_rt;
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_item_id;

    -- generate request
    v_request.put := ('name', p_new_name);

    -- make request
    v_response := msgraph_utils.make_patch_request ( v_request_url,
                                                     v_request.to_clob );

    RETURN v_response.get_string ( 'id' );

END rename_item;

PROCEDURE delete_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_item_id;

    -- make request
    v_response := msgraph_utils.make_delete_request ( v_request_url );

END delete_item;

END msgraph_sharepoint;

set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_onedrive AS

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
    v_item.item_size := p_json.get_number ( 'size' );

    IF p_json.has ( 'folder' ) THEN
        v_item.item_type := 'folder';
        v_item.folder_child_count := p_json.get_object ( 'folder' ).get_number ( 'childCount' );
    ELSIF p_json.has ( 'file' ) THEN
        v_item.item_type := 'file';
        v_item.file_mime_type := p_json.get_object ( 'file' ).get_string ( 'mimeType' );
    END IF;
    
    v_item.created_by_user_email := p_json.get_object ( 'createdBy' ).get_object ( 'user' ).get_string ( 'email' );
    v_item.last_modified_by_user_email := p_json.get_object ( 'lastModifiedBy' ).get_object ( 'user' ).get_string ( 'email' );
    v_item.created_date_time := p_json.get_date ( 'createdDateTime' );
    v_item.last_modified_date_time :=  p_json.get_date ('lastModifiedDateTime' );

    IF p_json.has ( 'parentReference' ) THEN
        v_item.parent_item_id := p_json.get_object ( 'parentReference' ).get_string ( 'id' );
    END IF;
    
    RETURN v_item;

END json_object_to_item;

FUNCTION item_to_json_object ( p_item IN item_rt ) RETURN JSON_OBJECT_T IS

    v_json JSON_OBJECT_T := JSON_OBJECT_T ();
    v_object JSON_OBJECT_T;

BEGIN

    v_json.put ( 'name', p_item.name );

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

FUNCTION get_user_drive ( p_user_id IN VARCHAR2 ) RETURN drive_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_drive drive_rt;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_drive_url, '{id}', p_user_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_drive := json_object_to_drive ( v_response );

    RETURN v_drive;

END get_user_drive;

FUNCTION list_folder_children ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_include_parent IN VARCHAR2 DEFAULT 'N', p_recursive IN VARCHAR2 DEFAULT 'N' ) RETURN items_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_items items_tt := items_tt ();
    v_child_items items_tt := items_tt ();
    
BEGIN

    -- add parent folder
    IF p_parent_item_id != 'root' AND p_include_parent = 'Y' THEN
        -- generate request URL for parent folder
        v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_parent_item_id ;
    
        -- make request
        v_response := msgraph_utils.make_get_request ( v_request_url );
    
        v_value := TREAT ( v_response AS JSON_OBJECT_T );
    
        v_items.extend;
        v_items (1) := json_object_to_item ( v_value );

    END IF;

    -- add child items
    -- generate request URL
    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_parent_item_id || '/children';
    
    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );
    
    FOR nI IN 1 .. v_values.get_size LOOP

        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_items.extend;
        v_items ( v_items.count ) := json_object_to_item ( v_value );

        IF p_recursive = 'Y' AND v_items ( v_items.count ).folder_child_count > 0 THEN

            v_child_items := list_folder_children ( p_drive_id => p_drive_id, p_parent_item_id => v_items ( v_items.count ).id, p_include_parent => 'N', p_recursive => 'Y' );

            FOR nII IN 1 .. v_child_items.count LOOP
                v_items.extend;
                v_items ( v_items.count ) := v_child_items ( nII );
            END LOOP;

        END IF;
        
    END LOOP;

    RETURN v_items;

END list_folder_children;

FUNCTION pipe_list_folder_children ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_include_parent IN VARCHAR2 DEFAULT 'N', p_recursive IN VARCHAR2 DEFAULT 'N' ) RETURN items_tt PIPELINED IS

    v_items items_tt;

    nI PLS_INTEGER;

BEGIN

    v_items := list_folder_children ( p_drive_id, p_parent_item_id, p_include_parent, p_recursive );

    nI := v_items.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_items (nI) );

        nI := v_items.NEXT ( nI );

    END LOOP;

END pipe_list_folder_children;

FUNCTION create_folder ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_folder_name IN VARCHAR2, p_description IN VARCHAR2 DEFAULT NULL ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_parent_item_id || '/children';

    -- generate request
    v_request.put ( 'name', p_folder_name );
    v_request.put ( 'folder', JSON_OBJECT_T () );
    v_request.put ( 'description', p_description );

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );
    
    RETURN v_response.get_string ( 'id' );

END create_folder;

FUNCTION copy_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2, p_new_parent_item_id IN VARCHAR2, p_new_item_name IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_object JSON_OBJECT_T := JSON_OBJECT_T ();
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();
    v_response JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_new_parent_item_id || '/copy';

    -- generate request
    v_object.put ( 'driveId', p_drive_id );
    v_object.put ( 'id', p_new_parent_item_id );
    v_request.put ( 'parentReference', v_object );
    v_request.put ('name', p_new_item_name);

    -- make request
    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

    RETURN v_response.get_string ( 'id' );

END copy_item;

PROCEDURE rename_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2, p_new_item_name IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);
    v_item item_rt;
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_item_id;

    -- generate request
    v_request.put ('name', p_new_item_name);

    -- make request
    msgraph_utils.make_patch_request ( v_request_url,
                                       v_request.to_clob );

END rename_item;

PROCEDURE delete_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) IS

    v_request_url VARCHAR2 (255);

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_item_id;

    -- make request
    msgraph_utils.make_delete_request ( v_request_url );

END delete_item;

FUNCTION get_item ( p_drive_id IN VARCHAR2, p_item_path IN VARCHAR2 ) RETURN item_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T := JSON_OBJECT_T ();
    v_item item_rt;

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/root:/' || p_item_path;

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    -- populate user record
    v_item := json_object_to_item ( v_response );

    RETURN v_item;

END get_item;

FUNCTION get_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) RETURN item_rt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T := JSON_OBJECT_T ();
    v_item item_rt;

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_item_id;

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    -- populate user record
    v_item := json_object_to_item ( v_response );

    RETURN v_item;

END get_item;

FUNCTION upload_file ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_file_name IN VARCHAR2, p_file_blob BLOB ) RETURN VARCHAR2 IS

    v_file_size INTEGER;
    v_request_url VARCHAR2 (255);
    v_upload_url VARCHAR2 (2000);
    v_response JSON_OBJECT_T := JSON_OBJECT_T ();

BEGIN

    v_file_size := dbms_lob.getlength ( p_file_blob );

    -- check if file bigger than 4 MB
    IF v_file_size < 4194304 THEN
        -- https://learn.microsoft.com/en-us/graph/api/driveitem-put-content
        v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_parent_item_id || '/' || p_file_name || '/content';

        v_response := msgraph_utils.make_put_request ( p_url => v_request_url,
                                                       p_body_blob => p_file_blob );

    ELSE
        -- https://learn.microsoft.com/en-us/graph/api/driveitem-createuploadsession
        v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_parent_item_id || '/' || p_file_name || '/createUploadSession';

        v_response := msgraph_utils.make_post_request ( p_url => v_request_url,
                                                        p_content_length => 0 );
        v_upload_url := v_response.get_string ( 'uploadUrl' );

        v_response := msgraph_utils.make_put_request ( p_url => v_upload_url,
                                                       p_body_blob => p_file_blob,
                                                       p_content_range_start => 0,
                                                       p_content_range_end => v_file_size - 1,
                                                       p_content_range_size => v_file_size );

    END IF;

    RETURN v_response.get_string ( 'id' );

END upload_file;

FUNCTION download_file ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) RETURN BLOB IS

    v_request_url VARCHAR2(255);
    v_response BLOB;

BEGIN

    v_request_url := REPLACE ( gc_drive_items_url, '{id}', p_drive_id ) || '/' || p_item_id || '/content';

    v_response := msgraph_utils.make_get_request_blob ( v_request_url );

END download_file;

END msgraph_onedrive;
/

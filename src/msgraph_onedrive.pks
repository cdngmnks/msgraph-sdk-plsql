CREATE OR REPLACE PACKAGE msgraph_onedrive AS

    -- endpoint urls
    gc_site_drive_url CONSTANT VARCHAR2 (50) := 'https://graph.microsoft.com/v1.0/sites/{id}/drive';
    gc_group_drive_url CONSTANT VARCHAR2 (50) := 'https://graph.microsoft.com/v1.0/groups/{id}/drive';
    gc_user_drive_url CONSTANT VARCHAR2 (50) := 'https://graph.microsoft.com/v1.0/users/{id}/drive';
    gc_drive_items_url CONSTANT VARCHAR2 (50) := 'https://graph.microsoft.com/v1.0/drives/{id}/items';

    -- type definitions
    TYPE drive_rt IS RECORD (
        id VARCHAR2 (2000),
        name VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        web_url VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE
    );

    TYPE drives_tt IS TABLE OF drive_rt;

    TYPE item_rt IS RECORD (
        id VARCHAR2 (2000),
        name VARCHAR2 (2000),
        web_url VARCHAR2 (2000),
        item_size NUMBER,
        item_type VARCHAR2 (2000),
        folder_child_count NUMBER,
        file_mime_type VARCHAR2 (2000),
        created_by_user_email VARCHAR2 (2000),
        last_modified_by_user_email VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE,
        parent_item_id VARCHAR2 (2000)
    );

    TYPE items_tt IS TABLE OF item_rt;

    -- drives
    FUNCTION get_site_drive ( p_site_id IN VARCHAR2 ) RETURN drive_rt;
    FUNCTION get_group_drive ( p_group_id IN VARCHAR2 ) RETURN drive_rt;
    FUNCTION get_user_drive ( p_user_id IN VARCHAR2 ) RETURN drive_rt;

    -- drive items
    FUNCTION list_folder_children ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_include_parent IN VACHAR2 DEFAULT 'N', p_recursive IN VARCHAR2 DEFAULT 'N' ) RETURN items_tt;
    FUNCTION pipe_list_folder_children ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_include_parent IN VACHAR2 DEFAULT 'N', p_recursive IN VARCHAR2 DEFAULT 'N' ) RETURN items_tt PIPELINED;

    FUNCTION create_folder ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2,  p_folder_name IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION copy_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2, p_new_parent_item_id IN VARCHAR2, p_new_item_name IN VARCHAR2 ) RETURN VARCHAR2;
    PROCEDURE rename_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2, p_new_item_name IN VARCHAR2 );
    PROCEDURE delete_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2);

    FUNCTION upload_file ( p_drive_id IN VARCHAR2, p_parent_item_id IN VARCHAR2, p_file_name IN VARCHAR2, p_file_blob IN BLOB ) RETURN VARCHAR2;
    FUNCTION download_file ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) RETURN BLOB;

END msgraph_onedrive;
/

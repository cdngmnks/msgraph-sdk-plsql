CREATE OR REPLACE PACKAGE msgraph_onedrive AS

    -- endpoint urls
    gc_site_drive_url CONSTANT VARCHAR2 (49) := 'https://graph.microsoft.com/v1.0/sites/{id}/drive';
    gc_group_drive_url CONSTANT VARCHAR2 (50) := 'https://graph.microsoft.com/v1.0/groups/{id}/drive';
    gc_drive_root_children_url CONSTANT VARCHAR2 (58) := 'https://graph.microsoft.com/v1.0/drives/{id}/root/children';
    gc_drive_item_children_url CONSTANT VARCHAR2 (68) := 'https://graph.microsoft.com/v1.0/drives/{id}/items/{itemId}/children';
    gc_drive_path_children_url CONSTANT VARCHAR2 (71) := 'https://graph.microsoft.com/v1.0/drives/{id}/root:/{itemPath}:/children';


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
        size NUMBER,
        item_type VARCHAR2 (2000),
        folder_child_count NUMBER,
        file_mime_type VARCHAR2 (2000),
        created_by_user_email VARCHAR2 (2000),
        last_modified_by_user_email VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE
    );

    TYPE items_tt IS TABLE OF item_rt;

    -- drives
    FUNCTION get_site_drive ( p_site_id IN VARCHAR2 ) RETURN drive_rt;
    FUNCTION get_group_drive ( p_group_id IN VARCHAR2 ) RETURN drive_rt;

    -- drive items
    FUNCTION list_root_children ( p_drive_id IN VARCHAR2 ) RETURN items_tt;
    FUNCTION pipe_list_root_children ( p_drive_id IN VARCHAR2 ) RETURN items_tt PIPELINED;
    FUNCTION list_item_children ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) RETURN items_tt;
    FUNCTION pipe_list_item_children ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) RETURN items_tt PIPELINED;
    FUNCTION list_path_children ( p_drive_id IN VARCHAR2, p_item_path IN VARCHAR2 ) RETURN items_tt;
    FUNCTION pipe_list_path_children ( p_drive_id IN VARCHAR2, p_item_path IN VARCHAR2 ) RETURN items_tt PIPELINED;
    FUNCTION get_drive_item ( p_drive_id IN VARCHAR2, p_item_id IN VARCHAR2 ) RETURN BLOB;

END msgraph_onedrive;
/

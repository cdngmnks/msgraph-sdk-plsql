CREATE OR REPLACE PACKAGE msgraph_sharepoint AS

    -- endpoint urls
    gc_sites_url CONSTANT VARCHAR2 (38) := 'https://graph.microsoft.com/v1.0/sites';
    gc_site_lists_url CONSTANT VARCHAR2 (49) := 'https://graph.microsoft.com/v1.0/sites/{id}/lists';

    -- type definitions
    TYPE site_rt IS RECORD (
        id VARCHAR2 (2000),
        name VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        web_url VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE
    );

    TYPE sites_tt IS TABLE OF site_rt;

    TYPE list_rt IS RECORD (
        id VARCHAR2 (2000),
        name VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        web_url VARCHAR2 (2000),
        list_template VARCHAR2 (2000),
        created_date_time DATE,
        last_modified_date_time DATE
    );

    TYPE lists_tt IS TABLE OF list_rt;

    -- sites
    FUNCTION list_sites RETURN sites_tt;
    FUNCTION pipe_list_sites RETURN sites_tt PIPELINED;

    -- site lists
    FUNCTION list_site_lists ( p_site_id IN VARCHAR2 ) RETURN lists_tt;
    FUNCTION pipe_list_site_lists ( p_site_id IN VARCHAR2 ) RETURN lists_tt PIPELINED;

END msgraph_sharepoint;
/

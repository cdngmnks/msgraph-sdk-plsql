CREATE OR REPLACE PACKAGE msgraph_onenote AS

    -- endpoint urls
    gc_user_notebooks_url CONSTANT VARCHAR2 (76) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/onenote/notebooks';
    gc_user_notebook_sections_url CONSTANT VARCHAR2 (90) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/onenote/notebooks/{id}/sections';
    gc_user_section_pages_url CONSTANT VARCHAR2 (86) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/onenote/sections/{id}/pages';
    gc_user_page_content_url CONSTANT VARCHAR2 (85) := 'https://graph.microsoft.com/v1.0/users/{userPrincipalName}/onenote/pages/{id}/content';

    -- type definitions
    TYPE notebook_rt IS RECORD (
        id VARCHAR2 (2000),
        display_name VARCHAR2 (2000)
    );
    
    TYPE notebooks_tt IS TABLE OF notebook_rt;
    
    TYPE section_rt IS RECORD (
        id VARCHAR2 (2000),
        display_name VARCHAR2 (2000)
    );
    
    TYPE sections_tt IS TABLE OF section_rt;

    TYPE page_rt IS RECORD (
        id VARCHAR2 (2000),
        title VARCHAR2 (2000)
    );
    
    TYPE pages_tt IS TABLE OF page_rt;

    -- notes
    FUNCTION list_user_notebooks ( p_user_principal_name IN VARCHAR2 ) RETURN notebooks_tt;
    FUNCTION pipe_list_user_notebooks ( p_user_principal_name IN VARCHAR2 ) RETURN notebooks_tt PIPELINED;
    FUNCTION create_user_notebook ( p_user_principal_name IN VARCHAR2, p_display_name IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION list_user_notebook_sections ( p_user_principal_name IN VARCHAR2, p_notebook_id IN VARCHAR2 ) RETURN sections_tt;
    FUNCTION pipe_list_user_notebook_sections ( p_user_principal_name IN VARCHAR2, p_notebook_id IN VARCHAR2 ) RETURN sections_tt PIPELINED;
    FUNCTION create_user_notebook_section ( p_user_principal_name IN VARCHAR2, p_notebook_id IN VARCHAR2, p_display_name IN VARCHAR2 ) RETURN VARCHAR2;
    FUNCTION list_user_section_pages ( p_user_principal_name IN VARCHAR2, p_section_id IN VARCHAR2 ) RETURN pages_tt;
    FUNCTION pipe_list_user_section_pages ( p_user_principal_name IN VARCHAR2, p_section_id IN VARCHAR2 ) RETURN pages_tt PIPELINED;
    FUNCTION create_user_section_page_html ( p_user_principal_name IN VARCHAR2, p_section_id IN VARCHAR2, p_content IN CLOB ) RETURN VARCHAR2;
    FUNCTION get_user_page_content ( p_user_principal_name IN VARCHAR2, p_page_id IN VARCHAR2 ) RETURN CLOB;

END msgraph_onenote;
/

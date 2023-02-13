set define off;

CREATE OR REPLACE PACKAGE BODY msgraph_onenote AS

FUNCTION json_object_to_notebook ( p_json JSON_OBJECT_T ) RETURN notebook_rt IS

    v_notebook notebook_rt;

BEGIN

    v_notebook.id := p_json.get_string ( 'id' );
    v_notebook.display_name := p_json.get_string ( 'displayName' );

    RETURN v_notebook;

END json_object_to_notebook;

FUNCTION json_object_to_section ( p_json JSON_OBJECT_T ) RETURN section_rt IS

    v_section section_rt;

BEGIN

    v_section.id := p_json.get_string ( 'id' );
    v_section.display_name := p_json.get_string ( 'displayName' );

    RETURN v_section;

END json_object_to_section;

FUNCTION json_object_to_page ( p_json JSON_OBJECT_T ) RETURN page_rt IS

    v_page page_rt;

BEGIN

    v_page.id := p_json.get_string ( 'id' );
    v_page.title := p_json.get_string ( 'title' );

    RETURN v_page;

END json_object_to_page;

FUNCTION list_user_notebooks ( p_user_principal_name IN VARCHAR2 ) RETURN notebooks_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_notebooks notebooks_tt := notebooks_tt ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_notebooks_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url ); 

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_notebooks.extend;
        v_notebooks (nI) := json_object_to_notebook ( v_value );

    END LOOP;
    
    RETURN v_notebooks;

END list_user_notebooks;

FUNCTION pipe_list_user_notebooks ( p_user_principal_name IN VARCHAR2 ) RETURN notebooks_tt PIPELINED IS

    v_notebooks notebooks_tt;

    nI PLS_INTEGER;

BEGIN

    v_notebooks := list_user_notebooks ( p_user_principal_name );

    nI := v_notebooks.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_notebooks (nI) );

        nI := v_notebooks.NEXT ( nI );

    END LOOP;

END pipe_list_user_notebooks;

FUNCTION create_user_notebook ( p_user_principal_name IN VARCHAR2, p_display_name IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_notebooks_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request.put ( 'displayName', p_display_name );  

    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );
    
    RETURN v_response.get_string ( 'id' );
    
END create_user_notebook;

FUNCTION list_user_notebook_sections ( p_user_principal_name IN VARCHAR2, p_notebook_id IN VARCHAR2 ) RETURN sections_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_sections sections_tt := sections_tt ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_notebook_sections_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    v_request_url := REPLACE( v_request_url, '{id}', p_notebook_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_sections.extend;
        v_sections (nI) := json_object_to_section ( v_value );

    END LOOP;
    
    RETURN v_sections;

END list_user_notebook_sections;

FUNCTION pipe_list_user_notebook_sections ( p_user_principal_name IN VARCHAR2, p_notebook_id IN VARCHAR2 ) RETURN sections_tt PIPELINED IS

    v_sections sections_tt;

    nI PLS_INTEGER;

BEGIN

    v_sections := list_user_notebook_sections ( p_user_principal_name, p_notebook_id );

    nI := v_sections.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_sections (nI) );

        nI := v_sections.NEXT ( nI );

    END LOOP;

END pipe_list_user_notebook_sections;

FUNCTION create_user_notebook_section ( p_user_principal_name IN VARCHAR2, p_notebook_id IN VARCHAR2, p_display_name IN VARCHAR2 ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);
    v_request JSON_OBJECT_T := JSON_OBJECT_T ();

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_notebook_sections_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    
    -- generate request
    v_request.put ( 'displayName', p_display_name );  

    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    v_request.to_clob );

    RETURN v_response.get_string ( 'id' );
    
END create_user_notebook_section;

FUNCTION list_user_section_pages ( p_user_principal_name IN VARCHAR2, p_section_id IN VARCHAR2 ) RETURN pages_tt IS

    v_request_url VARCHAR2 (255);
    v_response JSON_OBJECT_T;

    v_values JSON_ARRAY_T;
    v_value JSON_OBJECT_T;
    
    v_pages pages_tt := pages_tt ();

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_section_pages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    v_request_url := REPLACE( v_request_url, '{id}', p_section_id );

    -- make request
    v_response := msgraph_utils.make_get_request ( v_request_url );

    v_values := v_response.get_array ( msgraph_config.gc_value_json_path );

    FOR nI IN 1 .. v_values.get_size LOOP
    
        v_value := TREAT ( v_values.get ( nI - 1 ) AS JSON_OBJECT_T );
    
        v_pages.extend;
        v_pages (nI) := json_object_to_page ( v_value );

    END LOOP;
    
    RETURN v_pages;

END list_user_section_pages;

FUNCTION pipe_list_user_section_pages ( p_user_principal_name IN VARCHAR2, p_section_id IN VARCHAR2 ) RETURN pages_tt PIPELINED IS

    v_pages pages_tt;

    nI PLS_INTEGER;

BEGIN

    v_pages := list_user_section_pages ( p_user_principal_name, p_section_id );

    nI := v_pages.FIRST;

    WHILE (nI IS NOT NULL) LOOP

        PIPE ROW ( v_pages (nI) );

        nI := v_pages.NEXT ( nI );

    END LOOP;

END pipe_list_user_section_pages;

FUNCTION create_user_section_page_html ( p_user_principal_name IN VARCHAR2, p_section_id IN VARCHAR2, p_content IN CLOB ) RETURN VARCHAR2 IS

    v_request_url VARCHAR2 (255);

    v_response JSON_OBJECT_T;

BEGIN

    -- generate request URL
    v_request_url := REPLACE( gc_user_section_pages_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    v_request_url := REPLACE( v_request_url, '{id}', p_section_id );

    v_response := msgraph_utils.make_post_request ( v_request_url,
                                                    p_content );

    RETURN v_response.get_string ( 'id' );
    
END create_user_section_page_html;

FUNCTION get_user_page_content ( p_user_principal_name IN VARCHAR2, p_page_id IN VARCHAR2 ) RETURN CLOB IS

    v_request_url VARCHAR2 (255);
    v_response CLOB;

BEGIN

    v_request_url := REPLACE( gc_user_page_content_url, msgraph_config.gc_user_principal_name_placeholder, p_user_principal_name );
    v_request_url := REPLACE( v_request_url, '{id}', p_page_id );

    v_response := msgraph_utils.make_get_request_clob ( v_request_url );

    RETURN v_response;

END get_user_page_content;

END msgraph_onenote;

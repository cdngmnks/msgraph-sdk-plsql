CREATE OR REPLACE PACKAGE msgraph_groups AS

    -- endpoint urls
    gc_groups_url CONSTANT VARCHAR2 (39) := 'https://graph.microsoft.com/v1.0/groups';
    gc_group_members_url CONSTANT VARCHAR2 (52) := 'https://graph.microsoft.com/v1.0/groups/{id}/members';

    -- type definitions
    TYPE group_rt IS RECORD (
        id VARCHAR2 (2000),
        created_date_time DATE,
        description VARCHAR2 (2000),
        display_name VARCHAR2 (2000),
        mail VARCHAR2 (2000),
        visibility VARCHAR2 (2000),
        resource_provisioning_options VARCHAR2(2000)
    );
    
    TYPE groups_tt IS TABLE OF group_rt;

    -- groups
    FUNCTION list_groups RETURN groups_tt;
    FUNCTION pipe_list_groups RETURN groups_tt PIPELINED;
    FUNCTION get_group ( p_group_id IN VARCHAR2 ) RETURN group_rt;
    FUNCTION get_group ( p_display_name IN VARCHAR2 ) RETURN group_rt;
    FUNCTION list_group_members ( p_group_id IN VARCHAR2 ) RETURN msgraph_users.users_tt;
    FUNCTION pipe_list_group_members ( p_group_id IN VARCHAR2 ) RETURN msgraph_users.users_tt PIPELINED;
    PROCEDURE add_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 );
    PROCEDURE remove_group_member ( p_group_id IN VARCHAR2, p_user_principal_name IN VARCHAR2 );

END msgraph_groups;
/

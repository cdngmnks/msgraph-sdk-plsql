CREATE OR REPLACE PACKAGE msgraph_config AS

    -- global constants
    gc_wallet_path CONSTANT VARCHAR2 (255) := '';
    gc_wallet_pwd CONSTANT VARCHAR2 (255) := '';

    gc_tenant_id CONSTANT VARCHAR2 (37) := '24e98fb7-3488-4171-9a69-69883213da64';
    gc_client_id CONSTANT VARCHAR2 (37) := '0b243a9c-efa4-4084-9736-945ee833ad9d';
    gc_client_secret CONSTANT VARCHAR2 (41) := 'xj88Q~h6OeHbzR4kvhhLW_nY773uR.QW0p_Glad7';

    gc_user_principal_name_placeholder CONSTANT VARCHAR2 (19) := '{userPrincipalName}';

END msgraph_config;
/

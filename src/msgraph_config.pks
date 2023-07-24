CREATE OR REPLACE PACKAGE msgraph_config AS

    -- global constants
    gc_wallet_path CONSTANT VARCHAR2 (255) := null;
    gc_wallet_pwd CONSTANT VARCHAR2 (255) := null;

    -- delegated access
    gc_delegated_access CONSTANT BOOLEAN := true;
    gc_access_token_context CONSTANT VARCHAR2 (12) := 'ACCESS_TOKEN';

    -- application access
    gc_tenant_id CONSTANT VARCHAR2 (37) := null;
    gc_client_id CONSTANT VARCHAR2 (37) := null;
    gc_client_secret CONSTANT VARCHAR2 (41) := null;

    gc_user_principal_name_placeholder CONSTANT VARCHAR2 (19) := '{userPrincipalName}';

    gc_value_json_path CONSTANT VARCHAR2 (5) := 'value';
    gc_error_json_path CONSTANT VARCHAR2 (5) := 'error';
    gc_error_message_json_path CONSTANT VARCHAR2 (13) := 'error.message';

END msgraph_config;
/

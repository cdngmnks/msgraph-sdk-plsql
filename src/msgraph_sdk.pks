CREATE OR REPLACE PACKAGE msgraph_sdk AS

    gc_wallet_path CONSTANT VARCHAR2 (255) := '';
    gc_wallet_pwd CONSTANT VARCHAR2 (255) := '';

    gc_tenant_id CONSTANT VARCHAR2 (37) := '<tenant_id>';
    gc_client_id CONSTANT VARCHAR2 (37) := '<client_id>';
    gc_client_secret CONSTANT VARCHAR2 (37) := '<client_secret>';

    gc_token_url CONSTANT VARCHAR2 (84) := 'https://login.microsoftonline.com/' || gc_tenant_id || '/oauth2/token';

    gv_access_token CLOB;
    gv_access_token_expiration DATE;

    FUNCTION get_access_token RETURN CLOB;

END msgraph_sdk;
/

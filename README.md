# Microsoft Graph SDK for PL/SQL
Integrate the [Microsoft Graph API](https://graph.microsoft.io/) into your Oracle PL/SQL project!

The Microsoft Graph SDK for PL/SQL is still in the early alpha stages of development, and by no means ready for production use. We encourage anyone who is interested in getting an early glimpse of our plans to download and use our package, but please note that you may hit bumps along the way. Please leave us feedback or file issues if you run into bumps, and we will continue to improve the quality and scope of the package.

# Getting Started
## 1. Register your application
[Register your application in Azure](https://docs.microsoft.com/en-us/graph/auth-register-app-v2) to use the Microsoft Graph API in the [Microsoft Application Registration Portal](https://aka.ms/appregistrations).

## 2. Add a client secret
As the SDK is currently using the [OAuth 2.0 client credentials flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow) for authentication to [get access without a user](https://docs.microsoft.com/en-us/graph/auth-v2-service), you need to add a client secret to your application and to [configure API permissions](https://docs.microsoft.com/en-us/graph/auth-v2-service#2-configure-permissions-for-microsoft-graph).

## 3. Configure API permissions
For the currently implemented functionalities, you need the following permissions.

Permission | Type | Description
---------- | ---- | -----------
User.Read.All | Application | Read all users' full profiles
Contacts.ReadWrite | Application | Read and write contacts in all mailboxes
Calendar.ReadWrite | Application | Read and write calendars in all mailboxes

## 4. Adapt global constants

You need to adapt the global constants to your environment settings in the package specification (msgraph_sdk.pks)

```plsql
gc_wallet_path   CONSTANT VARCHAR2 (255) := '<enter wallet path>';
gc_wallet_pwd    CONSTANT VARCHAR2 (255) := '<enter wallet password>';

gc_tenant_id     CONSTANT VARCHAR2 (37)  := '<enter tenant id>';
gc_client_id     CONSTANT VARCHAR2 (37)  := '<enter client id>';
gc_client_secret CONSTANT VARCHAR2 (37)  := '<enter client secret>';
```

# Issues
To view or log issues, see [issues](https://github.com/cdngmnks/msgraph-sdk-plsql/issues).

# License
Copyright (c) codingmonkeys doo. All Rights Reserved. Licensed under the MIT license.

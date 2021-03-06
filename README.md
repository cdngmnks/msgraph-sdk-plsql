[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=cdngmnks_msgraph-sdk-plsql&metric=alert_status)](https://sonarcloud.io/dashboard?id=cdngmnks_msgraph-sdk-plsql)

# Microsoft Graph SDK for PL/SQL
Integrate the [Microsoft Graph API](https://graph.microsoft.io/) into your Oracle PL/SQL project!

The Microsoft Graph SDK for PL/SQL is still in the early alpha stages of development, and by no means ready for production use. We encourage anyone who is interested in getting an early glimpse of our plans to download and use our package, but please note that you may hit bumps along the way. Please leave us feedback or file issues if you run into any problems, and we will continue to improve the quality and scope of the package.

# Getting Started
## 0. Preconditions
The package currently depends on APEX_WEB_SERVICE and APEX_JSON, making the availability of [Oracle APEX](https://apex.oracle.com/) a precondition for it's use.

## 1. Register your application
[Register your application in Azure](https://docs.microsoft.com/en-us/graph/auth-register-app-v2) to use the Microsoft Graph API in the [Microsoft Application Registration Portal](https://aka.ms/appregistrations).

## 2. Add a client secret
As the SDK is currently using the [OAuth 2.0 client credentials flow](https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow) for authentication to [get access without a user](https://docs.microsoft.com/en-us/graph/auth-v2-service), you need to add a client secret to your application and to [configure API permissions](https://docs.microsoft.com/en-us/graph/auth-v2-service#2-configure-permissions-for-microsoft-graph).

## 3. Configure API permissions
For the currently implemented functionalities, you need the following permissions.

Permission | Type | Description
---------- | ---- | -----------
User.Read.All | Application | Read all users' full profiles
Group.Read.All | Application | Read all groups
Group.ReadWrite.All | Application | Read and write all groups
GroupMember.Read.All | Application | Read all group memberships
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
# Coverage
The following areas and functionalities are already covered by the SDK.

Area | Functionality | Action | Endpoint
---- | ------------- | ------ | --------
Users | get user | GET | /users/{id}
Users | list users | GET | /users
Users | get user manager | GET | /users/{id}/manager
Users | list user direct reports | GET | /users/{id}/directReports
Contacts | get user contact | GET | /users/{id}/contacts/{id}
Contacts | list user contacts | GET | /users/{id}/contacts
Contacts | create user contact | POST | /users/{id}/contacts
Contacts | update user contact | PUT | /users/{id}/contacts/{id}
Contacts | delete user contact | DELETE | /users/{id}/contacts/{id}
Calendar | get user calendar event | GET | /users/{id}/calendar/events/{id}
Calendar | create user calendar event | POST | /users/{id}/calendar/events
Calendar | update user calendar event | PUT | /users/{id}/calendar/events/{id}
Calendar | delete user calendar event | DELETE | /users/{id}/calendar/events/{id}
Calendar | list user calendar events | GET | /users/{id}/calendar/events
Calendar | list user calendar event attendees | GET | /users/{id}/calendar/events/{id}
Groups | list groups | GET | /groups
Groups | list group members | GET | /groups/{id}/members
Groups | add group member | POST | /groups/{id}/members
Groups | delete group member | DELETE | /groups/{id}/members/{id}
Teams | list team groups | GET | /groups
Teams | list team channels | GET | /teams/{id}/channels
Teams | create team channel | POST | /teams/{id}/channels
Teams | delete team channel | DELETE | /teams/{id}/channels/{id}
Teams | send team channel message | POST | /teams/{id}/channels/{id}/messages
Planner | list group plans | GET | /groups/{id}/planner/plans
Planner | create group plan | POST | /planner/plans
Planner | list plan buckets | GET | /planner/plans/{id}/buckets
Planner | create plan bucket | POST | /planner/buckets
Planner | list plan tasks | GET | /planner/plans/{id}/tasks
Planner | create plan task | POST | /planner/tasks
Todos | list todo lists | GET | /me/todo/lists
Todos | create todo list | POST | /me/todo/lists
Todos | create todo list task | POST | /me/todo/lists/{id}/tasks
Activity Feed | list user activities | GET | /me/activities
Activity Feed | create user activity | POST | /me/activities

# Issues
To view or log issues, see [issues](https://github.com/cdngmnks/msgraph-sdk-plsql/issues).

# License
Copyright (c) codingmonkeys doo. All Rights Reserved. Licensed under the [MIT license](https://github.com/cdngmnks/msgraph-sdk-plsql/blob/master/LICENSE).


# Microsoft Graph SDK for PL/SQL
Integrate the [Microsoft Graph API](https://graph.microsoft.io/) into your Oracle PL/SQL project!

Please leave us feedback or file issues if you run into any problems, and we will continue to improve the quality and scope of the package.

# Getting Started
## 0. Preconditions
The package currently depends on APEX_WEB_SERVICE, making the availability of [Oracle APEX](https://apex.oracle.com/) a precondition for it's use.

Therefore also the ACLs need to be set accordingly for your installed version of APEX.

```plsql
begin

   DBMS_NETWORK_ACL_ADMIN.CREATE_ACL ( acl => 'msgraph_acl.xml', 
                                       description => 'MS Graph ACL', 
                                       principal => 'APEX_XXYYZZ', 
                                       is_grant => true, 
                                       privilege => 'connect' );
                                       
   DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE ( acl => 'msgraph_acl.xml',
                                          principal => 'APEX_XXYYZZ', 
                                          is_grant => true, 
                                          privilege => 'resolve' );
                                          
   DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL ( acl => 'msgraph_acl.xml', 
                                       host => 'graph.microsoft.com', 
                                       lower_port => 443 );
                                       
   DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL ( acl => 'msgraph_acl.xml', 
                                       host => 'login.microsoftonline.com', 
                                       lower_port => 443 );

end;
/
```

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
Notes.ReadWrite.All | Application | Read and write all OneNote notebooks
Files.ReadWrite.All | Application | Read and write files in all drives
Sites.Read.All | Application | Read items in all site collections
Mail.ReadWrite | Application | Read and write mails in all mailboxes
Mail.Send | Application | Send mail as any user

## 4. Adapt global constants
You need to adapt the global constants to your environment settings in the config package specification (msgraph_config.pks)

```plsql
gc_wallet_path   CONSTANT VARCHAR2 (255) := '<enter wallet path>';
gc_wallet_pwd    CONSTANT VARCHAR2 (255) := '<enter wallet password>';

gc_tenant_id     CONSTANT VARCHAR2 (37)  := '<enter tenant id>';
gc_client_id     CONSTANT VARCHAR2 (37)  := '<enter client id>';
gc_client_secret CONSTANT VARCHAR2 (37)  := '<enter client secret>';
```

# Package Structure
Package | Description 
------- | ---- 
msgraph_config | Global constants, environment settings
msgraph_utils | shared functionality, token handling
msgraph_users | implementing [Users](https://docs.microsoft.com/en-us/graph/api/resources/users)
msgraph_contacts | implementing [Contacts](https://docs.microsoft.com/en-us/graph/api/resources/contact)
msgraph_calendar | implementing [Calendar](https://docs.microsoft.com/en-us/graph/api/resources/calendar) and [Events](https://docs.microsoft.com/en-us/graph/api/resources/event)
msgraph_groups | implementing [Groups](https://docs.microsoft.com/en-us/graph/api/resources/groups-overview)
msgraph_teams | implementing [Teams](https://docs.microsoft.com/en-us/graph/api/resources/teams-api-overview)
msgraph_planner | implementing [Planner](https://docs.microsoft.com/en-us/graph/api/resources/planner-overview)
msgraph_todo | implementing [Todo](https://docs.microsoft.com/en-us/graph/api/resources/todo-overview)
msgraph_onenote | implementing [OneNote](https://docs.microsoft.com/en-us/graph/api/resources/onenote-api-overview)
msgraph_onedrive | implementing [OneDrive](https://learn.microsoft.com/en-us/graph/api/resources/drive)
msgraph_sharepoint | implementing [SharePoint](https://learn.microsoft.com/en-us/graph/api/resources/sharepoint)
msgraph_mail | implementing [Mail](https://learn.microsoft.com/en-us/graph/api/resources/mail-api-overview)
msgraph_me | implementing functionality related to the signed in user

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
Contacts | list user contacts in folder | GET | /users/{id}/contactFolders/{id}/contacts
Contacts | create user contact | POST | /users/{id}/contacts
Contacts | create user contact in folder | POST | /users/{id}/contactFolders/{id}/contacts
Contacts | update user contact | PUT | /users/{id}/contacts/{id}
Contacts | delete user contact | DELETE | /users/{id}/contacts/{id}
Contacts | list user contact folders | GET | /users/{id}/contactFolders
Contacts | create user contact folder | POST | /users/{id}/contactFolders
Contacts | delete user contact folder | DELETE | /users/{id}/contactFolders
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
Teams | list team members | GET | /teams/{id}/channels/{id}/members
Teams | add team member | POST | /teams/{id}/channels/{id}/members
Teams | remove team member | DELETE | /teams/{id}/channels/{id}/members/{id}
Teams | list team channels | GET | /teams/{id}/channels
Teams | create team channel | POST | /teams/{id}/channels
Teams | delete team channel | DELETE | /teams/{id}/channels/{id}
Teams | list team channel messages | GET | /teams/{id}/channels/{id}/messages
Teams | send team channel message | POST | /teams/{id}/channels/{id}/messages
Teams | send team channel message reply | POST | /teams/{id}/channels/{id}/messages/{id}/replies
Teams | update team channel message | PUT | /teams/{id}/channels/{id}/messages
Teams | update team channel message reply | PUT | /teams/{id}/channels/{id}/messages/{id}/replies
Teams | set team channel message reaction | POST | /teams/{id}/channels/{id}/messages/{id}/setReaction
Teams | unset team channel message reaction | POST | /teams/{id}/channels/{id}/messages/{id}/unsetReaction
Planner | list group plans | GET | /groups/{id}/planner/plans
Planner | create group plan | POST | /planner/plans
Planner | list plan buckets | GET | /planner/plans/{id}/buckets
Planner | create plan bucket | POST | /planner/buckets
Planner | list plan tasks | GET | /planner/plans/{id}/tasks
Planner | create plan task | POST | /planner/tasks
Todo | list todo lists | GET | /me/todo/lists
Todo | create todo list | POST | /me/todo/lists
Todo | create todo list task | POST | /me/todo/lists/{id}/tasks
OneNote | list user notebooks | GET | /users/{id}/onenote/notebooks
OneNote | list user notebook sections | GET | /users/{id}/onenote/notebooks/{id}/sections
OneNote | list user section pages | GET | /users/{id}/onenote/sections/{id}/pages
OneNote | create user notebook | POST | /users/{id}/onenote/notebooks
OneNote | create user notebook section | POST | /users/{id}/onenote/notebooks/{id}/sections
OneNote | create user section page | POST | /users/{id}/onenote/sections/{id}/pages
OneDrive | get site drive | GET | /sites/{id}/drive
OneDrive | get group drive | GET | /groups/{id}/drive
OneDrive | get user drive | GET | /users/{id}/drive
OneDrive | get folder children | GET | /drives/{id}/items/{id}/children
OneDrive | create folder | POST | /drives/{id}/items/{id}/children
OneDrive | copy item or folder| POST | /drives/{id}/items/{id}/copy
OneDrive | rename item or folder | PUT | /drives/{id}/items/{id}
OneDrive | delete item or folder | DELETE | /drives/{id}/items/{id}
OneDrive | upload file | PUT | /drives/{id}/items/{id}/{fileName}/content
OneDrive | download file | GET | /drives/{id}/items/{id}/content
SharePoint | list sites | GET | /sites
SharePoint | list site lists | GET | /sites/{id}/lists
Mail | list user messages | GET | /users/{id}/messages
Mail | list user folder messages | GET | /users/{id}/mailFolders/{id}/messages
Mail | create forward message draft | POST | /users/{id}/messages/{id}/createForward
Mail | create reply message draft | POST | /users/{id}/messages/{id}/createReply
Mail | create reply all message draft | POST | /users/{id}/messages/{id}/createReplyAll
Mail | update message draft | PATCH | /users/{id}/messages/{id}
Mail | send message draft | POST | /users/{id}/messages/{id}/send
Mail | delete message | DELETE | /users/{id}/messages/{id}
Mail | get message | GET | /users/{id}/mailFolders/{id}/messages/{id}
Mail | download message | GET | /users/{id}/mailFolders/{id}/messages/{id}/$value
Mail | list attachments | GET | /users/{id}/messages/{id}/attachments
Mail | add file attachment | POST | /users/{id}/messages/{id}/attachments
Mail | delete attachment | DELETE | /users/{id}/messages/{id}/attachments/{id}
Mail | download attachment | GET | /users/{id}/messages/{id}/attachments/{id}/$value
Activity Feed | list user activities | GET | /me/activities
Activity Feed | create user activity | POST | /me/activities

# Issues
To view or log issues, see [issues](https://github.com/cdngmnks/msgraph-sdk-plsql/issues).

# License
Copyright (c) codingmonkeys doo. All Rights Reserved. Licensed under the [MIT license](https://github.com/cdngmnks/msgraph-sdk-plsql/blob/master/LICENSE).

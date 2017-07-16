<!DOCTYPE md>
# obs-websocket 4.1 protocol reference

**This is the reference for the latest 4.1 developement build. [See here for obs-websocket 4.0.0!](https://github.com/Palakis/obs-websocket/blob/4.0.0/PROTOCOL.md)**


# Table of Contents

<!-- toc -->

- [General Introduction](#general-introduction)
- [Authentication](#authentication)
- [Events](#events)
  * [Category: Scenes](#category-scenes)
    + [OnSceneChange](#onscenechange)
- [Requests](#requests)
  * [Category: General](#category-general)
    + [GetVersion](#getversion)
    + [GetAuthRequired](#getauthrequired)
    + [Authenticate](#authenticate)
  * [Category: Scenes](#category-scenes-1)
    + [SetCurrentScene](#setcurrentscene)
    + [GetCurrentScene](#getcurrentscene)
    + [GetSceneList](#getscenelist)
  * [Category: Sources](#category-sources)
    + [SetSourceRender](#setsourcerender)
  * [Category: Streaming](#category-streaming)
    + [GetStreamingStatus](#getstreamingstatus)
  * [Category: Scene Collections](#category-scene-collections)
    + [ListSceneCollections](#listscenecollections)
  * [Category: Profiles](#category-profiles)
    + [SetCurrentProfile](#setcurrentprofile)
    + [GetCurrentProfile](#getcurrentprofile)
  * [Category: Settings](#category-settings)
    + [SetStreamingSettings](#setstreamingsettings)

<!-- tocstop -->

# General Introduction
Messages exchanged between the client and the server are JSON objects.  
The protocol in general is based on the OBS Remote protocol created by Bill Hamilton, with new commands specific to OBS Studio.


# Authentication
A call to [`GetAuthRequired`](#getauthrequired) gives the client two elements:
- A `challenge`: a random string that will be used to generate the auth response
- A `salt`: applied to the password when generating the auth response

The client knows a password and must it to authenticate itself to the server.  
However, it must keep this password secret, and it is the purpose of the authentication mecanism used by obs-websocket.

After a call to [`GetAuthRequired`](#getauthrequired), the client knows a password (kept secret), a challenge and a salt (sent by the server).
To generate the answer to the auth challenge, follow this procedure:
- Concatenate the password with the salt sent by the server (in this order: password + server salt), then generate a binary SHA256 hash of the result and encode the resulting SHA256 binary hash to base64.
- Concatenate the base64 secret with the challenge sent by the server (in this order: base64 secret + server challenge), then generate a binary SHA256 hash of the result and encode it to base64.
- Voilà, this last base64 string is the auth response. You may now use it to authenticate to the server with the `Authenticate` request.

Here's how it looks in pseudocode:
```
password = "supersecretpassword"
challenge = "ztTBnnuqrqaKDzRM3xcVdbYm"
salt = "PZVbYpvAnZut2SS6JNJytDm9"

secret_string = password + salt
secret_hash = binary_sha256(secret_string)
secret = base64_encode(secret_hash)

auth_response_string = secret + challenge
auth_response_hash = binary_sha256(auth_response_string)
auth_response = base64_encode(auth_response_hash)
```

A client can then authenticate to the server by calling [`Authenticate`](#authenticate) with the computed challenge response.


# Events
Events are sent exclusively by the server and broadcast to each connected client.  
An event message will contain at least one field:
- **update-type** _String_: the type of event
- **stream-timecode** _String (optional)_: time elapsed between now and stream start (only present if OBS Studio is streaming)
- **rec-timecode** _String (optional)_: time elapsed between now and recording start (only present if OBS Studio is recording)

Timecodes are in the following format: HH:MM:SS.mmm

Additional fields will be present in the event message depending on the event type.


## Category: Scenes

### OnSceneChange
__Category__: Scenes  
Indicates a scene change.

__Response Items__:  
- `scene-name` _String_: The new scene.  
- `sources` _Array_: List of sources in the new scene.  


---


# Requests
Requests are sent by the client and must have at least the following two fields:  
- `request-type` _String_: String name of the request type.
- `message-id` _String_: Client defined identifier for the message, will be echoed in the response.

Depending on the request type additional fields may be required (see the requests below for more information).

Once a request is sent, the server will return a JSON response with the following fields:  
- `message-id` _String_: The identifier specified in the request.
- `status` _String_: Response status, will be one of the following: `ok`, `error`
- `error` _String_: The error message associated with an `error` status.  

Depending on the request type additional fields may be present (see the "[Request Types](#request-types)" section below for more information).


## Category: General

### GetVersion 
__Category__: General  
Returns the latest version of the plugin and the API.  

__Request Fields__:  
_No required parameters._

__Response Items__:  
- `version` _double_: OBSRemote compatible API version. Fixed to 1.1 for retrocompatibility.  
- `obs-websocket-version` _String_: obs-websocket plugin version.  
- `obs-studio-version` _String_: OBS Studio program version.  


---
### GetAuthRequired 
__Category__: General  
Tells the client if authentication is required. If so, returns authentication parameters &#x60;challenge&#x60; and &#x60;salt&#x60; (see &quot;Authentication&quot; for more information).  

__Request Fields__:  
_No required parameters._

__Response Items__:  
- `authRequired` _boolean_: Indicates whether authentication is required.  
- `challenge` _String (optional)_:   
- `salt` _String (optional)_:   


---
### Authenticate 
__Category__: General  
Attempt to authenticate the client to the server.  

__Request Fields__:  
- `auth` _String_: Response to the auth challenge (see &quot;Authentication&quot; for more information).  


__Response Items__:  
_No additional response items._

---
## Category: Scenes

### SetCurrentScene 
__Category__: Scenes  
Switch to the specified scene.  

__Request Fields__:  
- `scene-name` _String_: Name of the scene to switch to.  


__Response Items__:  
_No additional response items._

---
### GetCurrentScene 
__Category__: Scenes  
Get the current scene&#39;s name and source items.  

__Request Fields__:  
_No required parameters._

__Response Items__:  
- `name` _String_: Name of the currently active scene.  
- `sources` _Source|Array_: Ordered list of the current scene&#39;s source items.  


---
### GetSceneList 
__Category__: Scenes  
Get a list of scenes in the currently active profile.  

__Request Fields__:  
_No required parameters._

__Response Items__:  
- `current-scene` _String_: Name of the currently active scene.  
- `scenes` _Scene|Array_: Ordered list of the current profile&#39;s scenes (See &#x60;[GetCurrentScene](#getcurrentscene)&#x60; for more information).  


---
## Category: Sources

### SetSourceRender 
__Category__: Sources  
Show or hide a specified source item in a specified scene.  

__Request Fields__:  
- `source` _String_: Name of the source in the specified scene.  
- `render` _boolean_: Desired visibility.  
- `scene-name` _String (optional)_: Name of the scene where the source resides. Defaults to the currently active scene.  


__Response Items__:  
_No additional response items._

---
## Category: Streaming

### GetStreamingStatus 
__Category__: Streaming  
Get current streaming and recording status.  

__Request Fields__:  
_No required parameters._

__Response Items__:  
- `streaming` _boolean_: Current streaming status.  
- `recording` _boolean_: Current recording status.  
- `stream-timecode` _String (optional)_: Time elapsed since streaming started (only present if currently streaming).  
- `rec-timecode` _String (optional)_: Time elapsed since recording started (only present if currently recording).  
- `preview-only` _boolean_: Always false. Retrocompatibility with OBSRemote.  


---
## Category: Scene Collections

### ListSceneCollections 
__Category__: Scene Collections  
Get a list of available scene collections.  

__Request Fields__:  
_No required parameters._

__Response Items__:  
- `scene-collections` _String|Array_: String list of available scene collections.  


---
## Category: Profiles

### SetCurrentProfile 
__Category__: Profiles  
Set the currently active profile.  

__Request Fields__:  
- `profile-name` _String_: Name of the desired profile.  


__Response Items__:  
_No additional response items._

---
### GetCurrentProfile 
__Category__: Profiles  
Get the name of the current profile.  

__Request Fields__:  
_No required parameters._

__Response Items__:  
- `profile-name` _String_: Name of the currently active profile.  


---
## Category: Settings

### SetStreamingSettings 
__Category__: Settings  
Sets one or more attributes of the current streaming server settings. Any options not passed will remain unchanged. Returns the updated settings in response. If &#39;type&#39; is different than the current streaming service type, all settings are required. Returns the full settings of the stream (the same as GetStreamSettings).  

__Request Fields__:  
- `type` _String_: The type of streaming service configuration, usually &#x60;rtmp_custom&#x60; or &#x60;rtmp_common&#x60;.  
- `settings` _Object_: The actual settings of the stream.  
- `settings.server` _String (optional)_: The publish URL.  
- `settings.key` _String (optional)_: The publish key.  
- `settings.use-auth` _boolean (optional)_: Indicates whether authentication should be used when connecting to the streaming server.  
- `settings.username` _String (optional)_: The username for the streaming service.  
- `settings.password` _String (optional)_: The password for the streaming service.  
- `save` _boolean_: Persist the settings to disk.  


__Response Items__:  
_No additional response items._

---

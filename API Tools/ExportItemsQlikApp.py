# ----------------------------------------------------
# -- Projet : Export Items, with filters - DO NOT WORK ON QLIK DESKTOP - SHOULD WORK ON ENTREPRISE - UNTESTED
# -- Author : Ronaf
# -- Created : 20/04/2025
# -- Usage : 
# -- Update :  
# --  
# ----------------------------------------------------

# ==============================================================================================================================
# Imports
# ==============================================================================================================================
import websockets
import json
import asyncio
import aiohttp
import os

# ==============================================================================================================================
# Const
# ==============================================================================================================================

APP_ID = r"PathOrID"
# WebSocket URL for Qlik Sense Engine API
# wss for entreprise
URL = "ws://localhost:4848/app/"
EXPORT_PATH = "./exports"

# ==============================================================================================================================
# Generic WebSocket Request Function
# ==============================================================================================================================

async def send_request(ws, request_data):
    """
    Sends a generic WebSocket request and returns the response.
    This is used to handle any request dynamically.
    """
    await ws.send(json.dumps(request_data))
    response = json.loads(await ws.recv())
    return response

# ==============================================================================================================================
# Request Templates Outside Functions
# ==============================================================================================================================

# Template for opening a document
open_doc_req = {
    "jsonrpc": "2.0",
    "method": "OpenDoc",
    "handle": -1,
    "params": [APP_ID],
    "id": 1,
    "outKey": -1,
}

# Template for getting objects (sheets)
get_sheets_req = {
    "jsonrpc": "2.0",
    "method": "GetObjects",
    "handle": None,  # Will be updated dynamically
    "params": {},
    "id": 10,
}

# Template for getting all object information
get_all_infos_req = {
    "jsonrpc": "2.0",
    "method": "GetAllInfos",
    "handle": None,  # Will be updated dynamically
    "params": {},
    "id": 100
}

# Template for selecting values
select_values_req = {
    "jsonrpc": "2.0",
    "method": "SelectValues",
    "handle": None,  # Will be updated dynamically
    "params": {
        "qField": None,  # Will be updated dynamically
        "qValues": None   # Will be updated dynamically
    },
    "id": 200
}

# Template for getting child info
get_children_req = {
    "jsonrpc": "2.0",
    "method": "GetChildInfos",
    "handle": None,  # Will be updated dynamically
    "params": {},
    "id": None,  # Will be updated dynamically
}

# Template for getting the layout of an object
get_layout_req = {
    "jsonrpc": "2.0",
    "method": "GetLayout",
    "handle": None,  # Will be updated dynamically
    "params": {},
    "id": None,  # Will be updated dynamically
}

# Template for getting object handle
get_obj_req = {
    "jsonrpc": "2.0",
    "method": "GetObject",
    "handle": None,  # Will be updated dynamically
    "params": {"qId": None},  # Will be updated dynamically
    "id": None,  # Will be updated dynamically
}

# Template for exporting objects
export_req = {
    "jsonrpc": "2.0",
    "method": "Export",
    "handle": None,  # Will be updated dynamically
    "params": {
        "qFileType": "png",  # Static, as we want PNG exports
        "qPath": ""
    },
    "id": None,  # Will be updated dynamically
}

# Template for exporting Img
exportImg_req = {
    "jsonrpc": "2.0",
    "method": "ExportImg",
    "handle": None,  # Will be updated dynamically
    "params": {
        "qFileType": "png",  # Static, as we want PNG exports
        "qPath": ""
    },
    "id": None,  # Will be updated dynamically
}
    

reload_app_req = {
    "jsonrpc": "2.0",
    "method": "DoReload",
    "handle": None,  # Will be updated dynamically
    "params": {},
    "id": 2,
}

save_app_req = {
    "jsonrpc": "2.0",
    "method": "DoSave",
    "handle": None,  # Will be updated dynamically
    "params": {},
    "id": 3,
}

# ==============================================================================================================================
# Functions for Exporting and Selecting
# ==============================================================================================================================

async def select_values(ws, app_handle, field_name, values):
    """
    Selects the specified values from the specified field.
    """
    select_values_req["handle"] = app_handle
    select_values_req["params"]["qField"] = field_name
    select_values_req["params"]["qValues"] = values
    return await send_request(ws, select_values_req)

async def export_all_objects_as_png(ws, app_handle):
    """
    Exports all objects in the app as PNG images.
    """
    get_all_infos_req["handle"] = app_handle
    response = await send_request(ws, get_all_infos_req)

    all_infos = response.get("result", {}).get("qInfos", [])
    sheets = [obj for obj in all_infos if obj.get("qType") == "sheet"]

    print(f"Found {len(sheets)} sheets")

    obj_id = 20
    for sheet in sheets:
        sheet_id = sheet['qId']

        # Get sheet object handle
        get_obj_req["handle"] = app_handle
        get_obj_req["params"]["qId"] = sheet_id
        get_obj_req["id"] = obj_id
        response = await send_request(ws, get_obj_req)
        sheet_handle = response.get("result", {}).get("qReturn", {}).get("qHandle")
        obj_id += 1

        # Get layout to extract title and child objects
        get_layout_req["handle"] = sheet_handle
        get_layout_req["id"] = obj_id
        layout_resp = await send_request(ws, get_layout_req)
        obj_id += 1

        layout = layout_resp.get("result", {}).get("qLayout", {})
        sheet_title = layout.get("qMeta", {}).get("title", "Untitled")
        print(f"Sheet ID: {sheet_id}, Title: {sheet_title}")

        get_children_req["handle"] = sheet_handle
        get_children_req["id"] = obj_id
        child_resp = await send_request(ws, get_children_req)
        obj_id += 1

        child_infos = child_resp.get("result", {}).get("qInfos", [])
        print(f"Found {len(child_infos)} child objects on sheet {sheet_id}")

        for child in child_infos:
            obj_ref_id = child.get("qId")
            print(f"Exporting object: {obj_ref_id} ({child.get('qType')})")

            # Get object handle
            get_obj_req["handle"] = app_handle
            get_obj_req["params"]["qId"] = obj_ref_id
            get_obj_req["id"] = obj_id
            obj_resp = await send_request(ws, get_obj_req)
            obj_handle = obj_resp.get("result", {}).get("qReturn", {}).get("qHandle")
            obj_id += 1

            export_req["handle"] = obj_handle
            export_req["id"] = obj_id
            export_resp = await send_request(ws, export_req)
            #json.dumps(export_resp, indent=2)
            print(f"Export response for {obj_ref_id}:",export_resp)

            # test exportImg_req
            exportImg_req["handle"] = obj_handle
            exportImg_req["id"] = obj_id
            exportImg_resp = await send_request(ws, exportImg_req)
            #json.dumps(export_resp, indent=2)
            print(f"Export response for {obj_ref_id}:",exportImg_resp)
            

            obj_id += 1

            download_url = export_resp.get("result", {}).get("qUrl", "")
            print(f"Download URL: {download_url}")

            if download_url:
                filename = f"{sheet_title}_{obj_ref_id}.png".replace(" ", "_")
                # Remove the 'ws://' prefix to get the base URL
                base_url = URL.replace("ws://", "")
                await download_file(base_url + download_url, os.path.join(EXPORT_PATH, filename))

# Helper to download files
async def download_file(url, path):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as resp:
            if resp.status == 200:
                with open(path, 'wb') as f:
                    f.write(await resp.read())
                print(f"Saved to {path}")
            else:
                print(f"Failed to download {url}, status {resp.status}")

async def open_document(ws, app_id):
    """
    Opens a Qlik app using the OpenDoc request and returns the app handle.
    
    Args:
        ws: The WebSocket connection object.
        app_id: The ID of the Qlik app to open.
        
    Returns:
        app_handle: The handle of the opened Qlik app, or None if failed.
    """
    # Define the OpenDoc request
    open_doc_req = {
        "jsonrpc": "2.0",
        "method": "OpenDoc",
        "handle": -1,
        "params": [app_id],
        "id": 1,
        "outKey": -1
    }

    # Send the OpenDoc request
    await ws.send(json.dumps(open_doc_req))

    while True:
        # Wait for the response
        result = await ws.recv()
        response = json.loads(result)
        print("Received response:", response)
        
        if response.get("id") == open_doc_req["id"]:
            open_doc_response = response
            break

    # Extract the app handle from the response
    app_handle = open_doc_response.get("result", {}).get("qReturn", {}).get("qHandle")
    if not app_handle:
        print("Failed to open the app. Exiting.")
        return None

    print(f"Opened app with handle: {app_handle}")
    return app_handle


async def reload_app(ws, app_handle):
    """
    Reloads the Qlik app identified by the given app_handle using send_request.
    
    Args:
        ws: The WebSocket connection object.
        app_handle: The handle of the Qlik app to reload.
    """
    # Define the reload request
    reload_app_req = {
        "jsonrpc": "2.0",
        "method": "DoReload",
        "handle": app_handle,
        "params": {},
        "id": 2
    }

    # Send the reload request and get the response
    reload_response = await send_request(ws, reload_app_req)
    print("Reload Response:", reload_response)

async def save_app(ws, app_handle):
    """
    Saves the Qlik app identified by the given app_handle using send_request.
    
    Args:
        ws: The WebSocket connection object.
        app_handle: The handle of the Qlik app to save.
    """
    # Define the save request
    save_app_req = {
        "jsonrpc": "2.0",
        "method": "DoSave",
        "handle": app_handle,
        "params": {},
        "id": 3
    }

    # Send the save request and get the response
    save_response = await send_request(ws, save_app_req)
    print("Save Response:", save_response)


# ==============================================================================================================================
# Main Export Logic for Looping Over Dynamic Selections
# ==============================================================================================================================

async def export_for_all_values(ws, app_handle, field_name, values_list):
    """
    Loops through a list of values and exports the graphs for each selection.
    """
    for values in values_list:
        # Step 1: Select the values dynamically for the given field
        await select_values(ws, app_handle, field_name, values)
        
        # Step 2: Export all objects for the selected values
        await export_all_objects_as_png(ws, app_handle)
        print(f"Export completed for values: {values} in field {field_name}")

# ==============================================================================================================================
# API Call Setup
# ==============================================================================================================================

async def call_api():
    async with websockets.connect(URL) as ws:
        # Call the open_document function to get the app handle
        app_handle = await open_document(ws, APP_ID)

        # Call the reload function
        await reload_app(ws, app_handle)
        
        # Call the save function
        await save_app(ws, app_handle)

        # Example field and values
        field_name = "Products"  
        values_list = [
            ["Products1"],  
            ["Products2"]
        ]

        # Export for each set of values in the list
        await export_for_all_values(ws, app_handle, field_name, values_list)


if __name__ == '__main__':
    asyncio.get_event_loop().run_until_complete(call_api())

exit()


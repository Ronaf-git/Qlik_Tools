# ----------------------------------------------------
# -- Projet : Reload and Save Qlik App
# -- Author : Ronaf
# -- Created : 15/04/2025
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

# ==============================================================================================================================
# Const
# ==============================================================================================================================

APP_ID = r"Path\to\file.qvf"
# WebSocket URL for Qlik Sense Engine API
# wss if entreprise
URL = "ws://localhost:4848/app/"

# ==============================================================================================================================
# API REQUEST
# ==============================================================================================================================
# Request to open the app 
req_open_doc = {
    "jsonrpc": "2.0",
    "method": "OpenDoc",
    "handle": -1,
    "params": [
        APP_ID
    ],
    "id": 1,
    "outKey": -1,
}

# Request to save the app
req_save_app = {
    "jsonrpc": "2.0",
    "method": "DoSave",
    "handle": 1,  # Use the correct handle received from OpenDoc
    "params": {},  # Empty params for DoSave
    "id": 3,
}

# Request to reload the app 
req_reload_app = {
    "jsonrpc": "2.0",
    "method": "DoReload",
    "handle": 1,
    "params": {},
    "id": 2,
}

# ==============================================================================================================================
# Functions
# ==============================================================================================================================

async def call_api():
    async with websockets.connect(URL) as ws:
        # Send the request to open the app
        await ws.send(json.dumps(req_open_doc))

        # Wait for a response to OpenDoc
        while True:
            result = await ws.recv()
            response = json.loads(result)
            print("Received response:", response)

            # Check if we received the correct response
            if response.get("id") == 1:
                open_doc_response = response
                break
            else:
                print("Waiting for valid response to OpenDoc...")

        # Extract the handle for the opened app from the response
        app_handle = open_doc_response.get("result", {}).get("qReturn", {}).get("qHandle")

        if not app_handle:
            print("Failed to open the app. Exiting.")
            return

        print(f"Opened app with handle: {app_handle}")

        # Update the reload request with the correct app handle
        req_reload_app["handle"] = app_handle

        # Send the reload request
        await ws.send(json.dumps(req_reload_app))

        # Receive and print the reload response
        reload_response = await ws.recv()
        print("Reload Response:", reload_response)

        # Optionally, save the app after the reload
        await ws.send(json.dumps(req_save_app))

        # Receive and print the save response
        save_response = await ws.recv()
        print("Save Response:", save_response)

# ==============================================================================================================================
# Logic
# ==============================================================================================================================

if __name__ == '__main__':
    asyncio.get_event_loop().run_until_complete(call_api())


exit()


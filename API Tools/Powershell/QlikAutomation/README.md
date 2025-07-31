# QlikAutomation PowerShell Toolkit

This PowerShell module automates interactions with **Qlik Sense** via WebSocket API, enabling automated tasks such as reloading apps, selecting fields, and exporting object data (e.g., as Excel files).

---

## 🚀 Features

- 📡 WebSocket session connection (with authentication cookie - UNTESTED)
- 🔁 Reload Qlik apps
- 💾 Save app state
- 🎯 Select specific field values
- 📊 Export object/sheet data (OOXML, CSV, etc.)
- 🧱 Discover app layout and object metadata
- 🧼 Automatic filename sanitization for safe file exports

---

## 📂 Project Structure

```
QlikAutomation/
├── Config/
│   └── QlikSettings.json            # Configuration file
├── Private/
│   ├── FileHelpers.ps1              # Utilities for formatting/sanitizing
│   ├── Qlik-ApiRequests.ps1         # Engine API wrappers
│   └── WebSocket-Helpers.ps1        # WebSocket send/receive helpers
├── Public/
│   ├── Connect-QlikSession.ps1      # Authentication and session handling
│   ├── Export-QlikObject.ps1        # Object selection/export logic
│   ├── Reload-QlikApp.ps1           # Reload app logic
│   └── Select-QlikField.ps1         # Make field selections
├── QlikAutomation.psm1              # Module manifest
└── example.ps1                      # Examples of use
```

---

## ⚙️ Prerequisites

- Qlik Sense Desktop or Qlik Sense Enterprise
- PowerShell 5.1 or newer
- A local `.qvf` app file or server-hosted app accessible via WebSocket

---

## ▶️ Usage

Import the module in your powershell script :

```powershell
Import-Module .\QlikAutomation.psm1 -Force
```

---

## 📤 Example Summary (example.ps1)

1. Load config from JSON (see below)
2. Open WebSocket session to Qlik Engine
3. Reload the app
4. Save the app
5. Loop through field values:
   - Select value
   - Iterate sheets and visualizations
   - Export each object’s data to Excel (`.xlsx`)
6. Save files to `OutputDirectory`
7. Close WebSocket session

### Configuration of `Config/QlikSettings.json`


- **QlikUrl**: URL of the Qlik server.
  - For Qlik Sense Desktop:
    ```
    ws://localhost:4848/app/
    ```
  - For Qlik Sense Enterprise:
    ```
    wss://YOUR_SERVER
    ```

- **AppId**: ID of the app you want to interact with.
  - For Qlik Sense Desktop, use the path to your `.qvf` file:
    ```
    Path\\to\\your\\file.qvf
    ```
  - For Qlik Sense Enterprise, use the app ID (e.g. as seen in the URL):
    ```
    YOUR_APP_ID
    ```

- **CookieName**: Cookie name for authentication if using `wss` (default is `"X-Qlik-Session"`).

- **FieldName**: Field name on which you want to iterate.

- **FieldValues**: List of field values you want to iterate over (these must exist in the specified `FieldName`).

- **OutputDirectory**: Directory where exported files will be saved.

- **WriteHost**: Boolean flag to display requests in the terminal.

Example :
```json
{
  "QlikUrl": "ws://localhost:4848/app/",
  "AppId": "Path\\to\\your\\file.qvf",
  "CookieName": "X-Qlik-Session",
  "FieldName": "YourFieldName",
  "FieldValues":  ["Value1", "Value2", "Value3"],
  "OutputDirectory": "Path\\to\\your\\folder",
  "WriteHost": true
}
```
---

## 📚 References

- [Qlik Sense Engine API Docs](https://help.qlik.com/en-US/sense-developer/)
- PowerShell WebSocket: `System.Net.WebSockets.ClientWebSocket`

---

## 👤 Author

**Ronaf**


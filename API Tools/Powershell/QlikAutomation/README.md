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
- 📜 Download app load script  
- ✍️ Upload/update app load script  

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
│   ├── Get-QlikApp.ps1              # Get QlikApp
│   ├── Get-QlikScript.ps1           # Get QlikScript
│   ├── Save-QlikApp.ps1             # Save app change (new data/new script/new viz/...)
│   ├── Reload-QlikApp.ps1           # Reload app logic
│   ├── Set-QlikScript.ps1           # Set QlikScript (without saving)
│   └── Select-QlikField.ps1         # Make field selections
├── QlikAutomation.psd1              # Module manifest
├── QlikAutomation.psm1              # Module load
└── example.ps1                      # Examples of use
```

---

## ⚙️ Prerequisites

- Qlik Sense Desktop or Qlik Sense Enterprise
- PowerShell 5.1 or newer
- A local `.qvf` app file or server-hosted app accessible via WebSocket

---

## ▶️ Usage

To properly use the module, save the `QlikAutomation` folder inside one of your PowerShell module paths, for example:
- Dedicated User : `C:\Users\<YourUsername>\Documents\WindowsPowerShell\Modules\QlikAutomation`
- All users : `C:\Program Files\WindowsPowerShell\Modules\QlikAutomation`

Then, in your PowerShell session or script, import the module by running:

```powershell
Import-Module QlikAutomation -Force
```

Or, if you are running your script directly from the `QlikAutomation` folder (regardless of its location) and want to import it by relative path, use:
```powershell
Import-Module .\QlikAutomation.psm1 -Force
```

---

## 📤 Example Summary (example.ps1)

1. Load config from JSON (see below)
2. Open WebSocket session to Qlik Engine
3. Connect to a QlikApp
4. Get various AppInfos
5. Get AppScript
6. Update AppScript
7. Reload the app
8. Save the app
9. Loop through field values:
   - Select value
   - Iterate sheets and visualizations
   - Export each object’s data to Excel (`.xlsx`)
10. Save files to `OutputDirectory`
11. Close WebSocket session

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


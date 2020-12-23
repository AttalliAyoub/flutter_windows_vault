<!--
  Title: Flutter Windows Vautl
  Description: flutter Windows to store read/write data into credential manager, with encryption.
  Author: Attalli Ayoub @AttalliAyoub <attalliayoub50@gmail.com>
  -->
# flutter_windows_vault

flutter Windows to read/write data into credential manager (windows vault), with encryption.
<meta name='keywords' content='flutter, windows, desktop, encryption, vault, credential manager, dart, cpp, storage, key/value'>
using "wincred.h" in windows api to write, read, encrypt ..., from the windows vault (credential manager)

## Getting Started

```dart
import 'package:flutter_windows_vault/flutter_windows_vault.dart';

// Write value
bool result = await FlutterWindowsVault.set(key: 'password', value: '123456789');

// Encrypt and Write value
bool result = await FlutterWindowsVault.set(key: 'password', value: '123456789', encrypted: true);

// Read value
Cred cred = await FlutterWindowsVault.get(key: 'password');

// Read Encrypted value
Cred cred = await FlutterWindowsVault.get(key: 'password', encrypted: true);

// Delete value
bool result = await FlutterWindowsVault.del(key: 'password');

// Read all values
List<Cred> list = await FlutterWindowsVault.list();

// Encrypt data                 /// result encrypted: => @@D\u0007\b\f\n\rgAAAAAYppBAAAAAAA5c5uXGQ1pJpY0VrAG-aZawRYNC3MboXJ
String data = await FlutterWindowsVault.encrypt(value: '123456789');

// Decrypt data                 /// result decrypted: data => '123456789';
String data = await FlutterWindowsVault.decrypt(value:"@@D\u0007\b\f\n\rgAAAAAYppBAAAAAAA5c5uXGQ1pJpY0VrAG-aZawRYNC3MboXJ"); 
```
specific writing of data

all the argument below documentation hrer [CREDENTIALA structure] https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members 
```dart
    FlutterWindowsVault.set(
        /// key or TargetName: The name of the credential. The TargetName and Type members uniquely identify the credential. This member cannot be changed after the credential is created. Instead, the credential with the old name should be deleted and the credential with the new name created.
        key: 'password',
        /// value: Secret data for the credential. The value member can be both read and written.
        value: '123456789',
        /// persist: Defines the persistence of this credential. This member can be read and written.
        persist: Persist.CRED_PERSIST_LOCAL_MACHINE,
        /// type: The type of the credential. This member cannot be changed after the credential is created. The following values are valid.
        type: Type.CRED_TYPE_GENERIC,
        /// userName: The user name of the account used to connect to TargetName.
        userName: 'com.example.<your_app_name>',
        /// encrypted: whether to encrypt the data before saving it or not.
        encrypted: true,
        /// fAsSelf: Set to TRUE to specify that the credentials are encrypted in the security context of the current process. Set to FALSE to specify that credentials are encrypted in the security context of the calling thread security context.
        fAsSelf: false,
    );
```

for more details about wincred.h api => [wincred.h header] https://docs.microsoft.com/en-us/windows/win32/api/wincred/

### support the author
<a href="https://www.buymeacoffee.com/attalliayoub" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 30px !important;width: 108.5px !important;" ></a>
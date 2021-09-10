import 'dart:async';
import './flutter_windows_vault_interfaces.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

export './flutter_windows_vault_interfaces.dart';

/// A singleton class holds the static methods like set, get and del to invoke.
///
/// you can't construct this class you only can call methods.
///
/// example:
/// ```
///// Delete value
///bool result = await FlutterWindowsVault.del(key: 'password');
/// ```
class FlutterWindowsVault {
  FlutterWindowsVault._();

  static const MethodChannel _channel =
      const MethodChannel('com.ayoub.flutter_windows_vault');

  /// get current device windows version
  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// save a key/value data in windows credential manager (vault).
  /// you could find more info: https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew
  ///
  /// handle errors: https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credwritew#return-value
  ///
  /// ```dart
  ///FlutterWindowsVault.set(
  ///
  ///// key (TargetName): The name of the credential. The TargetName and Type members uniquely identify the credential.
  ///// This member cannot be changed after the credential is created.
  ///// Instead, the credential with the old name should be deleted and the credential with the new name created.
  ///key: 'password',
  ///
  ///// value (CredentialBlob): Secret data for the credential. The CredentialBlob member can be both read and written.
  ///value: '123456789',
  ///
  ///// type: The type of the credential. This member cannot be changed after the credential is created. The values are in Type enum.
  ///// default value is Type.CRED_TYPE_GENERIC.
  ///// for more about the types => https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members
  ///type: Type.CRED_TYPE_GENERIC,
  ///
  ///// persist: Defines the persistence of this credential. This member can be read and written. the values are in Persist enum.
  ///// for more about the types => https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members
  ///// default value is Persist.CRED_PERSIST_LOCAL_MACHINE.
  ///persist: Persist.CRED_PERSIST_LOCAL_MACHINE,
  ///
  ///// userName: The user name of the account used to connect to key (TargetName).
  ///// default value is 'com.ayoub.flutter_windows_vault'.
  ///userName: 'com.example.<your_app_name>',
  ///
  ///// encrypted: whether to encrypt the data before saving it or not.
  ///// default value is false.
  ///encrypted: true,
  ///
  ///// fAsSelf: (this works only if encrypted is true) Set to TRUE to specify that the credentials are encrypted in the security context of the current process.
  ///// Set to FALSE to specify that credentials are encrypted in the security context of the calling thread security context.
  ///// default value is false.
  ///fAsSelf: false,
  /// ```
  /// you could find more https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members
  static Future<bool> set({
    required String key,
    required String value,
    Type type = Type.CRED_TYPE_GENERIC,
    Persist persist = Persist.CRED_PERSIST_LOCAL_MACHINE,
    String userName = 'com.ayoub.flutter_windows_vault',
    bool encrypted = false,
    bool fAsSelf = false,
  }) {
    assert(key.isNotEmpty);
    assert(value.isNotEmpty);
    assert(userName.isNotEmpty);
    // assert(type != null);
    // assert(persist != null);
    // assert(encrypted != null);
    // assert(!encrypted || (encrypted && fAsSelf != null));
    assert(!fAsSelf || (fAsSelf && encrypted));
    return _channel.invokeMethod<bool>('set', {
      'key': key,
      'value': value,
      'type': type.index + 1,
      'persist': persist.index + 1,
      'userName': userName,
      'encrypted': encrypted,
      'fAsSelf': fAsSelf,
    }).then((value) => value ?? false);
  }

  /// The get (uses CredReadW from wincred.h) function reads a credential from the user's credential set.
  /// The credential set used is the one associated with the logon session of the current token.
  /// The token must not have the user's SID disabled.
  ///
  /// more info and error types https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credreadw#return-value
  ///
  /// ```
  /// FlutterWindowsVault.get(
  ///   // the key value you want to return its value
  ///   key: 'password',
  ///   // type: The type of the credential you want to return its value.
  ///   // This member cannot be changed after the credential is created. The values are in Type enum.
  ///   // default value is Type.CRED_TYPE_GENERIC.
  ///   // for more about the types => https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members
  ///   type: Type.CRED_TYPE_GENERIC,
  ///   // if the the value you want to get is encrypted
  ///   // default value is false.
  ///   encrypted: true,
  ///   // fAsSelf: (this works only if encrypted is true) Set to TRUE to specify that the credentials are encrypted in the security context of the current process.
  ///   // Set to FALSE to specify that credentials are encrypted in the security context of the calling thread security context.
  ///   // default value is false.
  ///   fAsSelf: false,
  /// );
  /// ```
  ///
  static Future<Cred?> get({
    required String key,
    Type type = Type.CRED_TYPE_GENERIC,
    bool encrypted = false,
    bool fAsSelf = false,
  }) async {
    assert(key.isNotEmpty);
    // assert(type != null);
    // assert(encrypted != null);
    // assert(!encrypted || (encrypted && fAsSelf != null));
    assert(!fAsSelf || (fAsSelf && encrypted));

    try {
      return await _channel.invokeMapMethod<String, dynamic>('get', {
        'key': key,
        'type': type.index + 1,
        'encrypted': encrypted,
        'fAsSelf': fAsSelf,
      }).then((data) {
        if (data == null) return null;
        return Cred.fromJson(data);
      });
    } catch (err) {
      if (err is PlatformException && err.code != 'ERROR_NOT_FOUND') throw err;
      return Future<Cred>.value(null);
    }
  }

  static Future<bool> containsKey({
    required String key,
    Type type = Type.CRED_TYPE_GENERIC,
    bool encrypted = false,
    bool fAsSelf = false,
  }) async {
    assert(key.isNotEmpty);
    assert(!fAsSelf || (fAsSelf && encrypted));
    try {
      return await _channel.invokeMapMethod<String, dynamic>('get', {
        'key': key,
        'type': type.index + 1,
        'encrypted': encrypted,
        'fAsSelf': fAsSelf,
      }).then((data) {
        if (data == null) return false;
        return true;
      });
    } catch (err) {
      if (err is PlatformException && err.code != 'ERROR_NOT_FOUND')
        throw err;
      else
        return false;
    }
  }

  ///The del function (user CredDeleteW from wincred.h) deletes a credential from the user's credential set.
  ///The credential set used is the one associated with the logon session of the current token.
  ///The token must not have the user's SID disabled.
  ///
  /// more info and error types https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-creddeletew#return-value
  ///
  ///````
  ///FlutterWindowsVault.del(
  ///  // the key (TargetName) value you want to delete
  ///  key: 'password',
  ///  // type: The type of the credential you want to delete.
  ///  // This member cannot be changed after the credential is created. The values are in Type enum.
  ///  // default value is Type.CRED_TYPE_GENERIC.
  ///  // for more about the types => https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members
  ///  type: Type.CRED_TYPE_GENERIC,
  ///);
  ///```
  ///
  static Future<bool> del({
    required String key,
    Type type = Type.CRED_TYPE_GENERIC,
  }) {
    assert(key.isNotEmpty);
    // assert(type != null);
    return _channel.invokeMethod<bool>('del', {
      'key': key,
      'type': type.index + 1,
    }).then((value) => value ?? false);
  }

  /// The list function (uses CredEnumerateW from wincred.h) enumerates the credentials from the user's credential set.
  /// The credential set used is the one associated with the logon session of the current token.
  /// The token must not have the user's SID disabled.
  ///
  /// more info and error types https://docs.microsoft.com/en-us/windows/win32/api/wincred/nf-wincred-credenumeratew#return-value
  ///
  ///```
  ///// filter: string that contains the filter for the returned credentials. Only credentials with a TargetName matching the filter will be returned.
  ///// The filter specifies a name prefix followed by an asterisk. For instance, the filter "FRED*" will return all credentials with a TargetName beginning with the string "FRED".
  ///FlutterWindowsVault.list(filter: '*');
  ///```
  ///
  static Future<List<Cred>> list({String? filter}) {
    return _channel.invokeListMethod(
        'list', {'filter': filter}).then<List<Cred>>((values) {
      // print(values);
      return List.from(values ?? [])
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e))
          .map<Cred>((cred) {
        return Cred.fromJson(cred);
      }).toList();
    });
  }

  /// The encrypt function (uses CredProtectW from wincred.h) encrypts the specified credentials so that only the current security context can decrypt them.
  /// return string of the encrypted value.
  ///
  ///```
  ///FlutterWindowsVault.encrypt(
  ///   // the value you want to encrypt
  ///   value: '123456789',
  ///   // fAsSelf: (this works only if encrypted is true) Set to TRUE to specify that the credentials are encrypted in the security context of the current process.
  ///   // Set to FALSE to specify that credentials are encrypted in the security context of the calling thread security context.
  ///   // default value is false.
  ///   fAsSelf: false,
  ///);
  ///```
  ///
  static Future<String> encrypt({
    required String value,
    bool fAsSelf = false,
  }) {
    assert(value.isNotEmpty);
    // assert(fAsSelf != null);
    return _channel.invokeMethod<String>('encrypt',
        {'value': value, 'fAsSelf': fAsSelf}).then((value) => value!);
  }

  /// The CredUnprotect function (uses CredUnprotectW from wincred.h) decrypts credentials that were previously encrypted by using the CredProtect function.
  /// The credentials must have been encrypted in the same security context in which CredUnprotect is called.
  /// return string of the decrypted value.
  ///
  ///```
  ///FlutterWindowsVault.decrypt(
  ///   // the value you want to decrypt
  ///   value: "@@D\u0007\b\f\n\rgAAAAAYppBAAAAAAA5c5uXGQ1pJpY0VrAG-aZawRYNC3MboXJ",
  ///   // fAsSelf: (this works only if encrypted is true) Set to TRUE to specify that the credentials are encrypted in the security context of the current process.
  ///   // Set to FALSE to specify that credentials are encrypted in the security context of the calling thread security context.
  ///   // default value is false.
  ///   fAsSelf: false,
  ///);
  ///```
  ///
  static Future<String> decrypt({
    required String value,
    bool fAsSelf = false,
  }) {
    assert(value.isNotEmpty);
    // assert(fAsSelf != null);
    return _channel.invokeMethod<String>('decrypte',
        {'value': value, 'fAsSelf': fAsSelf}).then((value) => value!);
  }
}

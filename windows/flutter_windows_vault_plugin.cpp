#include "include/flutter_windows_vault/flutter_windows_vault_plugin.h"
// This must be included before many other Windows headers.
#include <windows.h>
// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <wincred.h>
#include <VersionHelpers.h>
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <map>
#include <memory>
#include <sstream>

namespace {

	class FlutterWindowsVaultPlugin : public flutter::Plugin {
	public:
		static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);
		FlutterWindowsVaultPlugin();
		virtual ~FlutterWindowsVaultPlugin();
	private:
		char* encrypt(std::string* value, bool fAsSelf);
		char* decrypte(std::string* value, bool fAsSelf);
		LPWSTR StringToLPWSTR(const char* str);
		char* LPWSTRToString(LPWSTR bytes);
		template<typename T>
		T getArg(const flutter::EncodableValue* args, const char* key);
		void HandleMethodCall(
			const flutter::MethodCall<flutter::EncodableValue>& method_call,
			std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	};


	void FlutterWindowsVaultPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarWindows* registrar) {
		auto channel =
			std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
				registrar->messenger(), "com.ayoub.flutter_windows_vault",
				&flutter::StandardMethodCodec::GetInstance());

		auto plugin = std::make_unique<FlutterWindowsVaultPlugin>();

		channel->SetMethodCallHandler(
			[plugin_pointer = plugin.get()](const auto& call, auto result) {
			plugin_pointer->HandleMethodCall(call, std::move(result));
		});
		registrar->AddPlugin(std::move(plugin));
	}

	FlutterWindowsVaultPlugin::FlutterWindowsVaultPlugin() {}

	FlutterWindowsVaultPlugin::~FlutterWindowsVaultPlugin() {}

	char* FlutterWindowsVaultPlugin::encrypt(std::string* value, bool fAsSelf) {
		LPWSTR encryptionResult{};
		DWORD encryptionSize = 0;
		if (!::CredProtectW(fAsSelf, StringToLPWSTR(value->c_str()), (DWORD)(value->length() + 1), nullptr, &encryptionSize, nullptr)) {
			DWORD error = ::GetLastError();
			if ((ERROR_INSUFFICIENT_BUFFER == error) && (0 < encryptionSize)) {
				encryptionResult = (LPWSTR)CoTaskMemAlloc(encryptionSize * sizeof(wchar_t));
				if (encryptionResult) {
					if (!::CredProtectW(fAsSelf, StringToLPWSTR(value->c_str()), (DWORD)(value->length() + 1), encryptionResult, &encryptionSize, nullptr)) {
						error = ::GetLastError();
						goto handleError;
					}
				}
				else goto handleError;
			}
			else {
			handleError:
				throw error;
			};
		}
		return LPWSTRToString(encryptionResult);
	}

	char* FlutterWindowsVaultPlugin::decrypte(std::string* value, bool fAsSelf) {
		LPWSTR decryptionResult{};
		DWORD decryptionSize = 0;
		if (!::CredUnprotectW(fAsSelf, StringToLPWSTR(value->c_str()), (DWORD)(value->length() + 1), nullptr, &decryptionSize)) {
			DWORD error = ::GetLastError();
			if ((ERROR_INSUFFICIENT_BUFFER == error) && (0 < decryptionSize)) {
				decryptionResult = (LPWSTR)CoTaskMemAlloc(decryptionSize * sizeof(wchar_t));
				if (decryptionResult) {
					if (!::CredUnprotectW(fAsSelf, StringToLPWSTR(value->c_str()), (DWORD)(value->length() + 1), decryptionResult, &decryptionSize)) {
						error = ::GetLastError();
						goto handleError;
					}
				}
				else goto handleError;
			}
			else {
			handleError:
				throw error;
			};
		}
		return LPWSTRToString(decryptionResult);
	}

	LPWSTR FlutterWindowsVaultPlugin::StringToLPWSTR(const char* str) {
		size_t size = strlen(str) + 1;
		LPWSTR result = new wchar_t[size];
		size_t outSize;
		mbstowcs_s(&outSize, result, size, str, size);
		LocalFree(&str);
		LocalFree(&size);
		LocalFree(&outSize);
		return result;
	}

	char* FlutterWindowsVaultPlugin::LPWSTRToString(LPWSTR lstr) {
		size_t size = wcslen(lstr) + 1;
		char* value = new char[size];
		size_t outSize;
		wcstombs_s(&outSize, value, size, lstr, size - 1);
		LocalFree(&outSize);
		LocalFree(&size);
		return value;
	}

	template<typename T>
	T FlutterWindowsVaultPlugin::getArg(const flutter::EncodableValue* args, const char* key) {
		flutter::EncodableMap map = std::get<flutter::EncodableMap>(*args);
		return std::get<T>(map[flutter::EncodableValue(key)]);
	}

	void FlutterWindowsVaultPlugin::HandleMethodCall(
		const flutter::MethodCall<flutter::EncodableValue>& method_call,
		std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
		if (method_call.method_name().compare("getPlatformVersion") == 0) {
			std::ostringstream version_stream;
			version_stream << "Windows ";
			if (IsWindows10OrGreater()) {
				version_stream << "10+";
			}
			else if (IsWindows8OrGreater()) {
				version_stream << "8";
			}
			else if (IsWindows7OrGreater()) {
				version_stream << "7";
			}
			result->Success(flutter::EncodableValue(version_stream.str().c_str()));
		}
		else if (method_call.method_name().compare("set") == 0) {
			const flutter::EncodableValue* args = method_call.arguments();
			std::string key = getArg<std::string>(args, "key");
			std::string value = getArg<std::string>(args, "value");
			int type = getArg<int>(args, "type");
			if (type >= 8) type = CRED_TYPE_MAXIMUM_EX;
			int persist = getArg<int>(args, "persist");
			std::string userName = getArg<std::string>(args, "userName");
			bool encrypted = getArg<bool>(args, "encrypted");
			if (encrypted) {
				bool fAsSelf = getArg<bool>(args, "fAsSelf");
				try {
					value = std::string(encrypt(&value, fAsSelf));
				}
				catch (DWORD error) {
					char* errorCode = "NOT_ENCRYPTED";
					LPSTR messageBuffer = nullptr;
					DWORD size = FormatMessage(
						FORMAT_MESSAGE_ALLOCATE_BUFFER |
						FORMAT_MESSAGE_FROM_SYSTEM |
						FORMAT_MESSAGE_IGNORE_INSERTS,
						NULL,
						error,
						MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
						(LPTSTR)&messageBuffer,
						0, NULL);
					std::string message(messageBuffer, (int)size);
					LocalFree(messageBuffer);
					result->Error(errorCode, message);
					return;
				}
			}
			DWORD cbCreds = (DWORD)(1 + value.length());
			CREDENTIALW cred = { 0 };
			cred.Type = type; // CRED_TYPE_GENERIC
			cred.TargetName = StringToLPWSTR(key.c_str());
			cred.CredentialBlobSize = cbCreds;
			cred.CredentialBlob = (LPBYTE)value.c_str();
			cred.Persist = persist;// CRED_PERSIST_LOCAL_MACHINE;
			cred.UserName = StringToLPWSTR(userName.c_str());
			if (!::CredWriteW(&cred, 0)) {
				DWORD error = ::GetLastError();
				char* errorCode = "NOT_SETTED";
				switch (error) {
				case ERROR_NO_SUCH_LOGON_SESSION: errorCode = "ERROR_NO_SUCH_LOGON_SESSION"; break;
				case ERROR_INVALID_PARAMETER: errorCode = "ERROR_INVALID_PARAMETER"; break;
				case ERROR_INVALID_FLAGS: errorCode = "ERROR_INVALID_FLAGS"; break;
				case ERROR_BAD_USERNAME: errorCode = "ERROR_BAD_USERNAME"; break;
				case ERROR_NOT_FOUND: errorCode = "ERROR_NOT_FOUND"; break;
				case SCARD_E_NO_READERS_AVAILABLE: errorCode = "SCARD_E_NO_READERS_AVAILABLE"; break;
				case SCARD_E_NO_SMARTCARD: errorCode = "SCARD_E_NO_SMARTCARD"; break;
				case SCARD_W_REMOVED_CARD: errorCode = "SCARD_W_REMOVED_CARD"; break;
				case SCARD_W_WRONG_CHV: errorCode = "SCARD_W_WRONG_CHV"; break;
				default: break;
				}
				LPSTR messageBuffer = nullptr;
				DWORD size = FormatMessage(
					FORMAT_MESSAGE_ALLOCATE_BUFFER |
					FORMAT_MESSAGE_FROM_SYSTEM |
					FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					error,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR)&messageBuffer,
					0, NULL);
				std::string message(messageBuffer, (int)size);
				LocalFree(messageBuffer);
				result->Error(errorCode, message);
				return;
			}
			auto r = flutter::EncodableValue();
			r = true;
			result->Success(r);
		}
		else if (method_call.method_name().compare("get") == 0) {
			const flutter::EncodableValue* args = method_call.arguments();
			std::string key = getArg<std::string>(args, "key");
			int type = getArg<int>(args, "type");
			bool encrypted = getArg<bool>(args, "encrypted");
			if (type >= 8) type = CRED_TYPE_MAXIMUM_EX;
			PCREDENTIALW pcred;
			LPWSTR TargetName = StringToLPWSTR(key.c_str());
			if (!::CredReadW(TargetName, type, 0, &pcred)) {
				DWORD error = ::GetLastError();
				char* errorCode = "NOT_GOTTEN";
				switch (error) {
				case ERROR_NOT_FOUND: errorCode = "ERROR_NOT_FOUND"; break;
				case ERROR_NO_SUCH_LOGON_SESSION: errorCode = "ERROR_NO_SUCH_LOGON_SESSION"; break;
				case ERROR_INVALID_FLAGS: errorCode = "ERROR_INVALID_FLAGS"; break;
				default: break;
				}
				LPSTR messageBuffer = nullptr;
				DWORD size = FormatMessage(
					FORMAT_MESSAGE_ALLOCATE_BUFFER |
					FORMAT_MESSAGE_FROM_SYSTEM |
					FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					error,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR)&messageBuffer,
					0, NULL);
				std::string message(messageBuffer, (int)size);
				LocalFree(messageBuffer);
				result->Error(errorCode, message);
				return;
			}
			auto map = flutter::EncodableMap();
			map[flutter::EncodableValue("userName")] = flutter::EncodableValue((const char*)LPWSTRToString(pcred->UserName));
			if (encrypted) {
				std::string value = std::string((char*)pcred->CredentialBlob);
				bool fAsSelf = getArg<bool>(args, "fAsSelf");
				try {
					value = std::string(decrypte(&value, fAsSelf));
					map[flutter::EncodableValue("value")] = flutter::EncodableValue(value.c_str());
				}
				catch (DWORD error) {
					char* errorCode = "NOT_DECRYPTED";
					LPSTR messageBuffer = nullptr;
					DWORD size = FormatMessage(
						FORMAT_MESSAGE_ALLOCATE_BUFFER |
						FORMAT_MESSAGE_FROM_SYSTEM |
						FORMAT_MESSAGE_IGNORE_INSERTS,
						NULL,
						error,
						MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
						(LPTSTR)&messageBuffer,
						0, NULL);
					std::string message(messageBuffer, (int)size);
					LocalFree(messageBuffer);
					result->Error(errorCode, message);
					return;
				}
			} else map[flutter::EncodableValue("value")] = flutter::EncodableValue((const char*)pcred->CredentialBlob);
			map[flutter::EncodableValue("key")] = flutter::EncodableValue((const char*)LPWSTRToString(pcred->TargetName));
			flutter::EncodableValue persist = flutter::EncodableValue(); persist = (int)pcred->Persist; map[flutter::EncodableValue("persist")] = persist;
			flutter::EncodableValue type0 = flutter::EncodableValue(); type0 = (int)pcred->Type; map[flutter::EncodableValue("type")] = type0;
			result->Success(map);
			::CredFree(pcred);
		}
		else if (method_call.method_name().compare("del") == 0) {
			const flutter::EncodableValue* args = method_call.arguments();
			std::string key = getArg<std::string>(args, "key");
			int type = getArg<int>(args, "type");
			if (!::CredDeleteW(StringToLPWSTR(key.c_str()), type, 0)) {
				DWORD error = ::GetLastError();
				char* errorCode = "NET_DELETED";
				switch (error) {
				case ERROR_NOT_FOUND: errorCode = "ERROR_NOT_FOUND"; break;
				case ERROR_NO_SUCH_LOGON_SESSION: errorCode = "ERROR_NO_SUCH_LOGON_SESSION"; break;
				case ERROR_INVALID_FLAGS: errorCode = "ERROR_INVALID_FLAGS"; break;
				default: break;
				}
				LPSTR messageBuffer = nullptr;
				DWORD size = FormatMessage(
					FORMAT_MESSAGE_ALLOCATE_BUFFER |
					FORMAT_MESSAGE_FROM_SYSTEM |
					FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					error,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR)&messageBuffer,
					0, NULL);
				std::string message(messageBuffer, (int)size);
				LocalFree(messageBuffer);
				result->Error(errorCode, message);
				return;
			}
			auto v = flutter::EncodableValue();
			v = true;
			result->Success(v);
		}
		else if (method_call.method_name().compare("list") == 0) {
			const flutter::EncodableValue* args = method_call.arguments();
			PCREDENTIALW* creds;
			DWORD credsCount;
			BOOL ok = false;
			flutter::EncodableMap map = std::get<flutter::EncodableMap>(*args);
			if (auto filterptr = std::get_if<std::string>(&map[flutter::EncodableValue("filter")]))
				ok = CredEnumerateW(StringToLPWSTR(filterptr->c_str()), 0, &credsCount, &creds);
			else ok = CredEnumerateW(NULL, 0, &credsCount, &creds);
			if (!ok) {
				DWORD error = ::GetLastError();
				char* errorCode = "NOT_LISTED";
				switch (error) {
				case ERROR_NOT_FOUND: errorCode = "ERROR_NOT_FOUND"; break;
				case ERROR_NO_SUCH_LOGON_SESSION: errorCode = "ERROR_NO_SUCH_LOGON_SESSION"; break;
				case ERROR_INVALID_FLAGS: errorCode = "ERROR_INVALID_FLAGS"; break;
				default: break;
				}
				LPSTR messageBuffer = nullptr;
				DWORD size = FormatMessage(
					FORMAT_MESSAGE_ALLOCATE_BUFFER |
					FORMAT_MESSAGE_FROM_SYSTEM |
					FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					error,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR)&messageBuffer,
					0, NULL);
				std::string message(messageBuffer, (int)size);
				LocalFree(messageBuffer);
				result->Error(errorCode, message);
				return;
			}
			flutter::EncodableList list = flutter::EncodableList((int)credsCount);
			for (int i = 0; i < (int)credsCount; i++) {
				PCREDENTIALW cred = creds[i];
				flutter::EncodableMap lmap = flutter::EncodableMap();
				if (cred->UserName != NULL)
					lmap[flutter::EncodableValue("userName")] = flutter::EncodableValue((const char*)LPWSTRToString(cred->UserName));
				lmap[flutter::EncodableValue("key")] = flutter::EncodableValue((const char*)LPWSTRToString(cred->TargetName));
				if (cred->CredentialBlob != NULL)
					lmap[flutter::EncodableValue("value")] = flutter::EncodableValue(flutter::EncodableValue((const char*)cred->CredentialBlob));
				flutter::EncodableValue persist = flutter::EncodableValue(); persist = (int)cred->Persist; lmap[flutter::EncodableValue("persist")] = persist;
				flutter::EncodableValue type = flutter::EncodableValue(); type = (int)cred->Type; lmap[flutter::EncodableValue("type")] = type;
				list[i] = lmap;
			}
			::CredFree(creds);
			result->Success(list);
		}
		else if (method_call.method_name().compare("encrypt") == 0) {
			const flutter::EncodableValue* args = method_call.arguments();
			std::string value = getArg<std::string>(args, "value");
			bool fAsSelf = getArg<bool>(args, "fAsSelf");
			try {
				result->Success(flutter::EncodableValue((const char*)encrypt(&value, fAsSelf)));
			}
			catch (DWORD error) {
				char* errorCode = "NOT_ENCRYPTED";
				LPSTR messageBuffer = nullptr;
				DWORD size = FormatMessage(
					FORMAT_MESSAGE_ALLOCATE_BUFFER |
					FORMAT_MESSAGE_FROM_SYSTEM |
					FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					error,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR)&messageBuffer,
					0, NULL);
				std::string message(messageBuffer, (int)size);
				LocalFree(messageBuffer);
				result->Error(errorCode, message);
			}
		}
		else if (method_call.method_name().compare("decrypte") == 0) {
			const flutter::EncodableValue* args = method_call.arguments();
			std::string value = getArg<std::string>(args, "value");
			bool fAsSelf = getArg<bool>(args, "fAsSelf");
			try {
				result->Success(flutter::EncodableValue((const char*)decrypte(&value, fAsSelf)));
			}
			catch (DWORD error) {
				char* errorCode = "NOT_DECRYPTED";
				LPSTR messageBuffer = nullptr;
				DWORD size = FormatMessage(
					FORMAT_MESSAGE_ALLOCATE_BUFFER |
					FORMAT_MESSAGE_FROM_SYSTEM |
					FORMAT_MESSAGE_IGNORE_INSERTS,
					NULL,
					error,
					MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
					(LPTSTR)&messageBuffer,
					0, NULL);
				std::string message(messageBuffer, (int)size);
				LocalFree(messageBuffer);
				result->Error(errorCode, message);
			}
		}
		else result->NotImplemented();
	}

}  // namespace

void FlutterWindowsVaultPluginRegisterWithRegistrar(
	FlutterDesktopPluginRegistrarRef registrar) {
	FlutterWindowsVaultPlugin::RegisterWithRegistrar(
		flutter::PluginRegistrarManager::GetInstance()
		->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

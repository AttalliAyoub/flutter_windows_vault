/// The type of the credential. This member cannot be changed after the credential is created. The following values are valid.
///
/// I | Value                               | Meaning
/// --------------------------------------------------
/// 0 | CRED_TYPE_GENERIC                   | The credential is a generic credential. The credential will not be used by any particular authentication package. The credential will be stored securely but has no other significant characteristics.
/// 1 | CRED_TYPE_DOMAIN_PASSWORD           | The credential is a password credential and is specific to Microsoft's authentication packages. The NTLM, Kerberos, and Negotiate authentication packages will automatically use this credential when connecting to the named target.
/// 2 | CRED_TYPE_DOMAIN_CERTIFICATE        | The credential is a certificate credential and is specific to Microsoft's authentication packages. The Kerberos, Negotiate, and Schannel authentication packages automatically use this credential when connecting to the named target.
/// 3 | CRED_TYPE_DOMAIN_VISIBLE_PASSWORD   | This value is no longer supported. Windows Server 2003 and Windows XP:  The credential is a password credential and is specific to authentication packages from Microsoft. The Passport authentication package will automatically use this credential when connecting to the named target. Additional values will be defined in the future. Applications should be written to allow for credential types they do not understand.
/// 4 | CRED_TYPE_GENERIC_CERTIFICATE       | The credential is a certificate credential that is a generic authentication package. Windows Server 2008, Windows Vista, Windows Server 2003 and Windows XP:  This value is not supported.
/// 5 | CRED_TYPE_DOMAIN_EXTENDED           | The credential is supported by extended Negotiate packages. Windows Server 2008, Windows Vista, Windows Server 2003 and Windows XP:  This value is not supported.
/// 6 | CRED_TYPE_MAXIMUM                   | The maximum number of supported credential types. Windows Server 2008, Windows Vista, Windows Server 2003 and Windows XP:  This value is not supported.
/// 7 | CRED_TYPE_MAXIMUM_EX                | The extended maximum number of supported credential types that now allow new applications to run on older operating systems. Windows Server 2008, Windows Vista, Windows Server 2003 and Windows XP:  This value is not supported.
enum Type {
  CRED_TYPE_GENERIC,
  CRED_TYPE_DOMAIN_PASSWORD,
  CRED_TYPE_DOMAIN_CERTIFICATE,
  CRED_TYPE_DOMAIN_VISIBLE_PASSWORD,
  CRED_TYPE_GENERIC_CERTIFICATE,
  CRED_TYPE_DOMAIN_EXTENDED,
  CRED_TYPE_MAXIMUM,
  CRED_TYPE_MAXIMUM_EX,
}

/// Defines the persistence of this credential. This member can be read and written.
///
/// I | Value                       | Meaning
/// -----------------------------------------
/// 0 | CRED_PERSIST_SESSION        | The credential persists for the life of the logon session. It will not be visible to other logon sessions of this same user. It will not exist after this user logs off and back on.
/// 0 | CRED_PERSIST_LOCAL_MACHINE  | The credential persists for all subsequent logon sessions on this same computer. It is visible to other logon sessions of this same user on this same computer and not visible to logon sessions for this user on other computers. Windows Vista Home Basic, Windows Vista Home Premium, Windows Vista Starter and Windows XP Home Edition:  This value is not supported.
/// 0 | CRED_PERSIST_ENTERPRISE     | The credential persists for all subsequent logon sessions on this same computer. It is visible to other logon sessions of this same user on this same computer and to logon sessions for this user on other computers. This option can be implemented as locally persisted credential if the administrator or user configures the user account to not have roam-able state. For instance, if the user has no roaming profile, the credential will only persist locally. Windows Vista Home Basic, Windows Vista Home Premium, Windows Vista Starter and Windows XP Home Edition:  This value is not supported.
enum Persist {
  CRED_PERSIST_SESSION,
  CRED_PERSIST_LOCAL_MACHINE,
  CRED_PERSIST_ENTERPRISE,
}

/// Cred class is class that holds information about a specific stored CREDENTIALS
///
/// more info go to https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members
class Cred {
  /// The user name of the account used to connect to TargetName.
  ///
  /// If the credential Type is CRED_TYPE_DOMAIN_PASSWORD, this member can be either a DomainNameUserName or a UPN.
  ///
  /// If the credential Type is CRED_TYPE_DOMAIN_CERTIFICATE, this member must be a marshaled certificate reference created by calling CredMarshalCredential with a CertCredential.
  ///
  /// If the credential Type is CRED_TYPE_GENERIC, this member can be non-NULL, but the credential manager ignores the member.
  ///
  /// This member cannot be longer than CRED_MAX_USERNAME_LENGTH (513) characters.
  String userName;

  /// Secret data for the credential. The CredentialBlob (or value) member can be both read and written.
  ///
  /// Secret data for the credential. The CredentialBlob member can be both read and written.
  ///
  /// If the Type member is CRED_TYPE_DOMAIN_PASSWORD, this member contains the plaintext Unicode password for UserName. The CredentialBlob and CredentialBlobSize members do not include a trailing zero character. Also, for CRED_TYPE_DOMAIN_PASSWORD, this member can only be read by the authentication packages.
  ///
  /// If the Type member is CRED_TYPE_DOMAIN_CERTIFICATE, this member contains the clear test Unicode PIN for UserName. The CredentialBlob and CredentialBlobSize members do not include a trailing zero character. Also, this member can only be read by the authentication packages.
  ///
  /// If the Type member is CRED_TYPE_GENERIC, this member is defined by the application.
  ///
  /// Credentials are expected to be portable. Applications should ensure that the data in CredentialBlob is portable. The application defines the byte-endian and alignment of the data in CredentialBlob.
  String value;

  /// The name of the credential. The TargetName (or the key) and Type members uniquely identify the credential. This member cannot be changed after the credential is created. Instead, the credential with the old name should be deleted and the credential with the new name created.
  ///
  /// more info go to https://docs.microsoft.com/en-us/windows/win32/api/wincred/ns-wincred-credentiala#members
  String key;

  /// Defines the persistence of this credential. This member can be read and written.
  Persist persist;

  /// The type of the credential. This member cannot be changed after the credential is created. The following values are valid.
  Type type;

  /// A CREDENTIALS constructor
  Cred({this.userName, this.value, this.key, this.persist, this.type});

  // constructe CREDENTIALS from json (Map) data;
  factory Cred.fromJson(Map<String, dynamic> data) {
    return Cred(
      userName: data['userName'],
      value: data['value'],
      key: data['key'],
      persist: Persist.values[data['persist'] - 1],
      type: Type.values[data['type'] - 1],
    );
  }

  // returns the current Cred instance as json (Map);
  Map<String, dynamic> get toJson {
    return {
      'userName': userName,
      'value': value,
      'key': key,
      'persist': persist?.toString()?.replaceAll("Persist.", ""),
      'type': type?.toString()?.replaceAll("Type.", ""),
    };
  }
}

import Foundation
import Security

enum Keychain {
    static func set(_ data: Data, for key: String) {
        let q: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                               kSecAttrAccount as String: key]
        SecItemDelete(q as CFDictionary)
        var item = q; item[kSecValueData as String] = data
        SecItemAdd(item as CFDictionary, nil)
    }
    
    static func get(_ key: String) -> Data? {
        let q: [String:Any] = [kSecClass as String: kSecClassGenericPassword,
                               kSecAttrAccount as String: key,
                               kSecReturnData as String: true,
                               kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &out)
        return status == errSecSuccess ? out as? Data : nil
    }
    
    static func delete(_ key: String) {
        SecItemDelete([kSecClass:kSecClassGenericPassword,
                       kSecAttrAccount:key] as CFDictionary)
    }
}
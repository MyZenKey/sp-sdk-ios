//
//  JsonDocument.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import Foundation

enum JsonErrorCode: Int {
    case parseError
    case keyNotFound
    case unknownNodeType    // add code to correct these cases as they are found
}

enum JsonDocument: CustomStringConvertible {
    
    // node types
    case stringNode(String)
    case numberNode(NSNumber)
    case nullNode
    case dictionaryNode([String: JsonDocument])
    case arrayNode([JsonDocument])
    case errorNode(NSError)
    
    /*
    Printable description as valid compressed JSON. Any error nodes will be represented as valid escaped string nodes.
    */
    
    var description: String {
        switch self {
            
        case .stringNode(let str):
            return "\"\(str.jsonEscaped())\""
            
        case .numberNode(let number):
            return "\(number)"  // TODO: use formatter?
            
        case .nullNode:
            return "null"
            
        case .dictionaryNode(let dict):
            var result = ""
            if dict.isEmpty {
                return "{}"
            } else {
                for (key, value) in dict {
                    if result.isEmpty {
                        result += "{"
                    } else {
                        result += ","
                    }
                    result += "\"\(key.jsonEscaped())\":\(value)"
                }
                return result + "}"
            }
            
        case .arrayNode(let arr):
            return "\(arr)"
            
        case .errorNode(let err):
            return "\"\(err.description.jsonEscaped())\""
        }
    }
    
    /*
    Create default JSON document (error node).
    */
    
    init() {
        self = JsonDocument.errorNode(NSError(domain: "JSON_Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty json document."]))
    }
    
    /* Create a json document from a key and another JSON document as a value. */
    
    init(key: String, value: JsonDocument) {
        self = JsonDocument.dictionaryNode([key: value])
    }
    
    /* Create a JSON document from a dictionary of keys (strings) and values (JsonDocument). */
    
    init(dict: [String: JsonDocument]) {
        self = JsonDocument.dictionaryNode(dict)
    }
    
    /// Create a JSON document from a Data object.
    ///
    /// - Parameter data: The Data object used to create the JSON.
    init(data: Data?) {
        if let data = data {
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
                self = JsonDocument(object: jsonObj)
            } catch let error {
                self = JsonDocument.errorNode(NSError(domain: "JSON_Error",
                                                      code: JsonErrorCode.parseError.rawValue,
                                                      userInfo: [NSLocalizedDescriptionKey: "Couldn't parse json: \(error)"]))
            }
        } else {
            self = JsonDocument.errorNode(NSError(domain: "JSON_Error",
                                                  code: JsonErrorCode.parseError.rawValue,
                                                  userInfo: [NSLocalizedDescriptionKey: "Can't parse empty json."]))
        }
    }
    
    /// Create a JSON document from a String object.
    ///
    /// - Parameter data: The Data object used to create the JSON.
    init(string: String?) {
        if let string = string, let data = string.data(using: .utf8) {
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: [])
                self = JsonDocument(object: jsonObj)
            } catch let error {
                self = JsonDocument.errorNode(NSError(domain: "JSON_Error",
                                                      code: JsonErrorCode.parseError.rawValue,
                                                      userInfo: [NSLocalizedDescriptionKey: "Couldn't parse json: \(error)"]))
            }
        } else {
            self = JsonDocument.errorNode(NSError(domain: "JSON_Error",
                                                  code: JsonErrorCode.parseError.rawValue,
                                                  userInfo: [NSLocalizedDescriptionKey: "Can't parse empty json."]))
        }
    }
    
    /*
    Create a JSON document (node) from another JSON document (node). Nodes will be created recursively until the entire JSON structure returned from deserialization is walked.
    */
    
    init(object: Any) {
        switch object {
        case let str as String:
            self = .stringNode(str)
            
        case let number as NSNumber:
            self = .numberNode(number)
            
        case _ as NSNull:
            self = .nullNode
            
        case let dict as NSDictionary:
            var jsonDict = [String: JsonDocument]()
            for (key, value): (Any, Any) in dict {
                if let stringKey = key as? String {
                    jsonDict[stringKey] = JsonDocument(object: value)
                }
            }
            self = .dictionaryNode(jsonDict)
            
        case let dict as [String: Any]:
            var jsonDict = [String: JsonDocument]()
            for (key, value): (String, Any) in dict {
                if let json = value as? JsonDocument {
                    jsonDict[key] = json
                } else {
                    jsonDict[key] = JsonDocument(object: value)
                }
            }
            self = .dictionaryNode(jsonDict)
            
        case let array as NSArray:
            var jsonArray = [JsonDocument]()
            for value in array {
                jsonArray += [JsonDocument(object: value)]
            }
            self = .arrayNode(jsonArray)
            
        case let json as JsonDocument:
            self = json
            
        default:
            self = .errorNode(NSError(domain: "JSON_Error", code: JsonErrorCode.unknownNodeType.rawValue, userInfo: [NSLocalizedDescriptionKey: "Unknown node: \(object)"]))
        }
    }
    
    /*
    Return a node given a key.
    */

    subscript(key: String) -> JsonDocument {
        get {
            switch self {
            case .dictionaryNode(let dictionary):
                if let value = dictionary[key] {
                    return value
                } else {
                    return JsonDocument.errorNode(NSError(domain: "JSON_Error", code: JsonErrorCode.keyNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey: "Key not found: \(key)"]))
                }
            default:
                return JsonDocument.errorNode(NSError(domain: "JSON_Error", code: JsonErrorCode.keyNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey: "Key not found: \(key)"]))
            }
        }
    }
    
    /*
    Return true if this node is exists and is not an error.
    */
    
    var exists: Bool {
        switch self {
        case .errorNode(_):
            return false
        case .nullNode:
            return false
        default:
            return true
        }
    }

    /*
     Attempt to convert a node to a string. If the node is not a string (i.e it's a dictionary or array) return nil.
     */
    
    var toString: String? {
        switch self {
        case .stringNode(let value):
            return value
        default:
            return nil
        }
    }
    
    /*
     Attempt to convert a node to a number. If the node is not a number (i.e it's a dictionary or array) return nil.
     */
    
    var toNumber: NSNumber? {
        switch self {
        case .numberNode(let value):
            return value
        default:
            return nil
        }
    }
    
    /*
     Attempt to convert a node to a Double. If the node is not a number (i.e it's a dictionary or array) return nil.
     */
    
    var toDouble: Double? {
        if let number = self.toNumber {
            return number.doubleValue
        } else {
            return nil
        }
    }
    
    /*
     Attempt to convert a node to a Int. If the node is not a number (i.e it's a dictionary or array) return nil.
     */
    
    var toInt: Int? {
        if let number = self.toNumber {
            return number.intValue
        } else {
            return nil
        }
    }
    
    /// Returns true or false if the node value exists and is "true" or "false". Returns nil otherwise.
    var toBoolOptional: Bool? {
        guard let boolText = self.toString else {
            return nil
        }
        
        switch boolText {
        case "true":
            return true
        case "false":
            return false
        default:
            return nil
        }
    }
    
    /* Convert node to Bool. It will only return true if the node is a string and is "true". Everything else will be false. */
    
    var toBool: Bool {
        if let boolText = self.toString {
            return boolText == "true"
        }
        return false
    }
    
    /*
    Return true if this node is null, false otherwise.
    */
    
    var isNull: Bool {
        switch self {
        case .nullNode:
            return true
        default:
            return false
        }
    }
    
    /*
    Return true if node is a dictionary.
    */
    
    var isDict: Bool {
        switch self {
        case .dictionaryNode(_):
            return true
        default:
            return false
        }
    }
    
    /*
    Return true if node is an array.
    */
    
    var isArray: Bool {
        switch self {
        case .arrayNode(_):
            return true
        default:
            return false
        }
    }
    
    /*
     Attempt to convert a node to a dictionary. If the node is not a dictionary (i.e it's a string or array) return nil.
     */
    
    var toDict: [String: JsonDocument]? {
        switch self {
        case .dictionaryNode(let value):
            return value
        default:
            return nil
        }
    }
    
    /*
     Returns as node as itself but only if it's a dictionary node.
     */
    
    var toJsonIfDict: JsonDocument? {
        switch self {
        case .dictionaryNode:
            return self
        default:
            return nil
        }
    }
    
    /*
    Attempt to convert a node to an array. If the node is not a array (i.e it's a string or dictionary) return nil.
    */
    
    var toArray: [JsonDocument]? {
        switch self {
        case .arrayNode(let value):
            return value
        default:
            return nil
        }
    }
    
    /*
     Attempt to convert a node to an array. If the node is not a array or dict return nil.
     */
    
    var toArrayIfArrayOrDict: [JsonDocument]? {
        switch self {
        case .arrayNode(let value):
            return value
        case .dictionaryNode(let node):
            return [JsonDocument(dict: node)]
        default:
            return nil
        }
    }
    
    /*
    If the node is an error type, return nil, otherwise return the document. This is so we can use the "if let" syntax to make sure a document node actually exists.
    */
    
    var toDocument: JsonDocument? {
        switch self {
        case .errorNode:
            return nil
        default:
            return self
        }
    }
    
    /*
    Returns the json document as NSData, suitable for persisting.
    */

    var toData: Data? {
        return description.data(using: String.Encoding.utf8)
    }
}

extension String {
    static let charToEscapedJsonString: [Character: String] = [
        Character("\""): "\\\"",
        Character("\\"): "\\\\",
        Character("/"): "\\/",
        Character(UnicodeScalar(0x0000)): "\\u0000",
        Character(UnicodeScalar(0x0001)): "\\u0001",
        Character(UnicodeScalar(0x0002)): "\\u0002",
        Character(UnicodeScalar(0x0003)): "\\u0003",
        Character(UnicodeScalar(0x0004)): "\\u0004",
        Character(UnicodeScalar(0x0005)): "\\u0005",
        Character(UnicodeScalar(0x0006)): "\\u0006",
        Character(UnicodeScalar(0x0007)): "\\u0007",
        Character(UnicodeScalar(0x0008)): "\\b",        // backspace
        Character(UnicodeScalar(0x0009)): "\\t",        // tab
        Character(UnicodeScalar(0x000a)): "\\n",        // line feed
        Character(UnicodeScalar(0x000b)): "\\u000b",
        Character(UnicodeScalar(0x000c)): "\\f",        // form feed
        Character(UnicodeScalar(0x000d)): "\\r",        // carriage return
        Character(UnicodeScalar(0x000e)): "\\u000e",
        Character(UnicodeScalar(0x000f)): "\\u000f",
        Character(UnicodeScalar(0x0010)): "\\u0010",
        Character(UnicodeScalar(0x0011)): "\\u0011",
        Character(UnicodeScalar(0x0012)): "\\u0012",
        Character(UnicodeScalar(0x0013)): "\\u0013",
        Character(UnicodeScalar(0x0014)): "\\u0014",
        Character(UnicodeScalar(0x0015)): "\\u0015",
        Character(UnicodeScalar(0x0016)): "\\u0016",
        Character(UnicodeScalar(0x0017)): "\\u0017",
        Character(UnicodeScalar(0x0018)): "\\u0018",
        Character(UnicodeScalar(0x0019)): "\\u0019",
        Character(UnicodeScalar(0x001a)): "\\u001a",
        Character(UnicodeScalar(0x001b)): "\\u001b",
        Character(UnicodeScalar(0x001c)): "\\u001c",
        Character(UnicodeScalar(0x001d)): "\\u001d",
        Character(UnicodeScalar(0x001e)): "\\u001e",
        Character(UnicodeScalar(0x001f)): "\\u001f",
        Character("\r\n"): "\\r",                       // combined \r\n glyph; converting to \r since \n has no meaning for iOS/macOS
        ]
    
    static let charsToEscapeForJson = CharacterSet(charactersIn: "\"\\/\u{0000}\u{0001}\u{0002}\u{0003}\u{0004}\u{0005}\u{0006}\u{0007}\u{0008}\u{0009}\u{000a}\u{000b}\u{000c}\u{000d}\u{000e}\u{000f}\u{0010}\u{0011}\u{0012}\u{0013}\u{0014}\u{0015}\u{0016}\u{0017}\u{0018}\u{0019}\u{001a}\u{001b}\u{001c}\u{001d}\u{001e}\u{001f}")
    
    func jsonEscaped() -> String {
        // optimization: return self if no need to escape anything
        guard let _ = rangeOfCharacter(from: String.charsToEscapeForJson) else {
            return self
        }
        
        // non-optimized, but easy to write and understand
        
        // string needs to be escaped, start processing here
        let escapedString = map({
            if let escapeValue = String.charToEscapedJsonString[$0] {
                return escapeValue
            } else {
                return String($0)
            }
        }).joined(separator: "")
        return escapedString
    }
}

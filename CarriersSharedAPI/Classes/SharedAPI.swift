//
//  SharedAPI.swift
//  CarriersSharedAPI
//
//  Created by John Moline on 11/5/18.
//  Copyright © 2018 John Moline. All rights reserved.
//

import UIKit
import Foundation
import CoreTelephony

public class SharedAPI {
    
    //private variables
    var mcc:String?
    var mnc:String?
    public var carrierName:String?
    var attCodes:[String] = ["070", "560", "410", "380", "170", "150", "680", "980"];
    var tMobileCodes = ["160", "200", "210", "220", "230", "240", "250", "260", "270", "310", "490", "660", "800", "031", "300", "280", "330"];
    var verizonCodes = ["010", "012", "013", "590", "890", "910", "004","110", "270", "271", "272", "273", "274", "275", "276", "277", "278", "279", "280", "281", "282", "283", "284", "285", "286", "287", "288", "289", "390", "480", "481", "482", "483", "484", "485", "486", "487", "488", "489"];
    var discoveryData = ["tmo":["scopes_supported":"openid email profile", "response_types_supported":"code", "userinfo_endpoint":"https://iam.msg.t-mobile.com/oidc/v1/userinfo", "token_endpoint":"https://brass.account.t-mobile.com/tms/v3/usertoken", "authorization_endpoint":"https://account.t-mobile.com/oauth2/v1/auth", "issuer":"https://ppd.account.t-mobile.com"], "vzw":["scopes_supported":"openid email profile", "response_types_supported":"code", "userinfo_endpoint":"https://api.yourmobileid.com:22790/userinfo", "token_endpoint":"https://auth.svcs.verizon.com:22790/vzconnect/token", "authorization_endpoint":"https://auth.svcs.verizon.com:22790/vzconnect/authorize", "issuer":"https://auth.svcs.verizon.com"], "att":["scopes_supported":"email zipcode name phone", "response_types_supported":"code", "userinfo_endpoint":"https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/userinfo", "token_endpoint":"https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/token", "authorization_endpoint":"https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/authorize", "issuer":"https://oidc.test.xlogin.att.com"]]
    var discoveryEndpoint:String? = nil
    var configuration:[String:Any]? = nil
    
    //constructor
    public init() {
        //init device data lookup
        self.getDeviceData()
        
        //init discovery
        //self.discoveryEndpoint = "http://ec2-18-208-92-241.compute-1.amazonaws.com/ccarrier/.well-known/openid-configuration?name=att"
        self.discoveryEndpoint = "https://100.25.175.177/.well-known/openid_configuration?config=false&mcc=" + self.getMCC() + "&mnc=" + self.getMNC()
        //self.discoveryEndpoint = "http://100.25.175.177/.well-known/openid_configuration?mcc=310&mnc=210&config=true"
        //self.discoveryEndpoint = "https://dev-764172-admin.oktapreview.com/.well-known/openid-configuration"
        self.performDiscovery()
    }
    
    //this function will perform a backup discovery
    private func performDiscovery() {
        print("Performing primary discovery lookup")
        let request = NSMutableURLRequest(url: URL(string:self.discoveryEndpoint!) as! URL)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            print("Discovery Information has returned")
            if(error == nil) {
                if let res = response as? HTTPURLResponse {
                    print(res)
                    let responseString = String(data: data!, encoding:String.Encoding.utf8) as String!
                    print(responseString)
                    do {
                        //convert the json string to pure json
                        if let json = responseString!.data(using: String.Encoding.utf8){
                            var jsonDocument:JsonDocument = JsonDocument(data: json)
                            self.configuration = ["scopes_supported":"openid email profile", "response_types_supported":"code", "userinfo_endpoint":jsonDocument["userinfo_endpoint"].toString, "token_endpoint":jsonDocument["token_endpoint"].toString, "authorization_endpoint":jsonDocument["authorization_endpoint"].toString, "issuer":jsonDocument["issuer"].toString]
                        }
                    } catch {
                        print(error.localizedDescription)
                        self.configuration = nil
                    }
                }
            }
            else {
                print(error)
                self.configuration = nil
            }
        }
        task.resume()
    }
    
    //this function will get the device data
    private func getDeviceData() {
        //populate the mcc and mnc codes
        var configuration:[String:Any]? = nil;
        var mob = CTTelephonyNetworkInfo()
        if let r = mob.subscriberCellularProvider {
            self.mcc = r.mobileCountryCode
            self.mnc = r.mobileNetworkCode
            print("Found MCC: " + self.mcc!)
            print("Found MNC: " + self.mnc!)
        }
    }
    
    //this function will supply the carrier information based on discovery
    public func discoverCarrierConfiguration() -> [String:Any]? {
        print("Acquiring discovery data...")
        //check if configuration is still nil
        if configuration == nil {
            //check if mcc is a US code
            if self.mcc == "310" || self.mcc == "311" {
                print("Found US country code - " + self.mcc!)
                if attCodes.contains(self.mnc!) {
                    print("Found ATT")
                    self.carrierName = "att"
                    configuration = discoveryData[self.carrierName!]
                }
                else if verizonCodes.contains(mnc!) {
                    print("Found VERIZON")
                    self.carrierName = "vzw"
                    configuration = discoveryData[self.carrierName!]
                }
                else if tMobileCodes.contains(mnc!) {
                    print("Found T-MOBILE")
                    self.carrierName = "tmo"
                    configuration = discoveryData[self.carrierName!]
                }
            }
        }
        return configuration
    }
    
    //this function will return the mcc code
    public func getMCC() -> String {
        return self.mcc ?? ""
    }
    
    //this function will return the mnc code
    public func getMNC() -> String {
        return self.mnc ?? ""
    }
}



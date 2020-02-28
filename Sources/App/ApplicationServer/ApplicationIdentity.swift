//
//  ApplicationIdentity.swift
//  App
//
//  Created by Luca MURATORE on 22/02/2020.
//

import Vapor

struct ApplicationIdentity: Codable, Hashable {
    /// ise a gloabal key for unique identifay unique
    public var key: UUID?
    /// a bundle name
    public var bundle = ""
    /// application name
    public var name: String = ""
    /// define the payed key
    public var subscription: String = ""
    /// define the device of application
    public var device: String = ""
    public var browser: String = ""
    
    
    
    init() {
        key = UUID()
        name =  ""
        device = ""
        browser = ""
        subscription = ""
    }
    
    init(keyValue: UUID) {
        key = keyValue
        name =  ""
        device = ""
        browser = ""
        subscription = ""
    }
    
    /// Define the hash value
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
    }
    
    /// Implement the equalizer
    static func == (lhs: ApplicationIdentity, rhs: ApplicationIdentity) -> Bool {
        return lhs.key == rhs.key
    }
    
}

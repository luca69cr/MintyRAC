//
//  ApplicationIdentity.swift
//  App
//
//  Created by Luca MURATORE on 22/02/2020.
//

import Foundation

struct ApplicationIdentity: Codable {
    public var key: UUID
    public var name: String = ""
    public var device: String = ""
    public var browser: String = ""
    
    
    init() {
        key = UUID()
        name =  ""
        device = ""
        browser = ""
    }
    
}

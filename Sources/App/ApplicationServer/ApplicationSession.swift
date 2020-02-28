//
//  ApplicationSession.swift
//  App
//
//  Created by Luca MURATORE on 22/02/2020.
///
/// for evaluated memory leack i find this issue that solve the problem
/// https://github.com/vapor/vapor/issues/1792

import Vapor


/// Define the Session of one application that join websocket channel, it
/// echange bidirectional application message with client connected to the same socket.
///
/// it compute concurrent reactivity with socket event methodology.
/// Only the message, when received, will be processed in FIFO mode.
final class ApplicationSession: Hashable {
    
    public var          key: UUID
    public var subscriptionKey: String = ""
    public var          appIdentity: ApplicationIdentity? = nil
    //unowned private var channel: WebSocket?
    unowned private var appController: ApplicationController?
    private var         messageQueue: DispatchQueue?
    private var         clientState: String = ""
    
    ///Initialize application session attribute
    init(appId: ApplicationIdentity, controller: ApplicationController ) {
        
        /// create a session key
        self.key = UUID()
        /// Create a new application identity
        self.appIdentity = appId
        /// SevreKey/AppIdentityKey/SessionKey
        self.subscriptionKey = controller.key.uuidString + ":" + appId.key!.uuidString + ":" + self.key.uuidString
        /// Hold a controller for interaction
        self.appController = controller
        /// Create a thread queue named with application key
        self.messageQueue = DispatchQueue(label: self.key.uuidString, attributes: .concurrent)
        /// set the application state
        self.clientState = "ACTIVE"
    }
       
    
    /// Destroy process of Session
    deinit {
        print("Bye session: \(self.key)")
        
        ///  if socket isnt' closed close it
        //if (!self.channel!.isClosed){
        //    self.channel!.close()
        //}
        
        /// Reinitialize propertyes for reallocate memory
        self.appIdentity = nil
        //self.channel = nil
        self.appController = nil
    }
    
    
    /// Define the hash value
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.key)
    }
    
    /// Implement the equalizer
    static func == (lhs: ApplicationSession, rhs: ApplicationSession) -> Bool {
        return lhs.key == rhs.key
    }
}

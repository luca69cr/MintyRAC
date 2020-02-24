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
    
    public var          appIdentity: ApplicationIdentity? = nil
    unowned private var channel: WebSocket?
    unowned private var appController: ApplicationController?
    private var         messageQueue: DispatchQueue?
    private var         state: String = ""
    
    ///Initialize application session attribute
    init(socket: WebSocket, controller: ApplicationController ) {
        
        /// Create a new application identity
        self.appIdentity = ApplicationIdentity()
        /// hold a socket channel
        self.channel = socket
        /// Hold a controller for interaction
        self.appController = controller
        /// Create a thread queue named with application key
        self.messageQueue = DispatchQueue(label: appIdentity!.key.uuidString, attributes: .concurrent)
        /// set the application state
        self.state = "ACTIVE"
        
        ///************** Next connect to websocket handler**************
        
        ///**web socket message received**
        socket.onText {
            [weak self]
            (ws, text) in
        
            /// the message was processed in thread with FIFO order, this is compliant to sequence messaging behavior
            guard (self?.messageQueue != nil) else {return}
            self!.messageQueue!.sync {
                // Simply echo any received text
                ws.send("\(self!.appIdentity!.key): \(text)")
            }
        }
        
        ///**websocket HeartBeat timed to 30 second**
        socket.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(15), delay: .seconds(30)) {
            [weak self]
            task -> Void in
            
            /// check if the socket was cloded
            guard !socket.isClosed else {
                task.cancel()
                return
            }
            
            // send the heartbeat signal
            socket.send(raw: (self!.appIdentity!.key.uuidString), opcode: .ping)
        }
        
        ///**websocket close handler**
        socket.onCloseCode {
            [weak self]
            (WebSocketErrorCode) in
            
            //self?.appController?.CloseSession(identity: (self!.appIdentity!))
            self?.appController!.DestroySession(appIdentity: ((self?.appIdentity!)!))
        }
        
        ///**websocket error handler**
        socket.onError {
            [weak self]
            (ws, error) in
            
            print(error)
        }
    }
    
    /// Destroy process of Session
    deinit {
        print("Bye session: \(appIdentity!.key)")
        
        ///  if socket isnt' closed close it
        if (!self.channel!.isClosed){
            self.channel!.close()
        }
        
        /// Reinitialize propertyes for reallocate memory
        self.appIdentity = nil
        self.channel = nil
        self.appController = nil
    }
    
    
    /// Define the hash value
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.appIdentity!.key)
    }
    
    /// Implement the equalizer
    static func == (lhs: ApplicationSession, rhs: ApplicationSession) -> Bool {
        return lhs.appIdentity!.key == rhs.appIdentity!.key
    }
}

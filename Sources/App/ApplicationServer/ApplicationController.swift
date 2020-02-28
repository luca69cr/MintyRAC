/// ApplicationController.swift
///
/// ** Copyright (c) 2008-2012 MintyCode All rights reserved.**
///
///  Created by Luca MURATORE on 20/02/2020.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///   http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

import Vapor
import Redis


/// Application Session controller
/// is a vapor service registered in configure procedure
///
/// Define the possible creation and destroy of an  Application Session.
/// The concurrent theading is demande to socket threading reacivity mapped by Application Session
///

final class ApplicationController: Service {
    
    ///is a server Key
    final public var key = UUID()
    
    struct rawSessionHandler {
        var session: ApplicationSession
        var channel: WebSocket
        var redisChannel: RedisClient
        var httpRequest: Request
    }
    final private var handledSessions:[rawSessionHandler] = []
    //final private var handledSessions = Set<rawSessionHandler>()
    
    
    
    init(){
        //appSessions.removeAll()
    }
    
    deinit {
        /// all application session are destroyed
        self.handledSessions.removeAll()
    }
    
    func ConnectSessionTo(channel: WebSocket, request: Request){
        
        let _ = request.withPooledConnection(to: .redis, closure: {
            [weak self, unowned channel, unowned request]
            (connection) -> Future<Void> in
            
            ///if a connection on redis is active create a new application session and old
            let newSession = ApplicationSession(appId: ApplicationIdentity(), controller: self!)
            self!.handledSessions.append(rawSessionHandler(session: newSession, channel: channel, redisChannel:connection, httpRequest: request))
            
            print("connected")
            
            let  _ = try! connection.subscribe([ "randomStringHere.pippo"], subscriptionHandler: {
                (rData) in
                
               // print(rData.data.string)
                channel.send("Redis message: \(rData.data.string)")
                return
            })
            
            /// setted for olding in websocket closure
            let idxSession = self!.handledSessions.count - 1
            guard idxSession>0 else {return request.future()}
            let keySession = self!.handledSessions.last!.session.key
            
            ///************** Connect to websocket handler**************
            
            ///**websocket HeartBeat timed to 30 second**
            channel.eventLoop.scheduleRepeatedTask(initialDelay: .seconds(15), delay: .seconds(30)) {
                [weak self]
                task -> Void in
                
                ///owned by closure
                let keySessionIdx = keySession
                let rawIdx = self!.handledSessions.firstIndex(where: { $0.session.key == keySessionIdx})
                guard (rawIdx != nil) else {return}
                
                /// check if the socket was cloded
                guard !channel.isClosed else {
                    task.cancel()
                    return
                }
                
                // send the heartbeat signal
                print("ping: \(self!.handledSessions[rawIdx!].session.subscriptionKey)")
                channel.send(raw: (self!.handledSessions[rawIdx!].session.subscriptionKey), opcode: .ping)
            }
            
            ///**websocket close handler**
            channel.onCloseCode {
                [weak self]
                (WebSocketErrorCode) in
                
                ///owned by closure
                let keySessionIdx = keySession
                let rawIdx = self!.handledSessions.firstIndex(where: { $0.session.key == keySessionIdx})
                //let rawIdx = self!.handledSessions.firstIndex(where: { $0.channel == channel})
                guard (rawIdx != nil) else {return}
                
                self?.handledSessions[rawIdx!].redisChannel.close()
                print("closed")
                
                self?.handledSessions.remove(at: rawIdx!)
            }
            
            ///**web socket message received**
            channel.onText {
                [weak self]
                (ws, text) in
                
                ///owned by closure
                let keySessionIdx = keySession
                let rawIdx = self!.handledSessions.firstIndex(where: { $0.session.key == keySessionIdx})
                
                    // Simply echo any received text
                ws.send("message: \(text)")
            }
            
            ///**websocket error handler**
            channel.onError {
                [weak self]
                (ws, error) in
                
                ///owned by closure
                let keySessionIdx = keySession
                let rawIdx = self!.handledSessions.firstIndex(where: { $0.session.key == keySessionIdx})
                print(error)
            }
            
            return request.future()
        }).catchFlatMap({ (errr) -> (EventLoopFuture<Void>) in
            print("error get redis pool" + errr.localizedDescription)
            return request.future()
        })
 
        ///move this on application session
        ///self.handledSessions[idxSession].channel.send("Welcome application: \(self.handledSessions[idxSession].session.subscriptionKey)")
    }
    
    func ReConnectTo(channel: WebSocket, request: Request){}
    
    func CloneTo(channel: WebSocket, request: Request){}
    
    final func DestroySession(appIdentity: ApplicationIdentity){
        
        /// check non empty sessions set;
        /*guard (!self.appSessions.isEmpty) else {
            print("WARNING_DESTROY_SESSION: without sessions presence")
            return
        }
        
        /// find the appSession joined with sochet channel
        let toRemove = self.appSessions.first(where: { $0.appIdentity!.key == appIdentity.key })
        
        guard (toRemove != nil) else {
            print("WARNING_DESTROY_SESSION: invalid application session")
            return}
        
        /// remove the session that handle closed channel
        self.appSessions.remove(at: appSessions.firstIndex(of: toRemove!)!)*/
    }
}

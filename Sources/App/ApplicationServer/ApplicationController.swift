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


/// Application Session controller
/// is a vapor service registered in configure procedure
///
/// Define the possible creation and destroy of an  Application Session.
/// The concurrent theading is demande to socket threading reacivity mapped by Application Session
///

final class ApplicationController: Service {
    
    final private var appSessions:[ApplicationSession] = []
    
    init(){
        //appSessions.removeAll()
    }
    
    deinit {
        /// all application session are destroyed
        self.appSessions.removeAll()
    }
    
    func ConnectSessionTo(channel: WebSocket, request: Request){

        let newSession = ApplicationSession(socket: channel, controller: self)
        self.appSessions.append(newSession)
        
        ///move this on application session
        channel.send("Welcome application: \(newSession.appIdentity!.key)")
    }
    
    func ReConnectTo(channel: WebSocket, request: Request){}
    
    func CloneTo(channel: WebSocket, request: Request){}
    
    final func DestroySession(appIdentity: ApplicationIdentity){
        
        /// check non empty sessions set;
        guard (!self.appSessions.isEmpty) else {
            print("WARNING_DESTROY_SESSION: without sessions presence")
            return
        }
        
        /// find the appSession joined with sochet channel
        let toRemove = self.appSessions.first(where: { $0.appIdentity!.key == appIdentity.key })
        
        guard (toRemove != nil) else {
            print("WARNING_DESTROY_SESSION: invalid application session")
            return}
        
        /// remove the session that handle closed channel
        self.appSessions.remove(at: appSessions.firstIndex(of: toRemove!)!)
    }
}

//
//  GatewayHandler.swift
//  Sword
//
//  Created by Alejandro Alonso
//  Copyright © 2018 Alejandro Alonso. All rights reserved.
//

import Foundation
import Starscream

/// Represents a WebSocket session for Discord
protocol GatewayHandler : AnyObject {
  /// Internal WebSocket session
  var session: WebSocket? { get set }

  /// Connects the handler to a specific gateway URL
  ///
  /// - parameter host: The gateway URL that this shard needs to connect to
  func connect(to host: String)
  
  /// Disconnects the handler from the gateway
  func disconnect()
  
  /// Defines what to do when data is received as text
  ///
  /// - parameter text: The String that was received from the gateway
  func handleText(_ text: String)
  
  /// Reconnects the handler to the gateway
  func reconnect()
}

extension GatewayHandler {
  /// Connects the handler to a specific gateway URL
  ///
  /// - parameter host: The gateway URL that this shard needs to connect to
  func connect(to host: String) {
    session = WebSocket(url: URL(string: host)!)
    
    session?.onText = { [weak self] text in
      guard let this = self else {
        Sword.log(.error, "Unable to capture gateway handler after receiving data.")
        return
      }
      
      this.handleText(text)
    }
    
    session?.connect()
  }
  
  /// Disconnects the handler from the gateway
  func disconnect() {
    session?.disconnect()
  }
}

//
//  Sword.swift
//  Sword
//
//  Created by Alejandro Alonso
//  Copyright © 2018 Alejandro Alonso. All rights reserved.
//

import Foundation
import Dispatch

/// Swift meets Discord
open class Sword {
  /// Mappings from command names/aliases to base command
  var commandMap = [String: Command]()
  
  /// Used to decode stuff from Discord
  static let decoder = JSONDecoder()
  
  /// Used to encode stuff to send off to Discord
  static let encoder = JSONEncoder()
  
  /// Used to determine if the bot is disconnected
  static var isDisconnected = false
  
  /// Customizable options used when setting up the bot
  public var options: Options
  
  /// Shared URLSession
  let session = URLSession.shared
  
  /// Shard Manager
  lazy var shardManager = Shard.Manager()
  
  /// Bot's Chuck E Cheese token to the magical world of Discord's API
  let token: String
  
  /// Instantiates a Sword instance
  ///
  /// - parameter token: The bot token used to connect to Discord's API
  /// - parameter options: Customizable options used when setting up the bot
  public init(token: String, options: Options = Options()) {
    self.options = options
    self.token = token
    
    if options.willLog {
      Sword.Logger.isEnabled = true
    }
  }
  
  /// Connects the bot
  public func connect() {
    getGateway { [weak self] info, error in
      guard let info = info,
            let this = self else {
        return
      }
      
      this.shardManager.sword = this
      
      for i in 0 ..< info.shards {
        this.shardManager.spawn(i, to: info.url.absoluteString)
      }
    }
    
    while !Sword.isDisconnected
      && RunLoop.main.run(mode: .defaultRunLoopMode, before: .distantFuture) {}
  }
  
  /// Disconnects the bot
  public func disconnect() {
    shardManager.disconnect()
    Sword.isDisconnected = true
  }
  
  /// Get's the bot's initial gateway information for the websocket
  public func getGateway(then: @escaping (GatewayInfo?, Sword.Error?) -> ()) {
    request(.gateway()) { data, error in
      guard let data = data else {
        then(nil, error)
        return
      }
      
      do {
        try then(Sword.decoder.decode(GatewayInfo.self, from: data), nil)
      } catch {
        then(nil, Sword.Error(error.localizedDescription))
      }
    }
  }
  
  /// Sends a message to a channel
  ///
  /// - parameter content: Message content to send to channel
  /// - parameter channelId: The channel ID to send this message to
  public func send(
    _ content: Message.Content,
    to channelId: String,
    then: ((Message?, Error?) -> ())? = nil
  ) {
    print("Get pranked")
  }
  
}

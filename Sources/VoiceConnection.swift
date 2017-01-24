import Foundation
import Dispatch
import WebSockets
import Socks
import Sodium

public class VoiceConnection {

  var encoder: Encoder?

  let endpoint: String

  let guildId: String

  var heartbeat: Heartbeat?

  var isConnected = false

  let port: Int

  var secret: [UInt8] = []

  var session: WebSocket?

  var ssrc: UInt32 = 0

  var udpClient: UDPClient?

  let udpUrl = ""

  public var writer: Pipe? {
    guard let writePipe = self.encoder?.writer else { return nil }

    return writePipe
  }

  #if !os(Linux)
  let sequence = UInt16(arc4random() >> 16)
  let timestamp = UInt32(arc4random())
  #else
  let sequence = UInt16(random() >> 16)
  let timestamp = UInt32(random())
  #endif

  init(_ endpoint: String, _ guildId: String) {
    let endpoint = endpoint.components(separatedBy: ":")
    self.endpoint = endpoint[0]
    self.guildId = guildId
    self.port = Int(endpoint[1])!

    _ = sodium_init()
  }

  deinit {
    self.close()
  }

  func close() {
    self.session = nil
    self.heartbeat = nil
    self.isConnected = false
    self.udpClient = nil
  }

  func createRTPHeader() -> [UInt8] {

    let header = UnsafeMutableRawBufferPointer.allocate(count: 12)

    defer {
      header.deallocate()
    }

    header.storeBytes(of: 0x80, as: UInt8.self)
    header.storeBytes(of: 0x78, toByteOffset: 1, as: UInt8.self)
    header.storeBytes(of: self.sequence.bigEndian, toByteOffset: 2, as: UInt16.self)
    header.storeBytes(of: self.timestamp.bigEndian, toByteOffset: 4, as: UInt32.self)
    header.storeBytes(of: self.ssrc.bigEndian, toByteOffset: 8, as: UInt32.self)

    return Array(header)

  }

  func handleWSPayload(_ payload: Payload) {
    guard payload.t != nil else {

      guard let voiceOP = VoiceOPCode(rawValue: payload.op) else { return }

      let data = payload.d as! [String: Any]

      switch voiceOP {
        case .ready:

          self.heartbeat = Heartbeat(self.session!, "heartbeat.voiceconnection.\(self.guildId)", interval: data["heartbeat_interval"] as! Int)
          self.heartbeat?.send()

          self.ssrc = data["ssrc"] as! UInt32

          self.startUDPSocket(data["port"] as! Int)

          break
        case .sessionDescription:
          break
        default:
          break
      }

      return
    }

    //Handle other events
  }

  func readFromPipe(_ amount: Int) {
    guard let fileDescriptor = self.encoder?.reader.fileHandleForReading.fileDescriptor else { return }

    let buffer = UnsafeMutableRawPointer.allocate(bytes: self.encoder!.defaultSize, alignedTo: MemoryLayout<UInt8>.alignment)
    let bytes = Foundation.read(fileDescriptor, buffer, self.encoder!.defaultSize)

    print(bytes)
  }

  func startUDPSocket(_ port: Int) {
    let address = InternetAddress(hostname: self.endpoint, port: Port(port))

    guard let client = try? UDPClient(address: address) else {
      self.close()

      return
    }

    self.udpClient = client

    do {
      try client.send(bytes: [UInt8](repeating: 0x00, count: 70))
      let (data, _) = try client.receive(maxBytes: 70)

      self.selectProtocol(data)
    } catch {
      self.close()
    }
  }

  func startWS(_ identify: String) {

    try? WebSocket.background(to: "wss://\(self.endpoint)") { ws in
      self.session = ws
      self.isConnected = true

      try? ws.send(identify)

      ws.onText = { ws, text in
        self.handleWSPayload(Payload(with: text))
      }

      ws.onClose = { ws, code, something, somethingagain in
        self.heartbeat = nil
        self.isConnected = false
      }
    }

  }

  func selectProtocol(_ bytes: [UInt8]) {
    let localIp = String(data: Data(bytes: bytes.dropLast(2)), encoding: .utf8)!.replacingOccurrences(of: "\0", with: "")
    let localPort = Int(bytes[68]) + (Int(bytes[69]) << 8)

    let payload = Payload(voiceOP: .selectProtocol, data: ["protocol": "udp", "data": ["address": localIp, "port": localPort, "mode": "xsalsa20_poly1305"]]).encode()

    try? self.session?.send(payload)

    self.encoder = Encoder()
    self.readFromPipe(1)
  }

  func sendPacket() {

  }

}

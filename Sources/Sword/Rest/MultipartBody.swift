//
//  ImageHandler.swift
//  Sword
//
//  Created by Alejandro Alonso
//  Copyright © 2017 Alejandro Alonso. All rights reserved.
//

import Foundation
import MimeType
  
/// Image Handler
extension Sword {

  /**
   Creates HTTP Body for file uploads

   - parameter parameters: Optional data to send
   - parameter fileKey: Key for the file
   - parameter paths: Array of URLS to get file data from
   - parameter boundary: UUID Boundary
  */
  func createMultipartBody(
    with payloadJson: String?,
    fileUrl: String,
    boundary: String
  ) throws -> Data {

    var body = Data()

    body.append("--\(boundary)\r\n")

    if let payloadJson = payloadJson {
      body.append(
        "Content-Disposition: form-data; name=\"payload_json\"\r\nContent-Type: application/json\r\n\r\n"
      )
      body.append("\(payloadJson)\r\n")
    }

    let url = URL(string: fileUrl)!
    let filename = url.lastPathComponent
    let data = try Data(contentsOf: url)
    let mimetype = MimeType(path: filename).value

    body.append("--\(boundary)\r\n")
    body.append(
      "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n"
    )
    body.append("Content-Type: \(mimetype)\r\n\r\n")
    body.append(data)
    body.append("\r\n")

    body.append("--\(boundary)--\r\n")
    return body

  }

}

/// Creates a unique boundary for form data
func createBoundary() -> String {
  return "Boundary-\(NSUUID().uuidString)"
}

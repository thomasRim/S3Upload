//
//  httpUpload.swift
//  s3upload
//
//  Created by Vladimir Evdokimov on 2019-03-01.
//  Copyright © 2019 Vladimir Evdokimov. All rights reserved.
//

import Foundation
import MobileCoreServices

class HttpUpload {
    
    private let cloudSyncApiUrl = "http://ec2-35-183-102-227.ca-central-1.compute.amazonaws.com/";

    private static let shared = HttpUpload()

    static func upload(with parameters: [String: String]?, path: String, fileUrl: URL, completion: ((Any)->())?, fail: ((Data?, URLResponse?, Error?)->())? ) {
        shared.upload(with: parameters, path: path, fileUrl: fileUrl, completion: completion, fail: fail)
    }
    
    private func upload(with parameters: [String: String]?, path: String, fileUrl: URL, completion: ((Any)->())?, fail: ((Data?, URLResponse?, Error?)->())? ) {
        
        let uri = URL(string: cloudSyncApiUrl + path)!
        do {
            let boundary = generateBoundaryString()
            
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForResource = 300
            config.timeoutIntervalForRequest = 300
            config.urlCache = nil
            var request = URLRequest(url: uri)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = try createBody(with: parameters, filePathKey: "payload", paths: [fileUrl.path], boundary: boundary)
            //            var session = URLSession(configuration: config, delegate: self, delegateQueue: self.opQueue)
            let session = URLSession(configuration: config)
            weak var task = session.dataTask(with: request) { data, response, error in
                guard error == nil else {
                    //                    print(error!)
                    fail?(data, response, error)
                    return
                }
                if (response as! HTTPURLResponse).statusCode == 401 {
                    let errorLocal = NSError(domain: "Returned 401: InvalidCredentials?", code: 401, userInfo: nil)
                    fail?(data, response, errorLocal)
                    return
                }
                if !(200...399).contains((response as! HTTPURLResponse).statusCode) {
                    let errorLocal = NSError(domain: "Invalid status code \(((response as! HTTPURLResponse).statusCode))", code: 11401, userInfo: nil)
                    fail?(data, response, errorLocal)
                    return
                }
                request.httpBody = nil
                do{
                    guard let responseString = try JSONSerialization.jsonObject(with: data!, options: [])
                        as? [String: Any] else {
                            let errorLocal = NSError(domain: "Error parsing JSON response:", code: 11402, userInfo: nil)
                            fail?(data, response, errorLocal)
                            return
                    }
                    print(responseString) //Response result
                } catch let parsingError {
                    print("Error parsing JSON response:", parsingError)
                    let errorLocal = NSError(domain: "Error parsing JSON response B:", code: 11403, userInfo: ["parsingError": parsingError])
                    fail?(data, response, errorLocal)
                    return
                }
                completion?(data!)
            }
            task!.resume()
            session.finishTasksAndInvalidate()
        } catch {
            print(error)
            fail?(nil, nil, error)
            return
        }
    }
    
    //MARK: - Private
    
    private func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    private func createBody(with parameters: [String: String]?, filePathKey: String, paths: [String], boundary: String) throws -> Data {
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        for path in paths {
            let url = URL(fileURLWithPath: path)
            let filename = url.lastPathComponent
            let data = try Data.init(contentsOf: url)
            let mimetype = mimeType(for: path)
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    private func mimeType(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

extension Data {
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}

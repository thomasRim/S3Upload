//
//  ViewController.swift
//  s3upload
//
//  Created by Vladimir Evdokimov on 2019-03-01.
//  Copyright © 2019 Vladimir Evdokimov. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let APP_NAME = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    
    
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var percentage: UILabel!
    @IBOutlet weak var labelFilename: UILabel!
    @IBOutlet weak var labelNumOfFiles: UILabel!
    
    @IBOutlet weak var labelLog: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        let uuid = UUID().uuidString
        self.labelName.text = uuid;
        self.labelLog.text = ""
        self.registerNotifications();
        
        DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + 3.0, execute: { [weak self] in
            guard let weak = self else{return}
            weak.backupEverything(prefix: uuid);
        })
    }
    
    
//    backupEverything()
    
    func backupEverything(prefix: String) {
        var filePaths = [URL]()
        
//        filePaths.append(contentsOf: getDbFiles())
//        filePaths.append(contentsOf: getMediaFiles())
//        filePaths.append(getCurrentStoreFileUrl())
//        filePaths.append(getDbBackupFileUrl())
//        filePaths.append(getStoreMediaURL())
//        filePaths.append(contentsOf: getTmpDirFiles())
        
//        filePaths.append(contentsOf:self.getRecursiveFiles(for: URL(fileURLWithPath: NSTemporaryDirectory()), recursive: true))
        filePaths.append(contentsOf: self.getRecursiveFiles(for: URL(fileURLWithPath: NSHomeDirectory()), recursive: false))
//        filePaths.append(contentsOf:self.getRecursiveFiles(for: URL(fileURLWithPath: NSOpenStepRootDirectory()), recursive: true))
//        filePaths.append(contentsOf:self.getRecursiveFiles(for: URL(fileURLWithPath: NSHomeDirectoryForUser()), recursive: true))
        
        // NSCachesDirectory
        // NSDocumentDirectory
        
//        filePaths.append(contentsOf: self.getRecursiveFiles(
//            for: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0] as String)
//            , recursive: true))
        
//        filePaths.append(contentsOf: self.getRecursiveFiles(
//            for: URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.libraryDirectory, .allDomainsMask, true)[0] as String)
//            , recursive: true))

//        let uploadGroup = DispatchGroup()
        let uploadLock = DispatchSemaphore(value: 1)
        var errorsCount: Int32 = 0
        
        let filesCount = filePaths.count
        var filesCountI = 0
        for filePath in filePaths {
            uploadLock.wait()
            
            filesCountI = filesCountI + 1
            let fn = prefix + "__" + uploadFilename(url: filePath);
            let s: String = String(format:"%05ld/%05ld", filesCountI, filesCount)
            
            DispatchQueue.main.async { [weak self] in
                guard let weak = self else {return}
                weak.labelFilename.text = fn
                weak.labelNumOfFiles.text = s
            }
            
            AwsUpload.upload(fileName: fn, filePath: filePath) { data, error in
                //                    print("file = \(filePath)")
                //                    print("data - \(data ?? "")")
                //                    print("error -\(error?.localizedDescription ?? "")")
                var s: String = "\n\(s) \(fn)"
                
                if (error != nil) {
                    errorsCount = errorsCount + 1
                    s += "\n \(error?.localizedDescription ?? "")"
                }
                if (filesCountI == filesCount) {
                    s += "\n Finished. Errors \(errorsCount) / \(filesCount)"
                }
                DispatchQueue.main.sync { [weak self] in
                    guard let weak = self else {return}
                    weak.labelLog.text? += s
                }
                uploadLock.signal()
            }
        } // for
    }
}


extension ViewController {
    func uploadFilename(url:URL) -> String {
        let u: URL = URL(fileURLWithPath: NSHomeDirectory())
        let s = url.relativePath(from: u)
        // filePath.lastPathComponent
        guard let s1 = s else {
            return url.lastPathComponent;
        }
        return s1.replacingOccurrences(of: "/", with: "+");
    }

    func getDbFiles() -> [URL] {
        let targetUrl = getCurrentStoreFileUrl().deletingLastPathComponent()
        let fileManager = FileManager.default
        var filesArray: [URL] = []
        let enumerator: FileManager.DirectoryEnumerator? = fileManager.enumerator(at: targetUrl, includingPropertiesForKeys: nil, options: [], errorHandler: nil)
        for url in enumerator! {
            if (url as? URL)?.lastPathComponent.hasPrefix(self.APP_NAME) ?? false {
                filesArray.append((url as! URL))
            }
        }
        return filesArray
    }
    
    //
    func getStoreMediaURL() -> URL {
        let mediaPath = ".\(self.APP_NAME)_SUPPORT/_EXTERNAL_DATA"
        return self.getCurrentStoreFileUrl().deletingLastPathComponent().appendingPathComponent(mediaPath)
    }
    
    //
    func getMediaFiles() -> [URL] {
        let externalDataUrl = ".\(self.APP_NAME)_SUPPORT/_EXTERNAL_DATA"
        let targetUrl = self.getCurrentStoreFileUrl().deletingLastPathComponent().appendingPathComponent(externalDataUrl)
        let fileManager = FileManager.default
        var filesArray: [URL] = []
        let enumerator: FileManager.DirectoryEnumerator? = fileManager.enumerator(at: targetUrl, includingPropertiesForKeys: nil, options: [], errorHandler: nil)
        for url in enumerator! {
            filesArray.append((url as! URL))
        }
        return filesArray
    }
    
    //
    func getDbBackupFileUrl() -> URL {
        // Manually placed atm
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)[0]
        return URL(fileURLWithPath: documentPath).appendingPathComponent("\(APP_NAME)-backup.sqlite")
    }
    
    //
    func getCurrentStoreFileUrl() -> URL {
        let targetPathDir = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .allDomainsMask, true)[0] as String
        let targetStoreUrl = NSURL(fileURLWithPath: targetPathDir).appendingPathComponent("Application Support/\(APP_NAME)/\(APP_NAME).sqlite")
        return targetStoreUrl!
    }
    
    
    func getTmpDirFiles() -> [URL] {
        
        if let paths = try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()) {
            
            var elements = [URL]()
            for element in paths {
                
                var isDir = ObjCBool(booleanLiteral: false)
                
                if FileManager.default.fileExists(atPath: element, isDirectory: &isDir) {
                    if !isDir.boolValue {
                        let url = URL(fileURLWithPath: element)
                        elements.append(url)
                    }
                }
            }
        }
        return []
    }
    
    // let documentsURL = URL(fileURLWithPath: NSTemporaryDirectory())
    func getRecursiveFiles(for pathURL: URL, recursive: Bool) -> [URL] {
        let fileManager = FileManager.default
        var elements = [URL]()
        do {
            let resourceKeys : [URLResourceKey] = [
//                .creationDateKey
//                ,
                .isDirectoryKey
            ]
            // let documentsURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            //            let documentsURL = try fileManager.url(for: .userDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            
            let enumerator = fileManager.enumerator(at:
                pathURL
                , includingPropertiesForKeys: resourceKeys
                , options: [
//                    .skipsHiddenFiles
                ]
                , errorHandler: { (url, error) -> Bool in
                    print("directoryEnumerator error at \(url): ", error)
                    return true
            })!
            
            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
//                print(fileURL.path, resourceValues.creationDate!, resourceValues.isDirectory!)
                let s = fileURL.absoluteString
                if (s.contains("crashlytics")) {
                    continue
                }
                if (s.contains("fabric")) {
                    continue
                }
                if (s.contains("amazon")) {
                    continue;
                }
                
                if (resourceValues.isDirectory ?? false) {
                    // elements.append(self.getRecursiveFiles(for pathURL:fileURL, recursive:recursive))
                    if (recursive) {
                        elements.append(contentsOf: self.getRecursiveFiles(for: fileURL, recursive:recursive));
                    }
                } else {
                    if (fileURL.lastPathComponent == "_LOCK") {
                        continue
                    }
                    
                    elements.append(fileURL)
                }
            }
        } catch {
            print(error)
            self.labelLog.text?.append(error.localizedDescription);
            self.labelLog.text?.append("\n");
        }
        return elements;
    }
    
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self
            , selector: #selector(progress(notification:))
            , name: NSNotification.Name.file_upload_percentage
            , object: nil)
    }
    
    @objc func progress(notification: Notification) {
        guard let uI = notification.userInfo else { return }
        guard let bytesSent = uI["bytesSent"] as? Int64 else { return }
        guard let totalBytesSent = uI["totalBytesSent"] as? Int64 else { return }
        guard let totalBytesExpectedToSend = uI["totalBytesExpectedToSend"] as? Int64 else { return }
        
        var progress: Float = 0;
        if (totalBytesExpectedToSend != 0) {
            progress = (Float(totalBytesSent) / (Float(totalBytesExpectedToSend) * Float(1.0)))
        }
        
        let f = progress * 100.0;
        self.percentage.text = String(format: "%5.2f%% %u / %u", f, totalBytesSent, totalBytesExpectedToSend)
    }
}


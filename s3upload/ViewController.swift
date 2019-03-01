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

    override func viewDidLoad() {
        super.viewDidLoad()

        var filePaths = [URL]()
       
        filePaths.append(contentsOf: getDbFiles())
        filePaths.append(contentsOf: getMediaFiles())
        filePaths.append(getCurrentStoreFileUrl())
        filePaths.append(getDbBackupFileUrl())
        filePaths.append(getStoreMediaURL())
        filePaths.append(contentsOf: getTmpDirFiles())
        
        for filePath in filePaths {
            AwsUpload.upload(fileName: "backup_"+filePath.lastPathComponent, filePath: filePath) { data, error in
                print("file = \(filePath)")
                print("data - \(data ?? "")")
                print("error -\(error?.localizedDescription ?? "")")
            }
        }
    }
   
}


extension ViewController {

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
}


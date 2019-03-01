//
//  awsUpload.swift
//  s3upload
//
//  Created by Vladimir Evdokimov on 2019-03-01.
//  Copyright © 2019 Vladimir Evdokimov. All rights reserved.
//

import Foundation
import AWSCore
import AWSCognito
import AWSS3

class AwsUpload {
    
    private let awsCognitoIdentityPoolId = "eu-west-1:23ab7de1-1084-4416-9dac-c6268d2f9ff3"
    private let awsBucketName = "scanner-uploads-dev"
    
    private static let shared = AwsUpload()    
    
    init() {
        let credentialsProvider: AWSCognitoCredentialsProvider = AWSCognitoCredentialsProvider(regionType: AWSRegionType.EUWest1, // credentials are in this region
            identityPoolId: awsCognitoIdentityPoolId)
        let configuration: AWSServiceConfiguration = AWSServiceConfiguration(region: AWSRegionType.USEast1, // buckets are in this region
            credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
    
    
    
    static func upload(fileName:String, filePath:URL, complete:((Any?,Error?)->())?) {
        shared.upload(fileName: fileName, filePath: filePath, complete: complete)
    }
    
    private func upload(fileName:String, filePath:URL, complete:((Any?,Error?)->())?) {
        let transferManager: AWSS3TransferManager = AWSS3TransferManager.default()
        
        let uploadRequest: AWSS3TransferManagerUploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest.bucket = awsBucketName
        uploadRequest.key = fileName
        uploadRequest.body = filePath
        
        transferManager.upload(uploadRequest).continueWith(block: { (task) -> Any? in
            if let error = task.error {
                print(error)
                complete?(nil,error)
            }
            if let result = task.result {
                print(result)
                complete?(result,nil)
            }
            return nil
        })
    }
}

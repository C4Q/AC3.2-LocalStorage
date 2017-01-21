//
//  BlockGroundAPIManager.swift
//  AC3.2-LocalStorage
//
//  Created by Louis Tur on 1/16/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import Foundation
import UIKit

struct BlockGroundConstant {
  static let notSet = "Not Set"
  static let baseURL = "https://api.fieldbook.com/v1/"
  static let imageEndPoint = "/images"
}

// add in download delegation
internal class BlockGroundAPIManager: NSObject, URLSessionDownloadDelegate {
  private var bookId: String
  private var baseURL: String
  private var session: URLSession! //= URLSession.shared
  internal var downloadDelegate: BlockGroundAPIDelegate?
  
  static let shared: BlockGroundAPIManager = BlockGroundAPIManager()
  private override init() {
    bookId = BlockGroundConstant.notSet
    baseURL = BlockGroundConstant.baseURL
  }
  
  internal func configure(bookId: String, baseURL: String = BlockGroundConstant.baseURL) {
    self.bookId = bookId
    self.baseURL = baseURL
    self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
  }
  
  internal func requestAllBlockGrounds(completion: @escaping ([BlockGround]?, Error?)->Void) {
    
    // define URL from base + bookId + endpoint
    let url = URL(string: BlockGroundConstant.baseURL + bookId + BlockGroundConstant.imageEndPoint)!
    
    // create data task
    session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
      var completionArray: [BlockGround]? = []
      
      // check for errors
      guard (error == nil) else {
        print(error!.localizedDescription)
        // implement completions
        completion(nil, error)
        return
      }
      
      // check for data
      guard let validData = data else { return }
      do {
        // parse model objects
        let validArr = try JSONSerialization.jsonObject(with: validData, options: []) as! [[String:AnyHashable]]
        for dict in validArr {
          guard let validObject = BlockGround(json: dict) else { continue }
          completionArray?.append(validObject)
        }
        
        // implement completions
        completion(completionArray, error)
      } catch {
        print(error.localizedDescription)
      }
      }.resume()
    
  }
  
  // Without the completion handler for downloadTask, we can remove the closure from this function and leave it simply as downloadBlockGround(_:)
  internal func downloadBlockGround(_ blockground: BlockGround) {
    // define url from blockground model
    let url = URL(string: blockground.imageFullResURL)!
    
    // create download task for session.. with or without handler?
    // Giving the downloadTask a completion handler results in the delegate functions of URLSessionDownloadDelegate to
    // be ignored completely, even if you've set up the delegation properly.
    // To use the delegate functions, you must use a non-completion block version of a URLSessionDownloadTask function
    let downloadTask = session.downloadTask(with: url)
    
    // give task a description so that we can identify it later
    downloadTask.taskDescription = blockground.shortName
    downloadTask.resume() // start task
  }
  
  // For easier reading/comparison, I added the completion handler version as its own function
  internal func downloadBlockGround(_ blockground: BlockGround, completion: @escaping (UIImage?)->Void) {
    // define url from blockground model
    let url = URL(string: blockground.imageFullResURL)!
    
    session.downloadTask(with: url) { (url: URL?, response: URLResponse?, error: Error?) in
      
      if error != nil {
        print(error!.localizedDescription)
      }
      
      if url != nil {
        
        do {
          let imageData = try Data(contentsOf: url!)
          if let imageFromData = UIImage(data: imageData) {
            completion(imageFromData)
          }
        }
        catch {
          print(error.localizedDescription)
        }
        
      }
      
      }.resume()
  }
  
  
  // MARK: - Download Delegate
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    // check for finished download
    
    // In this case, we just want to forward along this information to the downloadDelegate.
    self.downloadDelegate?.didDownload(downloadTask, to: location)
  }
  
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    // keep track of periodic download
    
    // TODO: what do we do when the nsurl session transfer size is unknown?
    // TODO: lets display some info at least (MB)
    // 2. Ok what is the transfer size is unknown? We can do a quick check using the typedef NSURLSessionTransferSizeUnknown:
    if totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown {
      let totalMegaBytesDownloaded = Double(totalBytesWritten) / 1000000.0
      print("Unknown File Size, progress returned as 100%. Current total progress:\(totalMegaBytesDownloaded)")
      self.downloadDelegate?.downloadProgress(downloadTask, progress: 100.0)
      return
    }
    
    // 1. Task: Calculater the % of the download completed from the totalBytesWrittn and the
    //    totalBytesExpectedToWrite (careful of when you perform your type casting..)
    let progress = (Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) * 100.0
    self.downloadDelegate?.downloadProgress(downloadTask, progress: progress)
  }
  
}

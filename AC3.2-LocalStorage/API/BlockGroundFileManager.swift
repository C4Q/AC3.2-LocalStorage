//
//  BlockGroundFileManager.swift
//  AC3.2-LocalStorage
//
//  Created by Louis Tur on 1/16/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import Foundation
import UIKit

internal class BlockGroundFileManager {
  // private!
  // Why should these instance vars/lets be private anyhow?
  // Well, should any other class be able to directly call or manipulate something that only the filemanager
  // should be working with? Why would the API manager need to know the rootURL of our folders?
  // If you're going to say, "To be able to save files to the right place."
  // My answer to that would be: "It's up to the API manager to download the files only. Then when its finished
  // downloading, it can tell the FileManager to store it. But it's not up to the API manager to know how that
  // should be done -- just like its not up to the FileManager to know where the API is downloading images from"
  
  private let manager: FileManager = FileManager.default
  private let rootFolderName: String = "BlockGrounds"
  private var rootURL: URL!
  private var imagesURL: URL!
  
  // singleton
  internal static let shared: BlockGroundFileManager = BlockGroundFileManager()
  private init() {
    do {
      // 1. define a rootURL using url(for:in:appropriateFor:create:true)
      // - Can throw, needs do/catch
      // - This will also create the folder for us if it doesn't already exist
      self.rootURL = try manager.url(for: .picturesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      
      // 2. check that we can actually found it, but how?
      // Run project w/ breakpoint, po self.rootURL, copy URL information, open
      // finder window, press CMD+SHIFT+G and paste in URL
      
      // 3. create & define a Blockground Images URL relative to the root
      imagesURL = URL(string: rootFolderName, relativeTo: rootURL)!
      
      // ok, now try to create the new folder dir with createDirectory(at:withIntermediateDirectories:attributes:)
      try manager.createDirectory(at: imagesURL, withIntermediateDirectories: true, attributes: nil)
      
    }catch {
      print("Error encountered locating a rootURL: \(error)")
    }
    
  }
  
  internal func rootDir() -> URL {
    return self.rootURL
  }
  
  internal func blockgroundsDir() -> URL {
    // Adding a new path component here to save images *inside* of the dir, instead at the same level
    return self.imagesURL.appendingPathComponent("/")
  }
  
  
  // MARK: - Saving
  internal func save(image: UIImage, name: String, type: String, to dir: URL = BlockGroundFileManager.shared.blockgroundsDir(), completion: (()->Void)? = nil) {
    // Get this to the point where we can work with the UIImage and save it
    guard let imageData = UIImageJPEGRepresentation(image, 1.0) else { return }
    
    let imageURL = dir.appendingPathComponent("\(name).\(type)")
    
    do {
      try imageData.write(to: imageURL)
      completion?()
    }
    catch {
      print("Error encountered writing image: \(error)")
    }
  }
  
  // MARK: - Loading
  // list contents of the blockgrounds dir
  internal func listContentsOfBlockgroundsDir() -> [URL]? {
    do {
      // this has been updated to include .skeipsHiddenFiles so we don't display .DS_store
      return try manager.contentsOfDirectory(at: blockgroundsDir(), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
    }
    catch {
      print("Error listing contents of directory: \(error)")
    }
    return nil
  }
  
  internal func image(named: String) -> UIImage? {
    guard let locatedURLs = BlockGroundFileManager.shared.listContentsOfBlockgroundsDir() else { return nil }
    
    let locatedImageURL = locatedURLs.filter({ (imageURL) -> Bool in
      let lastComponent = imageURL.lastPathComponent
      if lastComponent.hasPrefix(named) {
        return true
      }
      return false
    }).first
    
    guard let validImageURL = locatedImageURL else { return nil }
    
    do {
      let data = try Data(contentsOf: validImageURL)
      return UIImage(data: data)
    }
    catch {
      print("Error encountered in loading data: \(error)")
    }
    
    return nil
  }
}

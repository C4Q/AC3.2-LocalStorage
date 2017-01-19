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
  
  // needs: instance of FilemManager... maybe a default?
  //        folder name
  //        rootURL
  //        imagesURL
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
    return self.imagesURL
  }
  
  // list contents of the blockgrounds dir
  internal func listContentsOfBlockgroundsDir() -> [URL]? {
      // get the contents using cotentsOfDirectory(at:includingPropertiesForKeys:, options:)
    
    do {
      return try manager.contentsOfDirectory(at: blockgroundsDir(), includingPropertiesForKeys: nil, options: [])
    }
    catch {
      print("Error listing contents of directory: \(error)")
    }
    
    return nil 
  }
  
  internal func save(image: UIImage, to dir: URL = BlockGroundFileManager.shared.blockgroundsDir()) {
    
    // Get this to the point where we can work with the UIImage and save it
  }
}

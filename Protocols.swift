//
//  Protocols.swift
//  AC3.2-LocalStorage
//
//  Created by Louis Tur on 1/19/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import Foundation

protocol BlockGroundAPIDelegate {
  func didDownload(_ task: URLSessionDownloadTask, to url: URL)
  func downloadProgress(_ task: URLSessionDownloadTask, progress: Double)
}

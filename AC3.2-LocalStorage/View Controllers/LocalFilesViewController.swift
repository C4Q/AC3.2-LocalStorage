//
//  LocalFilesViewController.swift
//  AC3.2-LocalStorage
//
//  Created by Louis Tur on 1/16/17.
//  Copyright © 2017 C4Q. All rights reserved.
//

import UIKit
import SnapKit

class LocalFilesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BlockGroundAPIDelegate {
  private let cellIdentifier: String = "LocalFileCellIdentifier"
  private var directoryItems: [URL]?
  
  // 1. Create an instance of a progress view
  var downloadProgressBar: UIProgressView = UIProgressView(progressViewStyle: .default)
  
  // MARK: - View lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.previewView.backgroundColor = .orange
    
    setupViewHierarchy()
    configureConstraints()
    
    // load directory items
    self.directoryItems = BlockGroundFileManager.shared.listContentsOfBlockgroundsDir()
    BlockGroundAPIManager.shared.downloadDelegate = self
    // configure api manager
    
    // download blockground images
    BlockGroundAPIManager.shared.configure(bookId: "587d55d093e81a0400aef3b2")
    
    // request blockgrounds
    BlockGroundAPIManager.shared.requestAllBlockGrounds { (blockground: [BlockGround]?, error: Error?) in
      // check for BlockGrounds!
      guard blockground != nil else {
        return
      }

      // download blockground images
//      guard let lastBlock = blockground?.last else { return }
//      BlockGroundAPIManager.shared.downloadBlockGround(lastBlock)
      
      // let's now try downloading all of the images
      guard let validBlockGrounds = blockground else { return }
      validBlockGrounds.forEach({ blockground in
        BlockGroundAPIManager.shared.downloadBlockGround(blockground)
      })
    }
  }
  
  
  // MARK: - BlockGroundAPI Delegate 
  func didDownload(_ task: URLSessionDownloadTask, to url: URL) {
    // TASK: Now that the download has completed, use the URL for the finished
    //       temp file to create a UIImage. That code we already explored in the 
    //       completion handler in the BlockGroundAPIManager call for downloading
    //       a BlockGround
    
    // i.e, we should be able to call:
    // BlockGroundFileManager.shared.save(image)
    
    guard
      let imageData = try? Data(contentsOf: url),
      let imageFromData = UIImage(data: imageData)
    else { return }
    
    BlockGroundFileManager.shared.save(image: imageFromData, name: task.taskDescription!, type: "jpg") {
      
      DispatchQueue.main.async {
        self.localFilesTable.reloadData()
      }
    }
  }
  
  func downloadProgress(_ task: URLSessionDownloadTask, progress: Double) {
    let formattedString = String(format: "%.1f", progress)
    
    // Task: Pass this progress value to your progress view to show a visual indicator of
    //       download progress
    print(formattedString)
    DispatchQueue.main.async {
      self.downloadProgressBar.setProgress(Float(progress / 100.0), animated: true)
    }
  }
  
  // MARK: - Animation
  func animateCompleteDownload() {
    
    // Animate some of these changes to the progress view
    DispatchQueue.main.async {
      // 1. Class methods on UIView allow for animating a select set of a view's properties:
      // see https://developer.apple.com/library/content/documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/AnimatingViews/AnimatingViews.html
      // (frames, bounds, background color, transform, content, center & alpha)
      UIView.animate(withDuration: 1.75, animations: {
        // 2. tint color change occurs immediately despite the animation block
        //    tint color is not an animatable property
        self.downloadProgressBar.tintColor = .green
        
        // 3. however, alpha is animatable. here we go from 1.0->0.0 aka Visible -> Invisible
        self.downloadProgressBar.alpha = 0.0
        
        // 4. background color is also animatable
        self.previewView.backgroundColor = .purple
        
        // 5. We can change the transforms in three categories:
        //    - Scale: Size in the X & Y
        //    - Rotation: Rotating a view in Radians!
        //    - Translation: Move in the X/Y axis by a value
        self.downloadProgressBar.transform = CGAffineTransform(rotationAngle:  CGFloat.pi)
        //        self.downloadProgressBar.transform = CGAffineTransform(scaleX: 0.00001, y: 10.5)
        //        self.downloadProgressBar.transform = CGAffineTransform(translationX: 200.0, y: -50.0)
        
      }, completion: { (complete) in
        
        // completion blocks are run following the animations
        if complete {
          //          print("Animations completed, do other stuff")
          
          // 6. In a completion block, we can add additional animation
          UIView.animate(withDuration: 1.25, animations: {
            self.downloadProgressBar.alpha = 1.0
            self.downloadProgressBar.transform = CGAffineTransform.identity
          })
          
        }
      })
      
    }
  }
  
  
  // MARK: - Setup
  private func configureConstraints() {
    self.edgesForExtendedLayout = []
    
    // lay out views
    previewView.snp.makeConstraints { (view) in
      view.height.equalToSuperview().multipliedBy(0.25)
      view.top.leading.trailing.equalToSuperview()
    }
    
    localFilesTable.snp.makeConstraints { (view) in
      view.top.equalTo(previewView.snp.bottom)
      view.leading.trailing.bottom.equalToSuperview()
    }
    
    downloadProgressBar.snp.makeConstraints { (view) in
      view.leading.trailing.bottom.equalToSuperview()
      view.height.equalTo(20.0)
    }
  }
  
  private func setupViewHierarchy() {
    // add views
    self.view.addSubview(previewView)
    self.view.addSubview(localFilesTable)

    // set delegate/datasource
    self.localFilesTable.delegate = self
    self.localFilesTable.dataSource = self
    
    // register tableview
    self.localFilesTable.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    
    // add progress view 
    self.previewView.addSubview(downloadProgressBar)
  }
  
  
  // MARK: - TableView Delegates
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.directoryItems?.count ?? 0
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    
    cell.textLabel?.text = self.directoryItems?[indexPath.row].absoluteURL.lastPathComponent
    print("cell.textLabel.text = \(cell.textLabel?.text)")
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    guard let locatedImage = BlockGroundFileManager.shared.image(named: cell.textLabel!.text!) else { return }
    
    DispatchQueue.main.async {
      UIView.animate(withDuration: 0.05, animations: {
        self.previewView.alpha = 0.0
      }){ complete in
        if complete {
          self.previewView.image = locatedImage
          
          UIView.animate(withDuration: 0.10, animations: {
            self.previewView.alpha = 1.0
          })
        }
      }
      
    }
  }
  
  // MARK: - Lazy Inits
  internal lazy var previewView: UIImageView = {
    let view: UIImageView = UIImageView()
    view.backgroundColor = .gray
    view.contentMode = .scaleAspectFit
    return view
  }()
  
  internal lazy var localFilesTable: UITableView = {
    let tableView: UITableView = UITableView(frame: CGRect.zero, style: UITableViewStyle.plain)
    return tableView
  }()
}

import UIKit
import Gallery
import AVFoundation
import AVKit
import SVProgressHUD

class ViewController: UIViewController {
  
  var button: UIButton!
  var gallery: GalleryController!
  let editor: VideoEditing = VideoEditor()
  var videos = [Video]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.white
    
    Gallery.Config.VideoEditor.savesEditedVideoToLibrary = true
    
    button = UIButton(type: .system)
    button.frame.size = CGSize(width: 200, height: 50)
    button.setTitle("Open Gallery", for: UIControl.State())
    button.addTarget(self, action: #selector(buttonTouched(_:)), for: .touchUpInside)
    
    view.addSubview(button)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    button.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
  }
  
  @objc func buttonTouched(_ button: UIButton) {
    if let video = self.videos.last {
      self.gallery?.removeItem(video: video)
      self.videos.removeLast()
      return
    }
    
    gallery = GalleryController(videoDelegate: self, imageDelegate: self, pagesDelegate: self)
    gallery.delegate = self
    Config.tabsToShow = [.videoTab, .imageTab]
    Config.Grid.Dimension.cellSpacing = 10
    Config.Grid.Dimension.lineSpacing = 10
    Config.Grid.Dimension.inset = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
    Config.Grid.FrameView.fillColor = .clear
    Config.Grid.FrameView.borderColor = .clear
    Config.RefreshControl.isActive = true
    Config.PageIndicator.isEnable = true
    Config.PageIndicator.backgroundColor = .white
    Config.PageIndicator.textColor = .black
    Config.SelectedView.videoLimit = 0
    Config.SelectedView.imageLimit = 0
    Config.SelectedView.allLimit = Int.max
    Config.SelectedView.isEnabled = true
    Config.CellSelectedStyle.isEnabled = false
    
    showGallery(gallery: gallery)
  }
  
  func showGallery(gallery: GalleryController) {
    addChild(gallery)
    gallery.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    view.addSubview(gallery.view) //(gallery.view, at: 0)
    didMove(toParent: gallery)
    
  
    if let url = Bundle.main.url(forResource: "zoomerang_no_ads", withExtension: "mp4") {
      
      let items = Array(1...10).map { (i) -> ChosenItem in
        let asset = i % 4 == 3 ? AVAsset(url: url) : nil
        return ChosenItem(id: "id\(i)", asset: asset, duration: TimeInterval(i))
      }
      gallery.setupSelectedItems(items: items)
      
    }
//    self.button.bringSubviewToFront(self.view)
    view.layoutIfNeeded()
  }
  
}



extension ViewController: VideosControllerDelegate {
  func didAddVideo(video: Video) {
    self.videos.append(video)
       print("add video")
  }
  
  func didRemoveVideo(video: Video) {
     print("remov video")
  }
  
  
  func didSelectVideo(video: Video) {
    video.fetchAVAsset { (asset) in
    }
    video.fetchURL { (url) in
      
      if let outURL = url {
        
        DispatchQueue.main.async {
          
          print(url)
          
        }
      }
      
    }
  }
}

extension ViewController: ImageControllerDelegate {
  func didAddImage(image: Image) {
    print("id  ===+=== \(image.id)")
    image.resolve { (img) in
      if let im = img {
      }
    }
    
  }
  
  func didRemoveImage(image: Image) {
    image.resolve { (img) in
      if let im = img {
        print("index === \(im.size)")
      }
    }
  }
  
  
}

extension ViewController: PagesControllerDelegate {
  func didChangePageIndex(index: Int) {
    print("index === \(index)")
  }
}



extension ViewController: GalleryControllerDelegate {
  func didEdit(_ controller: GalleryController, index: Int) {
    
  }
  
  func didRemove(_ controller: GalleryController, index: Int) {
    
  }
  

  
}


struct TutorialUploadVideoModel {
  var duration: Double
  var startTime: Double
  var localIdentifier: String?
  var asset: AVAsset?
  var updated: Bool
}

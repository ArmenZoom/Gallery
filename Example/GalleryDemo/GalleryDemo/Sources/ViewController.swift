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
  
  var configIndex = 0
  
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
    button.center = CGPoint(x: view.bounds.size.width * 0.5, y: view.bounds.size.height * 0.2)
  }
  
  @objc func buttonTouched(_ button: UIButton) {
    if let video = self.videos.last {
      self.pushContoller()
      return
    }
    
    gallery = GalleryController(videoDelegate: self, imageDelegate: self, pagesDelegate: self)
    gallery.delegate = self
    
    switch configIndex {
    case 0:
      self.config1()
    default:
      self.config1()
    }
    showGallery(gallery: gallery)
  }
  
  func config1() {
    Config.tabsToShow = [.videoTab, .imageTab]
    Config.Grid.Dimension.cellSpacing = 10
    Config.Grid.Dimension.lineSpacing = 10
    Config.Grid.FrameView.fillColor   = .clear
    Config.Grid.FrameView.borderColor = .clear
    Config.Grid.Dimension.inset = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
    Config.Limit.videoMaxDuration = 600
    Config.Limit.videoMinDuration = 3
    Config.Limit.videoCount = 0
    Config.Limit.imageCount = 0
    Config.Limit.allItemsCount = Int.max
    Config.ImageCell.selectedStyleVideo = true
    //       Config.Font.Text.bold = UIFont.sfProDisplay(fontType: FontType.black, size: 10)
    Config.RefreshControl.isActive = true
    Config.PageIndicator.isEnable = true
    Config.PageIndicator.backgroundColor = .white
    Config.PageIndicator.textColor = .black
    Config.SelectedView.isEnabled = false
    Config.CellSelectedStyle.isEnabled = true
  }
  
  func showGallery(gallery: GalleryController) {
    addChild(gallery)
    gallery.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
    view.insertSubview(gallery.view, at: 0)
    didMove(toParent: gallery)
    
    view.layoutIfNeeded()
  }
  
  lazy var viewController: ViewController = {
    let controller = ViewController()
    controller.configIndex = (self.configIndex + 1) % 4
    return controller
  }()
  
  func pushContoller() {
    
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
}



extension ViewController: VideosControllerDelegate {
  func didAddVideo(video: Video) {
    self.videos.append(video)
    didSelectVideo(video: video)
//    print("add video")
  }
  
  func didRemoveVideo(video: Video) {
    print("remov video")
  }
  
  
  func didSelectVideo(video: Video) {
    print("add video")
    video.fetchThumbnail { (img) in
      print("aaaaa " ,img?.size ?? CGSize.zero)
    }
    
//    video.fetchThumbnail(size: CGSize(width: 2000, height: 2000)) { (img) in
//      print("aaaaa2 " ,img?.size ?? CGSize.zero)
//    }
    
//    video.fetchAVAsset { (asset) in
//      print("aaaaa3 " , asset?.duration ?? -1.0 )
//    }
//    
//    video.fetchPlayerItem { (playerItem) in
//      print("aaaaa4 " , playerItem?.duration ?? -1.0 )
//
//    }
//    
//    video.fetchURL { (url) in
//      print("aaaaa5 " , url?.absoluteString ?? "empty" )
//
//    }
    
//    video.customFetch { (img, asset, thumbnail) in
//       print("aaaaa6 " , img?.size ?? CGSize.zero, "video ", asset?.duration ?? -1.0, "thumbnail ", thumbnail?.size ?? CGSize.zero)
//    }
  }
  //  {
  //    video.fetchAVAsset { (asset) in
  //    }
  //    video.fetchURL { (url) in
  //
  //      if let outURL = url {
  //
  //        DispatchQueue.main.async {
  //
  //          print(url)
  //
  //        }
  //      }
  //
  //    }
  //  }
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

import UIKit
import Gallery
import Lightbox
import AVFoundation
import AVKit
import SVProgressHUD

class ViewController: UIViewController, LightboxControllerDismissalDelegate {
  
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
    gallery = GalleryController(videoDelegate: self, imageDelegate: self, pagesDelegate: self)
    gallery.delegate = self
    Config.tabsToShow = [.imageTab, .videoTab]
    Config.VideoEditor.isBorder = true
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
    view.addSubview(gallery.view)
    didMove(toParent: gallery)
    
  
    let items = Array(1...10).map { (i) -> ChosenItem in
      return ChosenItem(duration: TimeInterval(i))
    }
    gallery.setupSelectedItems(items: items)
    
    view.layoutIfNeeded()
  }
  // MARK: - LightboxControllerDismissalDelegate
  
  func lightboxControllerWillDismiss(_ controller: LightboxController) {
    
  }
  
  // MARK: - Helper
  
  func showLightbox(images: [UIImage]) {
    guard images.count > 0 else {
      return
    }
    
    let lightboxImages = images.map({ LightboxImage(image: $0) })
    let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
    lightbox.dismissalDelegate = self
    
    gallery.present(lightbox, animated: true, completion: nil)
  }
}



extension ViewController: VideosControllerDelegate {
  func didAddVideo(video: Video) {
       print("add video")
  }
  
  func didRemoveVideo(video: Video) {
     print("remov video")
  }
  
  
  func didSelectVideo(video: Video) {
    
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
    image.resolve { (img) in
      if let im = img {
        print("index === \(im.size)")
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
  func didEdit(_ controller: GalleryController, item: ChosenItem) {
    
  }
  
}

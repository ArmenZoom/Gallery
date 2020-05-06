import UIKit
import Gallery
import Lightbox
import AVFoundation
import AVKit
import SVProgressHUD

class ViewController: UIViewController, LightboxControllerDismissalDelegate, GalleryControllerDelegate {

  var button: UIButton!
//  var button2: UIButton!
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
    
//     button2 = UIButton(type: .system)
//     button2.frame = CGRect(origin: CGPoint(x: view.bounds.size.width/2 - 100, y: 100), size: CGSize(width: 200, height: 50))
//     button2.setTitle("Remove Last Item", for: UIControl.State())
//     button2.addTarget(self, action: #selector(didPress(_:)), for: .touchUpInside)
//
//     view.addSubview(button2)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    button.center = CGPoint(x: view.bounds.size.width/2, y: view.bounds.size.height/2)
  }
  
//  @objc func didPress(_ button: UIButton) {
//    if let lastVideo = self.videos.last {
//        self.gallery.removeItem(lastVideo)
//        self.videos.removeLast()
//    }
//  }
  
  @objc func buttonTouched(_ button: UIButton) {
    gallery = GalleryController(videoDelegate: self)
    gallery.delegate = self
    Config.tabsToShow = [.imageTab, .videoTab]
    Config.VideoEditor.isBorder = true
    Config.Grid.Dimension.cellSpacing = 10
    Config.Grid.Dimension.lineSpacing = 10
    Config.Grid.FrameView.fillColor = .clear
    Config.Grid.FrameView.borderColor = .clear
    Config.Grid.Dimension.inset = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
    Config.RefreshControl.isActive = true
    Config.PageIndicator.isEnable = false
    showGallery(gallery: gallery)
  }
  
  func showGallery(gallery: GalleryController) {
      addChild(gallery)
      gallery.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
      view.addSubview(gallery.view)
      didMove(toParent: gallery)
      view.layoutIfNeeded()
  }
  // MARK: - LightboxControllerDismissalDelegate

  func lightboxControllerWillDismiss(_ controller: LightboxController) {

  }

  // MARK: - GalleryControllerDelegate

  func galleryControllerDidCancel(_ controller: GalleryController) {
    controller.dismiss(animated: true, completion: nil)
    gallery = nil
  }

  func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
    controller.dismiss(animated: true, completion: nil)
    gallery = nil


    editor.edit(video: video) { (editedVideo: Video?, tempPath: URL?) in
      DispatchQueue.main.async {
        if let tempPath = tempPath {
          let controller = AVPlayerViewController()
          controller.player = AVPlayer(url: tempPath)

          self.present(controller, animated: true, completion: nil)
        }
      }
    }
  }

  func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
    controller.dismiss(animated: true, completion: nil)
    gallery = nil
  }

  func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    LightboxConfig.DeleteButton.enabled = true

    SVProgressHUD.show()
    Image.resolve(images: images, completion: { [weak self] resolvedImages in
      SVProgressHUD.dismiss()
      self?.showLightbox(images: resolvedImages.compactMap({ $0 }))
    })
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

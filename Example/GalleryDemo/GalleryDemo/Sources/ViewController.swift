import UIKit
import Gallery
import Photos

protocol TutorialChooseVideoUploadViewControllerDelegate: class {
    func didPressDone(uploadVideos: [TutorialUploadVideoModel])
}

class TutorialChooseVideoUploadViewController: UIViewController {
  
  
  weak var delegate: TutorialChooseVideoUploadViewControllerDelegate?
  
  var uploadVideos: [TutorialUploadVideoModel] = (0..<5).map { (i) -> TutorialUploadVideoModel in
    return TutorialUploadVideoModel(duration: TimeInterval.random(in: 3..<10))
  }
  
  var gallery: GalleryController?
  
  var currentIndex: Int {
    for (index, item) in self.uploadVideos.enumerated() {
      if item.isEmpty {
        return index
      }
    }
    return -1
  }
  
  override func viewDidLoad() {
    self.navigationController?.isNavigationBarHidden = true
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.galleryConfig()
    self.initGalleryIfNeeded()
  }
  
  
  func galleryConfig() {
    Config.tabsToShow = [.videoTab, .imageTab]
    Config.Limit.videoMaxDuration = 600
    Config.Limit.videoMinDuration = 0
    Config.Limit.videoCount = 0
    Config.Limit.imageCount = 0
    Config.Limit.allItemsCount = Int.max
    Config.Font.Text.bold = UIFont.systemFont(ofSize: 10)
    Config.Grid.Dimension.cellSpacing = 10
    Config.Grid.Dimension.lineSpacing = 10
    Config.Grid.Dimension.inset = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
    Config.Grid.FrameView.fillColor = .clear
    Config.Grid.FrameView.borderColor = .clear
    Config.RefreshControl.isActive = true
    Config.PageIndicator.isEnable = true
    Config.PageIndicator.backgroundColor = .white
    Config.PageIndicator.textColor = .black
    Config.SelectedView.isEnabled = true
    Config.CellSelectedStyle.isEnabled = false
    Config.CellSelectedStyle.isCounter = true
    Config.SelectedView.Collection.isEnableTimeView = true
    Config.ImageCell.borderVisibility = false
    Config.PageIndicator.imagesTitle = "photos"
    Config.PageIndicator.videosTitle = "videos"
    Config.DropDown.isEnabled = true
}
  
  func initGalleryIfNeeded() {
    if gallery != nil {
      return
    }
    gallery = GalleryController(videoDelegate: self, imageDelegate: self)
    gallery?.delegate = self
    if let gallery = gallery {
      addChild(gallery)
      gallery.view.frame = self.view.bounds
      self.view.addSubview(gallery.view)
      didMove(toParent: gallery)
      view.layoutIfNeeded()
      self.updateGalleryItems()
    }
  }
  
  func updateGalleryItems() {
    let items = uploadVideos.map({ (item) -> ChosenItem in
      return ChosenItem(id: item.id,
                        localIdentifier: item.localIdentifier,
                        asset: item.asset,
                        startTime: item.startTime,
                        duration: item.duration,
                        updated: item.updated,
                        editable: item.editable)
    })
    gallery?.setupSelectedItems(items: items)
  }
  
  func updateChosenItem(model: TutorialUploadVideoModel) {
    let item = ChosenItem(id: model.id,
                          localIdentifier: model.localIdentifier,
                          asset: model.asset,
                          startTime: model.startTime,
                          duration: model.duration,
                          updated: model.updated,
                          editable: model.editable)
    self.gallery?.updateSelectedItem(item: item)
  }
  
  
  func cropImage(model: TutorialUploadVideoModel, image: UIImage) {
    if let url = VideoFileManager.getRandomVideoUrl(folderName: "tmp") {
      let imageRect = CGRect(origin: CGPoint.zero, size: image.size)
      let rect_9_16 = imageRect.aspectRect(aspect: 9.0 / 16.0)
      if let imageRef = image.cgImage?.cropping(to: rect_9_16) {
        let newImage = UIImage(cgImage: imageRef)
        let settings = CEMovieMaker.videoSettings(withCodec: AVVideoCodecType.h264.rawValue, withWidth: 720.0, andHeight: 1280.0)
        let movieMaker = CEMovieMaker(settings: settings, frameTime: CMTimeMake(value: 1, timescale: 30), url: url, frameCount: Int(ceil(30.0 * model.duration)))
        movieMaker?.createMovie(from: [newImage], withCompletion: { (videoURL) in
          DispatchQueue.main.async {
            if let newUrl = videoURL {
              let asset = AVURLAsset(url: newUrl)
              model.croppedAsset = asset
              model.thumbnail = newImage
              model.updated = true
              self.updateChosenItem(model: model)
            }
          }
        })
      }
    }
  }
}

extension TutorialChooseVideoUploadViewController: VideosControllerDelegate {
    func didAddVideo(video: Video) {
        video.customFetch { (_, asset, thumbnail) in
            DispatchQueue.main.async {
                if self.currentIndex != -1 {
                    let model = self.uploadVideos[self.currentIndex]
                    model.localIdentifier = video.localIdentifier
                    model.thumbnail = thumbnail
                    model.asset = asset
                    model.croppedAsset = asset as? AVURLAsset
                    model.updated = true
                    self.updateChosenItem(model: model)
                }
            }
        }
    }
    
    func didRemoveVideo(video: Video) {}
}

extension TutorialChooseVideoUploadViewController: ImageControllerDelegate {
    func didAddImage(image: Image) {
        image.resolve { (newImage) in
            DispatchQueue.main.async {
                if self.currentIndex != -1 {
                    let model = self.uploadVideos[self.currentIndex]
                    model.localIdentifier = image.localIdentifier
                    model.thumbnail = newImage
                    model.image = newImage
                    model.type = .image
                    if let image = newImage {
                        self.cropImage(model: model, image: image)
                    }
                }
            }
        }
    }
    
    func didRemoveImage(image: Image) {}
}

extension TutorialChooseVideoUploadViewController: GalleryControllerDelegate {
    func didEdit(_ controller: GalleryController, index: Int) {
    }
    
    func didRemove(_ controller: GalleryController, index: Int) {
        self.uploadVideos[index].clearAssets()
        self.uploadVideos[index].updated = true
    }
}

import Foundation

class TutorialUploadVideoModel {
    var duration: TimeInterval = 0
    var startTime: TimeInterval = 0
    var localIdentifier: String?
    var asset: AVAsset?
    var image: UIImage?
    var croppingOffset: CGPoint?
    var croppingRect: CGRect?
    var zoomScale: CGFloat = 1.0
    var croppedAsset: AVURLAsset?
    var id: String
    var thumbnail: UIImage?
    var updated: Bool = false
    var editable: Bool = true
    var type: TutorialUploadItemType = .video
    
    var timeRange: CMTimeRange {
        let timeScale = self.asset?.duration.timescale ?? 100
        let startTime = CMTime(seconds: self.startTime, preferredTimescale: timeScale)
        let duration = CMTime(seconds: self.duration, preferredTimescale: timeScale)
        return CMTimeRange(start: startTime, duration: duration)
    }
    
    var isEmpty: Bool {
        let hasAsset = asset != nil
        let hasImage = image != nil
        return !(hasAsset || hasImage)
    }
    
    init(duration: TimeInterval = 0,
         startTime: TimeInterval = 0,
         localIdentifier: String? = nil,
         asset: AVAsset? = nil,
         image: UIImage? = nil,
         croppedAsset: AVURLAsset? = nil,
         id: String = String.randomString(length: 10),
         thumbnail: UIImage? = nil,
         updated: Bool = false,
         editable: Bool = true,
         type: TutorialUploadItemType = .video,
         zoomScale: CGFloat = 1.0,
         croppingOffset: CGPoint? = nil) {
        self.duration = duration
        self.startTime = startTime
        self.localIdentifier = localIdentifier
        self.asset = asset
        self.image = image
        self.croppedAsset = croppedAsset
        self.id = id
        self.thumbnail = thumbnail
        self.updated = updated
        self.editable = editable
        self.type = type
        self.zoomScale = zoomScale
        self.croppingOffset = croppingOffset
    }
    
    convenience init(item: TutorialUploadVideoModel) {
        self.init(duration: item.duration,
                  startTime: item.startTime,
                  localIdentifier: item.localIdentifier,
                  asset: item.asset,
                  image: item.image,
                  croppedAsset: item.croppedAsset,
                  id: item.id,
                  thumbnail: item.thumbnail,
                  updated: item.updated,
                  editable: item.editable,
                  type: item.type,
                  zoomScale: item.zoomScale,
                  croppingOffset: item.croppingOffset)
    }
    
    func clearAssets() {
        self.startTime = 0
        self.localIdentifier = nil
        self.asset = nil
        self.croppedAsset = nil
        self.image = nil
        self.thumbnail = nil
        self.updated = false
        self.editable = true
        self.type = .video
        self.zoomScale = 1.0
        self.croppingOffset = nil
    }
}


enum TutorialUploadItemType {
    case video
    case image
}


extension CGRect {
    func aspectRect(aspect: CGFloat) -> CGRect {
        if aspect == 0 {
            return self
        }
        var w = self.width
        var h = ceil(w / aspect)
        if h < self.height {
            return CGRect(x: (self.width - w) * 0.5, y: (self.height - h) * 0.5, width: w, height: h)
        }
        h = self.height
        w = ceil(self.height * aspect)
        return CGRect(x: (self.width - w) * 0.5, y: (self.height - h) * 0.5, width: w, height: h)
    }
}

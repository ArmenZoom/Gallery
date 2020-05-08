import UIKit
import Photos

/// Wrap a PHAsset for video
public class Video: Equatable {
    
    public let asset: PHAsset
    
    public var id: String = String.randomString(length: 10)
    
    public var localIdentifier: String {
        return asset.localIdentifier
    }
    
    var durationRequestID: Int = 0
    
    public var duration: Double {
        return asset.duration
    }
    public var isVideo = true
    
    // MARK: - Initialization
    
    
    init(asset: PHAsset, isVideo: Bool = true) {
        self.asset = asset
        self.isVideo = isVideo
    }
    
    /// Fetch video duration asynchronously
    ///
    /// - Parameter completion: Called when finish
    //  func fetchDuration(_ completion: @escaping (Double) -> Void) {
    //    guard duration == 0
    //    else {
    //      DispatchQueue.main.async {
    //        completion(self.duration)
    //      }
    //      return
    //    }
    //
    //    if durationRequestID != 0 {
    //      PHImageManager.default().cancelImageRequest(PHImageRequestID(durationRequestID))
    //    }
    //
    //    let id = PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) {
    //      asset, mix, _ in
    //
    //      self.duration = asset?.duration.seconds ?? 0
    //      DispatchQueue.main.async {
    //        completion(self.duration)
    //      }
    //    }
    //
    //    durationRequestID = Int(id)
    //  }
    
    /// Fetch AVPlayerItem asynchronoulys
    ///
    /// - Parameter completion: Called when finish
    public func fetchPlayerItem(_ completion: @escaping (AVPlayerItem?) -> Void) {
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: videoOptions) {
            item, _ in
            
            DispatchQueue.main.async {
                completion(item)
            }
        }
    }
    
    /// Fetch AVAsset asynchronoulys
    ///
    /// - Parameter completion: Called when finish
    public func fetchAVAsset(_ completion: @escaping (AVAsset?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { avAsset, _, _ in
            DispatchQueue.main.async {
                completion(avAsset)
            }
        }
    }
    
    /// Fetch thumbnail image for this video asynchronoulys
    ///
    /// - Parameter size: The preferred size
    /// - Parameter completion: Called when finish
    public func fetchThumbnail(size: CGSize = CGSize(width: 100, height: 100), completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage( for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    public func resolve(completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        let targetSize = CGSize(
            width: asset.pixelWidth,
            height: asset.pixelHeight
        )
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { (image, _) in
            completion(image)
        }
    }
    
    public func customFetch(completion: @escaping (_ originalImage: UIImage?, _ asset: AVAsset?, _ thumbnailImage: UIImage? ) -> Void) {
        
        var image: UIImage?
        var asset: AVAsset?
        var originalImage: UIImage?
        var isAdded = false
        
        self.fetchThumbnail { (thumbnailImage ) in
            image = thumbnailImage
            if let img = thumbnailImage, !isAdded {
                if let ast = asset {
                    isAdded = true
                    completion(nil, ast, img)
                } else if let orImage = originalImage {
                    isAdded = true
                    completion(orImage, nil, img)
                }
            }
        }
        
        if self.isVideo {
            self.fetchAVAsset { (avasset) in
                asset = avasset
                if let img = image, let ast = avasset, !isAdded {
                    isAdded = true
                    completion(nil, ast, img)
                }
            }
        } else {
            self.resolve { (originImage) in
                originalImage = originImage
                if let img = originImage, let thumbnail = image, !isAdded {
                    isAdded = true
                    completion(img, nil, thumbnail)
                }
            }
        }
    }
    
    public func fetchURL(completion: @escaping (_ url: URL?) -> Void) {
        self.getURL(ofPhotoWith: asset) { (url) in
            completion(url)
        }
    }
    
    private func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
        
    }
    
    
    
    // MARK: - Helper
    
    private var videoOptions: PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        
        return options
    }
}

// MARK: - Equatable

public func ==(lhs: Video, rhs: Video) -> Bool {
    return lhs.asset == rhs.asset
}

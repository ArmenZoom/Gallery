import UIKit
import Photos

/// Wrap a PHAsset for video
public class Video: Equatable {
    
    public let asset: PHAsset
    
    public var id: String
    
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
        self.id = asset.localIdentifier
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
    public func fetchAVAsset(iCloudSaveURL: URL, _ completion: @escaping (AVAsset?) -> Void) {
        self.fetchURL(iCloudSaveURL: iCloudSaveURL, completion: { url in
            if let url = url {
                completion(AVAsset(url: url))
            } else {
                completion(nil)
            }
        })
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
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    public func customFetch(iCloudSaveURL: URL, completion: @escaping (_ originalImage: UIImage?, _ asset: AVAsset?, _ thumbnailImage: UIImage? ) -> Void) {
        
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
            self.fetchAVAsset(iCloudSaveURL: iCloudSaveURL, { avasset in
                asset = avasset
                if let img = image, let ast = avasset, !isAdded {
                    isAdded = true
                    completion(nil, ast, img)
                }
            })
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
    
    public func fetchURL(iCloudSaveURL: URL?, completion: @escaping (_ url: URL?) -> Void) {
        self.getURL(ofPhotoWith: asset, iCloudSaveURL: iCloudSaveURL) { (url) in
            completion(url)
        }
    }
    
    private func getURL(ofPhotoWith mPhasset: PHAsset, iCloudSaveURL: URL?, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                DispatchQueue.main.async {
                    completionHandler(contentEditingInput?.fullSizeImageURL)
                }
            })
        } else if mPhasset.mediaType == .video {
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: videoOptions, resultHandler: { (asset, audioMix, info) in
                DispatchQueue.main.async {
                    if let urlAsset = asset as? AVURLAsset {
                        if urlAsset.tracks(withMediaType: .video).count > 0 && false {
                            let localVideoUrl = urlAsset.url
                            completionHandler(localVideoUrl)
                        } else if let saveURL = iCloudSaveURL {
                            self.loadICloudVideo(url: urlAsset.url, saveURL: saveURL) { url in
                                completionHandler(url)
                            }
                        } else {
                            completionHandler(nil)
                        }
                    } else {
                        completionHandler(nil)
                    }
                }
            })
        }
        
    }
    
    func loadICloudVideo(url: URL, saveURL: URL, complation: @escaping (URL?)->()) {
        DispatchQueue.global(qos: .background).async {
            if  let urlData = NSData(contentsOf: url){
                DispatchQueue.main.async {
                    if urlData.write(toFile: saveURL.path, atomically: true) {
                        complation(saveURL)
//                        PHPhotoLibrary.shared().performChanges({
//                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: saveURL)
//                        }) { completed, error in
//                            DispatchQueue.main.async {
//                                print("error \(error?.localizedDescription ?? "empty")")
//                                if completed {
//                                    complation(saveURL)
//                                } else {
//                                    complation(nil)
//                                }
//                            }
//                        }
                    } else {
                        complation(nil)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    complation(nil)
                }
            }
        }
    }
    
    func randomString(length:Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
        
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

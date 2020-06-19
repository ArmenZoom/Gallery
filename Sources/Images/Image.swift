import UIKit
import Photos

/// Wrap a PHAsset
public class Image: Equatable {
    
    public let asset: PHAsset
    
    public var id: String
    public var localIdentifier: String {
        return asset.localIdentifier
    }
    
    // MARK: - Initialization
    
    init(asset: PHAsset) {
        self.asset = asset
        self.id = asset.localIdentifier
    }
}

// MARK: - UIImage

extension Image {
    
    /// Resolve UIImage synchronously
    ///
    /// - Parameter size: The target size
    /// - Returns: The resolved UIImage, otherwise nil
    public func resolve(completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        let targetSize = CGSize(
            width: asset.pixelWidth,
            height: asset.pixelHeight
        )
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .default,
            options: options) { (image, _) in
                completion(image)
        }
    }
    
    public func fetchThumbnail(size: CGSize = CGSize(width: 100, height: 100), completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage( for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    
    public func customFetch(completion: @escaping (_ originalImage: UIImage?, _ thumbnailImage: UIImage?) -> Void) {
        
        var image: UIImage?
        var originalImage: UIImage?
        var isAdded = false
        
        self.fetchThumbnail { (thumbnailImage ) in
            image = thumbnailImage
            if let img = thumbnailImage, !isAdded {
                if let orImage = originalImage {
                    isAdded = true
                    completion(orImage, img)
                }
            }
        }
        
        self.resolve { (originImage) in
            originalImage = originImage
            if let img = originImage, let thumbnail = image, !isAdded {
                isAdded = true
                completion(img, thumbnail)
            }
        }
        
    }
    
    public func fetchURL(completion: @escaping (_ url: URL?) -> Void) {
        self.getURL(ofPhotoWith: asset) { (url) in
            completion(url)
        }
    }
    
    /// Resolve an array of Image
    ///
    /// - Parameters:
    ///   - images: The array of Image
    ///   - size: The target size for all images
    ///   - completion: Called when operations completion
    public static func resolve(images: [Image], completion: @escaping ([UIImage?]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var convertedImages = [Int: UIImage]()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.enter()
            
            image.resolve(completion: { resolvedImage in
                if let resolvedImage = resolvedImage {
                    convertedImages[index] = resolvedImage
                }
                
                dispatchGroup.leave()
            })
        }
        
        dispatchGroup.notify(queue: .main, execute: {
            let sortedImages = convertedImages
                .sorted(by: { $0.key < $1.key })
                .map({ $0.value })
            completion(sortedImages)
        })
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
}

// MARK: - Equatable

public func == (lhs: Image, rhs: Image) -> Bool {
    return lhs.asset == rhs.asset
}

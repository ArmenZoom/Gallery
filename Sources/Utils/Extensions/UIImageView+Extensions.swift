import UIKit
import Photos

extension UIImageView {
    
    func g_loadImage(_ asset: PHAsset) {
        guard frame.size != CGSize.zero else {
            image = GalleryBundle.image("gallery_placeholder")
            return
        }
        
        if tag == 0 {
            image = GalleryBundle.image("gallery_placeholder")
        } else {
            PHImageManager.default().cancelImageRequest(PHImageRequestID(tag))
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let id = PHImageManager.default().requestImage(
            for: asset,
            targetSize: frame.size,
            contentMode: .aspectFill,
            options: options) { [weak self] image, _ in
                self?.image = image
        }
        
        tag = Int(id)
    }
    
    func g_loadImage(_ asset: AVAsset) {
        do {
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            self.image = thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            self.image = nil
        }
    }
}

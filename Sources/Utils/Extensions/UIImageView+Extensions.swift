import UIKit
import Photos

extension UIImageView {
    
    func g_loadImageChoosen(_ asset: PHAsset) {
        guard frame.size != CGSize.zero else {
            image = GalleryBundle.image("gallery_placeholder")
            return
        }
        
        if tag == 0 {
            image = GalleryBundle.image("gallery_placeholder")
        } else {
            PHImageManager.default().cancelImageRequest(PHImageRequestID(tag))
        }
        let size = self.frame.size
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let id = PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options) { [weak self] image, _ in
            self?.image = image
        }
        self.tag = Int(id)
    }
    
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
        let size = self.frame.size
        //        DispatchQueue.global().async {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let id = PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options) { [weak self] image, _ in
            DispatchQueue.main.async {
                self?.image = image
            }
        }
        DispatchQueue.main.async {
            self.tag = Int(id)
        }
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

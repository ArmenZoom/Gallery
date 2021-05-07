import UIKit
import Photos

class Album {
    
    let name:String
    let count:Int
    let collection: PHAssetCollection
    let type: Config.GalleryTab
    
    var items: [Any] = []
    
    // MARK: - Initialization
    
    init(name:String, count:Int, collection:PHAssetCollection, type: Config.GalleryTab) {
        self.type = type
        self.count = count
        self.name = name
        self.collection = collection
    }
    
    func reload() {
        items = []
        switch type {
        case .imageTab:
            let itemsFetchResult = PHAsset.fetchAssets(in: collection, options: Utils.fetchImageOptions())
            itemsFetchResult.enumerateObjects({ (asset, count, stop) in
                if asset.mediaType == .image {
                    self.items.append(Image(asset: asset))
                }
            })
        case .videoTab:
            let itemsFetchResult = PHAsset.fetchAssets(in: collection, options: Utils.fetchVideoOptions())
            itemsFetchResult.enumerateObjects({ (asset, count, stop) in
                if asset.mediaType == .video && asset.isVisible {
                    self.items.append(Video(asset: asset, isVideo: asset.duration != 0))
                }
            })
        case .videoImageTab:
            let itemsFetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            itemsFetchResult.enumerateObjects({ (asset, count, stop) in
                switch asset.mediaType {
                case .video:
                    if asset.isVisible {
                        self.items.insert(Video(asset: asset, isVideo: asset.duration != 0), at: 0)
                    }
                case .image:
                    self.items.insert(Video(asset: asset, isVideo: false), at: 0)
                default:
                    break
                    
                }
            })
        default:
            break
        }     
    }
}

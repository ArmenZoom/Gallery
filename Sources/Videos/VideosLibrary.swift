import UIKit
import Photos

class VideosLibrary {

  
    var items: [Video] = []
    var fetchResults: PHFetchResult<PHAsset>?
    var albumsFetchResults = [PHFetchResult<PHAssetCollection>]()

  
    // MARK: - Initialization

    init() {

    }

    // MARK: - Logic

    func reload(_ completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            self.reloadSync()
            DispatchQueue.main.async {
                completion()
            }
        }
    }


    fileprivate func reloadSync() {
        
        let types: [PHAssetCollectionType] = [.smartAlbum, .album]
        
        albumsFetchResults = types.map {
            return PHAssetCollection.fetchAssetCollections(with: $0, subtype: .smartAlbumUserLibrary, options: nil)
        }
        
        items = []
        for result in albumsFetchResults {
            result.enumerateObjects({ (collection, _, _) in
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    let itemsFetchResult = PHAsset.fetchAssets(in: collection, options: nil)
                    itemsFetchResult.enumerateObjects({ (asset, count, stop) in
                        if asset.mediaType == .video {
                            if asset.duration >= Config.Limit.videoMinDuration && asset.duration <= Config.Limit.videoMaxDuration {
                                self.items.insert(Video(asset: asset, isVideo: asset.duration != 0), at: 0)
                            }
                        } else if Config.tabsToShow == [.videoImageTab] && asset.mediaType == .image {
                            self.items.insert(Video(asset: asset, isVideo: false), at: 0)
                        }
                    })
                }
            })
        }
        
        print(self.items.count)
    }
    
}


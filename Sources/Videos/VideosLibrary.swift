import UIKit
import Photos

class VideosLibrary {

  
    var items: [Video] = []
    var fetchResults: PHFetchResult<PHAsset>?

  
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
        fetchResults = PHAsset.fetchAssets(with: .video, options: Utils.fetchOptions())
        items = []
        fetchResults?.enumerateObjects({ (asset, _, _) in
            self.items.append(Video(asset: asset))
        })
        
        if Config.tabsToShow == [.videoImageTab] {
            let imagesResault = PHAsset.fetchAssets(with: .image, options: nil)
              imagesResault.enumerateObjects { (asset, _, _) in
                  self.items.append(Video(asset: asset, isVideo: false))
              }
        }
        self.items.sort { (item1, item2) -> Bool in
            let date1 = item1.asset.creationDate ?? Date()
            let date2 = item2.asset.creationDate ?? Date()
            return  date1 > date2
        }

    }
    
}


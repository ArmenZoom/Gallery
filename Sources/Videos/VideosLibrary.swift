import UIKit
import Photos

class VideosLibrary {
    
    var albums: [Album] = []
    var albumsFetchResults = [PHFetchResult<PHAssetCollection>]()
        
    var names: [String] {
        return albums.map { (album) -> String in
            return album.name
        }
    }
    
    func findAlbumFromName(_ name: String) -> Album? {
        for album in self.albums {
            if album.name == name {
                return album
            }
        }
        return nil
    }

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
        
        albums = []
        let type: Config.GalleryTab = Config.tabsToShow == [.videoImageTab] ? .videoImageTab : .videoTab
        
        for result in albumsFetchResults {
            result.enumerateObjects({ (collection, count, _) in
                let album = Album(name: collection.localizedTitle!, count: count, collection: collection, type: type)
                album.reload()
                
                if !album.items.isEmpty {
                    self.albums.append(album)
                }
            })
        }
        
    }
    
}


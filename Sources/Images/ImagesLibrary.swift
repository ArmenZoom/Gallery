import UIKit
import Photos

class ImagesLibrary {
    
    var albums: [Album] = []
    var albumsFetchResults = [PHFetchResult<PHAssetCollection>]()
    
    var names: [String] {
        return albums.map { (album) -> String in
            return album.name
        }
    }
    
    func getFolderNameFromIndex(index: Int) -> String? {
        let names = self.names
        if index < names.count && index >= 0 {
            return names[index]
        }
        return nil
    }
    
    func getItemsFromAlbumName(name: String) -> [Image] {
        var images: [Image] = []
        for album in albums {
            if name == album.name, let objs = album.items as? [Image] {
                images.append(contentsOf: objs)
            }
        }
        return images
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
            return PHAssetCollection.fetchAssetCollections(with: $0, subtype: .any, options: nil)
        }
        
        albums = []
        
        for result in albumsFetchResults {
            result.enumerateObjects({ (collection, count, _) in
                let album = Album(name: collection.localizedTitle!, count: count, collection: collection, type: .imageTab)
                album.reload()
                
                if !album.items.isEmpty {
                    self.albums.append(album)
                }
            })
        }
        
        // Move Camera Roll first
        if let index = albums.index(where: { $0.collection.assetCollectionSubtype == . smartAlbumUserLibrary }) {
            albums.g_moveToFirst(index)
        }
    }
    
    
//    fileprivate func reloadSync() {
//        albums = []
//        let options = PHFetchOptions()
//        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
//        userAlbums.enumerateObjects{ (object: AnyObject!, count: Int, stop: UnsafeMutablePointer) in
//            if object is PHAssetCollection {
//                let obj:PHAssetCollection = object as! PHAssetCollection
//
//                let fetchOptions = PHFetchOptions()
//                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
//
//                let album = Album(name: obj.localizedTitle!, count: obj.estimatedAssetCount, collection:obj)
//                album.reload()
//                if count > 0 {
//                    self.albums.append(album)
//                }
//            }
//        }
//    }
}

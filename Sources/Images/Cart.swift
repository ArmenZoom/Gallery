import UIKit
import Photos

public protocol CartDelegate: class {
    func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool)
    func cart(_ cart: Cart, didRemove image: Image)
    
    func cart(_ cart: Cart, didAdd video: Video, newlyTaken: Bool)
    func cart(_ cart: Cart, didRemove video: Video)
    
    func cartDidReload(_ cart: Cart)
}

/// Cart holds selected images and videos information
public class Cart {
    
    public var images: [Image] = []
    public var videos: [Video] = []
    public var videoRecord: [AVAsset] = []
    
    public var addedVideoMinDuration: Double = 0
    
    public var canAddNewItems: Bool = true
    
    public var videosCount: Int {
        return videos.count + self.videoRecord.count
    }
    
    public var imagesCount: Int {
        self.images.count
    }
    
    public var allItemsCount: Int {
        return self.videosCount + self.imagesCount
    }
    
    var delegates: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    // MARK: - Initialization
    
    init() {
        
    }
    
    // MARK: - Delegate
    
    public func add(delegate: CartDelegate) {
        delegates.add(delegate)
    }
    
    // MARK: - Logic
    
    public func add(_ image: Image, newlyTaken: Bool = false) {
        if images.contains(image) && Config.CellSelectedStyle.isEnabled { return }
        
        images.append(image)
        
        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cart(self, didAdd: image, newlyTaken: newlyTaken)
        }
    }
    
    public func remove(_ image: Image) {
        for (i, img) in self.images.enumerated() {
            if image.id == img.id {
                print("removed item id == \(image.id)")
                images.remove(at: i)
                for case let delegate as CartDelegate in delegates.allObjects {
                    delegate.cart(self, didRemove: image)
                }
                return
            }
        }
    }
    
    
    public func reload( images: [Image]) {
        self.images = images
        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    
    public func add(_ video: Video, newlyTaken: Bool = false) {
        if (videos.contains(video) && Config.CellSelectedStyle.isEnabled) || video.duration < addedVideoMinDuration { return }
        
        videos.append(video)
        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cart(self, didAdd: video, newlyTaken: newlyTaken)
        }
    }
    
    public func remove(_ video: Video) {
        for (i, vid) in self.videos.enumerated() {
            if video.id == vid.id {
                videos.remove(at: i)
                for case let delegate as CartDelegate in delegates.allObjects {
                    delegate.cart(self, didRemove: video)
                }
                return
            }
        }
    }
    
    
    public func reload(videos: [Video]) {
        self.videos = videos
        
        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    public func reload() {
        for case let delegate as CartDelegate in delegates.allObjects {
            delegate.cartDidReload(self)
        }
    }
    
    // MARK: - Reset
    
    public func reset() {
        self.resetItems()
        delegates.removeAllObjects()
    }
    
    public func resetItems() {
        videos = []
        images = []
        videoRecord = []
    }
    
    
    public var canAddVideoFromCart: Bool {
        let checkVideoLimit = Config.SelectedView.videoLimit == 0 || Config.SelectedView.videoLimit > self.videosCount
        let checkAllItemLimit = Config.SelectedView.allLimit > self.allItemsCount
        return checkVideoLimit && self.canAddNewItems && checkAllItemLimit
    }
    
    public var canAddSingleVideoState: Bool {
        return !Config.SelectedView.isEnabled && Config.SelectedView.videoLimit == 1
    }
    

    public var canAddImageFromCart: Bool {
          let checkImageLimit = Config.SelectedView.imageLimit == 0 || Config.SelectedView.imageLimit > self.imagesCount
          let checkAllItemLimit = Config.SelectedView.allLimit > self.allItemsCount
          return checkImageLimit && self.canAddNewItems && checkAllItemLimit
      }
      
      public var canAddSingleImageState: Bool {
          return !Config.SelectedView.isEnabled && Config.SelectedView.imageLimit == 1
      }
}

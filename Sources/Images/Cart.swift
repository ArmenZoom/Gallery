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
    
    public var canAddNewItems: Bool = true {
        didSet {
            if !self.canAddNewItems {
                print("aaaaaa")
            }
        }
    }
    
    public var allItemsCount: Int {
        return images.count + videos.count
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
        if videos.contains(video) && Config.CellSelectedStyle.isEnabled { return }
        
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
        videos = []
        images = []
        delegates.removeAllObjects()
    }
}

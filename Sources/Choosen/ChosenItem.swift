//
//  ChosenItem.swift
//  Cache
//
//  Created by Armen Alex on 5/7/20.
//

import AVFoundation
import Photos

public class ChosenItem {
    public var id: String
    var video: Video?
    var image: Image?
    
    public var duration: TimeInterval = 0
    public var startTime: TimeInterval = 0
    public var localIdentifier: String?
    public var asset: AVAsset?
    public var updated: Bool = false
    public var editable: Bool = true
    
    public init(asset: AVAsset? = nil, localIdentifier: String? = nil, startTime: TimeInterval = 0, duration: TimeInterval = 0, updated: Bool = false, editable: Bool = true) {
        self.id = String.randomString(length: 10)
        print("items id \(id)")
        self.asset = asset
        self.duration = duration
        self.startTime = startTime
        self.updated = updated
        self.editable = editable
        self.localIdentifier = localIdentifier
        
        if let identifier = localIdentifier {
            //                let option = true ? Utils.fetchVideoOptions() : Utils.fetchImageOptions()
            let obj = self.loadFromLocalIdentifier(id: identifier)
            self.image = obj.image
            self.video = obj.video
        }
    }
    
    public func invalidate() {
        self.asset = nil
        self.image = nil
        self.video = nil
        self.localIdentifier = nil
        self.startTime = 0
    }
    
    public func loadFromLocalIdentifier(id: String) -> (image: Image?, video: Video?) {
        if let asset = Fetcher.fetchAsset(id) {
            if asset.duration > 0 {
                return (image: nil, video: Video(asset: asset))
            } else {
                return (image: Image(asset: asset), video: nil)
                
            }
        }
        return (image: nil, video: nil)
    }
    
}

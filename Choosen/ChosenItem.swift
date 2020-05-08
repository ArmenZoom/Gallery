//
//  ChosenItem.swift
//  Cache
//
//  Created by Armen Alex on 5/7/20.
//

import AVFoundation
import Photos

public class ChosenItem {
    var id: String
    var video: Video?
    var image: Image?
    
    var duration: TimeInterval = 0
    var startTime: TimeInterval = 0
    var localIdentifier: String?
    var asset: AVAsset?
    var updated: Bool = false
    var editable: Bool = false
    
    public init(asset: AVAsset? = nil, localIdentifier: String? = nil, startTime: TimeInterval = 0, duration: TimeInterval = 0, updated: Bool = false, editable: Bool = false) {
        self.id = String.randomString(length: 10)
        self.asset = asset
        self.duration = duration
        self.startTime = startTime
        self.updated = updated
        self.editable = editable
        self.localIdentifier = localIdentifier
        
        if let identifier = localIdentifier {
            DispatchQueue.global().async {
//                let option = true ? Utils.fetchVideoOptions() : Utils.fetchImageOptions()
                if let asset = Fetcher.fetchAsset(identifier) {
                    print("identifier === " , identifier)
                    self.video = Video(asset: asset)
                }
            }
        }
    }
    
    public func invalidate() {
        self.asset = nil
        self.image = nil
        self.video = nil
        self.localIdentifier = nil
        self.startTime = 0
        self.id = ""
    }

}

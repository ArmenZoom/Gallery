import UIKit
import Photos

/// Wrap a PHAsset for video
public class Video: Equatable {
    
    public let asset: PHAsset
    
    public var id: String = String.randomString(length: 10)
    
    public var localIdentifier: String {
        return asset.localIdentifier
    }
    
    var durationRequestID: Int = 0
    
    public var duration: Double {
        return asset.duration
    }
    public var isVideo = true
    
    // MARK: - Initialization
    
    
    init(asset: PHAsset, isVideo: Bool = true) {
        self.asset = asset
        self.isVideo = isVideo
    }
    
    /// Fetch video duration asynchronously
    ///
    /// - Parameter completion: Called when finish
    //  func fetchDuration(_ completion: @escaping (Double) -> Void) {
    //    guard duration == 0
    //    else {
    //      DispatchQueue.main.async {
    //        completion(self.duration)
    //      }
    //      return
    //    }
    //
    //    if durationRequestID != 0 {
    //      PHImageManager.default().cancelImageRequest(PHImageRequestID(durationRequestID))
    //    }
    //
    //    let id = PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) {
    //      asset, mix, _ in
    //
    //      self.duration = asset?.duration.seconds ?? 0
    //      DispatchQueue.main.async {
    //        completion(self.duration)
    //      }
    //    }
    //
    //    durationRequestID = Int(id)
    //  }
    
    /// Fetch AVPlayerItem asynchronoulys
    ///
    /// - Parameter completion: Called when finish
    public func fetchPlayerItem(_ completion: @escaping (AVPlayerItem?) -> Void) {
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: videoOptions) {
            item, _ in
            
            DispatchQueue.main.async {
                completion(item)
            }
        }
    }
    
    /// Fetch AVAsset asynchronoulys
    ///
    /// - Parameter completion: Called when finish
    public func fetchAVAsset(_ completion: @escaping (AVAsset?) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { avAsset, _, _ in
            DispatchQueue.main.async {
                completion(avAsset)
            }
        }
    }
    
    /// Fetch thumbnail image for this video asynchronoulys
    ///
    /// - Parameter size: The preferred size
    /// - Parameter completion: Called when finish
    public func fetchThumbnail(size: CGSize = CGSize(width: 100, height: 100), completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage( for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    public func resolve(completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        let targetSize = CGSize(
            width: asset.pixelWidth,
            height: asset.pixelHeight
        )
        
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { (image, _) in
            completion(image)
        }
    }
    
    public func customFetch(completion: @escaping (_ originalImage: UIImage?, _ asset: AVAsset?, _ thumbnailImage: UIImage? ) -> Void) {
        
        var image: UIImage?
        var asset: AVAsset?
        var originalImage: UIImage?
        var isAdded = false
        
        self.fetchThumbnail { (thumbnailImage ) in
            image = thumbnailImage
            if let img = thumbnailImage, !isAdded {
                if let ast = asset {
                    isAdded = true
                    completion(nil, ast, img)
                } else if let orImage = originalImage {
                    isAdded = true
                    completion(orImage, nil, img)
                }
            }
        }
        
        if self.isVideo {
            self.fetchAVAsset { (avasset) in
                asset = avasset
                if let img = image, let ast = avasset, !isAdded {
                    isAdded = true
                    completion(nil, ast, img)
                }
            }
        } else {
            self.resolve { (originImage) in
                originalImage = originImage
                if let img = originImage, let thumbnail = image, !isAdded {
                    isAdded = true
                    completion(img, nil, thumbnail)
                }
            }
        }
    }
    
    public func fetchURL(completion: @escaping (_ url: URL?) -> Void) {
        self.getURL(ofPhotoWith: asset) { (url) in
            completion(url)
        }
    }
    
    private func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)) {
        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: { (contentEditingInput, info) in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { (asset, audioMix, info) in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
        
    }
    
    
    
    // MARK: - Helper
    
    private var videoOptions: PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        
        return options
    }
}

// MARK: - Equatable

public func ==(lhs: Video, rhs: Video) -> Bool {
    return lhs.asset == rhs.asset
}



//
//  ChosenView.swift
//  Cache
//
//  Created by Armen Alex on 5/7/20.
//

import UIKit
import Photos

protocol ChosenViewDelegate: class {
    func didEdit(_ view: ChosenView, item: ChosenItem)
    func didRemove(_ view: ChosenView, item: ChosenItem)
}

public class ChosenView: UIView {
    weak var delegate: ChosenViewDelegate?
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.scrollDirection = .horizontal
        let c = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        c.backgroundColor = .white
        c.showsHorizontalScrollIndicator = false
        return c
    }()
        
    
    var items: [ChosenItem] = []
    
    var canAddNewItem: Bool {
        for item in self.items {
            if item.image == nil && item.video == nil {
                return true
            }
        }
        return false
    }
    
    var imageCount: Int {
        return self.items.count
    }
    
    var canShowedCellTime: Bool {
        return true
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func addVideo(video: Video) {
        if let index = self.getFirstEmtyIndex() {
            let item = self.items[index]
            item.image = nil
            item.video = video
            item.id = video.id
        }
        self.reload()
    }
    
    func removeVideo(video: Video) {
       if let index = self.getIndexById(id: video.id) {
            self.items[index].invalidate()
        }
        self.reload()
    }
    
    func addImage(image: Image) {
        if let index = self.getFirstEmtyIndex() {
            let item = self.items[index]
            item.image = image
            item.video = nil
            item.id = image.id
        }
        self.reload()
    }
    
    func removeImage(image: Image) {
        if let index = self.getIndexById(id: image.id) {
            self.items[index].invalidate()
        }
        self.reload()
    }
    
    public func updateItem(item: ChosenItem) {
        if let index = self.getIndexById(id: item.id) {
            self.items[index] = item
        }
    }
    
    public func addItem(item: ChosenItem) {
        if let index = self.getFirstEmtyIndex() {
            self.items[index] = item
        }
    }
    
    func getIndexById(id: String) -> Int? {
        for (i, item) in self.items.enumerated() {
            if id == item.id {
                return i
            }
        }
        return nil
    }
    
    func getFirstEmtyIndex() -> Int? {
        for (i, item) in self.items.enumerated() {
            if item.image == nil && item.video == nil {
                return i
            }
        }
        return nil
    }
    
    // MARK: - Setup
    
    func setup() {
        self.addSubview(collectionView)
        self.collectionView.g_pinEdges()
        self.collectionView.register(ChosenCell.self, forCellWithReuseIdentifier: String(describing: ChosenCell.self))
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    
    // MARK: - Reload
    
    func reload() {
        self.collectionView.reloadData()
    }
}


extension ChosenView: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

extension ChosenView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.imageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ChosenCell.self), for: indexPath)
            as! ChosenCell
        
        let item = self.items[indexPath.row]
        
        cell.configure(item, indexPath: indexPath)
        cell.delegate = self
        cell.selectedBorderIndex = self.getFirstEmtyIndex()
        
        return cell
    }
    
    
}

extension ChosenView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.bounds.size.height * 0.6
        var height: CGFloat
        if self.canShowedCellTime {
            height = collectionView.bounds.size.height * 0.8
        } else {
            height = width
        }
        return CGSize(width: width, height: height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Config.Grid.Dimension.inset
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Config.Grid.Dimension.lineSpacing
    }
    
}

extension ChosenView: ChosenCellDelegate {
    public func didRemove(_ view: ChosenCell, indexPath: IndexPath) {
        let item = ChosenItem()
        item.image = self.items[indexPath.row].image
        item.video = self.items[indexPath.row].video
        self.delegate?.didRemove(self, item: item)
        
        self.items[indexPath.row].invalidate()
        self.reload()
       
    }
    
    public func didEdit(_ view: ChosenCell, indexPath: IndexPath) {
        self.delegate?.didEdit(self, item: self.items[indexPath.row])
    }
}



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


//
//  ChosenCollectionViewCell.swift
//  Cache
//
//  Created by Armen Alex on 5/7/20.
//

import UIKit
import Photos

public protocol ChosenCellDelegate: class {
    func didRemove(_ view: ChosenCell, indexPath: IndexPath)
    func didEdit(_ view: ChosenCell, indexPath: IndexPath)
}

public class ChosenCell: UICollectionViewCell {
    weak var delegate: ChosenCellDelegate?

    lazy var imageView: UIImageView = self.makeImageView()
    lazy var timeLabel: UILabel = self.makeTimeLabel()
    lazy var removeButton: UIButton = self.makeRemoveButton()
    lazy var editButton: UIButton = self.makeEditButton()
    
    let buttonWidth: CGFloat = 14
    var indexPath: IndexPath!
    
    private var borderColor: UIColor = UIColor(red: 203.0/256.0, green: 203.0/256.0, blue: 203.0/256.0, alpha: 1.0) {
        didSet {
            self.imageView.layer.borderColor = self.borderColor.cgColor
        }
    }
    
   public var selectedBorderIndex: Int? = 0 {
        didSet {
            self.borderColor = self.selectedBorderIndex == self.indexPath.row ? UIColor(red: 228.0/256.0, green: 170.0/256.0, blue: 72.0/256.0, alpha: 1.0) : UIColor(red: 203.0/256.0, green: 203.0/256.0, blue: 203.0/256.0, alpha: 1.0)
        }
    }
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Config
    
    func configure(_ item: ChosenItem, indexPath: IndexPath) {
        self.indexPath = indexPath
        imageView.layoutIfNeeded()
        if let asset = item.video?.asset {
            imageView.g_loadImage(asset)
            removeButton.isHidden = false
        } else if let asset = item.image?.asset {
            imageView.g_loadImage(asset)
            removeButton.isHidden = false
        } else {
            imageView.image = nil
            removeButton.isHidden = true
        }
        editButton.isHidden = removeButton.isHidden
        timeLabel.text = String(format: "%.f", item.duration) + "s"
        
    }
    
    // MARK: - Setup
    
    func setup() {
        [imageView, timeLabel, editButton, removeButton].forEach {
            self.contentView.addSubview($0)
        }
        Constraint.on(
            removeButton.topAnchor.constraint(equalTo: removeButton.superview!.topAnchor),
            removeButton.rightAnchor.constraint(equalTo: removeButton.superview!.rightAnchor),
            removeButton.heightAnchor.constraint(equalToConstant: self.buttonWidth),
            removeButton.widthAnchor.constraint(equalToConstant: self.buttonWidth),
            
            imageView.topAnchor.constraint(equalTo: imageView.superview!.topAnchor, constant: self.buttonWidth / 2.0),
            imageView.rightAnchor.constraint(equalTo: imageView.superview!.rightAnchor, constant: -self.buttonWidth / 2.0),
            imageView.centerXAnchor.constraint(equalTo: imageView.superview!.centerXAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            timeLabel.bottomAnchor.constraint(equalTo: imageView.superview!.bottomAnchor),
            timeLabel.rightAnchor.constraint(equalTo: imageView.superview!.rightAnchor, constant: -self.buttonWidth / 2.0),
            timeLabel.centerXAnchor.constraint(equalTo: imageView.superview!.centerXAnchor)
        )
        timeLabel.g_pin(on: .top, view: imageView, on: .bottom)
  
        self.editButton.g_pinEdges(view: imageView)
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true
    }
    
    // MARK: - Controls
    
    private func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = UIColor(red: 176.0/256.0, green: 176.0/256.0, blue: 176.0/256.0, alpha: 1.0)
        imageView.layer.borderColor = self.borderColor.cgColor
        imageView.layer.borderWidth = 2
        return imageView
    }
    
    private func makeRemoveButton() -> UIButton {
        let b = UIButton(type: UIButton.ButtonType.custom)
        b.setImage(GalleryBundle.image("gallery_close"), for: .normal)
        b.addTarget(self, action: #selector(removeAction), for: .touchUpInside)
        b.backgroundColor = .red
        b.layer.masksToBounds = true
        b.layer.cornerRadius = buttonWidth / 2.0
        return b
    }
    
    private func makeEditButton() -> UIButton {
        let b = UIButton(type: UIButton.ButtonType.custom)
        b.setImage(GalleryBundle.image("gallery_close"), for: .normal)
        b.addTarget(self, action: #selector(editAction), for: .touchUpInside)
        b.backgroundColor = .clear
        return b
    }
    
    private func makeTimeLabel() -> UILabel {
        let l = UILabel(frame: CGRect.zero)
        l.font = Config.Font.Text.bold.withSize(12)
        l.textAlignment = .center
        l.textColor = .black
        l.backgroundColor = .white
        return l
    }
    
    @objc func removeAction() {
        self.delegate?.didRemove(self, indexPath: indexPath)
    }
    
    @objc func editAction() {
        self.delegate?.didEdit(self, indexPath: indexPath)
    }
    
}

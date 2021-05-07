//
//  ChosenView.swift
//  Cache
//
//  Created by Armen Alex on 5/7/20.
//

import UIKit
import Photos

protocol ChosenViewDelegate: class {
    func didEdit(_ view: ChosenView, index: Int)
    func didRemove(_ view: ChosenView, index: Int)
}

public class ChosenView: UIView {
    weak var delegate: ChosenViewDelegate?
    
    lazy var collectionView: UICollectionView = self.makeCollectionView()
    
    
    var items: [ChosenItem] = [] {
        didSet {
            self.cart.resetItems()
            self.items.forEach { (item) in
                if let imd = item.image {
                    self.cart.images.append(imd)
                } else if let vid = item.video {
                    self.cart.videos.append(vid)
                } else if let asset = item.asset {
                    self.cart.recordVideos.append(asset)
                }
            }
            self.cart.canAddNewItems = self.getFirstEmtyIndex() != nil
            self.update()
        }
    }
    
    var cart: Cart
    
    // MARK: - Initialization
    public required init(cart: Cart) {
        self.cart = cart
        super.init(frame: .zero)
        cart.delegates.add(self)
        self.setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
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
        return Config.SelectedView.Collection.isEnableTimeView
    }
    
    func addVideo(video: Video) {
        if let index = self.getFirstEmtyIndex() {
            let item = self.items[index]
            video.id = item.id
            item.image = nil
            item.video = video
            self.cart.canAddNewItems = index < (self.items.count-1)
        }
        self.update()
    }
    
    func removeVideo(video: Video) {
        if let index = self.getIndexById(id: video.id) {
            self.items[index].invalidate()
            self.cart.canAddNewItems = true
        }
        self.update()
    }
    
    func addImage(image: Image) {
        if let index = self.getFirstEmtyIndex() {
            let item = self.items[index]
            image.id = item.id
            item.image = image
            item.video = nil
            self.cart.canAddNewItems = index < (self.items.count-1)
        }
        
        self.update()
    }
    
    func removeImage(image: Image) {
        if let index = self.getIndexById(id: image.id) {
            self.items[index].invalidate()
            self.cart.canAddNewItems = true
        }
        self.update()
    }
    
    public func updateItem(item: ChosenItem) {
        if let index = self.getIndexById(id: item.id) {
            self.items[index] = item
        }
    }
    
    public func addItem(item: ChosenItem) {
        if let index = self.getFirstEmtyIndex() {
            self.items[index] = item
            self.cart.canAddNewItems = index < (self.items.count-1)
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
            if item.image == nil && item.video == nil && item.asset == nil {
                return i
            }
        }
        return nil
    }
    
    func getLastRemovedItem() -> Int? {
        var index: Int?
        for i in stride(from: 0, to: self.items.count, by: 1) {
            let item = self.items[i]
            if (item.image != nil || item.video != nil || item.asset != nil) {
                index = i
            }
        }
        return index
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
    
    func update() {
        if let index = self.getFirstEmtyIndex() {
            self.cart.addedVideoMinDuration = self.items[index].duration
        } else {
            self.cart.addedVideoMinDuration = 0
        }
        self.cart.update()
    }
    
    func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.scrollDirection = .horizontal
        let c = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        c.backgroundColor = .white
        c.showsHorizontalScrollIndicator = false
        return c
    }
}

extension ChosenView: CartDelegate {
    public func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool){}
    public func cart(_ cart: Cart, didRemove image: Image){}
    public func cart(_ cart: Cart, didAdd video: Video, newlyTaken: Bool){}
    public func cart(_ cart: Cart, didRemove video: Video){}
    public func cart(_ cart: Cart, canAddNewItem: Bool) {}
    
    public func cartDidUpdate(_ cart: Cart) {
        self.collectionView.reloadData()
    }
    public func cartDidReload(_ cart: Cart) {
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
        
        cell.removedButtonHide = self.getLastRemovedItem() != indexPath.row
        cell.configure(item, indexPath: indexPath)
        cell.delegate = self
        cell.selectedBorder = self.getFirstEmtyIndex() == indexPath.row
        
        
        return cell
    }
    
    
}

extension ChosenView: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let height: CGFloat = collectionView.bounds.size.height * 0.8
        let width = collectionView.bounds.size.height * 0.6

        return CGSize(width: width, height: height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Config.Grid.Dimension.inset
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension ChosenView: ChosenCellDelegate {
    public func didRemove(_ view: ChosenCell, indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        if let image = item.image {
            self.cart.remove(image)
        } else if let video = item.video {
            self.cart.remove(video)
        } else if let video = item.asset {
            self.cart.removeRecordVideo(video)
        }
        self.delegate?.didRemove(self, index: indexPath.row)
        item.invalidate()
        self.cart.canAddNewItems = true
        self.update()
    }
    
    public func didEdit(_ view: ChosenCell, indexPath: IndexPath) {
        self.delegate?.didEdit(self, index: indexPath.row)
    }
}

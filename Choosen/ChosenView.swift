////
////  ChosenView.swift
////  Cache
////
////  Created by Armen Alex on 5/7/20.
////
//
//import UIKit
//import Photos
//
//protocol ChosenViewDelegate: class {
//    func didEdit(_ view: ChosenView, item: ChosenItem)
//    func didRemove(_ view: ChosenView, item: ChosenItem)
//}
//
//public class ChosenView: UIView {
//    weak var delegate: ChosenViewDelegate?
//    
//    lazy var collectionView: UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        layout.minimumInteritemSpacing = 2
//        layout.minimumLineSpacing = 2
//        layout.scrollDirection = .horizontal
//        let c = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
//        c.backgroundColor = .white
//        c.showsHorizontalScrollIndicator = false
//        return c
//    }()
//        
//    
//    var items: [ChosenItem] = []
//    
//    var canAddNewItem: Bool {
//        for item in self.items {
//            if item.image == nil && item.video == nil {
//                return true
//            }
//        }
//        return false
//    }
//    
//    var imageCount: Int {
//        return self.items.count
//    }
//    
//    var canShowedCellTime: Bool {
//        return true
//    }
//    
//    // MARK: - Initialization
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        setup()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    
//    func addVideo(video: Video) {
//        if let index = self.getFirstEmtyIndex() {
//            let item = self.items[index]
//            item.image = nil
//            item.video = video
//            item.id = video.id
//        }
//        self.reload()
//    }
//    
//    func removeVideo(video: Video) {
//       if let index = self.getIndexById(id: video.id) {
//            self.items[index].invalidate()
//        }
//        self.reload()
//    }
//    
//    func addImage(image: Image) {
//        if let index = self.getFirstEmtyIndex() {
//            let item = self.items[index]
//            item.image = image
//            item.video = nil
//            item.id = image.id
//        }
//        self.reload()
//    }
//    
//    func removeImage(image: Image) {
//        if let index = self.getIndexById(id: image.id) {
//            self.items[index].invalidate()
//        }
//        self.reload()
//    }
//    
//    public func updateItem(item: ChosenItem) {
//        if let index = self.getIndexById(id: item.id) {
//            self.items[index] = item
//        }
//    }
//    
//    public func addItem(item: ChosenItem) {
//        if let index = self.getFirstEmtyIndex() {
//            self.items[index] = item
//        }
//    }
//    
//    func getIndexById(id: String) -> Int? {
//        for (i, item) in self.items.enumerated() {
//            if id == item.id {
//                return i
//            }
//        }
//        return nil
//    }
//    
//    func getFirstEmtyIndex() -> Int? {
//        for (i, item) in self.items.enumerated() {
//            if item.image == nil && item.video == nil {
//                return i
//            }
//        }
//        return nil
//    }
//    
//    // MARK: - Setup
//    
//    func setup() {
//        self.addSubview(collectionView)
//        self.collectionView.g_pinEdges()
//        self.collectionView.register(ChosenCell.self, forCellWithReuseIdentifier: String(describing: ChosenCell.self))
//        self.collectionView.delegate = self
//        self.collectionView.dataSource = self
//    }
//    
//    
//    // MARK: - Reload
//    
//    func reload() {
//        self.collectionView.reloadData()
//    }
//}
//
//
//extension ChosenView: UICollectionViewDelegate {
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return 1
//    }
//}
//
//extension ChosenView: UICollectionViewDataSource {
//    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.imageCount
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ChosenCell.self), for: indexPath)
//            as! ChosenCell
//        
//        let item = self.items[indexPath.row]
//        
//        cell.configure(item, indexPath: indexPath)
//        cell.delegate = self
//        cell.selectedBorderIndex = self.getFirstEmtyIndex() 
//        
//        return cell
//    }
//    
//    
//}
//
//extension ChosenView: UICollectionViewDelegateFlowLayout {
//    
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        
//        let width = collectionView.bounds.size.height * 0.6
//        var height: CGFloat
//        if self.canShowedCellTime {
//            height = collectionView.bounds.size.height * 0.8
//        } else {
//            height = width
//        }
//        return CGSize(width: width, height: height)
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return Config.Grid.Dimension.inset
//    }
//    
//    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return Config.Grid.Dimension.lineSpacing
//    }
//    
//}
//
//extension ChosenView: ChosenCellDelegate {
//    public func didRemove(_ view: ChosenCell, indexPath: IndexPath) {
//        let item = ChosenItem()
//        item.image = self.items[indexPath.row].image
//        item.video = self.items[indexPath.row].video
//        self.delegate?.didRemove(self, item: item)
//        
//        self.items[indexPath.row].invalidate()
//        self.reload()
//       
//    }
//    
//    public func didEdit(_ view: ChosenCell, indexPath: IndexPath) {
//        self.delegate?.didEdit(self, item: self.items[indexPath.row])
//    }
//}

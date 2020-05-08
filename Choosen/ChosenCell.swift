////
////  ChosenCollectionViewCell.swift
////  Cache
////
////  Created by Armen Alex on 5/7/20.
////
//
//import UIKit
//import Photos
//
//public protocol ChosenCellDelegate: class {
//    func didRemove(_ view: ChosenCell, indexPath: IndexPath)
//    func didEdit(_ view: ChosenCell, indexPath: IndexPath)
//}
//
//public class ChosenCell: UICollectionViewCell {
//    weak var delegate: ChosenCellDelegate?
//
//    lazy var imageView: UIImageView = self.makeImageView()
//    lazy var timeLabel: UILabel = self.makeTimeLabel()
//    lazy var removeButton: UIButton = self.makeRemoveButton()
//    lazy var editButton: UIButton = self.makeEditButton()
//    
//    let buttonWidth: CGFloat = 14
//    var indexPath: IndexPath!
//    
//    private var borderColor: UIColor = UIColor(red: 203.0/256.0, green: 203.0/256.0, blue: 203.0/256.0, alpha: 1.0) {
//        didSet {
//            self.imageView.layer.borderColor = self.borderColor.cgColor
//        }
//    }
//    
//   public var selectedBorderIndex: Int? = 0 {
//        didSet {
//            self.borderColor = self.selectedBorderIndex == self.indexPath.row ? UIColor(red: 228.0/256.0, green: 170.0/256.0, blue: 72.0/256.0, alpha: 1.0) : UIColor(red: 203.0/256.0, green: 203.0/256.0, blue: 203.0/256.0, alpha: 1.0)
//        }
//    }
//    // MARK: - Initialization
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.clipsToBounds = false
//        setup()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Config
//    
//    func configure(_ item: ChosenItem, indexPath: IndexPath) {
//        self.indexPath = indexPath
//        imageView.layoutIfNeeded()
//        if let asset = item.video?.asset {
//            imageView.g_loadImage(asset)
//            removeButton.isHidden = false
//        } else if let asset = item.image?.asset {
//            imageView.g_loadImage(asset)
//            removeButton.isHidden = false
//        } else {
//            imageView.image = nil
//            removeButton.isHidden = true
//        }
//        editButton.isHidden = removeButton.isHidden
//        timeLabel.text = String(format: "%.f", item.duration) + "s"
//        
//    }
//    
//    // MARK: - Setup
//    
//    func setup() {
//        [imageView, timeLabel, editButton, removeButton].forEach {
//            self.contentView.addSubview($0)
//        }
//        Constraint.on(
//            removeButton.topAnchor.constraint(equalTo: removeButton.superview!.topAnchor),
//            removeButton.rightAnchor.constraint(equalTo: removeButton.superview!.rightAnchor),
//            removeButton.heightAnchor.constraint(equalToConstant: self.buttonWidth),
//            removeButton.widthAnchor.constraint(equalToConstant: self.buttonWidth),
//            
//            imageView.topAnchor.constraint(equalTo: imageView.superview!.topAnchor, constant: self.buttonWidth / 2.0),
//            imageView.rightAnchor.constraint(equalTo: imageView.superview!.rightAnchor, constant: -self.buttonWidth / 2.0),
//            imageView.centerXAnchor.constraint(equalTo: imageView.superview!.centerXAnchor),
//            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
//            
//            timeLabel.bottomAnchor.constraint(equalTo: imageView.superview!.bottomAnchor),
//            timeLabel.rightAnchor.constraint(equalTo: imageView.superview!.rightAnchor, constant: -self.buttonWidth / 2.0),
//            timeLabel.centerXAnchor.constraint(equalTo: imageView.superview!.centerXAnchor)
//        )
//        timeLabel.g_pin(on: .top, view: imageView, on: .bottom)
//  
//        self.editButton.g_pinEdges(view: imageView)
//        self.layer.cornerRadius = 8
//        self.layer.masksToBounds = true
//    }
//    
//    // MARK: - Controls
//    
//    private func makeImageView() -> UIImageView {
//        let imageView = UIImageView()
//        imageView.clipsToBounds = true
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 8
//        imageView.layer.masksToBounds = true
//        imageView.backgroundColor = UIColor(red: 176.0/256.0, green: 176.0/256.0, blue: 176.0/256.0, alpha: 1.0)
//        imageView.layer.borderColor = self.borderColor.cgColor
//        imageView.layer.borderWidth = 2
//        return imageView
//    }
//    
//    private func makeRemoveButton() -> UIButton {
//        let b = UIButton(type: UIButton.ButtonType.custom)
//        b.setImage(GalleryBundle.image("gallery_close"), for: .normal)
//        b.addTarget(self, action: #selector(removeAction), for: .touchUpInside)
//        b.backgroundColor = .red
//        b.layer.masksToBounds = true
//        b.layer.cornerRadius = buttonWidth / 2.0
//        return b
//    }
//    
//    private func makeEditButton() -> UIButton {
//        let b = UIButton(type: UIButton.ButtonType.custom)
//        b.setImage(GalleryBundle.image("gallery_close"), for: .normal)
//        b.addTarget(self, action: #selector(editAction), for: .touchUpInside)
//        b.backgroundColor = .clear
//        return b
//    }
//    
//    private func makeTimeLabel() -> UILabel {
//        let l = UILabel(frame: CGRect.zero)
//        l.font = Config.Font.Text.bold.withSize(12)
//        l.textAlignment = .center
//        l.textColor = .black
//        l.backgroundColor = .white
//        return l
//    }
//    
//    @objc func removeAction() {
//        self.delegate?.didRemove(self, indexPath: indexPath)
//    }
//    
//    @objc func editAction() {
//        self.delegate?.didEdit(self, indexPath: indexPath)
//    }
//    
//}

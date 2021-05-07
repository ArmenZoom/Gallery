import UIKit
import Photos
import AVKit

public protocol VideosControllerDelegate: class {
    func didAddVideo(video: Video)
    func didRemoveVideo(video: Video)
}

public class VideosController: UIViewController {
    
    weak var delegate: VideosControllerDelegate? = nil
    lazy var gridView: GridView = self.makeGridView()
    lazy var infoLabel: UILabel = self.makeInfoLabel()
    lazy var lockView: UIView = self.makeLockView()
    
    lazy var dropDownBGView: UIView = self.makeDropDownBGView()
    lazy var dropDownLineView: UIView = self.makeDropDownBottomView()

    lazy var folderNameLabel: UILabel = self.makeFolderLabel()
    lazy var arowImageView: UIImageView = self.makeArrow()

    let dropDown = MakeDropDown()
    var folderModelArr: [Album] {
        return self.library.albums
    }
    var dropDownRowHeight: CGFloat = 80
    
    
    var items: [Video] = []
    var library = VideosLibrary()
    var selectedAlbum: Album?
    let once = Once()
    let cart: Cart
        
    // MARK: - Init
    
    public required init(cart: Cart) {
        self.cart = cart
        super.init(nibName: nil, bundle: nil)
        cart.delegates.add(self)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life cycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    public func unselectVideo(_ video: Video) {
        if let index = self.items.index(of: video) {
             self.gridView.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    // MARK: - Setup
    
    func setup() {
        view.backgroundColor = UIColor.white
        view.addSubview(gridView)
        
        if Config.DropDown.isEnabled {
            view.addSubview(dropDownBGView)
            dropDownBGView.addSubview(dropDownLineView)
            dropDownBGView.addSubview(folderNameLabel)
            dropDownBGView.addSubview(arowImageView)
            dropDownBGView.g_pinUpward()
            dropDownBGView.g_pin(height: 30)
            
            folderNameLabel.g_pin(on: .top, constant: 0)
            folderNameLabel.g_pin(on: .centerX, constant: 0)

            arowImageView.g_pin(size: CGSize(width: 12, height: 12))
            arowImageView.g_pin(on: .centerY, view: folderNameLabel, constant: 0)
            arowImageView.g_pin(on: .right, view: folderNameLabel, constant: 16)
            
            dropDownLineView.g_pinDownward()
            dropDownLineView.g_pin(height: 0.5)
            
            gridView.g_pinDownward()
            gridView.g_pin(on: .top, constant: 30)
        } else {
            gridView.g_pinEdges()
        }

        gridView.collectionView.dataSource = self
        gridView.collectionView.delegate = self
        gridView.collectionView.register(VideoCell.self, forCellWithReuseIdentifier: String(describing: VideoCell.self))
        
        view.addSubview(lockView)
        lockView.g_pinEdges()
        
        self.view.layoutIfNeeded()
        self.view.layoutSubviews()
        setUpGestures()
        dropDownConfig()
    }
    
    // MARK: - Action
    
    @objc func closeButtonTouched(_ button: UIButton) {
        EventHub.shared.close?()
    }
    
    @objc func doneButtonTouched(_ button: UIButton) {
        EventHub.shared.doneWithVideos?()
    }
    
    
    func reloadLibrary() {
        library = VideosLibrary()
        library.reload {
            self.gridView.loadingIndicator.stopAnimating()
            if let album = self.selectedAlbum,
               let newAlbum = self.library.findAlbumFromName(album.name) {
                self.items = newAlbum.items as? [Video] ?? []
            } else {
                self.items = self.library.albums.first?.items as? [Video] ?? []
            }
            self.gridView.collectionView.reloadData()
            self.gridView.emptyView.isHidden = !self.items.isEmpty
        }
    }
    
    func updateLibrary() {
        library.reload {
            self.gridView.loadingIndicator.stopAnimating()
            if let album = self.selectedAlbum,
               let newAlbum = self.library.findAlbumFromName(album.name) {
                self.items = newAlbum.items as? [Video] ?? []
            } else {
                self.items = self.library.albums.first?.items as? [Video] ?? []
            }
            self.gridView.collectionView.reloadData()
            self.gridView.emptyView.isHidden = !self.items.isEmpty
        }
    }
    
    
    // MARK: - Controls
    
    func makeGridView() -> GridView {
        let view = GridView()
        view.delegate = self
        
        return view
    }
    
    func makeInfoLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = Config.Font.Text.regular.withSize(12)
        label.text = String(format: "Gallery.Videos.MaxiumDuration".g_localize(fallback: "FIRST %d SECONDS"), (Int(Config.Limit.videoMaxDuration)))
        
        return label
    }

    func makeLockView() -> UIView {
        let v = UIView(frame: CGRect.zero)
        let color = Config.LoackView.color
        let alpha = Config.LoackView.alpha
        v.backgroundColor = color.withAlphaComponent(alpha)
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }
    
    private func makeArrow() -> UIImageView {
        let arrow = UIImageView()
        arrow.image = GalleryBundle.image("gallery_title_arrow")?.withRenderingMode(.alwaysTemplate)
        arrow.tintColor = UIColor.black
        arrow.alpha = 0.66
        arrow.contentMode = .scaleAspectFit
        arrow.isHidden = true
        return arrow
    }
    
    private func makeDropDownBGView() -> UIView {
        let v = UIView(frame: CGRect.zero)
        v.backgroundColor = UIColor.clear
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = false
        return v
    }
    
    private func makeDropDownBottomView() -> UIView {
        let v = UIView(frame: CGRect.zero)
        v.backgroundColor = UIColor.black
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = false
        v.alpha = 0.25
        return v
    }
    
    private func makeFolderLabel() -> UILabel {
        let l = UILabel(frame: CGRect.zero)
        l.font = Config.DropDown.textFont
        l.textAlignment = .center
        l.textColor = .black
        l.backgroundColor = .clear
        l.alpha = 1.0
        return l
    }
    
    
    func dropDownConfig(){
        dropDown.makeDropDownDelegate = self
        dropDown.makeDropDownDataSourceProtocol = self
        dropDown.setUpDropDown(viewPositionReference: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30), offset: 0)
        dropDown.setRowHeight(height: self.dropDownRowHeight)
        self.view.addSubview(dropDown)
    }
    
    func setUpGestures() {
        self.dropDownBGView.isUserInteractionEnabled = true
        let testLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(testLabelTapped))
        self.dropDownBGView.addGestureRecognizer(testLabelTapGesture)
    }
    
    @objc func testLabelTapped() {
        self.dropDown.showDropDown(height: self.gridView.bounds.height)
    }
    
    // MARK: - Logic
    
    func show(album: Album) {
        gridView.arrowButton.updateText(album.collection.localizedTitle ?? "")
        items = album.items as? [Video] ?? []
        gridView.collectionView.reloadData()
        gridView.emptyView.isHidden = !items.isEmpty
    }
    
    func refreshSelectedAlbum() {
        if let selectedAlbum = selectedAlbum {
            selectedAlbum.reload()
            show(album: selectedAlbum)
        }
    }
}

extension VideosController: MakeDropDownDataSourceProtocol {
    func getDataToDropDown(cell: UITableViewCell, indexPos: Int) {
        if let customCell = cell as? AlbumCell {
            customCell.configure(self.folderModelArr[indexPos])
        }
    }
    
    func numberOfRows() -> Int {
        return self.folderModelArr.count
    }
    
    func selectItemInDropDown(indexPos: Int) {
        self.folderNameLabel.text = self.folderModelArr[indexPos].name
        let album = self.library.albums[indexPos]
        self.selectedAlbum = album
        self.show(album: album)
        self.dropDown.hideDropDown()
    }
}

extension VideosController: MakeDropDownDelegate {
    func didShow() {
        self.arowImageView.transform = .identity
        UIView.animate(withDuration: 0.3, animations: {
            self.arowImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }, completion: { _ in
            
        })
    }
    
    func didHide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.arowImageView.transform = .identity
        }, completion: { _ in
            
        })
    }
}


extension VideosController: CartDelegate {
    public func cartDidUpdate(_ cart: Cart) {
        self.gridView.collectionView.reloadItems(at: self.gridView.collectionView.indexPathsForVisibleItems)
    }
    
    public func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) { }
    public func cart(_ cart: Cart, didRemove image: Image) {}
    
    public func cart(_ cart: Cart, didAdd video: Video, newlyTaken: Bool) {
        self.delegate?.didAddVideo(video: video)
    }
    
    public func cart(_ cart: Cart, didRemove video: Video) {
        self.unselectVideo(video)
        self.delegate?.didRemoveVideo(video: video)
    }

    public func cartDidReload(_ cart: Cart) {
        self.gridView.collectionView.reloadItems(at: self.gridView.collectionView.indexPathsForVisibleItems)

    }
    
    public func cart(_ cart: Cart, canAddNewItem: Bool) {
        self.lockView.isHidden = canAddNewItem
    }
}

extension VideosController: GridViewDelegate {
    func reloadCollectionView() {
        self.updateLibrary()
    }
}

extension VideosController: PageAware {
    func pageDidShow() {
        once.run {
            library.reload {
                self.gridView.loadingIndicator.stopAnimating()

                if let album = self.library.albums.first {
                    self.folderNameLabel.text = album.name
                    self.arowImageView.isHidden = false
                    self.selectedAlbum = album
                    self.show(album: album)
                }
            }
        }
    }
}

extension VideosController: VideoBoxDelegate {
    
    func videoBoxDidTap(_ videoBox: VideoBox) {
        //        cart.video?.fetchPlayerItem { item in
        //            guard let item = item else { return }
        //
        //            DispatchQueue.main.async {
        //                let controller = AVPlayerViewController()
        //                let player = AVPlayer(playerItem: item)
        //                controller.player = player
        //
        //                self.present(controller, animated: true) {
        //                    player.play()
        //                }
        //            }
        //        }
    }
}

extension VideosController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDataSource
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VideoCell.self), for: indexPath) as! VideoCell
        let item = items[(indexPath as NSIndexPath).item]
        
        cell.canSelect = item.duration >= self.cart.addedVideoMinDuration
        cell.configure(item)
        
        
//        cell.frameView.label.isHidden = true
        configureFrameView(cell, indexPath: indexPath)
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = (collectionView.bounds.size.width - Config.Grid.Dimension.inset.left - Config.Grid.Dimension.inset.right - (Config.Grid.Dimension.columnCount - 1) * Config.Grid.Dimension.cellSpacing )
            / Config.Grid.Dimension.columnCount
        return CGSize(width: size, height: size)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Config.Grid.Dimension.inset
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Config.Grid.Dimension.lineSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if Config.CellSelectedStyle.isCounter {
            let item = items[(indexPath as NSIndexPath).item]
            if self.cart.canAddImageFromCart {
                cart.add(item)
            }
        } else if Config.CellSelectedStyle.isEnabled {
            let item = items[(indexPath as NSIndexPath).item]
            if cart.videos.contains(item) {
                cart.remove(item)
            } else {
                if self.cart.canAddVideoFromCart {
                    cart.add(item)
                } else if self.cart.canAddSingleVideoState, let cartItem = cart.videos.first {
                    cart.remove(cartItem)
                    cart.add(item)
                }
            }
        } else {
            let item = Video(asset: items[(indexPath as NSIndexPath).item].asset)
            if self.cart.canAddVideoFromCart {
                cart.add(item)
            }
        }
        
        configureFrameViews()
    }
    
    func configureFrameViews() {
        for case let cell as VideoCell in gridView.collectionView.visibleCells {
            if let indexPath = gridView.collectionView.indexPath(for: cell) {
                configureFrameView(cell, indexPath: indexPath)
            }
        }
    }
    
    func configureFrameView(_ cell: VideoCell, indexPath: IndexPath) {
        let item = items[(indexPath as NSIndexPath).item]

        if Config.CellSelectedStyle.isCounter {
            var count = 0
            for video in cart.videos {
                if video.localIdentifier == item.localIdentifier {
                    count += 1
                }
            }
            if count != 0 {
                cell.frameView.g_quickFade()
                cell.frameView.label.text = "\(count)"
                cell.choosen = true
            } else {
                cell.choosen = false
                cell.frameView.alpha = 0
            }
        } else if Config.CellSelectedStyle.isEnabled {
             cell.choosen = cart.videos.index(of: item) != nil
        }
    }
}

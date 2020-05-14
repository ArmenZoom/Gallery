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
//    lazy var videoBox: VideoBox = self.makeVideoBox()
    lazy var infoLabel: UILabel = self.makeInfoLabel()
    
    
    var items: [Video] = []
    var library = VideosLibrary()
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
        gridView.g_pinEdges()
        gridView.collectionView.dataSource = self
        gridView.collectionView.delegate = self
        gridView.collectionView.register(VideoCell.self, forCellWithReuseIdentifier: String(describing: VideoCell.self))
    }
    
    // MARK: - Action
    
    @objc func closeButtonTouched(_ button: UIButton) {
        EventHub.shared.close?()
    }
    
    @objc func doneButtonTouched(_ button: UIButton) {
        EventHub.shared.doneWithVideos?()
    }
    
    // MARK: - View
    
    func refreshView() {
//        if let selectedItem = cart.video {
//            videoBox.imageView.g_loadImage(selectedItem.asset)
//        } else {
//            videoBox.imageView.image = nil
//        }
//
//        let duration = cart.video?.duration ?? 0.00
//        self.infoLabel.isHidden = duration <= Config.VideoEditor.maximumDuration
    }
    
    func reloadLibrary() {
        library = VideosLibrary()
        library.reload {
            self.gridView.loadingIndicator.stopAnimating()
            self.items = self.library.items
            self.gridView.collectionView.reloadData()
            self.gridView.emptyView.isHidden = !self.items.isEmpty
        }
    }
    
    func updateLibrary() {
        library.reload {
            self.gridView.loadingIndicator.stopAnimating()
            self.items = self.library.items
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
    
//    func makeVideoBox() -> VideoBox {
//        let videoBox = VideoBox()
//        videoBox.delegate = self
//        
//        return videoBox
//    }
    
    func makeInfoLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = Config.Font.Text.regular.withSize(12)
        label.text = String(format: "Gallery.Videos.MaxiumDuration".g_localize(fallback: "FIRST %d SECONDS"), (Int(Config.Limit.videoMaxDuration)))
        
        return label
    }
}

extension VideosController: CartDelegate {
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
                self.items = self.library.items
                self.gridView.collectionView.reloadData()
                self.gridView.emptyView.isHidden = !self.items.isEmpty
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

        if Config.CellSelectedStyle.isEnabled {
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
        if Config.CellSelectedStyle.isEnabled {
             let item = items[(indexPath as NSIndexPath).item]
             cell.choosen = cart.videos.index(of: item) != nil
        }
    }
}

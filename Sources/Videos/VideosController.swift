import UIKit
import Photos
import AVKit

public protocol VideosControllerDelegate: class {
    func didSelectVideo(video: Video)
    func didAddVideo(video: Video)
    func didRemoveVideo(video: Video)
}

public class VideosController: UIViewController {
    
    weak var delegate: VideosControllerDelegate? = nil
    lazy var gridView: GridView = self.makeGridView()
    lazy var videoBox: VideoBox = self.makeVideoBox()
    lazy var infoLabel: UILabel = self.makeInfoLabel()
    
    
    var items: [Video] = []
    var library = VideosLibrary()
    let once = Once()
    let cart: Cart
    
    private var selectedVideo = [Video]()
    
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
        var indexPaths = [IndexPath]()
        self.selectedVideo.removeAll { (item) -> Bool in
            let removed = item == video
            if removed {
                if let index = self.items.index(of: item) {
                    indexPaths.append(IndexPath(row: index, section: 0))
                }
            }
            return removed
        }
        
        self.gridView.collectionView.reloadItems(at: indexPaths)
    }
    
    public func unselectAllVideo() {
        self.selectedVideo.removeAll()
        self.gridView.collectionView.reloadData()
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
    
    func makeVideoBox() -> VideoBox {
        let videoBox = VideoBox()
        videoBox.delegate = self
        
        return videoBox
    }
    
    func makeInfoLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = Config.Font.Text.regular.withSize(12)
        label.text = String(format: "Gallery.Videos.MaxiumDuration".g_localize(fallback: "FIRST %d SECONDS"), (Int(Config.VideoEditor.maximumDuration)))
        
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
        self.delegate?.didRemoveVideo(video: video)
    }

    public func cartDidReload(_ cart: Cart) {
        self.gridView.collectionView.reloadData()
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
        
        cell.configure(item)
        cell.frameView.label.isHidden = true
        if Config.VideoEditor.isBorder {
            cell.choosen = selectedVideo.contains(item)
        }
        
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
        let item = items[(indexPath as NSIndexPath).item]
        
        
        if Config.CellSelectedStyle.isEnabled {
            if cart.videos.contains(item) {
                cart.remove(item)
            } else {
                if (Config.SelectedView.videoLimit == 0 || Config.SelectedView.videoLimit > cart.videos.count) && Config.SelectedView.allLimit > cart.allItemsCount {
                    cart.add(item)
                } else if !Config.SelectedView.isEnabled, Config.SelectedView.videoLimit == 1, let cartItem = cart.videos.first {
                    cart.remove(cartItem)
                    cart.add(item)
                }
            }
        } else {
            if (Config.SelectedView.videoLimit == 0 || Config.SelectedView.videoLimit > cart.videos.count) && Config.SelectedView.allLimit > cart.allItemsCount {
                cart.add(item)
            }
        }

//        if cart.videos.contains(item) && Config.CellSelectedStyle.isEnabled {
//            cart.remove(item)
//        } else  {
//            if Config.Camera.videoLimit == 0 || Config.Camera.videoLimit > cart.videos.count {
//                cart.add(item)
//            } else {
//                if Config.Camera.videoLimit == 1, let cartItem = cart.videos.first {
//                    cart.remove(cartItem)
//                    cart.add(item)
//                }
//            }
//        }
        
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
        
        if Config.CellSelectedStyle.isEnabled {
            if let index = cart.videos.index(of: item) {
                cell.choosen = true
                cell.frameView.g_quickFade()
            } else {
                cell.choosen = false
                cell.frameView.alpha = 0
            }
        }
    }
}

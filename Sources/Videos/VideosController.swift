import UIKit
import Photos
import AVKit

public protocol VideosControllerDelegate: class {
     func didSelectVideo(video: Video)
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
        if let selectedItem = cart.video {
          videoBox.imageView.g_loadImage(selectedItem.asset)
        } else {
          videoBox.imageView.image = nil
        }
     
        let duration = cart.video?.duration ?? 0.00
        self.infoLabel.isHidden = duration <= Config.VideoEditor.maximumDuration
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
        cart.video?.fetchPlayerItem { item in
            guard let item = item else { return }

            DispatchQueue.main.async {
                let controller = AVPlayerViewController()
                let player = AVPlayer(playerItem: item)
                controller.player = player

                self.present(controller, animated: true) {
                    player.play()
                }
            }
        }
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

        if let cell = collectionView.cellForItem(at: indexPath) as? VideoCell, Config.VideoEditor.isBorder {
            let isSelected = self.selectedVideo.contains(item)
            if isSelected {
                self.selectedVideo.removeAll(where: { $0 == item })
            } else {
                self.selectedVideo.append(item)
            }
            cell.choosen = !isSelected
        }
        delegate?.didSelectVideo(video: item)
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

        if let selectedItem = cart.video, selectedItem == item {
            cell.frameView.g_quickFade()
        } else {
            cell.frameView.alpha = 0
        }
    }
}

import UIKit
import Photos

public protocol ImageControllerDelegate: class {
    func didAddImage(image: Image)
    func didRemoveImage(image: Image)
}

class ImagesController: UIViewController {
    weak var delegate: ImageControllerDelegate?
    
    lazy var dropdownController: DropdownController = self.makeDropdownController()
    lazy var gridView: GridView = self.makeGridView()
    lazy var stackView: StackView = self.makeStackView()
    
    var items: [Image] = []
    let library = ImagesLibrary()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - Setup
    
    func setup() {
        view.backgroundColor = UIColor.white
        view.addSubview(gridView)
        gridView.g_pinEdges()
        gridView.collectionView.dataSource = self
        gridView.collectionView.delegate = self
        gridView.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
    }
    
    // MARK: - Action
    
    @objc func closeButtonTouched(_ button: UIButton) {
        EventHub.shared.close?()
    }
    
    @objc func doneButtonTouched(_ button: UIButton) {
        EventHub.shared.doneWithImages?()
    }
    
    @objc func arrowButtonTouched(_ button: ArrowButton) {
        dropdownController.toggle()
        button.toggle(dropdownController.expanding)
    }
    
    @objc func stackViewTouched(_ stackView: StackView) {
        EventHub.shared.stackViewTouched?()
    }
    
    // MARK: - Logic
    
    func show(album: Album) {
        gridView.arrowButton.updateText(album.collection.localizedTitle ?? "")
        items = album.items
        gridView.collectionView.reloadData()
        gridView.collectionView.g_scrollToTop()
        gridView.emptyView.isHidden = !items.isEmpty
    }
    
    func refreshSelectedAlbum() {
        if let selectedAlbum = selectedAlbum {
            selectedAlbum.reload()
            show(album: selectedAlbum)
        }
    }
    
    // MARK: - View
    
    func refreshView() {
        let hasImages = !cart.images.isEmpty
        gridView.bottomView.g_fade(visible: hasImages)
        gridView.collectionView.g_updateBottomInset(hasImages ? gridView.bottomView.frame.size.height : 0)
    }
    
    // MARK: - Controls
    
    func makeDropdownController() -> DropdownController {
        let controller = DropdownController()
        controller.delegate = self
        
        return controller
    }
    
    func makeGridView() -> GridView {
        let view = GridView()
        view.bottomView.alpha = 0
        
        return view
    }
    
    func makeStackView() -> StackView {
        let view = StackView()
        
        return view
    }
}

extension ImagesController: PageAware {
    
    func pageDidShow() {
        once.run {
            library.reload {
                self.gridView.loadingIndicator.stopAnimating()
                self.dropdownController.albums = self.library.albums
                self.dropdownController.tableView.reloadData()
                
                if let album = self.library.albums.first {
                    self.selectedAlbum = album
                    self.show(album: album)
                }
            }
        }
    }
}

extension ImagesController: CartDelegate {
    func cart(_ cart: Cart, didAdd video: Video, newlyTaken: Bool) { }
    func cart(_ cart: Cart, didRemove video: Video) { }
    
    func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) {
        self.delegate?.didAddImage(image: image)
        //stackView.reload(cart.images, added: true)
        refreshView()

        if newlyTaken {
            refreshSelectedAlbum()
        }
    }

    func cart(_ cart: Cart, didRemove image: Image) {
        self.delegate?.didRemoveImage(image: image)
        //stackView.reload(cart.images)
        refreshView()
    }

    func cartDidReload(_ cart: Cart) {
        //stackView.reload(cart.images)
        refreshView()
        refreshSelectedAlbum()
    }
}

extension ImagesController: DropdownControllerDelegate {
    
    func dropdownController(_ controller: DropdownController, didSelect album: Album) {
        selectedAlbum = album
        show(album: album)
        
        dropdownController.toggle()
        gridView.arrowButton.toggle(controller.expanding)
    }
}

extension ImagesController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath)
            as! ImageCell
        let item = items[(indexPath as NSIndexPath).item]
        
        cell.configure(item)
        configureFrameView(cell, indexPath: indexPath)
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let size = (collectionView.bounds.size.width - Config.Grid.Dimension.inset.left - Config.Grid.Dimension.inset.right - (Config.Grid.Dimension.columnCount - 1) * Config.Grid.Dimension.cellSpacing )
            / Config.Grid.Dimension.columnCount
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Config.Grid.Dimension.inset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Config.Grid.Dimension.lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[(indexPath as NSIndexPath).item]
        
        
        if Config.CellSelectedStyle.isEnabled {
            if cart.images.contains(item) {
                cart.remove(item)
            } else {
                if (Config.SelectedView.imageLimit == 0 || Config.SelectedView.imageLimit > cart.images.count) && Config.SelectedView.allLimit > cart.allItemsCount {
                    cart.add(item)
                } else if !Config.SelectedView.isEnabled, Config.SelectedView.imageLimit == 1, let cartItem = cart.images.first {
                    cart.remove(cartItem)
                    cart.add(item)
                }
            }
        } else {
            if (Config.SelectedView.imageLimit == 0 || Config.SelectedView.imageLimit > cart.images.count) && Config.SelectedView.allLimit > cart.allItemsCount {
                cart.add(item)
            }
        }
        
        
        
//        if cart.images.contains(item) && Config.CellSelectedStyle.isEnabled {
//            cart.remove(item)
//        } else {
//            if Config.Camera.imageLimit == 0 || Config.Camera.imageLimit > cart.images.count {
//                cart.add(item)
//            } else {
//                if Config.Camera.imageLimit == 1, let cartItem = cart.images.first {
//                    cart.remove(cartItem)
//                    cart.add(item)
//                }
//            }
//        }
        
        configureFrameViews()
    }
    
    func configureFrameViews() {
        for case let cell as ImageCell in gridView.collectionView.visibleCells {
            if let indexPath = gridView.collectionView.indexPath(for: cell) {
                configureFrameView(cell, indexPath: indexPath)
            }
        }
    }
    
    func configureFrameView(_ cell: ImageCell, indexPath: IndexPath) {
        let item = items[(indexPath as NSIndexPath).item]
        
        if Config.CellSelectedStyle.isEnabled {
            if let index = cart.images.index(of: item) {
                cell.frameView.g_quickFade()
                cell.frameView.label.text = "\(index + 1)"
            } else {
                cell.frameView.alpha = 0
            }
        }
      
    }
}

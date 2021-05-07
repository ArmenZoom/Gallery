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
    lazy var lockView: UIView = self.makeLockView()
    lazy var arowImageView: UIImageView = self.makeArrow()
    
    lazy var dropDownBGView: UIView = self.makeDropDownBGView()
    lazy var dropDownLineView: UIView = self.makeDropDownBottomView()

    lazy var folderNameLabel: UILabel = self.makeFolderLabel()
    let dropDown = MakeDropDown()
    var albums: [Album] { return self.library.albums }
    var dropDownRowHeight: CGFloat = 80
    
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
        setUpGestures()
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
            dropDownBGView.g_pin(height: 50)
            
            folderNameLabel.g_pinCenter()
            
            arowImageView.g_pin(size: CGSize(width: 12, height: 12))
            arowImageView.g_pin(on: .centerY, constant: 0)
            arowImageView.g_pin(on: .right, view: folderNameLabel, constant: 16)
            
            dropDownLineView.g_pinDownward()
            dropDownLineView.g_pin(height: 0.5)
            
            gridView.g_pinDownward()
            gridView.g_pin(on: .top, constant: 50)
        } else {
            gridView.g_pinEdges()
        }
        gridView.collectionView.dataSource = self
        gridView.collectionView.delegate = self
        gridView.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
        
        view.addSubview(lockView)
        lockView.g_pinEdges()
        
        self.view.layoutIfNeeded()
        self.view.layoutSubviews()
        dropDownConfig()
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
        items = album.items as? [Image] ?? []
        gridView.collectionView.reloadData()
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
    
    public func unselectItem(_ image: Image) {
        if let index = self.items.index(of: image) {
            self.gridView.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        }
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
   
    private func makeDropDownBottomView() -> UIView {
        let v = UIView(frame: CGRect.zero)
        v.backgroundColor = UIColor.black
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = false
        v.alpha = 0.25
        return v
    }
    
    func makeDropDownBGView() -> UIView {
        let v = UIView(frame: CGRect.zero)
        v.backgroundColor = UIColor.clear
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = false
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
    
    private func makeFolderLabel() -> UILabel {
        let l = UILabel(frame: CGRect.zero)
        l.font = Config.Font.Text.bold.withSize(16)
        l.textAlignment = .center
        l.textColor = .black
        l.backgroundColor = .clear
        l.alpha = 1.0
        return l
    }
    
    public func changeFolder() {
        dropdownController.toggle()
    }
    
    
    func dropDownConfig(){
        dropDown.makeDropDownDataSourceProtocol = self
        dropDown.makeDropDownDelegate = self
        dropDown.setUpDropDown(viewPositionReference: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width ,height: 50), offset: 0)
        dropDown.setRowHeight(height: self.dropDownRowHeight)
        self.view.addSubview(dropDown)
    }
    
    func setUpGestures(){
        self.dropDownBGView.isUserInteractionEnabled = true
        let testLabelTapGesture = UITapGestureRecognizer(target: self, action: #selector(testLabelTapped))
        self.dropDownBGView.addGestureRecognizer(testLabelTapGesture)
    }
    
    @objc func testLabelTapped() {
        self.dropDown.showDropDown(height: self.gridView.bounds.height)
    }
}

extension ImagesController: MakeDropDownDataSourceProtocol {
    func getDataToDropDown(cell: UITableViewCell, indexPos: Int) {
            if let customCell = cell as? AlbumCell {
                customCell.configure(self.albums[indexPos])
            }
    }
    
    func numberOfRows() -> Int {
        return self.albums.count
    }
    
    func selectItemInDropDown(indexPos: Int) {
        self.folderNameLabel.text = self.albums[indexPos].name
        let album = self.library.albums[indexPos]
        self.selectedAlbum = album
        self.show(album: album)
        self.dropDown.hideDropDown()
    }
    
}

extension ImagesController: MakeDropDownDelegate {
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


extension ImagesController: PageAware {
    
    func pageDidShow() {
        once.run {
            library.reload {
                self.gridView.loadingIndicator.stopAnimating()
                self.dropdownController.albums = self.library.albums
                self.dropdownController.tableView.reloadData()
                
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

extension ImagesController: CartDelegate {
    func cart(_ cart: Cart, didAdd video: Video, newlyTaken: Bool) { }
    func cart(_ cart: Cart, didRemove video: Video) { }
    
    func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) {
        self.delegate?.didAddImage(image: image)
        refreshView()

        if newlyTaken {
            refreshSelectedAlbum()
        }
    }

    func cart(_ cart: Cart, didRemove image: Image) {
        self.unselectItem(image)
        self.delegate?.didRemoveImage(image: image)
        refreshView()
    }

    func cartDidReload(_ cart: Cart) {
        refreshView()
        refreshSelectedAlbum()
    }
    
    func cart(_ cart: Cart, canAddNewItem: Bool) {
        self.lockView.isHidden = canAddNewItem
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
        
        if Config.CellSelectedStyle.isCounter {
            let item = items[(indexPath as NSIndexPath).item]
            if self.cart.canAddImageFromCart {
                cart.add(item)
            }
        } else if Config.CellSelectedStyle.isEnabled {
            let item = items[(indexPath as NSIndexPath).item]
            if cart.images.contains(item) {
                cart.remove(item)
            } else {
                if self.cart.canAddImageFromCart {
                    cart.add(item)
                } else if self.cart.canAddSingleImageState, let cartItem = cart.images.first {
                    cart.remove(cartItem)
                    cart.add(item)
                }
            }
        } else {
            let item = Image(asset: items[(indexPath as NSIndexPath).item].asset)
            if self.cart.canAddImageFromCart {
                cart.add(item)
            }
        }
        
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
        
        
        if Config.CellSelectedStyle.isCounter {
            var count = 0
            for image in cart.images {
                if image.localIdentifier == item.localIdentifier {
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
            if let index = cart.images.index(of: item) {
                cell.frameView.g_quickFade()
                cell.frameView.label.text = "\(index + 1)"
                cell.choosen = true
            } else {
                cell.choosen = false
                cell.frameView.alpha = 0
            }
        }
      
    }
}

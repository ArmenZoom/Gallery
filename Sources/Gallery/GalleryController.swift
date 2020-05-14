import UIKit
import AVFoundation

//public protocol GalleryControllerDelegate: class {
//    func galleryController(_ controller: GalleryController, didSelectImages images: [Image])
//    func galleryController(_ controller: GalleryController, didSelectVideo video: Video)
//    func galleryController(_ controller: GalleryController, requestLightbox images: [Image])
//    func galleryControllerDidCancel(_ controller: GalleryController)
//}

public protocol GalleryControllerDelegate: class {
    func didEdit(_ controller: GalleryController, index: Int)
    func didRemove(_ controller: GalleryController, index: Int)
}

public class GalleryController: UIViewController {
    
    public weak var delegate: GalleryControllerDelegate?
    weak var videoDelegate: VideosControllerDelegate?
    weak var imageDelegate: ImageControllerDelegate?
    weak var pagesDelegate: PagesControllerDelegate?
    
    lazy var stackContentView: UIView = UIView(frame: CGRect.zero)
    lazy var shadowView: UIView = self.makeShadowView()
    lazy var pagesItemsContentView: UIView = UIView(frame: CGRect.zero)
    
    lazy var chosenView: ChosenView = self.makeChosenView()
    
    var cart = Cart()
    var imagesController: ImagesController?
    var videoController: VideosController?
    var pagesController: PagesController?
    
    
    // MARK: - Init
    
    public init(videoDelegate: VideosControllerDelegate? = nil,
                imageDelegate: ImageControllerDelegate?  = nil,
                pagesDelegate: PagesControllerDelegate?  = nil) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.videoDelegate = videoDelegate
        self.imageDelegate = imageDelegate
        self.pagesDelegate = pagesDelegate
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(videoDelegate: nil, imageDelegate: nil, pagesDelegate: nil)
    }
    
    // MARK: - Life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.loadControllers()
    }
    
    func loadControllers() {
        if let pagesController = makePagesController() {
            // Is multi select
            if Config.SelectedView.isEnabled {
                self.view.addSubview(stackContentView)
                self.view.addSubview(pagesItemsContentView)
                self.stackContentView.addSubview(chosenView)
                self.stackContentView.addSubview(shadowView)
                
                shadowView.g_pin(height: 2)
                shadowView.g_pin(on: .left, view: stackContentView)
                shadowView.g_pin(on: .right, view: stackContentView)
                shadowView.g_pin(on: .top, view: stackContentView, constant: 6)
                
                stackContentView.g_pinDownward()
                stackContentView.g_pin(height: 100)
                
                pagesItemsContentView.g_pinUpward()
                pagesItemsContentView.g_pin(on: .bottom, view: stackContentView, on: .top)
                
                chosenView.g_pinEdges()
                
                g_addChildController(pagesController, addFromView: self.pagesItemsContentView)
            } else {
                g_addChildController(pagesController, addFromView: self.view)
            }
            
        } else {
            let permissionController = makePermissionController()
            g_addChildController(permissionController, addFromView: self.view)
        }
    }
    
    override public func loadView() {
        super.loadView()
        chosenView.layer.shadowColor = UIColor.black.cgColor
        chosenView.layer.shadowOpacity = 0.5
        chosenView.layer.shadowOffset = CGSize(width: 0, height: -2)
        chosenView.layer.shadowRadius = 5
    }
    
    
    public func reloadData() {
        self.videoController?.reloadLibrary()
        self.imagesController?.refreshSelectedAlbum()
    }
    
    public func resetAllItems() {
        self.cart.reload(images: [])
        self.cart.reload(videos: [])
    }
    
    public func removeItem(video: Video) {
        self.cart.remove(video)
    }
    
    public func changePagesIndex(_ index: Int) {
        if let pagesController = self.pagesController {
            pagesController.didChangeSlectedIndex(index)
        }
    }
    
    public override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Child view controller
    
    func makeImagesController() -> ImagesController {
        let controller = ImagesController(cart: cart)
        controller.title = "Gallery.Images.Title".g_localize(fallback: "PHOTOS")
        controller.delegate = self
        imagesController = controller
        return controller
    }
    
    func makeCameraController() -> CameraController {
        let controller = CameraController(cart: cart)
        controller.title = "Gallery.Camera.Title".g_localize(fallback: "CAMERA")
        
        return controller
    }
    
    func makeVideosController() -> VideosController {
        let controller = VideosController(cart: cart)
        controller.title = "Gallery.Videos.Title".g_localize(fallback: "VIDEOS")
        controller.delegate = self
        videoController = controller
        
        return controller
    }
    
    func makePagesController() -> PagesController? {
        guard Permission.Photos.status == .authorized else {
            return nil
        }
        
        let useCamera = Permission.Camera.needsPermission && Permission.Camera.status == .authorized
        
        let tabsToShow = Config.tabsToShow.compactMap { $0 != .cameraTab ? $0 : (useCamera ? $0 : nil) }
        
        let controllers: [UIViewController] = tabsToShow.compactMap { tab in
            if tab == .imageTab {
                return makeImagesController()
            } else if tab == .cameraTab {
                return makeCameraController()
            } else if tab == .videoTab || tab == .videoImageTab {
                return makeVideosController()
            } else {
                return nil
            }
        }
        
        guard !controllers.isEmpty else {
            return nil
        }
        
        pagesController = PagesController(controllers: controllers)
        pagesController?.delegate = self
        pagesController?.selectedIndex = tabsToShow.index(of: Config.initialTab ?? .cameraTab) ?? 0
        
        return pagesController
    }
    
    func makePermissionController() -> PermissionController {
        let controller = PermissionController()
        controller.delegate = self
        
        return controller
    }
    
    func makeChosenView() -> ChosenView {
        let view = ChosenView(cart: self.cart)
        view.delegate = self
        return view
    }
    
    func makeShadowView() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 2
        return view
    }
    
    public func setupSelectedItems(items: [ChosenItem]) {
        self.chosenView.items = items
    }
    
    public func updateSelectedItem(item: ChosenItem) {
        self.chosenView.updateItem(item: item)
    }
    
    public func addNewItem(item: ChosenItem) {
        self.chosenView.addItem(item: item)
    }
    
    public func startProcessing() -> [ChosenItem] {
        return  self.chosenView.items
    }
    
}

extension GalleryController: PermissionControllerDelegate {
    func permissionControllerDidFinish(_ controller: PermissionController) {
        self.loadControllers()
    }
}

extension GalleryController: PagesControllerDelegate {
    public func didChangePageIndex(index: Int) {
        self.pagesDelegate?.didChangePageIndex(index: index)
    }
}

extension GalleryController: ImageControllerDelegate {
    public func didAddImage(image: Image) {
        self.chosenView.addImage(image: image)
        self.imageDelegate?.didAddImage(image: image)
    }
    
    public func didRemoveImage(image: Image) {
        self.imageDelegate?.didRemoveImage(image: image)
        self.chosenView.removeImage(image: image)
    }
}

extension GalleryController: VideosControllerDelegate {
    public func didAddVideo(video: Video) {
        self.chosenView.addVideo(video: video)
        self.videoDelegate?.didAddVideo(video: video)
    }
    
    public func didRemoveVideo(video: Video) {
        self.videoDelegate?.didRemoveVideo(video: video)
        self.chosenView.removeVideo(video: video)
    }
    
}



extension GalleryController: ChosenViewDelegate {
    func didEdit(_ view: ChosenView, index: Int) {
        self.delegate?.didEdit(self, index: index)
    }
    
    func didRemove(_ view: ChosenView, index: Int) {
        self.delegate?.didRemove(self, index: index)
    }
}

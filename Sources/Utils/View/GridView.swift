import UIKit
import Photos

protocol GridViewDelegate: class {
    func reloadCollectionView()
}

public class GridView: UIView {

    weak var delegate: GridViewDelegate?

    // MARK: - Initialization

    lazy var topView: UIView = self.makeTopView()
    lazy var bottomView: UIView = self.makeBottomView()
    lazy var bottomBlurView: UIVisualEffectView = self.makeBottomBlurView()
    lazy var arrowButton: ArrowButton = self.makeArrowButton()
    lazy var collectionView: UICollectionView = self.makeCollectionView()
    lazy var closeButton: UIButton = self.makeCloseButton()
    lazy var doneButton: UIButton = self.makeDoneButton()
    lazy var emptyView: UIView = self.makeEmptyView()
    lazy var loadingIndicator: UIActivityIndicatorView = self.makeLoadingIndicator()
    private let refreshControl = UIRefreshControl()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
        loadingIndicator.startAnimating()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup() {
        [collectionView, bottomView, emptyView, loadingIndicator].forEach {
            addSubview($0)
        }

        //    [closeButton, arrowButton].forEach {
        //      topView.addSubview($0)
        //    }

        //    [bottomBlurView, doneButton].forEach {
        //        bottomView.addSubview($0)
        //    }

        Constraint.on(
        //      topView.leftAnchor.constraint(equalTo: topView.superview!.leftAnchor),
        //      topView.rightAnchor.constraint(equalTo: topView.superview!.rightAnchor),
        //      topView.heightAnchor.constraint(equalToConstant: 0),

            loadingIndicator.centerXAnchor.constraint(equalTo: loadingIndicator.superview!.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loadingIndicator.superview!.centerYAnchor)
        )

        emptyView.g_pinEdges(view: collectionView)

        collectionView.g_pinEdges(view: self)

        refreshControl.tintColor = Config.RefreshControl.color
        refreshControl.addTarget(self, action: #selector(refreshWeatherData(_:)), for: .valueChanged)

        if Config.RefreshControl.isActive {
            if #available(iOS 10.0, *) {
                collectionView.refreshControl = refreshControl
            } else {
                collectionView.addSubview(refreshControl)
            }
        }
        
    }

       
    @objc private func refreshWeatherData(_ sender: Any) {
        delegate?.reloadCollectionView()
    }
        
    public func refreshFinished() {
        self.refreshControl.endRefreshing()
    }

    // MARK: - Controls

    private func makeTopView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white

        return view
    }

    private func makeBottomView() -> UIView {
        let view = UIView()

        return view
    }

    private func makeBottomBlurView() -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

        return view
    }

    private func makeArrowButton() -> ArrowButton {
        let button = ArrowButton()
        button.layoutSubviews()

        return button
    }

    private func makeGridView() -> GridView {
        let view = GridView()

        return view
    }

    private func makeCloseButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(GalleryBundle.image("gallery_close")?.withRenderingMode(.alwaysTemplate), for: UIControl.State())
        button.tintColor = Config.Grid.CloseButton.tintColor

        return button
    }

    private func makeDoneButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitleColor(UIColor.white, for: UIControl.State())
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.titleLabel?.font = Config.Font.Text.regular.withSize(16)
        button.setTitle("Gallery.Done".g_localize(fallback: "Done"), for: UIControl.State())

        return button
    }

    private func makeCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.white

        return view
    }

    private func makeEmptyView() -> EmptyView {
        let view = EmptyView()
        view.isHidden = true

        return view
    }

    private func makeLoadingIndicator() -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView(style: .whiteLarge)
        view.color = .gray
        view.hidesWhenStopped = true

        return view
    }
    
}

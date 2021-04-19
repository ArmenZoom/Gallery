import UIKit
import Photos

class VideoCell: ImageCell {

    lazy var cameraImageView: UIImageView = self.makeCameraImageView()
    lazy var durationLabel: UILabel = self.makeDurationLabel()
    lazy var bottomOverlay: UIView = self.makeBottomOverlay()
    lazy var gradientLayer: CAGradientLayer = self.makeGradientLayer()
    
    lazy var forgraundView: UIView = {
        let v = UIView(frame: .zero)
        v.isUserInteractionEnabled = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.90)
        return v
    }()
    
    override func didUpdateSelectedState(selected: Bool) {
        if Config.ImageCell.borderVisibility {
            if self.choosen {
                self.addSubview(self.selectedOverlayView)
                self.updateView()
            } else {
                self.selectedOverlayView.removeFromSuperview()
            }
        }
    }
    
    var canSelect: Bool = true {
        didSet {
            if self.canSelect != oldValue {
                self.didUpdateSelectedState(selected: self.canSelect)
            }
        }
    }
  
    // MARK: - Config

    func configure(_ video: Video) {
        super.configure(video.asset)
        self.forgraundView.isHidden = self.canSelect
        self.bottomOverlay.isHidden = !(video.isVideo && self.canSelect)
        
        let text = video.duration == 0.0 ? nil : "\(Utils.format(video.duration))"
        self.durationLabel.text = text
    }

    // MARK: - Setup

    override func setup() {
        super.setup()
        [bottomOverlay, durationLabel].forEach {
            self.contentView.insertSubview($0, belowSubview: self.highlightOverlay)
        }
        
        bottomOverlay.layer.insertSublayer(self.gradientLayer, at: 0)
        self.contentView.addSubview(forgraundView)
        
        forgraundView.g_pinEdges()
        
        bottomOverlay.g_pinDownward()
        bottomOverlay.g_pin(height: 16)
        
        durationLabel.g_pinCenter(view: bottomOverlay)
      
        self.layoutIfNeeded()
        self.gradientLayer.frame = bottomOverlay.bounds
        
    }

    // MARK: - Controls

    func makeCameraImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.image = GalleryBundle.image("gallery_video_cell_camera")
        imageView.contentMode = .scaleAspectFit

        return imageView
    }

    func makeDurationLabel() -> UILabel {
        let label = UILabel()
        label.font = Config.Font.Text.bold.withSize(9)
        label.textColor = UIColor.white
        label.textAlignment = .right

        return label
    }

    func makeBottomOverlay() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func makeGradientLayer() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        let colors = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.5)]
        gradient.colors = colors.map { $0.cgColor }
        return gradient
    }
    
    override func updateView() {
        super.updateView()
        self.gradientLayer.frame = bottomOverlay.bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateView()
    }
    
}

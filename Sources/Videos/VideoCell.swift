import UIKit
import Photos

class VideoCell: ImageCell {

  lazy var cameraImageView: UIImageView = self.makeCameraImageView()
  lazy var durationLabel: UILabel = self.makeDurationLabel()
  lazy var bottomOverlay: UIView = self.makeBottomOverlay()
    lazy var selectedOverlayView: UIView = {
        let label = UIView()
        label.backgroundColor = UIColor.clear
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.layer.borderWidth = 2
        label.isUserInteractionEnabled = false
        label.layer.borderColor = UIColor(red: 198/255, green: 240/255, blue: 154/255, alpha: 1.0).cgColor
        return label
    }()
    
    var choosen: Bool = false {
        didSet {
            if self.choosen {
                self.addSubview(self.selectedOverlayView)
                self.updateView()
            } else {
                self.selectedOverlayView.removeFromSuperview()
            }
        }
    }
  // MARK: - Config

  func configure(_ video: Video) {
    super.configure(video.asset)

    video.fetchDuration { duration in
      DispatchQueue.main.async {
        self.durationLabel.text = "\(Utils.format(duration))"
      }
    }
  }

  // MARK: - Setup

  override func setup() {
    super.setup()

    [bottomOverlay, durationLabel].forEach {
      self.insertSubview($0, belowSubview: self.highlightOverlay)
    }

    bottomOverlay.g_pinDownward()
    bottomOverlay.g_pin(height: 16)

//    cameraImageView.g_pin(on: .left, constant: 4)
//    cameraImageView.g_pin(on: .centerY, view: durationLabel, on: .centerY)
//    cameraImageView.g_pin(size: CGSize(width: 12, height: 6))

//    durationLabel.g_pin(on: .right, constant: -4)
    durationLabel.g_pinCenter(view: bottomOverlay)
//    durationLabel.g_pin(on: .bottom, constant: -2)
    
    self.layer.cornerRadius = 8
    self.layer.masksToBounds = true
    
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
    view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

    return view
  }
    
    func updateView() {
        self.selectedOverlayView.frame = self.bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.updateView()
    }
}

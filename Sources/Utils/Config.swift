import UIKit
import AVFoundation

public struct Config {
    
    @available(*, deprecated, message: "Use tabsToShow instead.")
    public static var showsVideoTab: Bool {
        // Maintains backwards-compatibility.
        get {
            return tabsToShow.index(of: .videoTab) != nil
        }
        set(newValue) {
            if !newValue {
                tabsToShow = tabsToShow.filter({$0 != .videoTab})
            } else {
                if tabsToShow.index(of: .videoTab) == nil {
                    tabsToShow.append(.videoTab)
                }
            }
        }
    }
    public static var tabsToShow: [GalleryTab] = [.imageTab, .cameraTab, .videoTab, .videoImageTab]
    // Defaults to cameraTab if present, or whatever tab is first if cameraTab isn't present.
    public static var initialTab: GalleryTab?
    
    public enum GalleryTab {
        case imageTab
        case cameraTab
        case videoTab
        case videoImageTab
    }
    
    public struct PageIndicator {
        public static var backgroundColor: UIColor = UIColor(red: 0, green: 3/255, blue: 10/255, alpha: 1)
        public static var unselectedFont: UIFont = UIFont.systemFont(ofSize: 14)
        public static var selectedFont: UIFont = UIFont.boldSystemFont(ofSize: 14)
        public static var textColor: UIColor = UIColor.white
        public static var isEnable: Bool = true
        
        public static var imagesTitle: String = "PHOTOS"
        public static var videosTitle: String = "VIDEOS"
        public static var cameraTitle: String = "CAMERA"
    }
    
    public struct SelectedView {
        public static var isEnabled: Bool = false
        
        public struct Collection {
            public static var isEnableTimeView: Bool = true
            public static var textColor: UIColor = UIColor(red: 54/255, green: 56/255, blue: 62/255, alpha: 1)
            public static var textFont: UIFont = UIFont.systemFont(ofSize: 1)
        }
      
    }
    
    public struct Limit {
        public static var imageCount: Int = 0
        public static var videoCount: Int = 0
        public static var allItemsCount: Int = Int.max
        
        public static var videoMaxDuration: TimeInterval = 180
        public static var videoMinDuration: TimeInterval = 3
    }
    
    public struct Camera {
        
        public static var recordLocation: Bool = false
        
        public struct ShutterButton {
            public static var numberColor: UIColor = UIColor(red: 54/255, green: 56/255, blue: 62/255, alpha: 1)
        }
        
        public struct BottomContainer {
            public static var backgroundColor: UIColor = UIColor(red: 23/255, green: 25/255, blue: 28/255, alpha: 0.8)
        }
        
        public struct StackView {
            public static var imageCount: Int = 4
        }
    }
    
    public struct Grid {
        
        public struct CloseButton {
            public static var tintColor: UIColor = UIColor(red: 109/255, green: 107/255, blue: 132/255, alpha: 1)
        }
        
        public struct ArrowButton {
            public static var tintColor: UIColor = UIColor(red: 110/255, green: 117/255, blue: 131/255, alpha: 1)
        }
        
        public struct FrameView {
            public static var fillColor: UIColor = UIColor(red: 50/255, green: 51/255, blue: 59/255, alpha: 1)
            public static var borderColor: UIColor = UIColor(red: 0, green: 239/255, blue: 155/255, alpha: 1)
        }
        
        public struct Dimension {
            public static var columnCount: CGFloat = 4
            public static var cellSpacing: CGFloat = 2
            public static var lineSpacing: CGFloat = 2
            
            public static var inset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        }
    }
    
    public struct EmptyView {
        public static var image: UIImage? = GalleryBundle.image("gallery_empty_view_image")
        public static var textColor: UIColor = UIColor(red: 102/255, green: 118/255, blue: 138/255, alpha: 1)
    }
    
    public struct Permission {
        public static var image: UIImage? = GalleryBundle.image("gallery_permission_view_camera")
        public static var textColor: UIColor = UIColor(red: 102/255, green: 118/255, blue: 138/255, alpha: 1)
        
        public struct Button {
            public static var textColor: UIColor = UIColor.white
            public static var highlightedTextColor: UIColor = UIColor.lightGray
            public static var backgroundColor = UIColor(red: 40/255, green: 170/255, blue: 236/255, alpha: 1)
        }
    }
    
    public struct Font {
        
        public struct Main {
            public static var light: UIFont = UIFont.systemFont(ofSize: 1)
            public static var regular: UIFont = UIFont.systemFont(ofSize: 1)
            public static var bold: UIFont = UIFont.boldSystemFont(ofSize: 1)
            public static var medium: UIFont = UIFont.boldSystemFont(ofSize: 1)
        }
        
        public struct Text {
            public static var regular: UIFont = UIFont.systemFont(ofSize: 1)
            public static var bold: UIFont = UIFont.boldSystemFont(ofSize: 1)
            public static var semibold: UIFont = UIFont.boldSystemFont(ofSize: 1)
        }
    }
    
    public struct VideoEditor {
        
        public static var quality: String = AVAssetExportPresetHighestQuality
        public static var savesEditedVideoToLibrary: Bool = false
        public static var portraitSize: CGSize = CGSize(width: 360, height: 640)
        public static var landscapeSize: CGSize = CGSize(width: 640, height: 360)
//        public static var isBorder: Bool = false
    }
    
    public struct RefreshControl {
        public static var isActive = false
        public static var color = UIColor.gray
    }
    
    
    public struct CellSelectedStyle {
        public static var isEnabled = true
        public static var isCounter = false

    }
    
    public struct ImageCell {
        public static var borderVisibility: Bool = false
    }
    
    public struct LoackView {
        public static var color: UIColor = UIColor.white
        public static var alpha: CGFloat = 0.5
    }
    
    public struct DropDown {
        public static var isEnabled: Bool = false
        public static var textFont: UIFont = UIFont.boldSystemFont(ofSize: 14)
    }
}

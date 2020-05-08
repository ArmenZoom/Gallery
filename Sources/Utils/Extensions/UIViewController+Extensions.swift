import UIKit

extension UIViewController {
    
    func g_addChildController(_ controller: UIViewController, addFromView: UIView) {
        addChild(controller)
        addFromView.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        controller.view.g_pinEdges()
    }
    
    func g_removeFromParentController(addFromView: UIView) {
        willMove(toParent: nil)
        addFromView.removeFromSuperview()
        removeFromParent()
    }
}

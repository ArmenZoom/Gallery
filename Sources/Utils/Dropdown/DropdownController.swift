import UIKit
import Photos

protocol DropdownControllerDelegate: class {
  func dropdownController(_ controller: DropdownController, didSelect album: Album)
}

class DropdownController: UIViewController {

  lazy var tableView: UITableView = self.makeTableView()
  lazy var blurView: UIVisualEffectView = self.makeBlurView()

  var animating: Bool = false
  var expanding: Bool = false
  var selectedIndex: Int = 0

  var albums: [Album] = [] {
    didSet {
      selectedIndex = 0
    }
  }

  var expandedTopConstraint: NSLayoutConstraint?
  var collapsedTopConstraint: NSLayoutConstraint?

  weak var delegate: DropdownControllerDelegate?

  // MARK: - Initialization

  // MARK: - Life cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    setup()
  }

  // MARK: - Setup

  func setup() {
    view.backgroundColor = UIColor.clear
    tableView.backgroundColor = UIColor.clear
    tableView.backgroundView = blurView
    
    view.addSubview(tableView)
    tableView.register(AlbumCell.self, forCellReuseIdentifier: String(describing: AlbumCell.self))

    tableView.g_pinEdges()
  }

  // MARK: - Logic

  func toggle() {
    guard !animating else { return }

    animating = true
    expanding = !expanding

    if expanding {
      collapsedTopConstraint?.isActive = false
      expandedTopConstraint?.isActive = true
    } else {
      expandedTopConstraint?.isActive = false
      collapsedTopConstraint?.isActive = true
    }

    UIView.animate(withDuration: 0.25, delay: 0, options: UIView.AnimationOptions(), animations: {
      self.view.superview?.layoutIfNeeded()
    }, completion: { finished in
      self.animating = false
    })
  }

  // MARK: - Controls

  func makeTableView() -> UITableView {
    let tableView = UITableView()
    tableView.tableFooterView = UIView()
    tableView.separatorStyle = .none
    tableView.rowHeight = 84

    tableView.dataSource = self
    tableView.delegate = self

    return tableView
  }

  func makeBlurView() -> UIVisualEffectView {
    let view = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

    return view
  }
}

extension DropdownController: UITableViewDataSource, UITableViewDelegate {

  // MARK: - UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return albums.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlbumCell.self), for: indexPath)
      as! AlbumCell

    let album = albums[(indexPath as NSIndexPath).row]
    cell.configure(album)
    cell.backgroundColor = UIColor.clear

    return cell
  }

  // MARK: - UITableViewDelegate

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    let album = albums[(indexPath as NSIndexPath).row]
    delegate?.dropdownController(self, didSelect: album)

    selectedIndex = (indexPath as NSIndexPath).row
    tableView.reloadData()
  }
}


import Foundation
import UIKit

protocol MakeDropDownDataSourceProtocol {
    func getDataToDropDown(cell: UITableViewCell, indexPos: Int)
    func numberOfRows() -> Int
    
    func selectItemInDropDown(indexPos: Int)
}

protocol MakeDropDownDelegate {
    func didShow()
    func didHide()
}


extension MakeDropDownDataSourceProtocol {
    func selectItemInDropDown(indexPos: Int) {}
}

class MakeDropDown: UIView{
    
    // Table View
    lazy var dropDownTableView: UITableView = {
        let t = UITableView()
        t.separatorStyle = .none
        t.rowHeight = 80
        t.register(AlbumCell.self, forCellReuseIdentifier: String(describing: AlbumCell.self))
        t.dataSource = self
        t.delegate = self
        t.showsVerticalScrollIndicator = false
        t.showsHorizontalScrollIndicator = false
        t.backgroundColor = .white
        t.allowsSelection = true
        t.isUserInteractionEnabled = true
        t.tableFooterView = UIView()
        return t
    }()
    var width: CGFloat = 0
    var offset:CGFloat = 0
    var makeDropDownDataSourceProtocol: MakeDropDownDataSourceProtocol?
    var makeDropDownDelegate: MakeDropDownDelegate?
    // Other Variables
    var viewPositionRef: CGRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    var isDropDownPresent: Bool = false
   
    
    //MARK: - DropDown Methods
    
    // Make Table View Programatically
    
    func setUpDropDown(viewPositionReference: CGRect,  offset: CGFloat){
        self.frame = CGRect(x: viewPositionReference.minX, y: viewPositionReference.maxY + offset, width: 0, height: 0)

        self.width = viewPositionReference.width
        self.offset = offset
        self.viewPositionRef = viewPositionReference
     
        self.addSubview(dropDownTableView)
        
    }
    
    // Shows Drop Down Menu
    func showDropDown(height: CGFloat){
        if isDropDownPresent{
            self.hideDropDown()
        }else{
            self.makeDropDownDelegate?.didShow()

            isDropDownPresent = true
            self.frame = CGRect(x: self.viewPositionRef.minX, y: self.viewPositionRef.maxY + self.offset, width: width, height: 0)
            self.dropDownTableView.frame = CGRect(x: 0, y: 0, width: width, height: 0)
            self.dropDownTableView.reloadData()
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveLinear
                , animations: {
                self.frame.size = CGSize(width: self.width, height: height)
                self.dropDownTableView.frame.size = CGSize(width: self.width, height: height)
            })
        }
        
    }
    
    // Use this method if you want change height again and again
    // For eg in UISearchBar DropDownMenu
    func reloadDropDown(height: CGFloat){
        self.frame = CGRect(x: self.viewPositionRef.minX, y: self.viewPositionRef.maxY
            + self.offset, width: width, height: 0)
        self.dropDownTableView.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        self.dropDownTableView.reloadData()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveLinear
            , animations: {
            self.frame.size = CGSize(width: self.width, height: height)
            self.dropDownTableView.frame.size = CGSize(width: self.width, height: height)
        })
    }
    
    //Sets Row Height of your Custom XIB
    func setRowHeight(height: CGFloat){
        self.dropDownTableView.rowHeight = height
        self.dropDownTableView.estimatedRowHeight = height
    }
    
    //Hides DropDownMenu
    func hideDropDown(){
        self.makeDropDownDelegate?.didHide()
        isDropDownPresent = false
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveLinear
            , animations: {
            self.frame.size = CGSize(width: self.width, height: 0)
            self.dropDownTableView.frame.size = CGSize(width: self.width, height: 0)
        })
    }
    
    // Removes DropDown Menu
    // Use it only if needed
    func removeDropDown(){
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveLinear
            , animations: {
            self.dropDownTableView.frame.size = CGSize(width: 0, height: 0)
            self.makeDropDownDelegate?.didHide()
        }) { (_) in
            self.makeDropDownDelegate?.didHide()
            self.removeFromSuperview()
            self.dropDownTableView.removeFromSuperview()
        }
    }
    
}

// MARK: - Table View Methods

extension MakeDropDown: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return makeDropDownDataSourceProtocol?.numberOfRows() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: AlbumCell.self), for: indexPath)
            as? AlbumCell {
            makeDropDownDataSourceProtocol?.getDataToDropDown(cell: cell, indexPos: indexPath.row)
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        makeDropDownDataSourceProtocol?.selectItemInDropDown(indexPos: indexPath.row)
    }
    
}

//MARK: - UIView Extension
extension UIView{
    func addBorders(borderWidth: CGFloat = 0.2, borderColor: CGColor = UIColor.lightGray.cgColor){
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }
    
    func addShadowToView(shadowRadius: CGFloat = 2, alphaComponent: CGFloat = 0.6) {
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: alphaComponent).cgColor
        self.layer.shadowOffset = CGSize(width: -1, height: 2)
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOpacity = 1
    }
}

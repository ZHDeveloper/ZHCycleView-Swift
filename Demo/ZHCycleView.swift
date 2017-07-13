//
//  ZHCycleView.swift
//  YueTao
//
//  Created by ZhiHua Shen on 2017/7/11.
//  Copyright © 2017年 ZhiHua Shen. All rights reserved.
//

import UIKit

public enum PageControlPositionModel {
    case bottomCenter(marginBottom: CGFloat)
    case topCenter(marginTop: CGFloat)
    case leftTop(marginLeft: CGFloat, marginTop: CGFloat)
    case rightTop(marginRight: CGFloat, marginTop: CGFloat)
    case leftBottom(marginLeft: CGFloat, marginBottom: CGFloat)
    case rightBottom(marginRight: CGFloat, marginBottom: CGFloat)
}

@objc public protocol ZHCycleViewDelegate: class {
    
    /// if you want to custom cell please implement this property
    @objc optional var cellType: AnyClass { get }
    
    /// if you want to custom cell please implement this method to return custom cell
    @objc optional func cycleView(_ cycleView: ZHCycleView, itemForCell cell: UICollectionViewCell, atIndex index: Int)
    
    /// tap action
    @objc optional func itemClick(at index: Int, inView cycleView: ZHCycleView)
    
    /// image download error
    @objc optional func imageDownload(error: Error, withUrl url: URL, inView cycleView: ZHCycleView)
}

public class ZHCycleView: UIView {
    
    weak public var delegate: ZHCycleViewDelegate?
    
    /// Default is true,however when imageArray.count is 1 the value is false
    public var isTimerEnable: Bool = true  {
        didSet {
            
            timer?.invalidate()
            
            if isTimerEnable {
                timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
                RunLoop.main.add(timer!, forMode: .commonModes)
            }
        }
    }
    
    
    /// the timeInterval to trigger next page
    public var timeInterval: TimeInterval = 5.0 {
        didSet {
            if isTimerEnable {
                isTimerEnable = true
            }
        }
    }
    
    
    /// data source to load
    public var imageArray: [UIImage?] = [] {
        didSet {
            
            DispatchQueue.main.async {
                let targetIndex = (self.imageArray.count * self.baseDigital) / 2;
                self.collectionView.scrollToItem(at: IndexPath(item: targetIndex, section: 0), at: .centeredHorizontally, animated: false)
            }
            
            pageIndicator.currentPage = 0
            pageIndicator.numberOfPages = imageArray.count
            
            collectionView.isScrollEnabled = !(imageArray.count == 1)
            isTimerEnable = !(imageArray.count == 1)
        }
    }
    
    
    /// list of url to load image , you should set placeholder image first
    public var urlArray: [URL]? = nil {
        didSet {
            guard let urlArray = urlArray, urlArray.count > 0 else { return }

            //use place holder image first
            imageArray = urlArray.map({ (url) -> UIImage? in
                placeHolder
            })
            
            // Update UI
            func process(_ image: UIImage,index: Int) {
                self.imageArray[index] = image
                // reload view
                if self.indexOfCurrentImage == index {
                    self.collectionView.reloadData()
                }
            }
            
            //Download image and replace array
            for (indx, url) in urlArray.enumerated() {
                
                if let image = ZHImageCache.image(forUrl: url) {
                    process(image, index: indx)
                }
                else {
                    DispatchQueue.global().async {
                        do {
                            let data = try Data(contentsOf: url)
                            if let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    process(image, index: indx)
                                }
                                try? ZHImageCache.store(image: image, forUrl: url)
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.delegate?.imageDownload?(error: error, withUrl: url, inView: self)
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    /// default is 0. value pinned to 0..numberOfPages-1
    public var indexOfCurrentImage: Int {
        return pageIndicator.currentPage
    }
    
    /// page control tint color
    public var pageIndicatorTintColor: UIColor? {
        didSet {
            pageIndicator.pageIndicatorTintColor = pageIndicatorTintColor
        }
    }
    
    
    /// current page control color
    public var currentPageIndicatorTintColor: UIColor? {
        didSet {
            pageIndicator.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        }
    }
    
    
    /// to config page control position
    public var indicatorPosition: PageControlPositionModel = .bottomCenter(marginBottom: 10)
    {
        didSet {
            // remove pageIndicator layoutconsts
            pageIndicator.zh.removeAllAutoLayout()

            switch indicatorPosition {
            case .bottomCenter(let marginBottom):
                pageIndicator.zh.anchor(bottom: bottomAnchor, bottomConstant: marginBottom, heightConstant: 15)
                pageIndicator.zh.anchorCenterXToSuperview(constant: 0)
                
            case .topCenter(let marginTop):
                pageIndicator.zh.anchor(top: topAnchor, topConstant: marginTop, heightConstant: 15)
                pageIndicator.zh.anchorCenterXToSuperview(constant: 0)
                
            case .leftTop(let marginLeft, let marginTop):
                pageIndicator.zh.anchor(top: topAnchor, left: leftAnchor, topConstant: marginTop, leftConstant: marginLeft, heightConstant: 15)
                
            case .rightTop(let marginRight, let marginTop):
                pageIndicator.zh.anchor(top: topAnchor, right: rightAnchor, topConstant: marginTop, rightConstant: marginRight, heightConstant: 15)
                
            case .leftBottom(let marginLeft, let marginBottom):
                pageIndicator.zh.anchor(left: leftAnchor, bottom: bottomAnchor, leftConstant: marginLeft, bottomConstant: marginBottom, heightConstant: 15)
                
            case .rightBottom(let marginRight, let marginBottom):
                pageIndicator.zh.anchor(bottom: bottomAnchor, right: rightAnchor, bottomConstant: marginBottom, rightConstant: marginRight, heightConstant: 15)
            }
        }
    }
    
    
    /// item click action
    public var itemClickAction: ((ZHCycleView,Int) -> Void)? = nil
    
    
    /// it will show placeholder image while url is loading
    public var placeHolder: UIImage? = nil
    
    /// the layout of collectionView
    fileprivate let flowLayout = UICollectionViewFlowLayout()
    
    
    /// collectionView
    fileprivate let collectionView: UICollectionView
    
    
    /// timer
    fileprivate var timer: Timer? = nil
    
    
    /// collectionview number of row is imageArray.count * baseDigital
    fileprivate let baseDigital: Int = 100000
    
    
    /// page control
    fileprivate let pageIndicator = UIPageControl(frame: CGRect.zero)
    
    
    /// override init method to add custom subviews
    override init(frame: CGRect) {
        
        // default config
        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.flowLayout)
        collectionView.zh.register(cellWithClass: ZHCycleCell.self)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        
        pageIndicator.hidesForSinglePage = true
        pageIndicator.numberOfPages = imageArray.count
        pageIndicator.backgroundColor = UIColor.clear
        
        super.init(frame: frame)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        addSubview(collectionView)
        collectionView.zh.fillToSuperview()

        addSubview(pageIndicator)
        pageIndicator.zh.anchor(bottom: bottomAnchor, bottomConstant: 10, heightConstant: 15)
        pageIndicator.zh.anchorCenterXToSuperview(constant: 0)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// layout subview to adapter
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        flowLayout.scrollDirection = .horizontal
        flowLayout.itemSize = self.bounds.size
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.sectionInset = UIEdgeInsets.zero
    }
    
    
    /// scroll to next page
    @objc fileprivate func timerAction() {
        guard imageArray.count > 0  else { return }
        
        let currentIdx = Int(self.collectionView.contentOffset.x / self.flowLayout.itemSize.width);
        var nextIdx = currentIdx + 1
        
        if nextIdx == (self.imageArray.count * baseDigital) {
            nextIdx = (self.imageArray.count * baseDigital) / 2
        }
        
        pageIndicator.currentPage = nextIdx % imageArray.count
        
        collectionView.scrollToItem(at: IndexPath(item: nextIdx, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    public func setImageClickAction(_ action: @escaping (ZHCycleView,Int) -> Void) {
        self.itemClickAction = action
    }
}


// MARK: - CollectionView DataSource And Delegate
extension ZHCycleView: UICollectionViewDelegate,UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        /// if delegate impletement custom cell,regist custom cell
        if let type = delegate?.cellType {
            /// assert cellType is UICollectionViewCell,if false it will crash
            assert(type is UICollectionViewCell.Type, "customCell must be UICollectionViewCell")
            collectionView.register(type, forCellWithReuseIdentifier: String(describing: type))
        }
        
        return imageArray.count * baseDigital
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // if custom cell recall delegate method to config cell
        if let cellType = delegate?.cellType {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: cellType), for: indexPath)
            delegate!.cycleView?(self, itemForCell: cell, atIndex: (indexPath.row % imageArray.count))
            return cell
        }
        
        let cell = collectionView.zh.dequeueReusableCell(withClass: ZHCycleCell.self, for: indexPath)
        
        let index = indexPath.item % imageArray.count
        
        cell.imageView.image = imageArray[index] ?? placeHolder
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = (indexPath.row % imageArray.count)
        delegate?.itemClick?(at: index, inView: self)
        itemClickAction?(self, index)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isTimerEnable = false
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isTimerEnable = true
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let index = Int((scrollView.contentOffset.x + self.flowLayout.itemSize.width * 0.5) / self.flowLayout.itemSize.width);
        pageIndicator.currentPage = index % imageArray.count
    }
}


/// CustomCell
class ZHCycleCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        addSubview(imageView)
        imageView.zh.fillToSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ZHImageCache {
    
    static var storageURL: URL? {
        let dir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
        guard let cachesDirectory = dir  else {
            return nil
        }
        let directory = "ZHCycleView"
        let destDirectory = cachesDirectory.appending("/"+directory)
        
        //Adjust the path is exist,if not create destDirectory
        if FileManager.default.fileExists(atPath: destDirectory) == false {
            try? FileManager.default.createDirectory(atPath: destDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return URL(fileURLWithPath: destDirectory)
    }
    
    static func store(image: UIImage, forUrl url: URL) throws {
        if let toURL = storageURL?.appendingPathComponent(url.lastPathComponent) {
            do {
                try UIImageJPEGRepresentation(image, 1)?.write(to: toURL)
            } catch {
                throw error
            }
        }
        else {
            var userInfo: [AnyHashable : Any] = [:]
            userInfo[NSLocalizedDescriptionKey] = "story path initial error"
            let error = NSError(domain: "", code: 1999, userInfo: userInfo)
            throw error
        }
    }
    
    static func image(forUrl url: URL) -> UIImage? {
        if let toURL = storageURL?.appendingPathComponent(url.lastPathComponent),let image = UIImage(contentsOfFile: toURL.path) {
            return image
        }
        else {
            return nil
        }
    }
    
}

public final class ZHExtension<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol ZHExtensionCompatible {
    associatedtype CompatibleType
    var zh: CompatibleType { get }
}

public extension ZHExtensionCompatible {
    public var zh: ZHExtension<Self> {
        get { return ZHExtension(self) }
    }
}

//extension UICollectionView: ZHExtensionCompatible {}
extension UIView: ZHExtensionCompatible{}

public extension ZHExtension where Base: UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(withClass name: T.Type, for indexPath: IndexPath) -> T {
        return base.dequeueReusableCell(withReuseIdentifier: String(describing: name), for: indexPath) as! T
    }
    
    func register<T: UICollectionViewCell>(cellWithClass name: T.Type) {
        base.register(T.self, forCellWithReuseIdentifier: String(describing: name))
    }
    
    func register<T: UICollectionViewCell>(nib: UINib?, withCellClass name: T.Type) {
        base.register(nib, forCellWithReuseIdentifier: String(describing: name))
    }

}

public extension ZHExtension where Base: UIView {
    
    @available(iOS 6.0, *)
    public func addConstraints(withFormat: String, views: UIView...) {
        var viewsDictionary: [String: UIView] = [:]
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        base.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: withFormat, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    @available(iOS 9, *)
    public func fillToSuperview() {
        base.translatesAutoresizingMaskIntoConstraints = false
        if let superview = base.superview {
            base.leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
            base.rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
            base.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            base.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        }
    }
    
    @available(iOS 9, *)
    @discardableResult
    public func anchor(
        top: NSLayoutYAxisAnchor? = nil,
        left: NSLayoutXAxisAnchor? = nil,
        bottom: NSLayoutYAxisAnchor? = nil,
        right: NSLayoutXAxisAnchor? = nil,
        topConstant: CGFloat = 0,
        leftConstant: CGFloat = 0,
        bottomConstant: CGFloat = 0,
        rightConstant: CGFloat = 0,
        widthConstant: CGFloat = 0,
        heightConstant: CGFloat = 0) -> [NSLayoutConstraint] {
        
        base.translatesAutoresizingMaskIntoConstraints = false
        
        var anchors = [NSLayoutConstraint]()
        
        if let top = top {
            anchors.append(base.topAnchor.constraint(equalTo: top, constant: topConstant))
        }
        
        if let left = left {
            anchors.append(base.leftAnchor.constraint(equalTo: left, constant: leftConstant))
        }
        
        if let bottom = bottom {
            anchors.append(base.bottomAnchor.constraint(equalTo: bottom, constant: -bottomConstant))
        }
        
        if let right = right {
            anchors.append(base.rightAnchor.constraint(equalTo: right, constant: -rightConstant))
        }
        
        if widthConstant > 0 {
            anchors.append(base.widthAnchor.constraint(equalToConstant: widthConstant))
        }
        
        if heightConstant > 0 {
            anchors.append(base.heightAnchor.constraint(equalToConstant: heightConstant))
        }
        
        anchors.forEach({$0.isActive = true})
        
        return anchors
    }
    
    @available(iOS 9, *)
    public func anchorCenterXToSuperview(constant: CGFloat = 0) {
        base.translatesAutoresizingMaskIntoConstraints = false
        if let anchor = base.superview?.centerXAnchor {
            base.centerXAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }
    
    @available(iOS 9, *)
    public func anchorCenterYToSuperview(constant: CGFloat = 0) {
        base.translatesAutoresizingMaskIntoConstraints = false
        if let anchor = base.superview?.centerYAnchor {
            base.centerYAnchor.constraint(equalTo: anchor, constant: constant).isActive = true
        }
    }
    
    @available(iOS 9, *)
    public func anchorCenterSuperview() {
        anchorCenterXToSuperview()
        anchorCenterYToSuperview()
    }
    
    @available(iOS 6.0, *)
    public func removeAllAutoLayout() {
        guard let superview = base.superview else { return }
        base.removeFromSuperview()
        superview.addSubview(base)
    }

}

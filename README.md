
## ZHCycleView

纯Swift开发的轻量级无限循环轮播框架

* 简单易用
* 可自定义Cell的样式
* 支持缓存图片
* 布局约束使用NSLayoutAnchor,支持iOS9以上

## 开发属性

```
/// 代理属性，可实现自定义cell和响应点击事件
weak public var delegate: ZHCycleViewDelegate?
    
/// 定时器开关属性
public var isTimerEnable: Bool = true 
    
    
/// 定时器的间隔时间
public var timeInterval: TimeInterval = 5.0 
    
    
/// 图片数组
public var imageArray: [UIImage?] = [] 
    
    
/// URL数组,可根据URL来缓存图片
public var urlArray: [URL]? = nil 
    
/// 当前显示图片的索引值
public var indexOfCurrentImage: Int {
    return pageIndicator.currentPage
}
    
/// page control tint color
public var pageIndicatorTintColor: UIColor? 
    
    
/// current page control color
public var currentPageIndicatorTintColor: UIColor? 
    
    
/// page control的显示位置
public var indicatorPosition: PageControlPositionModel = .bottomCenter(marginBottom: 10) 
    
    
/// 图片的点击事件，注意要使用[weak self] 防止循环引用
public var itemClickAction: ((ZHCycleView,Int) -> Void)? = nil
    
    
/// 站位图
public var placeHolder: UIImage? = nil


```

## 简单实用


```
		
let cycleView = ZHCycleView()
let image1 = UIImage(contentsOfFile: (Bundle.main.path(forResource: "image1.jpg", ofType: nil))!)!
let image2 = UIImage(contentsOfFile: (Bundle.main.path(forResource: "image2.jpg", ofType: nil))!)!
let image3 = UIImage(contentsOfFile: (Bundle.main.path(forResource: "image3.jpg", ofType: nil))!)!
let image4 = UIImage(contentsOfFile: (Bundle.main.path(forResource: "image4.jpg", ofType: nil))!)!
cycleView.imageArray = [image1,image2,image3]


<!-- 自定义cell -->
...
cycleView.delegate = self
...

extension ViewController: ZHCycleViewDelegate {
    
    var cellType: AnyClass {
        return BannerCell.self
    }
    
    func cycleView(_ cycleView: ZHCycleView, itemForCell cell: UICollectionViewCell, atIndex index: Int) {
        
        let aCell = cell as! BannerCell
        aCell.imageView.image = cycleView.imageArray[index]
    }
    
    func itemClick(at index: Int, inView cycleView: ZHCycleView) {
        print(index)
    }
    
    func imageDownload(error: Error, withUrl url: URL, inView cycleView: ZHCycleView) {
        print(error)
    }
}

class BannerCell: UICollectionViewCell {
    
    let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

```



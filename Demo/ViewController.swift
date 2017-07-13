//
//  ViewController.swift
//  ZHCycleView
//
//  Created by ZhiHua Shen on 2017/7/12.
//  Copyright © 2017年 ZhiHua Shen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cycleView = ZHCycleView()
        
        let url1 = URL(string: "http://pic40.nipic.com/20140403/18026643_093317589136_2.jpg")!
        let url2 = URL(string: "http://pic49.nipic.com/file/20140927/19617624_230415502002_2.jpg")!
        let url3 = URL(string: "http://pic26.nipic.com/20121227/9252150_202014506165_2.jpg")!
        let url4 = URL(string: "http://pic.58pic.com/58pic/13/76/88/00U58PICPIv_1024.jpg")!
        
        cycleView.placeHolder = #imageLiteral(resourceName: "image1.jpg")
        
        cycleView.urlArray = [url1,url2,url3,url4]
        
//        cycleView.delegate = self
        
        view.addSubview(cycleView)
        cycleView.zh.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, heightConstant: 200)
    }
    
}

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
        imageView.zh.fillToSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



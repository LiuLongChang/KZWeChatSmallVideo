//
//  KZVideoListViewController.swift
//  KZWeChatSmallVideo
//
//  Created by HouKangzhu on 16/7/15.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

import UIKit

class KZCircleCloseBtn: UIButton {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.backgroundColor = UIColor.white.cgColor
        self.layer.cornerRadius = self.bounds.width/2
        self.layer.masksToBounds = true
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        context?.setStrokeColor(kzThemeBlackColor.cgColor)
        context?.setLineWidth(1.0)
        context?.setLineCap(.round);
        
        let selfCent = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        let closeWidth:CGFloat = 8.0

        context?.move(to: CGPoint(x: selfCent.x-closeWidth/2, y: selfCent.y - closeWidth/2))
        context?.addLine(to: CGPoint(x: selfCent.x + closeWidth/2, y: selfCent.y + closeWidth/2))
        
        context?.move(to: CGPoint(x: selfCent.x-closeWidth/2, y: selfCent.y + closeWidth/2))
        context?.addLine(to: CGPoint(x: selfCent.x + closeWidth/2, y: selfCent.y - closeWidth/2))
        
        context?.drawPath(using: .stroke)
    }
}

private class KZVideoListCell: UICollectionViewCell {
    
    fileprivate let thumImage:UIImageView = UIImageView()
    fileprivate var model:KZVideoModel? = nil
    fileprivate let closeBtn = KZCircleCloseBtn(type:.custom)
    var deleteVideoBlock:((KZVideoModel) -> Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.thumImage.frame = CGRect(x: 4, y: 4, width: self.bounds.width - 8, height: self.bounds.height - 8)
        self.thumImage.layer.cornerRadius = 8.0
        self.thumImage.layer.masksToBounds = true
        self.contentView.addSubview(self.thumImage)
        
        self.closeBtn.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        self.closeBtn.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        self.contentView.addSubview(self.closeBtn)
        self.closeBtn.isHidden = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setModel(_ newModel:KZVideoModel) {
        self.model = newModel
        self.thumImage.image = UIImage(contentsOfFile: newModel.totalThumPath!)
    }
    
    func setEdit(_ edit:Bool) {
        self.closeBtn.isHidden = !edit
    }
    
    @objc func deleteAction() {
        self.deleteVideoBlock?(self.model!)
    }

}

private class KZAddNewVideoCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupView()
    }
    func setupView() {
        let bgLayer = CALayer()
        bgLayer.frame = CGRect(x: 4, y: 4, width: self.bounds.width - 8, height: self.bounds.height - 8)
        bgLayer.backgroundColor = UIColor ( red: 0.5, green: 0.5, blue: 0.5, alpha: 0.3 ).cgColor
        bgLayer.cornerRadius = 8.0
        bgLayer.masksToBounds = true
        self.contentView.layer.addSublayer(bgLayer)
        
        let selfCent = CGPoint(x: bgLayer.bounds.width/2, y: bgLayer.bounds.height/2)
        let len:CGFloat = 20
        let path = CGMutablePath()


        path.move(to: CGPoint.init(x: selfCent.x, y: selfCent.y - len))
        path.addLine(to: CGPoint.init(x: selfCent.x, y: selfCent.y + len))
        path.move(to: CGPoint.init(x:selfCent.x - len, y: selfCent.y))
        path.addLine(to: CGPoint.init(x:selfCent.x + len,y:selfCent.y))
        
        let crossLayer = CAShapeLayer()
        crossLayer.fillColor = UIColor.clear.cgColor
        crossLayer.strokeColor = kzThemeGraryColor.cgColor
        crossLayer.lineWidth = 4.0
        crossLayer.path = path
        crossLayer.opacity = 1.0
        bgLayer.addSublayer(crossLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private var currentListVC:KZVideoListViewController? = nil

class KZVideoListViewController: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {

    var selectBlock:((KZVideoListViewController,KZVideoModel) -> (Void))? = nil
    
    
    let actionView:UIView = UIView()
    fileprivate var collection:UICollectionView! = nil
    fileprivate let titleLabel:UILabel! = UILabel()
    
    fileprivate let leftBtn:KZCloseBtn = KZCloseBtn(type: .custom)
    fileprivate let rightBtn = UIButton(type: .custom)
    fileprivate let videoInfoLabel = UILabel()
    
    fileprivate var dataArr:[KZVideoModel]! = nil
    
    //MARK: - public Func
    func showAniamtion() {
        self.setupSupViews()
        currentListVC = self
        let keyWindow = UIApplication.shared.delegate?.window!
        self.actionView.transform = CGAffineTransform.identity.scaledBy(x: 1.6, y: 1.6)
        self.actionView.alpha = 0.0
        keyWindow?.addSubview(self.actionView)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: { 
            self.actionView.transform = CGAffineTransform.identity
            self.actionView.alpha = 1.0
            }) { (finished) in
                
        }
        self.setupCollectionView()
    }
   fileprivate func closeAnimation() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            self.actionView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: self.actionView.bounds.width)
            self.actionView.alpha = 0.0
        }) { (finished) in
            self.actionView.removeFromSuperview()
            currentListVC = nil
        }
        
    }
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.backgroundColor = UIColor.clearColor()
//        self.setupSupViews()
//    }
    
    fileprivate func setupSupViews() {
        self.actionView.frame = viewFrame
        self.actionView.backgroundColor = kzThemeBlackColor
//        self.view.addSubview(self.actionView)
        
        self.titleLabel.frame = CGRect(x: 0, y: 0, width: self.actionView.frame.width, height: 40)
        self.titleLabel.textColor = kzThemeGraryColor
        self.titleLabel.textAlignment = .center
        self.titleLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        self.titleLabel.text = "小视频"
        self.actionView.addSubview(self.titleLabel)
        
        self.leftBtn.frame = CGRect(x: 0, y: 0, width: 60, height: 40)
        self.leftBtn.color = kzThemeTineColor
        self.leftBtn.addTarget(self, action: #selector(closeViewAction), for: .touchUpInside)
        self.actionView.addSubview(self.leftBtn)
        self.leftBtn.setNeedsDisplay()

        self.rightBtn.frame = CGRect(x: self.actionView.frame.width - 60, y: 0, width: 60, height: 40)
        self.rightBtn.setTitle("编辑", for: UIControlState())
        self.rightBtn.setTitle("完成", for: .selected)
        self.rightBtn.setTitleColor(kzThemeTineColor, for: UIControlState())
        self.rightBtn.setTitleColor(kzThemeTineColor, for: .selected)
        self.rightBtn.addTarget(self, action: #selector(editVideosAction), for: .touchUpInside)
        self.actionView.addSubview(self.rightBtn)
        
    }

    fileprivate func setupCollectionView() {
        self.dataArr = KZVideoUtil.getSortVideoList()
        
        let itemWidth = (self.actionView.frame.width - 40)/3
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth/3*2)
        layout.sectionInset = UIEdgeInsetsMake(10, 8, 10, 8)
        self.collection = UICollectionView(frame: CGRect(x: 0, y: self.titleLabel.frame.maxY, width: self.actionView.frame.width, height: self.actionView.frame.height - self.titleLabel.frame.height), collectionViewLayout: layout)
        self.collection.delegate = self
        self.collection.dataSource = self
        self.collection.register(KZVideoListCell.classForCoder(), forCellWithReuseIdentifier: "Cell")
        self.collection.register(KZAddNewVideoCell.classForCoder(), forCellWithReuseIdentifier: "AddCell")
        self.collection.backgroundColor = UIColor.clear
        self.actionView.addSubview(self.collection)
    }
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
    
    func closeViewAction() {
        self.closeAnimation()
    }
    
    func editVideosAction() {
        self.rightBtn.isSelected = !self.rightBtn.isSelected
        self.collection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.rightBtn.isSelected {
            return self.dataArr.count
        }
        else {
            return self.dataArr.count+1
        }
    }

   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == self.dataArr.count {
            let addCell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCell", for: indexPath)
            return addCell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! KZVideoListCell
        let model = self.dataArr[indexPath.item]
        cell.setModel(model)
        cell.setEdit(self.rightBtn.isSelected)
        cell.deleteVideoBlock = { cellModel in
            
            let cellIndexPath = IndexPath(item: self.dataArr.index(of: cellModel)!, section: 0)
            self.dataArr.remove(at: cellIndexPath.item)
            collectionView.deleteItems(at: [cellIndexPath])
            KZVideoUtil.deletefile(model.totalVideoPath)
            
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == self.dataArr.count { // add NewVideo
            self.closeAnimation()
        }
        else {
            self.selectBlock?(self, self.dataArr[indexPath.item])
            self.closeAnimation()
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

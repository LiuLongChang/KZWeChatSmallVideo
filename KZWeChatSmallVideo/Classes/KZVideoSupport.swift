//
//  KZfocusView.swift
//  KZWeChatSmallVideo
//
//  Created by HouKangzhu on 16/7/12.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

import UIKit
import AVFoundation
public let kzSCREEN_WIDTH:CGFloat = UIScreen.mainScreen().bounds.width
public let kzSCREEN_HEIGHT:CGFloat = UIScreen.mainScreen().bounds.height
public let kzDocumentPath:String = NSSearchPathForDirectoriesInDomains(.DocumentationDirectory, .UserDomainMask, true)[0]
public let kzVideoDirName:String = "kzSmailVideo"
public let kzThemeBlackColor = UIColor.blackColor()
public let kzThemeTineColor = UIColor.greenColor()
public let kzRecordTime:NSTimeInterval = 10.0

public let viewFrame:CGRect = CGRectMake(0, kzSCREEN_HEIGHT*0.4, kzSCREEN_WIDTH, kzSCREEN_HEIGHT*0.6)

class KZVideoModel: NSObject {
    var totalVideoPath:String!
    var totalThumPath:String?
    var recordTime:NSDate!
    override init() {
        super.init()
    }
    init(videoPath:String!, thumPath:String?, recordTime:NSDate!) {
        super.init()
        self.totalVideoPath = videoPath
        self.totalThumPath = thumPath
        self.recordTime = recordTime
    }
}

class KZVideoUtil: NSObject {
    
    class func getVideoList() -> [KZVideoModel] {
        let fileManager = NSFileManager.defaultManager()
        var totalPathList:[KZVideoModel] = Array()
        let nameList = fileManager.subpathsAtPath(self.getVideoDirPath())!
        for name in nameList as [NSString] {
            if name.hasSuffix(".JPG") {
                let model = KZVideoModel()
                let totalThumPath = (self.getVideoDirPath() as NSString).stringByAppendingPathComponent(name as String)
                model.totalThumPath = totalThumPath
                let totalVideoPath = totalThumPath.stringByReplacingOccurrencesOfString("JPG", withString: "MOV")
                if fileManager.fileExistsAtPath(totalThumPath) {
                    model.totalVideoPath = totalVideoPath
                }
                let timeString = name.substringToIndex(name.length-4)
                let dateformate = NSDateFormatter()
                dateformate.dateFormat = "yyyy-MM-dd_HH:mm:ss"
                let date = dateformate.dateFromString(timeString)
                model.recordTime = date
                
                totalPathList.append(model)
            }
        }
        return totalPathList
    }
    
    class func getSortVideoList() -> [KZVideoModel] {
        let oldList = self.getVideoList() as NSArray
        
    }
    
    class func saveThumImage(videoUrl: NSURL, second: Int64) {
        let urlSet = AVURLAsset(URL: videoUrl)
        let imageGenerator = AVAssetImageGenerator(asset: urlSet)
        
        let time = CMTimeMake(second, 10)
//        var actualTime:CMTime?
        do {
            let cgImage = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
//            CMTimeShow(actualTime!)
            let image = UIImage(CGImage: cgImage)
            let imgJPGData = UIImageJPEGRepresentation(image, 1.0)
            
            let videoPath = (videoUrl.absoluteString as NSString).stringByReplacingOccurrencesOfString("file://", withString: "")
            let thumPath = (videoPath as NSString).stringByReplacingOccurrencesOfString("MOV", withString: "JPG")
            let isok = imgJPGData!.writeToFile(thumPath, atomically: true)
            print("保存成功!\(isok)")
        }
        catch let error as NSError {
            print("缩略图获取失败:\(error)")
        }
    }
    
    class func getVideoPath() -> String {
        let currentDate = NSDate()
        let dataformate = NSDateFormatter()
        dataformate.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        let videoName = dataformate.stringFromDate(currentDate)
        let dirPath = self.getVideoDirPath()
        return (dirPath as NSString).stringByAppendingPathComponent(videoName+".MOV")
    }
    
    class func deletefile(filePath: String!) {
        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.removeItemAtPath(filePath)
        }
        catch let error as NSError {
            print("删除失败:\(error)")
        }
    }
    
    class func getVideoDirPath() -> String {
        return self.getDocumentSubPath(kzVideoDirName)
    }
    
    class func getDocumentSubPath(dirName:String!) -> String {
        return (kzDocumentPath as NSString).stringByAppendingPathComponent(dirName)
    }
    
    override class func initialize() {
        let fileManager = NSFileManager.defaultManager()
        let dirPath = self.getVideoDirPath()
        do {
            try fileManager.createDirectoryAtPath(dirPath, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError {
            print("创建文件夹失败:\(error.description)")
        }
    }
}

class KZfocusView: UIView {
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        // Drawing code
        let context = UIGraphicsGetCurrentContext()
        CGContextSetAllowsAntialiasing(context, true)
        CGContextSetStrokeColorWithColor(context, UIColor.greenColor().CGColor)
        CGContextSetLineWidth(context, 1.0)
        
        CGContextMoveToPoint(context, 0.0, 0.0)
        CGContextAddRect(context, self.bounds)
        CGContextDrawPath(context, .Stroke)
    }

}

class KZCloseBtn: UIButton {
    /*
    func setupView() {
        self.layer.opaque = true
        let centX = self.bounds.width/2
        let centY = self.bounds.height/2
        let drawWidth:CGFloat = 30
        let drawHeight:CGFloat = 20
        let path = CGPathCreateMutable()
        var transform:CGAffineTransform = CGAffineTransformIdentity
        CGPathMoveToPoint(path, &transform, (centX - drawWidth/2), (centY + drawHeight/2))
        CGPathAddLineToPoint(path, &transform, centX, centY - drawHeight/2)
        CGPathAddLineToPoint(path, &transform, centX + drawWidth/2, centY + drawHeight/2)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = self.bounds
        shapeLayer.strokeColor = kzThemeTineColor.CGColor
        shapeLayer.fillColor = UIColor.clearColor().CGColor
        shapeLayer.opacity = 1.0
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.lineWidth = 4.0
        shapeLayer.path = path
        self.layer.addSublayer(shapeLayer)
    }
    */
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetAllowsAntialiasing(context, true)
        CGContextSetStrokeColorWithColor(context, UIColor.grayColor().CGColor)
        CGContextSetLineWidth(context, 3.0)
        CGContextSetLineCap(context, .Round);
        
        let centX = self.bounds.width/2
        let centY = self.bounds.height/2
        let drawWidth:CGFloat = 22
        let drawHeight:CGFloat = 10
        
        CGContextBeginPath(context);
        
        CGContextMoveToPoint(context, (centX - drawWidth/2), (centY - drawHeight/2))
        CGContextAddLineToPoint(context, centX, centY + drawHeight/2)
        CGContextAddLineToPoint(context, centX + drawWidth/2, centY - drawHeight/2)
        
        CGContextStrokePath(context)
    }
}

class KZRecordBtn: UIView {
    
    var tapGesture: UITapGestureRecognizer! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setuproundButton()
        self.layer.cornerRadius = self.bounds.width/2
        self.layer.masksToBounds = true
        self.userInteractionEnabled = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addtarget(target:AnyObject!, action:Selector) {
        self.tapGesture = UITapGestureRecognizer(target: target, action:action)
        self.addGestureRecognizer(self.tapGesture)
    }
    
    func setuproundButton() {
        let width = self.frame.width
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: width/2)
        
        let trackLayer = CAShapeLayer()
        trackLayer.frame = self.bounds
        trackLayer.strokeColor = UIColor.greenColor().CGColor
        trackLayer.fillColor = UIColor.clearColor().CGColor
        trackLayer.opacity = 1.0
        trackLayer.lineCap = kCALineCapRound
        trackLayer.lineWidth = 2.0
        trackLayer.path = path.CGPath
        self.layer.addSublayer(trackLayer)
    }
    
    func setupShadowButton() {
        let width = self.frame.width
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: width/2)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [UIColor.greenColor().CGColor, UIColor.yellowColor().CGColor, UIColor.blueColor()]
        gradientLayer.locations = [NSNumber(float: 0.3), NSNumber(float: 0.6), NSNumber(float: 1.0)]
        gradientLayer.startPoint = CGPointMake(0.0, 1.0)
        gradientLayer.endPoint = CGPointMake(0.0, 0.0)
        
        gradientLayer.shadowPath = path.CGPath
        self.layer.addSublayer(gradientLayer)
    }
    
    func setupView() {
        self.backgroundColor = UIColor.clearColor()
        
        let width = self.frame.width
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: width/2)
        
        let trackLayer = CAShapeLayer()
        trackLayer.frame = self.bounds
        trackLayer.strokeColor = UIColor.greenColor().CGColor
        trackLayer.fillColor = UIColor.clearColor().CGColor
        trackLayer.opacity = 1.0
        trackLayer.lineCap = kCALineCapRound
        trackLayer.lineWidth = 2.0
        trackLayer.path = path.CGPath
        trackLayer.masksToBounds = true
        self.layer.addSublayer(trackLayer)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [UIColor.greenColor().CGColor, UIColor.yellowColor().CGColor, UIColor.blueColor()]
        gradientLayer.locations = [NSNumber(float: 0.0), NSNumber(float: 0.6), NSNumber(float: 1.0)]
        gradientLayer.startPoint = CGPointMake(0.0, 1.0)
        gradientLayer.endPoint = CGPointMake(0.0, 0.0)
        
        gradientLayer.shadowPath = path.CGPath
        trackLayer.addSublayer(gradientLayer)
    }
    
}

class KZControllerBar: UIView , UIGestureRecognizerDelegate{
    
    var startBtn:KZRecordBtn? = nil
    let longPress = UILongPressGestureRecognizer()
    
    var delegate:KZControllerBarDelegate?
    
    let progressLine = UIView()
    var touchIsInside:Bool = true
    var recordDidStart:Bool = false
    
    var timer:NSTimer! = nil
    var surplusTime:NSTimeInterval! = nil
    
    
    var videoListBtn:UIButton! = nil
    var closeVideoBtn:KZCloseBtn! = nil
    
    deinit {
        print("ctrlView deinit")
    }
    
    func setupSubViews() {
        self.layoutIfNeeded()
        
        let selfHeight = self.bounds.height
        let selfWidth = self.bounds.width
        
        let edge:CGFloat! = 20.0
        
        
        let startBtnWidth = selfHeight - (edge * 2)
        
        self.startBtn = KZRecordBtn(frame: CGRectMake((selfWidth - startBtnWidth)/2, edge, startBtnWidth, startBtnWidth))
        self.addSubview(self.startBtn!)
        
        self.longPress.addTarget(self, action: #selector(KZControllerBar.longpressAction(_:)))
        self.longPress.minimumPressDuration = 0.01
        self.longPress.delegate = self
        self.addGestureRecognizer(self.longPress)
        
        self.progressLine.frame = CGRectMake(0, 0, selfWidth, 4)
        self.progressLine.backgroundColor = kzThemeTineColor
        self.progressLine.hidden = true
        self.addSubview(self.progressLine)
        
        self.surplusTime = kzRecordTime
    
        self.videoListBtn = UIButton(type:.Custom)
        self.videoListBtn.frame = CGRectMake(edge, edge+startBtnWidth/6, startBtnWidth/4*3, startBtnWidth/3*2)
        self.videoListBtn.layer.cornerRadius = 8
        self.videoListBtn.layer.masksToBounds = true
        self.videoListBtn.addTarget(self, action: #selector(videoListAction), forControlEvents: .TouchUpInside)
//        self.videoListBtn.backgroundColor = kzThemeTineColor
        self.addSubview(self.videoListBtn)
        let videoList = KZVideoUtil.getVideoList()
        if videoList.count == 0 {
            self.videoListBtn.hidden = true
        }
        else {
            self.videoListBtn.setBackgroundImage(UIImage(contentsOfFile: (videoList.first?.totalThumPath!)!), forState: .Normal)
        }
        
        
        let closeBtnWidth = self.videoListBtn.frame.height
        self.closeVideoBtn = KZCloseBtn(type: .Custom)
        self.closeVideoBtn.frame = CGRectMake(self.bounds.width - closeBtnWidth - edge, self.videoListBtn.frame.minY, closeBtnWidth, closeBtnWidth)
        self.closeVideoBtn.addTarget(self, action: #selector(videoCloseAction), forControlEvents: .TouchUpInside)
        self.addSubview(self.closeVideoBtn)
    }
    
    private func startRecordSet() {
        self.startBtn?.alpha = 1.0
        self.progressLine.frame = CGRectMake(0, 0, self.bounds.width, 2)
        self.progressLine.hidden = false
        self.surplusTime = kzRecordTime
        if self.timer == nil {
            self.timer = NSTimer(timeInterval: 1.0, target: self, selector: #selector(KZControllerBar.recordTimerAction), userInfo: nil, repeats: true)
            NSRunLoop.currentRunLoop().addTimer(self.timer, forMode: NSDefaultRunLoopMode)
        }
        self.timer.fire()
        
        UIView.animateWithDuration(0.4, animations: {
            self.startBtn?.alpha = 0.0
            self.startBtn?.transform = CGAffineTransformScale(CGAffineTransformIdentity, 2.0, 2.0)
        }) { (finished) in
            if finished {
                self.startBtn?.transform = CGAffineTransformIdentity
            }
        }
    }
    
    private func endTimer() {
        self.progressLine.hidden = true
        self.timer?.invalidate()
        self.timer = nil
        
        self.startBtn?.alpha = 1
    }
    
    // MARK: - UIGestureRecognizerDelegate --
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.longPress {
            if self.surplusTime <= 0 {
                return false
            }
            
            let point = gestureRecognizer.locationInView(self)
            let startBtnCenter = self.startBtn!.center;
            let dx = point.x - startBtnCenter.x
            let dy = point.y - startBtnCenter.y
            if (pow(dx, 2) + pow(dy, 2) < pow(startBtn!.bounds.width/2, 2)) {
                return true
            }
            return false
        }
        return true
    }
    
    // MARK: - Actions
    func videoStartAction() {
        self.startRecordSet()
        self.delegate?.videoDidStart!(self)
    }
    func videoEndAction() {
        self.delegate?.videoDidEnd!(self)
    }
    func videoCancelAction() {
        self.delegate?.videoDidCancel!(self)
    }
    
    func longpressAction(gestureRecognizer:UILongPressGestureRecognizer) {
        let point = gestureRecognizer.locationInView(self)
        switch gestureRecognizer.state {
        case .Began:
            self.videoStartAction()
//            print("began")
            break
        case .Changed:
            self.touchIsInside = point.y >= 0
            if !touchIsInside {
                self.delegate?.videoWillCancel!(self)
            }
//            print("changed")
            break
        case .Ended:
            self.endTimer()
            if !touchIsInside {
                self.videoCancelAction()
            }
            else {
                self.videoEndAction()
            }
//            print("ended")
            break
        case .Cancelled:
            
//            print("cancelled")
            break
        default:
//            print("other")
            break
        }
    }
    
    func recordTimerAction() {
//        print("timer repeat")
        let reduceLen = self.bounds.width/CGFloat(kzRecordTime)
        let oldLineLen = self.progressLine.frame.width
        var oldFrame = self.progressLine.frame
        
        UIView.animateWithDuration(1.0, delay: 0.0, options: .CurveLinear, animations: {
            
            oldFrame.size.width = oldLineLen - reduceLen
            self.progressLine.frame = oldFrame
            self.progressLine.center = CGPointMake(self.bounds.width/2, self.progressLine.bounds.height/2)
        
        }) { (finished) in
            
            self.surplusTime = self.surplusTime - 1
            self.delegate?.videoDidRecordSEC!(self)
            if self.surplusTime <= 0.0 {
                self.endTimer()
                self.videoEndAction()
            }
        }
    }
    
    func videoListAction(sender:UIButton) {
        self.delegate?.videoOpenVideoList!(self)
    }
    
    func videoCloseAction(sender:UIButton) {
        self.delegate?.videoDidClose!(self)
    }
}

@objc protocol KZControllerBarDelegate {
    
    optional func videoDidStart(controllerBar:KZControllerBar!)
    
    optional func videoDidEnd(controllerBar:KZControllerBar!)
    
    optional func videoDidCancel(controllerBar:KZControllerBar!)
    
    optional func videoWillCancel(controllerBar:KZControllerBar!)
    
    optional func videoDidRecordSEC(controllerBar:KZControllerBar!)
    
    optional func videoDidClose(controllerBar:KZControllerBar!)
    
    optional func videoOpenVideoList(controllerBar:KZControllerBar!)
    
}
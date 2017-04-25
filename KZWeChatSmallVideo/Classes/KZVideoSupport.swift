//
//  KZfocusView.swift
//  KZWeChatSmallVideo
//
//  Created by HouKangzhu on 16/7/12.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

import UIKit
import AVFoundation
public let kzSCREEN_WIDTH:CGFloat = UIScreen.main.bounds.width
public let kzSCREEN_HEIGHT:CGFloat = UIScreen.main.bounds.height
public let kzDocumentPath:String = NSSearchPathForDirectoriesInDomains(.documentationDirectory, .userDomainMask, true)[0]
public let kzVideoDirName:String = "kzSmailVideo"
public let kzThemeBlackColor = UIColor.black
public let kzThemeTineColor = UIColor.green
public let kzThemeWaringColor = UIColor.red
public let kzThemeWhiteColor = UIColor.white
public let kzThemeGraryColor = UIColor.gray
public let kzRecordTime:TimeInterval = 10.0

public let viewFrame:CGRect = CGRect(x: 0, y: kzSCREEN_HEIGHT*0.4, width: kzSCREEN_WIDTH, height: kzSCREEN_HEIGHT*0.6)

// MARK: -  Model Define
open class KZVideoModel: NSObject {
    var totalVideoPath:String!
    var totalThumPath:String?
    var recordTime:Date!
    override init() {
        super.init()
    }
    init(videoPath:String!, thumPath:String?, recordTime:Date!) {
        super.init()
        self.totalVideoPath = videoPath
        self.totalThumPath = thumPath
        self.recordTime = recordTime
    }
}
// MARK: - Util --
class KZVideoUtil: NSObject {
    
//    static var videoList:[KZVideoModel]! = Array()
    
    class func getVideoList() -> [KZVideoModel] {
        let fileManager = FileManager.default
        var totalPathList:[KZVideoModel] = Array()
        let nameList = fileManager.subpaths(atPath: self.getVideoDirPath())!
        for name in nameList as [NSString] {
            if name.hasSuffix(".JPG") {
                let model = KZVideoModel()
                let totalThumPath = (self.getVideoDirPath() as NSString).appendingPathComponent(name as String)
                model.totalThumPath = totalThumPath
                let totalVideoPath = totalThumPath.replacingOccurrences(of: "JPG", with: "MOV")
                if fileManager.fileExists(atPath: totalThumPath) {
                    model.totalVideoPath = totalVideoPath
                }
                let timeString = name.substring(to: name.length-4)
                let dateformate = DateFormatter()
                dateformate.dateFormat = "yyyy-MM-dd_HH:mm:ss"
                let date = dateformate.date(from: timeString)
                model.recordTime = date
                
                totalPathList.append(model)
            }
        }
        return totalPathList
    }
    
    class func getSortVideoList() -> [KZVideoModel] {
//        if self.videoList != nil && self.videoList?.count > 0 {
//            return self.videoList!
//        }
        
        let oldList = self.getVideoList() as NSArray
        let sortList = oldList.sortedArray (comparator: { (obj1, obj2) -> ComparisonResult in
            let model1 = obj1 as! KZVideoModel
            let model2 = obj2 as! KZVideoModel
            let compare = model1.recordTime.compare(model2.recordTime)
            switch compare {
            case .orderedDescending:
                return .orderedAscending
            case .orderedAscending:
                return .orderedDescending
            default:
                return compare
            }
        })
        return sortList as! [KZVideoModel]
    }
    
    class func saveThumImage(_ videoUrl: URL, second: Int64) {
        let urlSet = AVURLAsset(url: videoUrl)
        let imageGenerator = AVAssetImageGenerator(asset: urlSet)
        
        let time = CMTimeMake(second, 10)
//        var actualTime:CMTime?
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
//            CMTimeShow(actualTime!)
            let image = UIImage(cgImage: cgImage)
            let imgJPGData = UIImageJPEGRepresentation(image, 1.0)
            
            let videoPath = (videoUrl.absoluteString as NSString).replacingOccurrences(of: "file://", with: "")
            let thumPath = (videoPath as NSString).replacingOccurrences(of: "MOV", with: "JPG")
            let isok = (try? imgJPGData!.write(to: URL(fileURLWithPath: thumPath), options: [.atomic])) != nil
            print("保存成功!\(isok)")
        }
        catch let error as NSError {
            print("缩略图获取失败:\(error)")
        }
    }
    
    class func createNewVideo() -> KZVideoModel {
        let currentDate = Date()
        let dataformate = DateFormatter()
        dataformate.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        let videoName = dataformate.string(from: currentDate)
        let dirPath = self.getVideoDirPath()
        
        let model = KZVideoModel()
        model.totalVideoPath = (dirPath as NSString).appendingPathComponent(videoName+".MOV")
        model.totalThumPath = (dirPath as NSString).appendingPathComponent(videoName+".JPG")
        model.recordTime = currentDate
        return model
    }
    
    class func deletefile(_ filePath: String!) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: filePath)
            let thumPath = (filePath as NSString).replacingOccurrences(of: "MOV", with: "JPG")
            try fileManager.removeItem(atPath: thumPath)
        }
        catch let error as NSError {
            print("删除失败:\(error)")
        }
    }
    
    class func getVideoDirPath() -> String {
        return self.getDocumentSubPath(kzVideoDirName)
    }
    
    class func getDocumentSubPath(_ dirName:String!) -> String {
        return (kzDocumentPath as NSString).appendingPathComponent(dirName)
    }
    
    override class func initialize() {
        let fileManager = FileManager.default
        let dirPath = self.getVideoDirPath()
        do {
            try fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError {
            print("创建文件夹失败:\(error.description)")
        }
    }
}

//class KZBaseViewController: UIViewController {
//    
//}

//MARK: - TransitionAnimator
public enum KZTransitionType:Int {
    case present
    case push
    case dismiss
    case pop
}
class KZTransitionManager:NSObject, UIViewControllerAnimatedTransitioning {
    var animationTime:TimeInterval! = 0.4
    var transitionType:KZTransitionType! = nil
    fileprivate var transitionContext: UIViewControllerContextTransitioning! = nil
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationTime
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        
        let containview = transitionContext.containerView
        containview.addSubview((fromVC?.view)!)
        containview.addSubview((toVC?.view)!)
        if self.transitionType == .present || self.transitionType == .push {
            UIView.animate(withDuration: self.animationTime, delay: 0.0, options: UIViewAnimationOptions(), animations: {
                toVC?.view.frame = (fromVC?.view.frame)!
                }, completion: { (finished) in
                    if transitionContext.transitionWasCancelled {
                        transitionContext.completeTransition(false)
                        fromVC?.view.isHidden = false
                    }else {
                        transitionContext.completeTransition(true)
                        fromVC?.view.isHidden = false
                        toVC?.view.isHidden = false
                    }
            })
        }
        else {
            UIView.animate(withDuration: self.animationTime, delay: 0.0, options: UIViewAnimationOptions(), animations: {
               fromVC?.view.frame = CGRect(x: 0, y: kzSCREEN_HEIGHT, width: kzSCREEN_WIDTH, height: kzSCREEN_HEIGHT)
                }, completion: { (finished) in
                    if transitionContext.transitionWasCancelled {
                        transitionContext.completeTransition(false)
                        fromVC?.view.isHidden = false
                    }else {
                        transitionContext.completeTransition(true)
                        fromVC?.view.isHidden = true
                        toVC?.view.isHidden = false
                    }
            })
            
        }
        
    }
    func animationEnded(_ transitionCompleted: Bool) {
        
    }
}

//MARK: - Custom View
class KZStatusBar: UIView {
    fileprivate var recoding = false
    var isRecoding:Bool {
        get {
            return self.recoding
        }
        set(newValue){
            self.recoding = newValue
            self.setNeedsDisplay()
        }
    }
    fileprivate var clear:Bool = false
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        let selfCent = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        
        if self.isRecoding {
            if clear {
                self.clear = false
                return
            }
        
            context?.setStrokeColor(kzThemeWaringColor.cgColor)
            context?.setFillColor(kzThemeWaringColor.cgColor)
            context?.setLineWidth(1.0)
            context?.setLineCap(.round);
            context?.addArc(center: CGPoint.init(x: selfCent.x, y: selfCent.y), radius: 5, startAngle: 0, endAngle: 2.0*CGFloat(Double.pi), clockwise: false)

            context?.drawPath(using: .fillStroke);
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.5*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                if !self.isRecoding {
                    return
                }
                self.clear = self.isRecoding
                self.setNeedsDisplay()
            })
        }
        else {
            let barW:CGFloat = 20.0
            let barSpace:CGFloat = 5.0
            let topEdge:CGFloat = 5.0
            context?.setStrokeColor(UIColor ( red: 0.5, green: 0.5, blue: 0.5, alpha: 0.7 ).cgColor)
            context?.setLineWidth(3.0)
            context?.setLineCap(.round);
            
            for index in 0 ..< 3 {
                context?.move(to: CGPoint(x: selfCent.x-(barW/2), y: topEdge+(barSpace*CGFloat(index))))
                context?.addLine(to: CGPoint(x: selfCent.x+(barW/2), y: topEdge+(barSpace*CGFloat(index))))
            }
        
            context?.drawPath(using: .stroke)
        }
        
    }
    
}

class KZfocusView: UIView {
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Drawing code
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        context?.setStrokeColor(kzThemeTineColor.cgColor)
        context?.setLineWidth(1.0)
        
        context?.move(to: CGPoint(x: 0.0, y: 0.0))
        context?.addRect(self.bounds)
        context?.drawPath(using: .stroke)
    }

}

class KZCloseBtn: UIButton {
    var color:UIColor = kzThemeGraryColor
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
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        context?.setStrokeColor(color.cgColor)
        context?.setLineWidth(3.0)
        context?.setLineCap(.round);
        
        let centX = self.bounds.width/2
        let centY = self.bounds.height/2
        let drawWidth:CGFloat = 22
        let drawHeight:CGFloat = 10
        
        context?.beginPath();
        
        context?.move(to: CGPoint(x: (centX - drawWidth/2), y: (centY - drawHeight/2)))
        context?.addLine(to: CGPoint(x: centX, y: centY + drawHeight/2))
        context?.addLine(to: CGPoint(x: centX + drawWidth/2, y: centY - drawHeight/2))
        
        context?.strokePath()
    }
}

class KZRecordBtn: UIView {
    
    var tapGesture: UITapGestureRecognizer! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setuproundButton()
        self.layer.cornerRadius = self.bounds.width/2
        self.layer.masksToBounds = true
        self.isUserInteractionEnabled = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addtarget(_ target:AnyObject!, action:Selector) {
        self.tapGesture = UITapGestureRecognizer(target: target, action:action)
        self.addGestureRecognizer(self.tapGesture)
    }
    
    func setuproundButton() {
        let width = self.frame.width
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: width/2)
        
        let trackLayer = CAShapeLayer()
        trackLayer.frame = self.bounds
        trackLayer.strokeColor = kzThemeTineColor.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.opacity = 1.0
        trackLayer.lineCap = kCALineCapRound
        trackLayer.lineWidth = 2.0
        trackLayer.path = path.cgPath
        self.layer.addSublayer(trackLayer)
    }
    
    func setupShadowButton() {
        let width = self.frame.width
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: width/2)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [kzThemeTineColor.cgColor, UIColor.yellow.cgColor, UIColor.blue]
        gradientLayer.locations = [NSNumber(value: 0.3 as Float), NSNumber(value: 0.6 as Float), NSNumber(value: 1.0 as Float)]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        
        gradientLayer.shadowPath = path.cgPath
        self.layer.addSublayer(gradientLayer)
    }
    
    func setupView() {
        self.backgroundColor = UIColor.clear
        
        let width = self.frame.width
        let path = UIBezierPath(roundedRect: self.bounds, cornerRadius: width/2)
        
        let trackLayer = CAShapeLayer()
        trackLayer.frame = self.bounds
        trackLayer.strokeColor = kzThemeTineColor.cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.opacity = 1.0
        trackLayer.lineCap = kCALineCapRound
        trackLayer.lineWidth = 2.0
        trackLayer.path = path.cgPath
        trackLayer.masksToBounds = true
        self.layer.addSublayer(trackLayer)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = [UIColor.green.cgColor, UIColor.yellow.cgColor, UIColor.blue]
        gradientLayer.locations = [NSNumber(value: 0.0 as Float), NSNumber(value: 0.6 as Float), NSNumber(value: 1.0 as Float)]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        
        gradientLayer.shadowPath = path.cgPath
        trackLayer.addSublayer(gradientLayer)
    }
    
}

//MARK: - videoContro -
class KZControllerBar: UIView , UIGestureRecognizerDelegate{
    
    var startBtn:KZRecordBtn? = nil
    let longPress = UILongPressGestureRecognizer()
    
    var delegate:KZControllerBarDelegate?
    
    let progressLine = UIView()
    var touchIsInside:Bool = true
    var recording:Bool = false
    
    var timer:Timer! = nil
    var surplusTime:TimeInterval! = nil
    
    
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
        
        self.startBtn = KZRecordBtn(frame: CGRect(x: (selfWidth - startBtnWidth)/2, y: edge, width: startBtnWidth, height: startBtnWidth))
        self.addSubview(self.startBtn!)
        
        self.longPress.addTarget(self, action: #selector(KZControllerBar.longpressAction(_:)))
        self.longPress.minimumPressDuration = 0.01
        self.longPress.delegate = self
        self.addGestureRecognizer(self.longPress)
        
        self.progressLine.frame = CGRect(x: 0, y: 0, width: selfWidth, height: 4)
        self.progressLine.backgroundColor = kzThemeTineColor
        self.progressLine.isHidden = true
        self.addSubview(self.progressLine)
        
        self.surplusTime = kzRecordTime
    
        self.videoListBtn = UIButton(type:.custom)
        self.videoListBtn.frame = CGRect(x: edge, y: edge+startBtnWidth/6, width: startBtnWidth/4*3, height: startBtnWidth/3*2)
        self.videoListBtn.layer.cornerRadius = 8
        self.videoListBtn.layer.masksToBounds = true
        self.videoListBtn.addTarget(self, action: #selector(videoListAction), for: .touchUpInside)
//        self.videoListBtn.backgroundColor = kzThemeTineColor
        self.addSubview(self.videoListBtn)
        let videoList = KZVideoUtil.getSortVideoList()
        if videoList.count == 0 {
            self.videoListBtn.isHidden = true
        }
        else {
            self.videoListBtn.setBackgroundImage(UIImage(contentsOfFile: (videoList.first?.totalThumPath!)!), for: UIControlState())
        }
        
        
        let closeBtnWidth = self.videoListBtn.frame.height
        self.closeVideoBtn = KZCloseBtn(type: .custom)
        self.closeVideoBtn.frame = CGRect(x: self.bounds.width - closeBtnWidth - edge, y: self.videoListBtn.frame.minY, width: closeBtnWidth, height: closeBtnWidth)
        self.closeVideoBtn.addTarget(self, action: #selector(videoCloseAction), for: .touchUpInside)
        self.addSubview(self.closeVideoBtn)
    }
    
    fileprivate func startRecordSet() {
        self.startBtn?.alpha = 1.0
        self.progressLine.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: 2)
        self.progressLine.isHidden = false
        self.surplusTime = kzRecordTime
        self.recording = true
        if self.timer == nil {
            self.timer = Timer(timeInterval: 1.0, target: self, selector: #selector(KZControllerBar.recordTimerAction), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer, forMode: RunLoopMode.defaultRunLoopMode)
        }
        self.timer.fire()
        
        UIView.animate(withDuration: 0.4, animations: {
            self.startBtn?.alpha = 0.0
            self.startBtn?.transform = CGAffineTransform.identity.scaledBy(x: 2.0, y: 2.0)
        }, completion: { (finished) in
            if finished {
                self.startBtn?.transform = CGAffineTransform.identity
            }
        }) 
    }
    
    fileprivate func endRecordSet() {
        self.progressLine.isHidden = true
        self.timer?.invalidate()
        self.timer = nil
        self.recording = false
        self.startBtn?.alpha = 1
        self.surplusTime = kzRecordTime
    }
    
    // MARK: - UIGestureRecognizerDelegate --
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.longPress {
            if self.surplusTime <= 0 {
                return false
            }
            
            let point = gestureRecognizer.location(in: self)
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
    
    func longpressAction(_ gestureRecognizer:UILongPressGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)
        switch gestureRecognizer.state {
        case .began:
            self.videoStartAction()
//            print("began")
            break
        case .changed:
            self.touchIsInside = point.y >= 0
            if !touchIsInside {
                self.progressLine.backgroundColor = kzThemeWaringColor
                self.delegate?.videoWillCancel!(self)
            }
            else {
                self.progressLine.backgroundColor = kzThemeTineColor
            }
//            print("changed")
            break
        case .ended:
            self.endRecordSet()
            if !touchIsInside {
                self.videoCancelAction()
            }
            else {
                self.videoEndAction()
            }
//            print("ended")
            break
        case .cancelled:
            
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
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: .curveLinear, animations: {
            
            oldFrame.size.width = oldLineLen - reduceLen
            self.progressLine.frame = oldFrame
            self.progressLine.center = CGPoint(x: self.bounds.width/2, y: self.progressLine.bounds.height/2)
        
        }) { (finished) in
            
            self.surplusTime = self.surplusTime - 1
            if self.recording {
                self.delegate?.videoDidRecordSEC!(self)
            }
            if self.surplusTime <= 0.0 {
                self.endRecordSet()
                self.videoEndAction()
            }
        }
    }
    
    func videoListAction(_ sender:UIButton) {
        self.delegate?.videoOpenVideoList!(self)
    }
    
    func videoCloseAction(_ sender:UIButton) {
        self.delegate?.videoDidClose!(self)
    }
}

@objc protocol KZControllerBarDelegate {
    
    @objc optional func videoDidStart(_ controllerBar:KZControllerBar!)
    
    @objc optional func videoDidEnd(_ controllerBar:KZControllerBar!)
    
    @objc optional func videoDidCancel(_ controllerBar:KZControllerBar!)
    
    @objc optional func videoWillCancel(_ controllerBar:KZControllerBar!)
    
    @objc optional func videoDidRecordSEC(_ controllerBar:KZControllerBar!)
    
    @objc optional func videoDidClose(_ controllerBar:KZControllerBar!)
    
    @objc optional func videoOpenVideoList(_ controllerBar:KZControllerBar!)
    
}

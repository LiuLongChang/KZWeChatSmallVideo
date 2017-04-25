//
//  KZVideoViewController.swift
//  KZWeChatSmallVideo
//
//  Created by HouKangzhu on 16/7/11.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

import UIKit
import AVFoundation

@objc public protocol KZVideoViewControllerDelegate {
    
    @objc optional func videoViewController(_ videoViewController: KZVideoViewController!, didRecordVideo video:KZVideoModel!)
    
    @objc optional func videoViewControllerDidCancel(_ videoViewController: KZVideoViewController!)
    
}

private var currentVC:KZVideoViewController? = nil

open class KZVideoViewController: NSObject, KZControllerBarDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    fileprivate let view:UIView = UIView(frame:UIScreen.main.bounds)
    
    fileprivate let actionView:UIView! = UIView(frame: viewFrame)
    
    fileprivate let topSlideView:KZStatusBar! = KZStatusBar()
    
    fileprivate let videoView:UIView! = UIView()
    fileprivate let focusView:KZfocusView! = KZfocusView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
    fileprivate let statusInfo:UILabel = UILabel()
    fileprivate let cancelInfo:UILabel = UILabel()
    
    fileprivate let ctrlBar:KZControllerBar! = KZControllerBar()
    
    fileprivate var videoSession:AVCaptureSession! = nil
    fileprivate var videoPreLayer:AVCaptureVideoPreviewLayer! = nil
    fileprivate var videoDevice:AVCaptureDevice! = nil
    fileprivate var moveOut:AVCaptureMovieFileOutput? = nil
//    private var videoDataOut:AVCaptureVideoDataOutput? = nil
    
//    AVCaptureVideoDataOutput
    fileprivate var currentRecord:KZVideoModel? = nil
    fileprivate var currentRecordIsCancel:Bool = false
    
    open var delegate:KZVideoViewControllerDelegate? = nil
    
    func startAnimation() {
        
        self.controllerSetup()
        currentVC = self
        let keyWindow = UIApplication.shared.delegate?.window!
        keyWindow?.addSubview(self.view)
        self.actionView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: kzSCREEN_HEIGHT*0.6)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIViewAnimationOptions(), animations: { 
            self.actionView.transform = CGAffineTransform.identity
            self.view.backgroundColor = UIColor( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
            }) { (finished) in
        }
        do {
            try self.setupVideo()
        }
        catch let error as NSError {
            print("error: \(error)")
        }
    }
    
    func endAnimation() {
        UIView.animate(withDuration: 0.3, animations: { 
            self.view.backgroundColor = UIColor.clear
            self.actionView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: kzSCREEN_HEIGHT*0.6)
            }, completion: { (finished) in
            self.closeView()
        }) 
    }
    func closeView() {
        self.view.removeFromSuperview()
        currentVC = nil
    }
    
    fileprivate func controllerSetup() {
        self.view.backgroundColor = UIColor.clear
        self.setupSubViews()
        // 
        let cancelBtn = UIButton(type: .custom)
        cancelBtn.titleLabel?.text = "cancel"
        cancelBtn.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        cancelBtn.addTarget(self, action: #selector(KZVideoViewController.cancelDismiss), for: .touchUpInside)
        self.view.addSubview(cancelBtn)
    }
    
    deinit {
        print("videoViewController deinit")
    }
    
    // MARK: - satup Views
    fileprivate func setupSubViews() {
        self.actionView.backgroundColor = UIColor.white
        self.view.addSubview(self.actionView)
        
        let themeColor = kzThemeBlackColor
        
        let topHeight:CGFloat = 20.0
        let buttomHeight:CGFloat = 120.0
        
        let allHeight = actionView.frame.height
        let allWidth = actionView.frame.width
        
        
        self.topSlideView.frame = CGRect(x: 0, y: 0, width: allWidth, height: topHeight)
        self.topSlideView.backgroundColor = themeColor
        self.actionView.addSubview(self.topSlideView)
        
        
        self.ctrlBar.frame = CGRect(x: 0, y: allHeight - buttomHeight, width: allWidth, height: buttomHeight)
        self.ctrlBar.setupSubViews()
        self.ctrlBar.backgroundColor = themeColor
        self.ctrlBar.delegate = self
        self.actionView.addSubview(self.ctrlBar)
        
        
        self.videoView.frame = CGRect(x: 0, y: self.topSlideView.frame.maxY, width: allWidth, height: allHeight - topHeight - buttomHeight)
        self.actionView.addSubview(self.videoView)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(KZVideoViewController.focusAction(_:)))
        self.videoView.addGestureRecognizer(tapGesture)
        
        self.focusView.backgroundColor = UIColor.clear
        
        
        self.statusInfo.frame = CGRect(x: 0, y: self.videoView.frame.maxY - 30, width: self.videoView.frame.width, height: 20)
        self.statusInfo.textAlignment = .center
        self.statusInfo.font = UIFont.systemFont(ofSize: 14.0)
        self.statusInfo.textColor = UIColor.white
        self.statusInfo.isHidden = true
        self.actionView.addSubview(self.statusInfo)
        
        self.cancelInfo.frame = CGRect(x: 0, y: 0, width: 120, height: 24)
        self.cancelInfo.center = self.videoView.center
        self.cancelInfo.textAlignment = .center
        self.cancelInfo.textColor = kzThemeWhiteColor
        self.cancelInfo.backgroundColor = kzThemeWaringColor
        self.cancelInfo.isHidden = true
        self.actionView.addSubview(self.cancelInfo)
        
    }
    // MARK: - setup Video
    fileprivate func setupVideo() throws {
        let devicesVideo = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        let devicesAudio = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio)
        
        let videoInput = try AVCaptureDeviceInput(device: devicesVideo?[0] as! AVCaptureDevice)
        let audioInput = try AVCaptureDeviceInput(device: devicesAudio?[0] as! AVCaptureDevice)
        
        self.videoDevice = devicesVideo?[0] as! AVCaptureDevice
        
        let moveOut = AVCaptureMovieFileOutput()
        self.moveOut = moveOut
        
//        self.videoDataOut = AVCaptureVideoDataOutput()
//        self.videoDataOut?.videoSettings = [kCVPixelBufferPixelFormatTypeKey:NSNumber(unsignedInt: kCVPixelFormatType_32BGRA)]
//        self.videoDataOut?.setSampleBufferDelegate(self, queue: dispatch_get_main_queue())
        
//        self.videoWriter = AVAssetWriter()
        
        let session = AVCaptureSession()
        if session.canSetSessionPreset(AVCaptureSessionPreset352x288) {
            session.canSetSessionPreset(AVCaptureSessionPreset352x288)
        }
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        if session.canAddOutput(moveOut) {
            session.addOutput(moveOut)
        }
//        if session.canAddOutput(self.videoDataOut) {
//            session.addOutput(self.videoDataOut)
//        }
        self.videoSession = session
        
        self.videoPreLayer = AVCaptureVideoPreviewLayer(session: session)
        self.videoPreLayer.frame = self.videoView.bounds
        self.videoPreLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.videoView.layer.addSublayer(self.videoPreLayer)
        
        session.startRunning()
    }
    
    
    // MARK: - Actions
    // 聚焦
    func focusAction(_ sender:UITapGestureRecognizer) {
        let point = sender.location(in: self.videoView)
        self.focusView.center = point
        self.videoView.addSubview(self.focusView)
        self.videoView.bringSubview(toFront: self.focusView)
        
        if self.videoDevice.accessibilityElementIsFocused() && self.videoDevice.isFocusModeSupported(.autoFocus) {
            do {
                try self.videoDevice.lockForConfiguration()
                self.videoDevice.focusMode = .autoFocus
                self.videoDevice.focusPointOfInterest = point
                self.videoDevice.unlockForConfiguration()
            }
            catch let error as NSError {
                print("error: \(error)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.0*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.focusView.removeFromSuperview()
        }
    }
    
    func cancelDismiss() {
        self.videoSession.stopRunning()
//        self.dismissViewControllerAnimated(true, completion: nil)
        self.endAnimation()
    }
    
    //MARK: - controllerBarDelegate
    
    func videoDidStart(_ controllerBar: KZControllerBar!) {
        print("视频录制开始了")
        self.currentRecord = KZVideoUtil.createNewVideo()
        self.currentRecordIsCancel = false
        let outUrl = URL(fileURLWithPath: self.currentRecord!.totalVideoPath)
        self.moveOut?.startRecording(toOutputFileURL: outUrl, recordingDelegate: self)
        
//        self.videoDataOut.
        self.topSlideView.isRecoding = true
        
        self.statusInfo.textColor = kzThemeTineColor
        self.statusInfo.text = "↑上移取消"
        self.statusInfo.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.5*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            self.statusInfo.isHidden = true
        })
    }
    
    func videoDidEnd(_ controllerBar: KZControllerBar!) {
        print("视频录制结束了")
        self.moveOut?.stopRecording()
        self.topSlideView.isRecoding = false
        
//        self.delegate?.videoViewController!(self, didRecordVideo: self.currentRecord!)
//        self.endAnimation()
    }
    
    func videoDidCancel(_ controllerBar: KZControllerBar!) {
        print("视频录制已经取消了")
        self.moveOut?.stopRecording()
        self.currentRecordIsCancel = true
        self.delegate?.videoViewControllerDidCancel!(self)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.0*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            KZVideoUtil.deletefile(self.currentRecord!.totalVideoPath)
        })
    }
    
    func videoWillCancel(_ controllerBar: KZControllerBar!) {
        print("视频录制将要取消")
        if !self.cancelInfo.isHidden {
            return
        }
        self.cancelInfo.text = "松手取消"
        self.cancelInfo.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.5*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
            self.cancelInfo.isHidden = true
        })
    }
    
    func videoDidRecordSEC(_ controllerBar: KZControllerBar!) {
        print("视频录制又过了一秒")
        self.topSlideView.isRecoding = true
    }
    
    func videoDidClose(_ controllerBar: KZControllerBar!) {
        print("关闭界面")
        self.cancelDismiss()
    }
    
    func videoOpenVideoList(_ controllerBar: KZControllerBar!) {
        print("查看视频列表")
        let listVideoVC = KZVideoListViewController()
        listVideoVC.selectBlock = { (listVC, selectVideo) in
            self.currentRecord = selectVideo
            self.delegate?.videoViewController!(self, didRecordVideo: selectVideo)
            self.closeView()
        }
        listVideoVC.showAniamtion()
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate -
    open func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("视频已经开始录制......")
    }
    
    open func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("视频完成录制......")
        if !currentRecordIsCancel {
            KZVideoUtil.saveThumImage(outputFileURL, second: 1)
            self.delegate?.videoViewController!(self, didRecordVideo: self.currentRecord!)
            self.endAnimation()
        }
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    open func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress( pixelBuffer, CVPixelBufferLockFlags(rawValue: 0) );
        let len = CVPixelBufferGetDataSize(pixelBuffer)
        
        let pixel = CVPixelBufferGetBaseAddress(pixelBuffer)
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pxPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        
        var newPixelBuffer: CVPixelBuffer? = nil
        
        let newWidth = 480
        let newHeight = 480*height/width
        let options = [kCVPixelBufferCGImageCompatibilityKey as String:NSNumber(value: true as Bool), kCVPixelBufferCGBitmapContextCompatibilityKey as String:NSNumber(value: true as Bool)]
        let status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, newWidth, newHeight, kCVPixelFormatType_32BGRA, pixel!, pxPerRow, nil, nil, options as CFDictionary, &newPixelBuffer)
        
        let description = CMSampleBufferGetFormatDescription(sampleBuffer)
        var newBuffer:CMSampleBuffer? = nil


        if status == kCVReturnSuccess {
            var timingInfo = CMSampleTimingInfo()
            CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, newPixelBuffer!, true, nil, nil, description!, &timingInfo, &newBuffer)
        }


        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
        print("width : \(width)\theight : \(height)\nlen : \(len)80")
    }
    
    open func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
    }
    
    /*
    // MARK: - UIViewControllerTransitioningDelegate
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = KZTransitionManager()
        transition.transitionType = .Present
        return transition
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = KZTransitionManager()
        transition.transitionType = .Dismiss
        return transition
    }
     */
}

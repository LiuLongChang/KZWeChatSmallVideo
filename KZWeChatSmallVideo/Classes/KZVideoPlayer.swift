//
//  KZVideoPlayer.swift
//  KZWeChatSmallVideo
//
//  Created by HouKangzhu on 16/7/18.
//  Copyright © 2016年 侯康柱. All rights reserved.
//

import UIKit
import AVFoundation
class KZVideoPlayer: UIView {

    var player:AVPlayer! = nil
    
    var videoCtrl:UIView! = nil
    
    var videoUrl:URL? = nil
    
    var isPlaying:Bool = false
    
    init(frame: CGRect, aVideoURL:URL) {
        super.init(frame: frame)
        self.videoUrl = aVideoURL
        self.setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupView() {
        let playerItem = AVPlayerItem(url: self.videoUrl!)
        self.player = AVPlayer(playerItem: playerItem)
        NotificationCenter.default.addObserver(self, selector: #selector(playEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        let playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.frame = self.bounds
        playerLayer.videoGravity = AVLayerVideoGravityResize
        self.layer.addSublayer(playerLayer)
        
        
        self.videoCtrl = UIView(frame: self.bounds)
        self.videoCtrl.backgroundColor = UIColor.clear
        self.addSubview(self.videoCtrl)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.videoCtrl.addGestureRecognizer(tapGesture)
        self.tapAction()
    }
    
    func stopViewChange() {
        let selfCent = CGPoint(x: self.bounds.width/2+10, y: self.bounds.height/2)
        let width:CGFloat = 40
        
        let path = CGMutablePath()
        path.move(to: CGPoint.init(x: selfCent.x - width/2, y: selfCent.y - width/2))
        path.addLine(to: CGPoint.init(x: selfCent.x - width/2, y: selfCent.y + width/2))
        path.addLine(to: CGPoint.init(x:selfCent.x + width/2 - 4, y: selfCent.y))
        path.addLine(to: CGPoint.init(x:selfCent.x - width/2,y:selfCent.y - width/2))

        let color = UIColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5 ).cgColor
        
        let trackLayer = CAShapeLayer()
        trackLayer.frame = self.bounds
        trackLayer.strokeColor = UIColor.clear.cgColor
        trackLayer.fillColor = color
        trackLayer.opacity = 1.0
        trackLayer.lineCap = kCALineCapRound
        trackLayer.lineWidth = 1.0
        trackLayer.path = path
        self.videoCtrl.layer.addSublayer(trackLayer)
    }
    
    func tapAction(){
        if self.isPlaying {
            self.player.pause()
            self.stopViewChange()
        }
        else {
            self.player.play()
        }
        self.isPlaying = !self.isPlaying
    }
    func playEnd() {
        self.player.seek(to: CMTimeMakeWithSeconds(0, self.player.currentItem!.duration.timescale), completionHandler: { (finished) in
            self.player.play()
        }) 
    }
}

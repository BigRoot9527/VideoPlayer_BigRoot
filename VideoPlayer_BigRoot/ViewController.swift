//
//  ViewController.swift
//  VideoPlayer_BigRoot
//
//  Created by 許庭瑋 on 2018/4/27.
//  Copyright © 2018年 許庭瑋. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var videoView: UIView!
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer!
    var isVideoPlaying = false
    var isMuted = false
    var buttonIsHide = false
    var buttons: [UIButton] = []
    
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var soundButton: UIButton!
    @IBOutlet weak var screeenButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var videoPlaceHolderLabel: UILabel!
    @IBOutlet weak var sliderStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBasicLayout()
        urlTextField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.hideButtons))
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let playerLayer = playerLayer, let videoView = videoView {
            playerLayer.frame = videoView.bounds
        }
        

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func addTimeObserver() {
        guard let player = player else {return}
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        _ = player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue, using: { [weak self] time in
            guard let currentItem = self?.player?.currentItem else {return}
            if currentItem.duration.seconds > 0 {
                self?.timeSlider.maximumValue = Float(currentItem.duration.seconds)
                self?.timeSlider.minimumValue = 0.0
                self?.timeSlider.value = Float(currentItem.currentTime().seconds)
                self?.currentTimeLabel.text = self?.getTimeString(from: currentItem.currentTime())
            }
        })
    }
    
    
    @IBAction func playPressed(_ sender: UIButton) {
        guard let player = player else {return}
        if isVideoPlaying {
            player.pause()
            sender.setImage(#imageLiteral(resourceName: "play_button").withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            player.play()
            sender.setImage(#imageLiteral(resourceName: "stop").withRenderingMode(.alwaysTemplate), for: .normal)
        }
        
        isVideoPlaying = !isVideoPlaying
    }
    
    @IBAction func forwardPressed(_ sender: UIButton) {
        guard let player = player else {return}
        guard let duration = player.currentItem?.duration else {return}
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = currentTime + 10.0
        
        if newTime < (CMTimeGetSeconds(duration) - 10.0) {
            let time: CMTime = CMTimeMake(Int64(newTime * 1000), 1000)
            player.seek(to: time)
        }
    }
    
    @IBAction func backwardPressed(_ sender: UIButton) {
        guard let player = player else {return}
        let currentTime = CMTimeGetSeconds(player.currentTime())
        var newTime = currentTime - 10.0
        
        if newTime < 0 {
            newTime = 0
        }
        let time: CMTime = CMTimeMake(Int64(newTime * 1000), 1000)
        player.seek(to: time)
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        guard let player = player else {return}
        player.seek(to: CMTimeMake(Int64(sender.value * 1000), 1000))
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = player else {return}
        if keyPath == "duration", let duration = player.currentItem?.duration.seconds, duration > 0.0 {
            self.durationTimeLabel.text = getTimeString(from: player.currentItem!.duration)
        }
    }
    
    @objc func hideButtons() {
        let isLandscaping =  UIDevice.current.orientation.isLandscape
        if isLandscaping {
            buttonIsHide = !buttonIsHide
        } else {
            buttonIsHide = false
        }
        sliderStackView.isHidden = buttonIsHide
        buttonsStackView.isHidden = buttonIsHide
    }
    
    func getTimeString(from time: CMTime) -> String {
        let totalSeconds = CMTimeGetSeconds(time)
        let hours = Int(totalSeconds/3600)
        let minutes = Int(totalSeconds/60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i", arguments: [hours, minutes, seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes, seconds])
        }
    }
    
    
    @IBAction func pressedSearchButton(_ sender: UIButton) {
        guard urlTextField.text != nil else {return}
        guard let url = URL(string:urlTextField.text!) else {return}
        playVideo(fromUrl: url)
    }
    
    func playVideo(fromUrl url: URL){
        if let lastPlayer = player, let lastPlayerLayer = playerLayer {
            lastPlayer.pause()
            lastPlayerLayer.removeFromSuperlayer()
        }
        player = AVPlayer(url: url)
        player?.currentItem?.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
        addTimeObserver()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        videoView.layer.addSublayer(playerLayer)
        playerLayer.frame = videoView.bounds
        player?.play()
        playButton.setImage(#imageLiteral(resourceName: "stop").withRenderingMode(.alwaysTemplate), for: .normal)
        urlTextField.endEditing(true)
        videoPlaceHolderLabel.isHidden = true
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        buttonsStackView.layoutIfNeeded()
        sliderStackView.layoutIfNeeded()
        setupRotateConstraint()
    }
    
    func setupRotateConstraint() {
        let isLandscaping =  UIDevice.current.orientation.isLandscape
        urlTextField.isHidden = isLandscaping
        searchButton.isHidden = isLandscaping
        print(isLandscaping)
        navigationController?.navigationBar.isHidden = isLandscaping
        if isLandscaping {
            screeenButton.setImage(#imageLiteral(resourceName: "full_screen_exit").withRenderingMode(.alwaysTemplate), for: .normal)
            buttons.forEach {
                $0.tintColor = UIColor.white
            }
            durationTimeLabel.textColor = UIColor.white
            currentTimeLabel.textColor = UIColor.white
        } else {
            screeenButton.setImage(#imageLiteral(resourceName: "full_screen_button").withRenderingMode(.alwaysTemplate), for: .normal)
            buttons.forEach {
                $0.tintColor = UIColor.black
            }
            durationTimeLabel.textColor = UIColor.black
            currentTimeLabel.textColor = UIColor.black
        }
    }
    
    func setupBasicLayout() {
        navigationController?.navigationBar.barTintColor = UIColor(red: 63.0/255, green: 81.0/255, blue: 181.0/255, alpha: 1.0)
        let textAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        searchButton.backgroundColor = .clear
        searchButton.layer.cornerRadius = 5
        searchButton.layer.borderWidth = 1
        searchButton.layer.borderColor = UIColor.gray.cgColor
        buttons = [soundButton, backwardButton, playButton, forwardButton, screeenButton]
        buttons.forEach {
            $0.imageView?.contentMode = UIViewContentMode.scaleAspectFill
            let tintedImage = $0.imageView?.image?.withRenderingMode(.alwaysTemplate)
            $0.setImage(tintedImage, for: .normal)
        }
        setupRotateConstraint()
    }
    
    
    @IBAction func pressedSoundButton(_ sender: UIButton) {
        guard let player = player else {return}
        isMuted = !isMuted
        player.isMuted = isMuted
        if isMuted {
            sender.setImage(#imageLiteral(resourceName: "volume_off").withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            sender.setImage(#imageLiteral(resourceName: "volume_up").withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    @IBAction func pressedScreenButton(_ sender: UIButton) {
        let isLandscaping =  UIDevice.current.orientation.isLandscape
        if isLandscaping {
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            sender.setImage(#imageLiteral(resourceName: "full_screen_button").withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
            sender.setImage(#imageLiteral(resourceName: "full_screen_exit").withRenderingMode(.alwaysTemplate), for: .normal)
        }
    }
    
    
    
    //TODO
    //handling of send invalid url again while playing
    
    
    
}


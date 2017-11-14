//
//  ViewController.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/30/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import VisheoVideo
import Lottie

class ViewController: UIViewController
{
	let renderer = VisheoRenderer();
	var lotView: LOTAnimationView!;
	var writer: AVAssetWriter!;
	var input: AVAssetWriterInput!;
	var adapter: AVAssetWriterInputPixelBufferAdaptor!;
	let queue = DispatchQueue(label: "queue", qos: DispatchQoS.default);
	
	@IBOutlet weak var statusLabel: UILabel!
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated);

//		let path = Bundle.main.path(forResource: "data1", ofType: "json");
//		container = LOTAnimationView(filePath: path!);
//		container?.frame = view.bounds;
//		view.insertSubview(container!, at: 0)

//		view.layer.insertSublayer(layer, at: 0);
		
		NotificationCenter.default.addObserver(self, selector: #selector(ViewController.markStart), name: NSNotification.Name(rawValue: "start"), object: nil);
		NotificationCenter.default.addObserver(self, selector: #selector(ViewController.markEnd(n:)), name: NSNotification.Name(rawValue: "finished"), object: nil);
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	@objc func markStart()
	{
		DispatchQueue.main.async {
			self.statusLabel.text = "Started render"
		}
	}

	@objc func markEnd(n: Notification)
	{
		DispatchQueue.main.async {
			let diff = (n.userInfo?["time"] as? NSNumber)?.doubleValue ?? 0.0;
			self.statusLabel.text = "Finished render in \(round(diff)) seconds"
		}
	}
	
	enum BufferFetchResult
	{
		case finish
		case skip
		case buffer(buffer: CVPixelBuffer, time: CMTime)
	}
	
	
	func animate()
	{
		let frame = CGRect(origin: .zero, size: CGSize(width: 480.0, height: 480.0));
		
		let path =  Bundle.main.path(forResource: "data1", ofType: "json");
		lotView = LOTAnimationView(filePath: path!)
		lotView.frame = frame;
		
		view.insertSubview(lotView, at: 0);
		
		lotView.play();
	}
	
	
	func render()
	{
		let cover = Bundle.main.path(forResource: "38167065_xxl", ofType: "jpg")!;
		
		var photos = [URL]();
		
		for i in 16...20
		{
			let path = Bundle.main.path(forResource: "Image \(i)", ofType: "jpg")!;
			photos.append(URL(fileURLWithPath: path));
		}
		
		let video = Bundle.main.path(forResource: "video", ofType: "mp4")!;
		let audio = Bundle.main.path(forResource: "beginning", ofType: "m4a")!;
		
		let task = VisheoRenderTask(id: "3434534",
		                            cover: URL(fileURLWithPath: cover),
		                            photos: photos,
		                            video: URL(fileURLWithPath: video),
		                            audio: URL(fileURLWithPath: audio));
		
		renderer.render(task: task);
	}
	

	@IBAction func action(_ sender: Any) 
	{
		render()
//		animate()
	}
}


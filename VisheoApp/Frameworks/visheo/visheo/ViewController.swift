//
//  ViewController.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/30/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import UIKit
import VisheoVideo

class ViewController: UIViewController
{
	let renderQueue = RenderQueue()
	
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
		
		var task = RenderTask(quality: .res720);
		
		task.addMedia(URL(fileURLWithPath: cover), type: .cover);
		task.addMedia(photos, type: .photo);
		task.addMedia(URL(fileURLWithPath: video), type: .video);
		task.addMedia(URL(fileURLWithPath: audio), type: .audio);
		
		renderQueue.enqueue(task);
	}
	

	@IBAction func action(_ sender: Any) 
	{
		render()
//		animate()
	}
}


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

class ViewController: UIViewController
{
	let renderer = VisheoRenderer();
	
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(animated);
		// Do any additional setup after loading the view, typically from a nib.
		
		
		
//		let result = animator!.prepareMotionLayer();
//
//		view.layer.addSublayer(result.parent);
//		result.animatable.add(result.animation, forKey: "animation");
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	
	func animate()
	{
				let layer = CustomAnimatable();
		//
				layer.frame = view.bounds;
				layer.backgroundColor = UIColor.magenta.cgColor;
		//
				view.layer.insertSublayer(layer, at: 0);
		
		CATransaction.begin()
		CATransaction.setDisableActions(true);
		CATransaction.setAnimationDuration(2.2);
		
		let anim = CABasicAnimation(keyPath: "brightness");
		
		anim.duration = 10.0;
		anim.fromValue = 1.0;
		//		anim.fillMode = kCAFillModeBoth;
//		anim.beginTime = AVCoreAnimationBeginTimeAtZero;
		//		anim.repeatCount = 1;
		anim.toValue = 0.0;
		anim.isRemovedOnCompletion = false;
		
		CATransaction.commit();
		
		layer.add(anim, forKey: "anim")
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


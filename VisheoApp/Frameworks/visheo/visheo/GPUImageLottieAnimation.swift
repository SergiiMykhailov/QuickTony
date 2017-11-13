//
//  GPUImageLottieAnimation.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/10/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import GPUImage
import Lottie
import pop
import CoreGraphics


class GPUImageLottieAnimation: GPUImageUIElement
{
	let lottieView: LOTAnimationView;
	
	var currentTime: CMTime;
	let startFrame: Int;
	let endFrame: Int;
	let frameRate: Int;
	var currentFrame: Int;
	
	var completionBlock: (() -> Void)?;
	
	
	init(animationView: LOTAnimationView)
	{
		lottieView = animationView;
		
		startFrame = animationView.sceneModel?.startFrame?.intValue ?? 0;
		endFrame = animationView.sceneModel?.endFrame?.intValue ?? 0;
		frameRate = animationView.sceneModel?.framerate?.intValue ?? 0;
		
		currentFrame = startFrame;
		currentTime = kCMTimeZero;
		
		super.init(view: animationView);
	}
	
	
	func renderFrame()
	{
		if (currentFrame > endFrame) {
			completionBlock?();
			return;
		}
		
		runSynchronouslyOnVideoProcessingQueue { [unowned self] in
			self.lottieView.setProgressWithFrame(NSNumber(value: self.currentFrame));
			self.update(withTimestamp: self.currentTime)
		}
	}
	
	
	func incrementFrame()
	{
		if (currentFrame + 1 > endFrame) {
			completionBlock?();
			return;
		}
		
		runSynchronouslyOnVideoProcessingQueue {  [unowned self] in
			
			let frameDuration = CMTimeMake(1, Int32(self.frameRate));
			
			self.currentFrame = self.currentFrame + 1;
			self.currentTime = CMTimeAdd(self.currentTime, frameDuration);
			
			self.renderFrame();
		}
	}
	
	
//	func renderWithCompletion(_ completion: @escaping () -> Void)
//	{
//		let
//		let
//		let
//
//
//
//		runAsynchronouslyOnVideoProcessingQueue
//		{
//			var time = CMTimeMake(0, Int32(frameRate));
//
//			for i in startFrame...endFrame
//			{
//				self.lottieView.setProgressWithFrame(NSNumber(value: i));
//				self.update(withTimestamp: time);
//			}
//
//			time = CMTimeAdd(time, frameDuration);
//
//			completion()
//		}
//	}
}

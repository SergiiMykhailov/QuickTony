//
//  VideoThumbnailExtractor.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/30/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation
import UIKit.UIImage


enum VideoThumbnailExtractorError: Error
{
	case invalidAsset(at: URL);
	case other(error: Error)
}


enum VideoAssetFrame
{
	case first
	case last
	case seconds(TimeInterval)
	case time(CMTime)
}


final class VideoThumbnailExtractor
{
	typealias ExtractionResult = (frame: VideoAssetFrame, image: UIImage, time: CMTime)
	
	private lazy var queue = DispatchQueue(label: "com.visheo.extractor", attributes: .concurrent);
	
	
	init(){}
	
	
	/// Attempts to generate thumbnails for specified frames from an asset at given url. The actual time of the generated thumbnails will be within the range [frame time - tolerance, frame time + tolerance].
	///
	/// - Parameters:
	///   - assetURL: Video file URL
	///   - frames: An array of VideoAssetFrame, specifying the asset times at which the thumbnails are requested
	///   - tolerance: The tolerance allowed before and after frame time
	///   - completion: A block that is called when thumbnail requests are complete.
	func generateThumbnails(asset: AVURLAsset, frames: [VideoAssetFrame], tolerance: CMTime? = nil,
	                        completion: @escaping (Result<[ExtractionResult]>) -> Void)
	{
		queue.async { [weak self] in
			
			guard let me = self else { return }
			
			do
			{
				let tracks = asset.tracks(withMediaType: .video);
				
				guard let track = tracks.first else {
					throw VideoThumbnailExtractorError.invalidAsset(at: asset.url);
				}
				
				let generator = try me.generator(for: asset, tolerance: tolerance);
				
				var results = [ExtractionResult]()
				
				for frame in frames
				{
					let time = me.convertToTime(frame: frame, videoTrackDuration: track.timeRange.end);
					
					let thumbnail = try me.generateThumbnailAt(time: time, generator: generator);
					
					let result = ExtractionResult(frame: frame, image: thumbnail.image, time: thumbnail.time);
					results.append(result);
				}
				
				completion(.success(value: results))
			}
			catch (let error) {
				let e = VideoThumbnailExtractorError.other(error: error);
				completion(.failure(error: e));
			}
		}
	}
	
	
	private func generateThumbnailAt(time: CMTime, generator: AVAssetImageGenerator) throws -> (image: UIImage, time: CMTime)
	{
		var generatedTime: CMTime = kCMTimeInvalid;
		let cgImage = try generator.copyCGImage(at: time, actualTime: &generatedTime);
		print("rqTime \(CMTimeGetSeconds(time)), act \(CMTimeGetSeconds(generatedTime))")
		let image = UIImage(cgImage: cgImage);
		return (image, generatedTime);
	}
	
	
	private func generator(for asset: AVURLAsset, tolerance: CMTime? = nil) throws -> AVAssetImageGenerator
	{
		var generatorTolerance: CMTime = kCMTimePositiveInfinity;
		
		switch tolerance
		{
			case .some(let value):
				generatorTolerance = value;
			case .none where asset.providesPreciseDurationAndTiming:
				generatorTolerance = kCMTimeZero;
			default:
				break;
		}
		
		let generator = AVAssetImageGenerator(asset: asset);
		generator.requestedTimeToleranceBefore = generatorTolerance;
		generator.requestedTimeToleranceAfter = generatorTolerance;
		
		return generator;
	}
	
	
	private func convertToTime(frame: VideoAssetFrame, videoTrackDuration duration: CMTime) -> CMTime
	{
		switch frame
		{
			case .first:
				return kCMTimeZero;
			case .last:
				return duration;
			case .seconds(let seconds):
				return CMTimeMakeWithSeconds(seconds, duration.timescale);
			case .time(let time):
				return time;
		}
	}
}

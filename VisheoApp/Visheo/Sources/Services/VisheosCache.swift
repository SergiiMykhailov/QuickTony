//
//  VisheosCache.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol VisheosCache {
    func localUrl(for visheoId: String) -> URL?
    func downloadVisheo(with id: String, remoteUrl: URL)
}

class VisheosLocalCache : VisheosCache {
    func localUrl(for visheoId: String) -> URL? {
        let renderingUrl = VisheoRenderingAssets.videoRenderingUrl(for: visheoId)
        if FileManager.default.fileExists(atPath: renderingUrl.path) {
            return renderingUrl
        }
        
        if FileManager.default.fileExists(atPath: cacheUrl(for: visheoId).path) {
            return cacheUrl(for: visheoId)
        }
        
        return nil
    }
    
    func downloadVisheo(with id: String, remoteUrl: URL) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
       let task = session.downloadTask(with: remoteUrl) { (location, response, error) in
            if let location = location {
                self.store(location: location, for: id)
            }
        }
        
        task.resume()
    }
    
    private func cacheUrl(for id: String) -> URL {
        let cachesUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesUrl.appendingPathComponent(id).appendingPathComponent("video.mov")
    }
    
    private func store(location: URL, for id: String) {
        do {
            if FileManager.default.fileExists(atPath: cacheUrl(for: id).path) {
                try FileManager.default.removeItem(at: cacheUrl(for: id))
            } else {
                
                let directory = cacheUrl(for: id).deletingLastPathComponent()
                if !FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                }
            }
            try FileManager.default.moveItem(at: location, to: cacheUrl(for: id))
        }
        catch {
            //Ignore error and retry caching next time
        }
    }
    
}

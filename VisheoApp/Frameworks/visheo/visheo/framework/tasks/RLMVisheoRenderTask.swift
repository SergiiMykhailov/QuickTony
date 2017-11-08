//
//  RLMVisheoRenderTask.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import RealmSwift

final class RLMVisheoRenderTask: Object
{
	@objc dynamic var id: String = "";
	@objc dynamic var cover: String = "";
	let photos = List<String>()
	@objc dynamic var video: String = ""
	@objc dynamic var audio: String = ""
	@objc dynamic var quality: Int = 0;
}

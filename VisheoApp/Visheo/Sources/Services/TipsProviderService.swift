//
//  TipsService.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Firebase

struct PracticeTip: Decodable {
	let title: String
	let text: String
	
	private enum CodingKeys: String, CodingKey {
		case title
		case text
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self);
		title = try container.decode(String.self, forKey: .title);
		text = try container.decode(String.self, forKey: .text);
	}
}


extension Notification.Name {
	static let practiceTipsDidChange = Notification.Name("practiceTipsDidChangeNotification")
}


protocol TipsProviderService: class {
	var practiceTips: [PracticeTip] { get }
}


class VisheoTipsProviderService: TipsProviderService {
	var practiceTips: [PracticeTip] {
		return _practicesRecords;
	}

	private let practicesRef: DatabaseReference;
	private var _practicesRecords: [PracticeTip] = []
	
	init() {
		practicesRef = Database.database().reference().child("practices")
		loadPractices();
	}

	private func loadPractices() {
		practicesRef.observe(.value) { [weak self] (snapshot) in
			guard let practices = snapshot.value as? [Any] else {return}
			do {
				let data = try JSONSerialization.data(withJSONObject: practices, options: JSONSerialization.WritingOptions(rawValue: 0))
				self?._practicesRecords = try JSONDecoder().decode([PracticeTip].self, from: data);
				NotificationCenter.default.post(name: .practiceTipsDidChange, object: nil);
			} catch (let error) {
				print("ERROR! \(error)")
			}
		}
	}
}

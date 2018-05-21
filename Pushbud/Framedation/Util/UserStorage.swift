//
//  UserStorage.swift
//  Pushbud
//
//  Created by Daria.R on 15.08.2017.
//  Copyright © 2016 meQuire AS. All rights reserved.
//

import Foundation

class UserStorage {

	static let shared = UserStorage()

    private let data = UserDefaults.standard
    
    var isPopularTagsDialogAvailable: Bool {
        guard let date = self.data.object(forKey: StorageConstants.keyHidePopularTagsDialog) as? Date else { return true }

        return date < Date()
    }
    
    var lastUserLocation: String? {
        return self.data.object(forKey: StorageConstants.keyLastUserLocation) as? String
    }
    
	// MARK: - Utility
	public func store(object: Any?, forKey key: String) {
		self.data.set(object, forKey: key)
        self.data.synchronize()
	}
    
    public func remove(forKey key: String) {
        self.data.removeObject(forKey: key)
        self.data.synchronize()
    }

}

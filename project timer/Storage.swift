//
//  Storage.swift
//  project timer
//
//  Created by 4 on '24.12.8.
//

import Foundation

enum Key: String {
    case lastStartTime = "lastStartTime"
    case lastEndTime = "lastEndTime"
}

struct Storage {
    static func getDate(of key: Key) -> Date {
        let timeElapsed = getDouble(for: key)
        return Date.init(timeIntervalSinceReferenceDate: timeElapsed)
    }
    
    static func storeDate(of key: Key, _ date: Date) {
        let timeElapsed = date.timeIntervalSinceReferenceDate
        UserDefaults.standard.set(timeElapsed, forKey: key.rawValue)
    }
    
    static func getDouble(for key: Key) -> Double {
        UserDefaults.standard.double(forKey: key.rawValue)
    }
}

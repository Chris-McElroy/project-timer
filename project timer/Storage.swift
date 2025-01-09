//
//  Storage.swift
//  project timer
//
//  Created by 4 on '24.12.8.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseDatabase

enum Key: String {
    case lastStartTime = "lastStartTime"
    case lastEndTime = "lastEndTime"
    case uuid = "uuid"
}

class Storage: ObservableObject {
    static let main: Storage = Storage()
    
    @Published var lastStartTime: Date
    @Published var lastEndTime: Date
    
    var ref: DatabaseReference!
    var myID: String = Storage.string(.uuid) ?? "00000000000000000000000000000000"
    
    init() {
        ref = Database.database().reference()
        lastStartTime = Storage.getDate(of: .lastStartTime)
        lastEndTime = Storage.getDate(of: .lastEndTime)
        _ = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                Storage.set(user.uid, for: .uuid)
                self.myID = user.uid
            } else {
                // should only happen once, when i first use the app
                Auth.auth().signInAnonymously() { (authResult, error) in
                    if let error = error {
                        print("Sign in error:", error)
                    }
                }
            }
        }
        _ = ref.observe(DataEventType.value, with: { snapshot in
            if let dict = snapshot.value as? [String: [String: Double]] {
                guard let mostRecent = dict.max(by: { l, r in
                    // TODO test this once 4 has it too!
                    if l.value[Key.lastStartTime.rawValue] == r.value[Key.lastStartTime.rawValue] {
                        return (l.value[Key.lastEndTime.rawValue] ?? 0) > (r.value[Key.lastEndTime.rawValue] ?? 0)
                    }
                    return (l.value[Key.lastStartTime.rawValue] ?? 0) < (r.value[Key.lastStartTime.rawValue] ?? 0)
                }) else { return }
                if mostRecent.key != self.myID {
                    if let newStart = mostRecent.value[Key.lastStartTime.rawValue], newStart != self.lastStartTime.timeIntervalSinceReferenceDate {
                        self.lastStartTime = Date.init(timeIntervalSinceReferenceDate: newStart)
                        self.storeDate(of: .lastStartTime, self.lastStartTime)
                    }
                    if let newEnd = mostRecent.value[Key.lastEndTime.rawValue], newEnd != self.lastEndTime.timeIntervalSinceReferenceDate {
                        self.lastEndTime = Date.init(timeIntervalSinceReferenceDate: newEnd)
                        self.storeDate(of: .lastEndTime, self.lastEndTime)
                    }
                }
            }
        })
    }
    
    func storeDate(of key: Key, _ date: Date) {
        let timeElapsed = date.timeIntervalSinceReferenceDate
        UserDefaults.standard.set(timeElapsed, forKey: key.rawValue)
        ref.child(myID).child(key.rawValue).setValue(timeElapsed)
    }
    
    func storeDates() {
        let startDouble = lastStartTime.timeIntervalSinceReferenceDate
        let endDouble = lastEndTime.timeIntervalSinceReferenceDate
        UserDefaults.standard.set(startDouble, forKey: Key.lastStartTime.rawValue)
        UserDefaults.standard.set(endDouble, forKey: Key.lastEndTime.rawValue)
        ref.child(myID).setValue([Key.lastStartTime.rawValue: startDouble, Key.lastEndTime.rawValue: endDouble])
    }
    
    static func set(_ value: Any?, for key: Key) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }
    
    static func string(_ key: Key) -> String? {
        UserDefaults.standard.string(forKey: key.rawValue)
    }
    
    private static func getDate(of key: Key) -> Date {
        let timeElapsed = getDouble(for: key)
        return Date.init(timeIntervalSinceReferenceDate: timeElapsed)
    }
    private static func getDouble(for key: Key) -> Double {
        UserDefaults.standard.double(forKey: key.rawValue)
    }
}

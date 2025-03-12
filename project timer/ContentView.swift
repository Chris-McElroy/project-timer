//
//  ContentView.swift
//  project timer
//
//  Created by 4 on '24.12.5.
//

import SwiftUI

let yellow: Color = Color(hue: 45/360, saturation: 0.98, brightness: 0.90)
let purple: Color = Color(hue: 280/360, saturation: 1, brightness: 0.7)
let cyan: Color = Color(hue: 200/360, saturation: 1, brightness: 0.7)
let brown: Color = Color(hue: 33/360, saturation: 1, brightness: 0.4)


struct ContentView: View {
    @ObservedObject var storage: Storage = Storage.main
    @State var update = false
    @State var projectTapped: Int? = nil
    @State var consumeTapped: Int? = nil // TODO this is not the right way to handle it cuz it fails if it's not tapped
    let height: Double = 480 // TODO animate fade-ins when project active and things change (borders and stuff)
    let width: Double = 90
    
    var body: some View {
        HStack(spacing: width) {
            timerStack(project: false)
            timerStack(project: true)
        }
        .padding(.all, update ? 1 : 1)
        .font(.custom("Baskerville", size: 20))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { _ in
                update.toggle()
            })
        }
    }
    
    func timerStack(project: Bool) -> some View {
        VStack {
            Text(storage.available(project) ? " " : getDateString(storage.start(project)))
            ZStack {
                if !storage.cooldown(project) {
                    VStack {
                        Text(getTimeString(storage.activeSpent(project)))
                        Spacer()
                    }
                    ForEach(0..<5) { n in
                        VStack(spacing: 0) {
                            Spacer().frame(height: storage.active(project) ? nil : (Double(n + 1)*height/6.0 - 20.0))
                            Text(getTimeString(storage.activeRemaining(project)))
                                .frame(height: 40)
                                .opacity((project ? (projectTapped ?? n == n) : (consumeTapped ?? n == n)) ? 1 : 0)
                            Spacer().frame(height: storage.active(project) ? 0 : nil)
                        }
                    }
                } else {
                    Text(" ")
                }
            }
            .frame(width: width, height: height)
            .background {
                VStack {
                    Spacer().frame(height: height*storage.activeRatio(project))
                    (project ? yellow : brown)
                }
                .animation(.linear(duration: 0.2), value: update)
            }
            .padding(4)
            .border((project ? yellow : brown).opacity(getActiveOpacity(project)), width: 4)
            Text(getDateString(storage.available(project) ? Date.now.timeIntervalSinceReferenceDate : storage.end(project)))
            VStack {
                if storage.cooldown(project) {
                    Text(getTimeString(storage.cooldownSpent(project)))
                    Spacer()
                    Text(getTimeString(storage.cooldownRemaining(project)))
                } else { Spacer() }
            }
            .frame(width: width, height: width)
            .background {
                VStack {
                    Spacer().frame(height: width*storage.cooldownRatio(project))
                    (project ? purple : cyan)
                }
            }
            .padding(4)
            .border((project ? purple : cyan).opacity(getCooldownOpacity(project)), width: 4)
            Text(getDateString(storage.available(project) ? Date.now.timeIntervalSinceReferenceDate : storage.cooldownEnd(project)))
        }
    }
    
    func getActiveOpacity(_ project: Bool) -> Double {
        if storage.active(project) {
            return 0.75
        } else if storage.cooldown(project) {
            return 0.5
        } else {
            return 1.0
        }
    }
    
    func getCooldownOpacity(_ project: Bool) -> Double {
        if storage.active(project) {
            return 1.0
        } else if storage.cooldown(project) {
            return 0.75
        } else {
            return 0.5
        }
    }
    
    func getTimeString(_ time: TimeInterval) -> String {
        let s = Int(time.rounded(.down))
        if s >= 60 {
            let hour: String = s >= 3600 ? String(s/3600) + "." : ""
            let min: String = String((s % 3600)/60)
            return hour + min + "m"
        } else {
            return String(s) + "s"
        }
    }
    
    func getDateString(_ date: Date) -> String {
        let dc = Calendar.current.dateComponents([.hour, .minute], from: date)
        return "," + String(dc.hour ?? 0) + "." + String(dc.minute ?? 0)
    }
    
    func getDateString(_ date: TimeInterval) -> String {
        let dc = Calendar.current.dateComponents([.hour, .minute], from: Date(timeIntervalSinceReferenceDate: date))
        return "," + String(dc.hour ?? 0) + "." + String(dc.minute ?? 0)
    }
}

extension String {
    func matches(_ regex: String) -> Bool {
        range(of: regex, options: .regularExpression) != nil
    }
}

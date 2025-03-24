//
//  ContentView.swift
//  cooldown timer
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
    @State var tapped: [Bool: Int?] = [false: Storage.main.consumeActive ? 4 : nil, true: Storage.main.projectActive ? 4 : nil]
    @State var timerOptions: [Bool: [Double]] = [false: [3600, 1800, 900, 180, 60], true: [3600, 1800, 900, 180, 60]]
    @State var consumeTimerHeights: [Double] = [100, 100, 100, 100, 120]
    @State var projectTimerProgress: Double = 0
    @State var projectTimerHeights: [Double] = [100, 200, 300, 350, 20]
    @State var cancel: Bool? = nil
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
        .onTapGesture {
            if cancel != nil { cancel = nil }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                if storage.projectAvailable { tapped[true] = nil }
                if storage.consumeAvailable { tapped[false] = nil }
                update.toggle()
            })
        }
        .onChange(of: storage.projectEnd, {
//            projectTimerProgress = 0 // TODO idk when the fuck to set this, maybe have two or something
            projectTimerProgress = 1
            if storage.projectActive {
                if tapped[true] == nil { tapped[true] = 4 }
                projectTimerHeights = Array(repeating: 30, count: 5)
            } else {
                tapped[true] = nil
                projectTimerHeights = Array(repeating: 350, count: 5)
            }
        })
        .onChange(of: storage.consumeEnd, {
            if storage.consumeActive {
                if tapped[false] == nil { tapped[false] = 4 }
            } else {
                tapped[false] = nil
            }
        })
        
    }
    
    func timerStack(project: Bool) -> some View {
        VStack {
            Text(storage.available(project) ? " " : getDateString(storage.start(project)))
            ZStack {
                if !storage.cooldown(project) {
                    VStack {
                        Spacer().frame(height: max(0, height*(storage.activeRatio(project))/2.0 - 15))
                        Text(getTimeString(storage.activeSpent(project)))
                            .opacity(storage.available(project) ? 0 : 1)
                        Spacer()
                    }
                    ForEach(0..<5) { n in
                        VStack(spacing: 0) {
                            Spacer().frame(height: (tapped[project] != nil || storage.active(project)) ? nil : (Double(n + 1)*height/6.0 - 15))
                            Text(getTimeString(storage.active(project) ? storage.activeRemaining(project) : timerOptions[project]?[n] ?? 0))
                                .frame(height: 30)
                                .opacity(((tapped[project] ?? n) ?? n == n) ? 1 : 0)
                                .gesture(setTimeGesture(project, n))
                            // TODO try longer animations that last the entire length of the period
                            // TODO it jumps awkwardly back up for a frame before starting cooldown
                            // TODO have total active time move down to center in active area when it's counting
                            Spacer().frame(height: project ? projectTimerHeights[n] : consumeTimerHeights[n])
                                .animation(.easeInOut(duration: 15.0), value: project ? projectTimerHeights : consumeTimerHeights) // TODO be more intentional about what i actually want to see
//                            Spacer().frame(height: (tapped[project] != nil || storage.active(project)) ? max(0, height*(1 - storage.activeRatio(project))/2.0 - 15) : nil)
                        }
                    }
                } else {
                    Text(" ")
                }
                    
            }
            .frame(width: width, height: height)
            .background {
                VStack {
                    Color.black.frame(height: height*projectTimerProgress)
                    (project ? yellow : brown)
                }
                .animation(.linear(duration: projectTimerProgress == 0 ? 0.4 : storage.projectActiveRemaining), value: projectTimerProgress)
            }
            .padding(4)
            .border((project ? yellow : brown).opacity(getActiveOpacity(project)), width: 4)
            .shadow(color: project ? yellow : brown, radius: cancel == project ? 30 : 0)
            .onTapGesture {
                if cancel != nil { cancel = nil }
                else if storage.active(project) && cancel == nil { cancel = project }
            }
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
                    Color.black.frame(height: width*storage.cooldownRatio(project))
                    (project ? purple : cyan)
                }
            }
            .padding(4)
            .border((project ? purple : cyan).opacity(getCooldownOpacity(project)), width: 4)
            .onTapGesture {
                if cancel == project {
                    cancel = nil
                    // TODO with animation most likely
                    if project {
                        storage.projectEnd = Date.now.timeIntervalSinceReferenceDate
                        storage.storeDate(of: .projectEnd, storage.projectEnd)
                    } else {
                        storage.consumeEnd = Date.now.timeIntervalSinceReferenceDate
                        storage.storeDate(of: .consumeEnd, storage.consumeEnd)
                    }
                } else {
                    cancel = nil
                }
            }
            Text(getDateString(storage.available(project) ? Date.now.timeIntervalSinceReferenceDate : storage.cooldownEnd(project)))
        }
    }
    
    func setTimeGesture(_ project: Bool, _ n: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded({ _ in
                if cancel != nil { cancel = nil; return }
                else if storage.active(project) && cancel == nil { cancel = project; return }
                guard storage.available(project) else { return }
                if project {
                    storage.projectStart = Date.now.timeIntervalSinceReferenceDate
                    storage.projectEnd = storage.projectStart + (timerOptions[project]?[n] ?? 0)
                    storage.storeProjectDates()
                } else {
                    storage.consumeStart = Date.now.timeIntervalSinceReferenceDate
                    storage.consumeEnd = storage.consumeStart + (timerOptions[project]?[n] ?? 0)
                    storage.storeConsumeDates()
                }
            })
            .onChanged({ a in
                // TODO add something to cancel on first tap and note within the gesture that i should stop taking anything into account
            })
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

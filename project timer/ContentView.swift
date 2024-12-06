//
//  ContentView.swift
//  project timer
//
//  Created by 4 on '24.12.5.
//

import SwiftUI


struct ContentView: View {
    @State var lastStartTime: Date = .distantPast
    @State var lastEndTime: Date = .distantPast
    @State var possibleDuration: Int? = nil
    @State var possibleEndTime: (Int, Int)? = nil
    @State var setDuration = false
    @State var setEndTime = false
    @State var rounded = false
    @State var update = false
    @State var cancelVisible = false
    @State var fakeText: String = ""
    
    var body: some View {
        VStack {
            if lastEndTime + lastStartTime.distance(to: lastEndTime) > .now {
                timerActiveView
            } else if possibleDuration != nil || possibleEndTime != nil {
                timerStartView
            } else if setDuration {
                setDurationView
            } else if setEndTime {
                setEndTimeView
            } else {
                timerOptionsView
            }
        }
        .padding(.all, update ? 1 : 1)
        .buttonStyle(Bubble())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                update.toggle()
            })
        }
    }
    
    var timerActiveView: some View {
        VStack {
            Spacer().frame(height: 71)
            if lastEndTime > .now {
                Text(getDateString(lastEndTime))
                    .font(.system(size: 30))
                    .foregroundStyle(.yellow)
                Text(getProjectTimeString())
                    .font(.system(size: 30))
                    .foregroundStyle(.yellow)
            }
            HStack {
                Text(getMinimumCooldownTimeString())
                if lastEndTime > .now {
                    Text("–")
                    Text(getMaximumCooldownTimeString())
                }
            }
            .font(.system(size: lastEndTime > .now ? 18 : 30))
            .foregroundStyle(.purple)
            HStack {
                Text(getDateString(Date.now + lastStartTime.distance(to: .now)))
                if lastEndTime > .now {
                    Text("–")
                    Text(getDateString(lastEndTime + lastStartTime.distance(to: lastEndTime)))
                }
            }
            .font(.system(size: lastEndTime > .now ? 18 : 30))
            .foregroundStyle(.purple)
            Button(action: {
                withAnimation {
                    cancelVisible = false
                    lastEndTime = .now
                }
            }, label: {
                Text("cancel")
            })
            .opacity(cancelVisible && lastEndTime > .now ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            if lastEndTime > .now {
                cancelVisible.toggle()
            }
        }
    }
    
    var timerStartView: some View {
        let possibleProjectEnd: Date
        let possibleProjectDuration: TimeInterval
        
        if let possibleDuration {
            if rounded {
                let unroundedTime = Date.now + Double(possibleDuration)
                let hourStart = Calendar.current.dateInterval(of: .hour, for: unroundedTime)?.start ?? .now
                let timeSinceHour = hourStart.distance(to: unroundedTime)
                let timeToAdd = 900 - timeSinceHour.truncatingRemainder(dividingBy: 900)
                let newProjectTime = unroundedTime + timeToAdd
                possibleProjectEnd = newProjectTime
                possibleProjectDuration = Date.now.distance(to: possibleProjectEnd)
            } else {
                possibleProjectDuration = Double(possibleDuration)
                possibleProjectEnd = .now + possibleProjectDuration
            }
        } else if let possibleEndTime {
            let dc = Calendar.current.dateComponents([.hour, .minute], from: .now)
            let hour = (possibleEndTime.0 % 24)
            let minute = possibleEndTime.1
            let advanceDay = hour < (dc.hour ?? 0) || (hour == (dc.hour ?? 0) && minute <= (dc.minute ?? 0))
            if advanceDay {
                possibleProjectEnd = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now.addingTimeInterval(86400)) ?? .now
            } else {
                possibleProjectEnd = Calendar.current.date(bySettingHour: possibleEndTime.0, minute: possibleEndTime.1, second: 0, of: .now) ?? .now
            }
            possibleProjectDuration = Date.now.distance(to: possibleProjectEnd)
        } else {
            possibleProjectEnd = .now
            possibleProjectDuration = 0
        }
        
        return VStack {
            Spacer().frame(height: 71)
            Text(getDateString(possibleProjectEnd))
                .font(.system(size: 30))
                .foregroundStyle(.yellow)
            Text(getTimeString(possibleProjectDuration))
                .font(.system(size: 30))
                .foregroundStyle(.yellow)
            Text(getTimeString(possibleProjectDuration*2))
                .font(.system(size: 18))
                .foregroundStyle(.purple)
            Text(getDateString(possibleProjectEnd + possibleProjectDuration))
                .font(.system(size: 18))
                .foregroundStyle(.purple)
            Button(action: {
                withAnimation {
                    lastStartTime = .now
                    lastEndTime = .now + possibleProjectDuration
                    possibleDuration = nil
                    possibleEndTime = nil
                }
#if os(iOS)
                UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)
#endif
            }, label: {
                Text("start")
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            possibleDuration = nil
            possibleEndTime = nil
        }
    }
    
    var setDurationView: some View {
        // TODO this and end time need to be fixed up completely
        // see https://stackoverflow.com/questions/65545374/how-to-always-show-the-keyboard-in-swiftui and others for how to show the keyboard
        VStack {
            TextField(text: $fakeText) {
                Spacer()
            }.opacity(0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            setDuration = false
        }
    }
    
    var setEndTimeView: some View {
        VStack {
            TextField(text: $fakeText) {
                Text(fakeText)
                    .frame(width: 100, height: 60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            setEndTime = false
        }
    }
    
    var timerOptionsView: some View {
        VStack {
            HStack {
                timer(60)
                timer(120)
                timer(180)
            }
            HStack {
                timer(300)
                timer(600)
                timer(900)
            }
            HStack {
                timer(900)
                timer(1200)
                timer(1500)
            }
            HStack {
                timer(1800)
                timer(2700)
                timer(3600)
            }
            HStack {
                Button(action: {
                    setDuration = true
                }, label: {
                    Text(verbatim: "_._m")
                })
                Button(role: rounded ? .cancel : nil, action: {
                    rounded.toggle()
#if os(iOS)
                        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.3)
#endif
                }, label: {
                    Text("rounded")
                        .foregroundStyle(rounded ? .black : .white)
                }).selectionDisabled()
                Button(action: {
                    setEndTime = true
                }, label: {
                    Text(verbatim: ",_._")
                }).selectionDisabled()
            }
        }
    }
    
    func timer(_ time: Int) -> some View {
        Button(action: {
            possibleDuration = time
        }, label: {
            Text(String(time/60) + "m")
        }).selectionDisabled()
    }
    
    func getProjectTimeString() -> String {
        let diffInterval = Date.now.distance(to: lastEndTime)
        if diffInterval < 0 {
            return ""
        }
        return getTimeString(diffInterval)
    }
    
    func getMinimumCooldownTimeString() -> String {
        if lastEndTime > .now {
            let diffInterval = lastStartTime.distance(to: .now)
            if diffInterval < 0 { return "" }
            return getTimeString(diffInterval)
        } else {
            let diffInterval = Date.now.distance(to: lastEndTime + lastStartTime.distance(to: lastEndTime))
            if diffInterval < 0 { return "" }
            return getTimeString(diffInterval)
        }
    }
    
    func getMaximumCooldownTimeString() -> String {
        let diffInterval = lastStartTime.distance(to: lastEndTime)
        if diffInterval < 0 { return "" }
        return getTimeString(diffInterval)
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
    
    struct Bubble: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .frame(width: 100, height: 55)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 2)
                        .fill(configuration.role == .cancel ? .white : .clear)
                    
                }
                .padding(8)
                .background(.black)
        }
    }

}

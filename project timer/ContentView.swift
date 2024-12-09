//
//  ContentView.swift
//  project timer
//
//  Created by 4 on '24.12.5.
//

import SwiftUI

let pink: Color = Color(hue: 270/360, saturation: 1, brightness: 0.75)
let yellow: Color = Color(hue: 45/360, saturation: 0.98, brightness: 0.90)

struct ContentView: View {
    @State var lastStartTime: Date = Storage.getDate(of: .lastStartTime)
    @State var lastEndTime: Date = Storage.getDate(of: .lastEndTime)
    @State var possibleDuration: Int? = nil
    @State var possibleEndTime: (Int, Int)? = nil
    @State var setDuration = false
    @State var setEndTime = false
    @State var rounded = false
    @State var update = false
    @State var cancelVisible = false
    @State var durationText: String = ""
    @State var endTimeText: String = ""
    @State var show1mWarning: Bool = false
    @State var show15sWarning: CGFloat? = nil
    @State var projectActive: Bool = false
    @State var finalWarning: Bool = false // TODO fix too-quick transitions when time naturally runs out on either timer
    @FocusState var focusState: Bool
    
    var body: some View {
        VStack {
            if lastEndTime + lastStartTime.distance(to: lastEndTime) > .now {
                timerActiveView
            } else if setDuration {
                setDurationView
            } else if setEndTime {
                setEndTimeView
            } else if possibleDuration != nil || possibleEndTime != nil {
                timerStartView
            } else {
                timerOptionsView
            }
        }
        .padding(.all, update ? 1 : 1)
        .buttonStyle(Bubble())
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true, block: { _ in
                update.toggle()
            })
        }
        .onChange(of: update, {
            // TODO move all of this elsewhere, reorganize, probably into separate files.
            // TODO consider ways that i could be doing updates less often and interpolating, or do no animation whatsoever (probably better)
            //          test these options with energy managmenet to understand the tradeoffs
            let timeToEnd = Date.now.distance(to: lastEndTime)
            show1mWarning = (58.9..<60).contains(timeToEnd)
            if (7..<18).contains(timeToEnd) {
                show15sWarning = CGFloat(3000*(18 - timeToEnd)/11)
            } else if (3..<7).contains(timeToEnd) {
                show15sWarning = CGFloat(3000*(7 - timeToEnd)/4)
            } else if (0..<3).contains(timeToEnd) {
                show15sWarning = CGFloat(3000*(3 - timeToEnd)/3)
            } else if (-3..<0).contains(timeToEnd) {
                show15sWarning = 3000
            } else {
                show15sWarning = nil
            }
            if (0..<1).contains(timeToEnd) {
                finalWarning = true
            } else {
                finalWarning = false
            }
            
            projectActive = timeToEnd >= 0 || possibleDuration != nil || possibleEndTime != nil
        })
    }
    
    var timerActiveView: some View {
        let minCooldownString = getDateString(Date.now + lastStartTime.distance(to: .now))
        let maxCooldownString = getDateString(lastEndTime + lastStartTime.distance(to: lastEndTime))
        let cooldownString = (cancelVisible && projectActive) ? minCooldownString : maxCooldownString
        
        return ZStack {
            Rectangle() // TODO change this out to be a pink circle that comes out of the pink circle when it reaches the apex w 1 min to
                .fill(.shadow(.inner(color: Color(hue: 300/360, saturation: 0.75, brightness: 1), radius: 120)))
                .foregroundStyle(.black)
                .frame(width: UIScreen.main.bounds.width + 220, height: UIScreen.main.bounds.height + 220)
                .offset(y: -10)
                .opacity(show1mWarning ? 1 : 0)
                .animation(.easeInOut(duration: 1), value: show1mWarning)
            Circle()
                .foregroundStyle(RadialGradient(colors: [.black, Color(hue: 300/360, saturation: 0.75, brightness: 1, opacity: 0.3), Color(hue: 300/360, saturation: 0.75, brightness: 1, opacity: 0.3), .black], center: .center, startRadius: 1000 - (show15sWarning ?? 0), endRadius: 3000 - (show15sWarning ?? 0)))
                .frame(width: 1000, height: 1000)
                .opacity(show15sWarning != nil ? 1 : 0)
            if projectActive {
                Circle() // TODO redo all this animation and probably split this into 3 separate circles so i don't have to worry about the resetting issue
                // i want to be able to come in at any given time and have everything in a set place, and remove as many of these if {} setups as possible in the view
                    .fill(yellow)
                    .frame(width: finalWarning ? 0 : 250, height: finalWarning ? 0 : 250)
                    .animation(.linear(duration: 1), value: finalWarning)
                    .onAppear {
                        UIApplication.shared.isIdleTimerDisabled = true
                    }
                    .onDisappear {
                        UIApplication.shared.isIdleTimerDisabled = false
                    }
            }
            VStack {
                Spacer().frame(height: 171)
                Text(getDateString(lastEndTime))
                    .font(.custom("Baskerville", size: 36))
                    .foregroundStyle(.black)
                    .frame(height: 40)
                Text(getProjectTimeString())
                    .font(.custom("Baskerville", size: 48))
                    .foregroundStyle(.black)
                    .frame(height: 50)
                    .padding(.bottom, 5)
                Text((cancelVisible || !projectActive) ? getMinimumCooldownTimeString() : getMaximumCooldownTimeString())
                    .font(.custom("Baskerville", size: 30))
                    .foregroundStyle(pink)
                Text(cooldownString)
                    .font(.custom("Baskerville", size: 30))
                    .foregroundStyle(pink)
                Spacer().frame(height: 100)
                Button(action: {
                    withAnimation {
                        cancelVisible = false
                        lastEndTime = .now
                        Storage.storeDate(of: .lastEndTime, lastEndTime)
                    }
                }, label: {
                    Text("cancel")
                })
                .opacity(cancelVisible && lastEndTime > .now ? 1 : 0)
            }
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
        let proposedDuration: TimeInterval = getProposedDuration()
        return VStack {
            Spacer().frame(height: 150+13+77.5) // TODO make this actually be exaclty the same, hopefully more cleanly than guessing numbers
                // aha yes i should use more ZStacks that solves this
            // good
            // imma do that if i have time
            Text(getDateString(.now + proposedDuration))
                .font(.custom("Baskerville", size: 36))
                .foregroundStyle(yellow)
            Text(getTimeString(proposedDuration))
                .font(.custom("Baskerville", size: 48))
                .foregroundStyle(yellow)
                .padding(.bottom, 5)
            Text(getTimeString(proposedDuration*2))
                .font(.custom("Baskerville", size: 30))
                .foregroundStyle(pink)
            Text(getDateString(.now + proposedDuration*2))
                .font(.custom("Baskerville", size: 30))
                .foregroundStyle(pink)
            Spacer().frame(height: 77.5)
            Button(action: {
                startTimer(with: proposedDuration)
            }, label: {
                Text("start")
            })
            .padding(.bottom, 13)
            Button(role: rounded ? .cancel : nil, action: {
                rounded.toggle()
#if os(iOS)
                    UIImpactFeedbackGenerator().impactOccurred(intensity: 0.5)
#endif
            }, label: {
                Text("rounded")
                    .foregroundStyle(rounded ? .black : .white)
            })
            .selectionDisabled()
            .onAppear { rounded = false }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            possibleDuration = nil
            possibleEndTime = nil
        }
        .onAppear {
            print(finalWarning)
        }
    }
    
    var setDurationView: some View {
        let proposedDuration = getProposedDuration()
        return VStack {
            Spacer().frame(height: 71 + 77.5)
            Text(getDateString(.now + proposedDuration))
                .font(.custom("Baskerville", size: 36))
                .foregroundStyle(yellow)
            HStack(spacing: 0) {
                TextField("", text: $durationText)
                    .keyboardType(.decimalPad)
                    .focused($focusState)
                    .onAppear { focusState = true }
                    .multilineTextAlignment(.trailing)
                    .onChange(of: durationText, checkDurationText)
                    .frame(width: 90)
                Text("m")
            }
            .font(.custom("Baskerville", size: 48))
            .foregroundStyle(yellow)
            .padding(.bottom, 5)
            Text(getTimeString(proposedDuration*2))
                .font(.custom("Baskerville", size: 30))
                .foregroundStyle(pink)
            Text(getDateString(.now + proposedDuration*2))
                .font(.custom("Baskerville", size: 30))
                .foregroundStyle(pink)
            Spacer().frame(height: 77.5)
            Button(action: {
                if durationText != "" {
                    startTimer(with: proposedDuration)
                    setDuration = false
                }
            }, label: {
                Text("start")
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            setDuration = false
            possibleDuration = nil
            durationText = ""
        }
        .onAppear {
            durationText = ""
        }
    }
    
    var setEndTimeView: some View {
        let proposedDuration = getProposedDuration()
        return VStack {
            Spacer().frame(height: 71 + 77.5)
            HStack(spacing: 0) {
                Text(",")
                TextField("", text: $endTimeText)
                    .keyboardType(.decimalPad)
                    .focused($focusState)
                    .onAppear { focusState = true }
                    .multilineTextAlignment(.leading)
                    .onChange(of: endTimeText, checkEndTimeText)
                    .frame(width: 90)
            }
            .font(.custom("Baskerville", size: 36))
            .foregroundStyle(yellow)
            Text(getTimeString(proposedDuration))
                .font(.custom("Baskerville", size: 48))
                .foregroundStyle(yellow)
                .padding(.bottom, 5)
            Text(getTimeString(proposedDuration*2))
                .font(.custom("Baskerville", size: 30))
                .foregroundStyle(pink)
            Text(getDateString(.now + proposedDuration*2))
                .font(.custom("Baskerville", size: 30))
                .foregroundStyle(pink)
            Spacer().frame(height: 77.5)
            Button(action: {
                if endTimeText != "" {
                    startTimer(with: proposedDuration)
                    setEndTime = false
                }
            }, label: {
                Text("start")
            })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onTapGesture {
            setEndTime = false
            possibleEndTime = nil
            endTimeText = ""
        }
        .onAppear {
            endTimeText = ""
        }
    }
    
    var timerOptionsView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("project timer")
            Spacer()
            HStack {
                timer(10800)
                timer(7200)
                timer(3600)
            }
            HStack {
                timer(2700)
                timer(1800)
                timer(900)
            }
            HStack {
                timer(600)
                timer(450)
                timer(300)
            }
            HStack {
                timer(180)
                timer(120)
                timer(60)
            }
            HStack {
                Button(action: {
                    setDuration = true
                }, label: {
                    Text("__m")
                })
                Button(action: {
                    setEndTime = true
                }, label: {
                    Text(",__")
                }).selectionDisabled()
            }
            Spacer().frame(height: 50)
        }
        .font(.custom("Baskerville", size: 20))
    }
    
    func timer(_ time: Int) -> some View {
        Button(action: {
            possibleDuration = time
        }, label: {
            Text(time >= 3600 ? String(time/3600) + "h" : String(time/60) + (time % 60 == 0 ? "" : ".5") + "m")
        }).selectionDisabled()
    }
    
    func getProposedDuration() -> TimeInterval {
        if let possibleDuration {
            if rounded {
                let unroundedTime = Date.now + Double(possibleDuration)
                let hourStart = Calendar.current.dateInterval(of: .hour, for: unroundedTime)?.start ?? .now
                let timeSinceHour = hourStart.distance(to: unroundedTime)
                let timeToAdd = 900 - timeSinceHour.truncatingRemainder(dividingBy: 900)
                return Double(possibleDuration) + timeToAdd
            } else {
                return Double(possibleDuration)
            }
        } else if let possibleEndTime {
            let dc = Calendar.current.dateComponents([.hour, .minute], from: .now)
            let hour = (possibleEndTime.0 % 24)
            let minute = possibleEndTime.1
            let advanceDay = hour < (dc.hour ?? 0) || (hour == (dc.hour ?? 0) && minute <= (dc.minute ?? 0))
            let newEndTime: Date
            if advanceDay {
                newEndTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now.addingTimeInterval(86400)) ?? .now
            } else {
                newEndTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
            }
            return Date.now.distance(to: newEndTime)
        } else { return 0 }
    }
    
    func startTimer(with duration: TimeInterval) {
        withAnimation {
            lastStartTime = .now
            lastEndTime = .now + duration
            Storage.storeDate(of: .lastStartTime, lastStartTime)
            Storage.storeDate(of: .lastEndTime, lastEndTime)
            possibleDuration = nil
            possibleEndTime = nil
            focusState = false
        }
#if os(iOS)
        UIImpactFeedbackGenerator().impactOccurred(intensity: 0.7)
#endif
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
    
    func checkDurationText(old: String, new: String) {
        if new.matches("^[1-9][0-9]?\\.(([1-9][0-9])|[0-9])$") {
            let parts: [Int] = new.split(separator: ".").map { Int($0) ?? 0 }
            if parts.count != 2 { durationText = old; return }
            if !(1...12).contains(parts[0]) || !(0...59).contains(parts[1]) {
                durationText = old
                return
            }
            possibleDuration = 3600*parts[0] + 60*parts[1]
        } else if new.matches("^[1-9][0-9]?\\.$") {
            guard let n = Int(new.dropLast()) else { durationText = old; return }
            if !(1...12).contains(n) {
                durationText = old
                return
            }
            possibleDuration = 3600*n
        } else if new.matches("^[1-9][0-9]{,2}$") {
            guard let n = Int(new) else { durationText = old; return }
            if !(1...120).contains(n) {
                durationText = old
                return
            }
            possibleDuration = 60*n
        } else if new == "" {
            possibleDuration = 0
            return
        } else {
            durationText = old
        }
    }
    
    func checkEndTimeText(old: String, new: String) {
        if new.matches("^([0-9]|([1-9][0-9]?))\\.(([1-9][0-9])|[0-9])$") {
            let parts: [Int] = new.split(separator: ".").map { Int($0) ?? 0 }
            if parts.count != 2 { endTimeText = old; return }
            if !(0...48).contains(parts[0]) || !(0...59).contains(parts[1]) {
                endTimeText = old
                return
            }
            possibleEndTime = (parts[0], parts[1])
        } else if new.matches("^([0-9]|([1-9][0-9]?))\\.$") {
            guard let n = Int(new.dropLast()) else { endTimeText = old; return }
            if !(0...48).contains(n) {
                endTimeText = old
                return
            }
            possibleEndTime = (n, 0)
        } else if new.matches("^([0-9]|([1-9][0-9]?))$") {
            guard let n = Int(new) else { endTimeText = old; return }
            if !(0...48).contains(n) {
                endTimeText = old
                return
            }
            possibleEndTime = (n, 0)
        } else if new == "" {
            possibleEndTime = nil
            return
        } else {
            endTimeText = old
        }
    }
    
    struct Bubble: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .frame(width: 100, height: 55)
                .foregroundStyle(.white)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 2)
                        .fill(configuration.role == .cancel ? .white : .clear)
                    
                }
                .padding(8)
                .background(.clear)
        }
    }

}

extension String {
    func matches(_ regex: String) -> Bool {
        range(of: regex, options: .regularExpression) != nil
    }
}

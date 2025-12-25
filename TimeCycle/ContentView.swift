import Foundation
import SwiftUI

private enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
}

private enum LocalizedKey {
    case appName
    case tagline
    case cycle
    case total
    case cycles
    case phaseA
    case phaseB
    case minutes
    case seconds
    case cue
    case sessionLength
    case minuteAlignedInfo
    case scheduleInfo
    case language
    case soundSettings
    case haptics
    case hapticsNote
    case start
    case stop
    case sounds
    case addSound
    case soundTextPlaceholder
    case addButton
}

private struct Localizer {
    static func text(_ key: LocalizedKey, language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishText(key)
        case .chinese:
            return chineseText(key)
        }
    }

    static func statusMessage(_ message: String, language: AppLanguage) -> String {
        guard language == .chinese else { return message }
        return statusTranslations[message] ?? message
    }

    static func soundError(_ message: String, language: AppLanguage) -> String {
        guard language == .chinese else { return message }
        return soundErrorTranslations[message] ?? message
    }

    private static func englishText(_ key: LocalizedKey) -> String {
        switch key {
        case .appName: return "TimeCycle"
        case .tagline: return "Mindful intervals for focus and rest."
        case .cycle: return "Cycle"
        case .total: return "Total"
        case .cycles: return "Cycles"
        case .phaseA: return "Phase A"
        case .phaseB: return "Phase B"
        case .minutes: return "Minutes"
        case .seconds: return "Seconds"
        case .cue: return "Cue"
        case .sessionLength: return "Session length"
        case .minuteAlignedInfo: return "Minute-aligned cycles can repeat without the 32-cycle limit."
        case .scheduleInfo: return "iOS schedules up to 32 cycles at a time."
        case .language: return "Language"
        case .soundSettings: return "Sound"
        case .haptics: return "Haptics"
        case .hapticsNote: return "Haptics are controlled by the system: Settings > Sounds & Haptics > Haptic Feedback."
        case .start: return "Start"
        case .stop: return "Stop"
        case .sounds: return "Sounds"
        case .addSound: return "Add Sound"
        case .soundTextPlaceholder: return "Sound text"
        case .addButton: return "Add"
        }
    }

    private static func chineseText(_ key: LocalizedKey) -> String {
        switch key {
        case .appName: return "TimeCycle"
        case .tagline: return "专注与休息的循环提醒。"
        case .cycle: return "单周期"
        case .total: return "总时长"
        case .cycles: return "循环"
        case .phaseA: return "阶段 A"
        case .phaseB: return "阶段 B"
        case .minutes: return "分钟"
        case .seconds: return "秒"
        case .cue: return "提示语"
        case .sessionLength: return "本次时长"
        case .minuteAlignedInfo: return "整除 60 秒的周期可绕过 32 次限制重复提醒。"
        case .scheduleInfo: return "iOS 每次最多排 32 个循环。"
        case .language: return "语言"
        case .soundSettings: return "提示音"
        case .haptics: return "震动控制"
        case .hapticsNote: return "震动由系统控制：设置-声音与触感反馈-触感反馈。"
        case .start: return "开始"
        case .stop: return "停止"
        case .sounds: return "声音"
        case .addSound: return "添加声音"
        case .soundTextPlaceholder: return "声音文本"
        case .addButton: return "添加"
        }
    }

    private static let statusTranslations: [String: String] = [
        "Cycles must be at least 1.": "循环次数至少为 1。",
        "Each phase must be greater than 0 seconds.": "每个阶段必须大于 0 秒。",
        "Notifications are disabled. Enable them in Settings.": "通知已被关闭，请在系统设置中开启。",
        "Repeat mode enabled. Open the app to stop after the set cycles.": "已启用重复模式，达到设置循环后请打开 App 停止。",
        "Short cycles that don't divide 60s still need the app open to continue.": "不能整除 60 秒的短周期仍需前台续排。",
        "iOS schedules 32 cycles at a time. Open the app to continue scheduling.": "iOS 每次最多排 32 个循环，需要前台继续续排。",
        "Some notifications failed to schedule. Please try again.": "部分通知未能安排，请重试。",
        "Failed to generate audio. Please try again.": "音频生成失败，请重试。"
    ]

    private static let soundErrorTranslations: [String: String] = [
        "Enter some text.": "请输入文本。",
        "Max length is 40 characters.": "最多 40 个字符。",
        "This sound already exists.": "该提示已存在。"
    ]
}

private enum Theme {
    static let backgroundTop = Color(red: 0.98, green: 0.93, blue: 0.86)
    static let backgroundBottom = Color(red: 0.86, green: 0.95, blue: 0.93)
    static let accentWarm = Color(red: 0.96, green: 0.53, blue: 0.3)
    static let accentCool = Color(red: 0.2, green: 0.47, blue: 0.52)
    static let accentSoft = Color(red: 0.98, green: 0.78, blue: 0.64)
    static let card = Color.white.opacity(0.78)
    static let cardStroke = Color.white.opacity(0.55)
    static let ink = Color(red: 0.16, green: 0.17, blue: 0.19)
    static let inkSecondary = Color(red: 0.36, green: 0.38, blue: 0.4)
    static let warning = Color(red: 0.85, green: 0.42, blue: 0.2)

    static let titleFont = Font.custom("AvenirNext-Heavy", size: 36)
    static let subtitleFont = Font.custom("AvenirNext-Regular", size: 15)
    static let sectionFont = Font.custom("AvenirNext-DemiBold", size: 18)
    static let bodyFont = Font.custom("AvenirNext-Regular", size: 15)
    static let captionFont = Font.custom("AvenirNext-Regular", size: 12)
    static let monoFont = Font.custom("Menlo-Regular", size: 12)
}

private struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.backgroundTop, Theme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Theme.accentSoft.opacity(0.55))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: -140, y: -240)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(Theme.accentCool.opacity(0.2))
                .frame(width: 320, height: 320)
                .rotationEffect(.degrees(25))
                .blur(radius: 50)
                .offset(x: 160, y: 220)
        }
        .ignoresSafeArea()
    }
}

private struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
    }
}

private struct ValuePill: View {
    let text: String
    let tint: Color
    let filled: Bool

    init(_ text: String, tint: Color, filled: Bool = false) {
        self.text = text
        self.tint = tint
        self.filled = filled
    }

    var body: some View {
        Text(text)
            .font(Theme.monoFont)
            .foregroundColor(filled ? .white : tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(filled ? tint : tint.opacity(0.16))
            )
    }
}

private struct StatusBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .font(Theme.captionFont)
        }
        .foregroundColor(Theme.warning)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Theme.warning.opacity(0.12))
        )
    }
}

private struct SettingTile<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
        )
    }
}

private struct MetricBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(Theme.captionFont)
                .foregroundColor(Theme.inkSecondary)
            Text(value)
                .font(Theme.sectionFont)
                .foregroundColor(Theme.ink)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PhaseSection: View {
    let title: String
    let accent: Color
    let totalSeconds: Int
    let options: [String]
    let language: AppLanguage
    @Binding var minutes: Double
    @Binding var seconds: Double
    @Binding var text: String

    var body: some View {
        Card {
            HStack {
                Text(title)
                    .font(Theme.sectionFont)
                    .foregroundColor(Theme.ink)
                Spacer()
                ValuePill(formatDuration(totalSeconds, language: language), tint: accent)
            }

            Divider()
                .overlay(Theme.cardStroke)

            VStack(alignment: .leading, spacing: 10) {
                sliderRow(
                    label: Localizer.text(.minutes, language: language),
                    valueText: minuteValueText(minutes),
                    tint: accent
                )
                Slider(value: $minutes, in: 0...120, step: 1)
                    .tint(accent)

                sliderRow(
                    label: Localizer.text(.seconds, language: language),
                    valueText: secondValueText(seconds),
                    tint: accent
                )
                Slider(value: $seconds, in: 0...59, step: 1)
                    .tint(accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(Localizer.text(.cue, language: language))
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.inkSecondary)
                Picker(Localizer.text(.cue, language: language), selection: $text) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.ink)
            }
        }
    }

    private func sliderRow(label: String, valueText: String, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.ink)
            Spacer()
            ValuePill(valueText, tint: tint)
        }
    }

    private func minuteValueText(_ minutes: Double) -> String {
        let value = Int(minutes)
        switch language {
        case .english:
            return "\(value)m"
        case .chinese:
            return "\(value)分"
        }
    }

    private func secondValueText(_ seconds: Double) -> String {
        let value = Int(seconds)
        let padded = String(format: "%02d", value)
        switch language {
        case .english:
            return "\(padded)s"
        case .chinese:
            return "\(padded)秒"
        }
    }
}

private struct ActionButton: View {
    let title: String
    let systemImage: String
    let gradient: LinearGradient
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Theme.bodyFont)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(gradient)
                        .opacity(isEnabled ? 1 : 0.4)
                )
        }
        .disabled(!isEnabled)
    }
}

private struct RevealModifier: ViewModifier {
    let appear: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 16)
            .animation(.easeOut(duration: 0.6).delay(delay), value: appear)
    }
}

private extension View {
    func reveal(appear: Bool, delay: Double) -> some View {
        modifier(RevealModifier(appear: appear, delay: delay))
    }
}

final class SoundSettingsStore: ObservableObject {
    @Published var options: [String] {
        didSet {
            saveOptions()
        }
    }

    private let defaultsKey = "TimeCycleSoundOptions"
    private let fallbackOptions = ["meditation", "go", "rest", "work", "breathe"]

    init() {
        let saved = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        if saved.isEmpty {
            options = fallbackOptions
        } else {
            options = saved
        }
    }

    func addOption(_ rawText: String) -> String? {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Enter some text." }
        guard trimmed.count <= 40 else { return "Max length is 40 characters." }
        guard !options.contains(trimmed) else { return "This sound already exists." }

        options.append(trimmed)
        return nil
    }

    func removeOptions(at offsets: IndexSet) {
        guard options.count - offsets.count >= 1 else { return }
        options.remove(atOffsets: offsets)
    }

    private func saveOptions() {
        UserDefaults.standard.set(options, forKey: defaultsKey)
    }
}

struct SoundSettingsView: View {
    @ObservedObject var store: SoundSettingsStore
    @State private var newOption: String = ""
    @State private var errorMessage: String = ""
    @AppStorage("TimeCycleAppLanguage") private var appLanguageRaw = AppLanguage.english.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    var body: some View {
        ZStack {
            AppBackground()
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        TextField(Localizer.text(.soundTextPlaceholder, language: appLanguage), text: $newOption)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.9))
                            )
                            .onSubmit { addOption() }

                        Button(Localizer.text(.addButton, language: appLanguage)) {
                            addOption()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accentCool)

                        if !errorMessage.isEmpty {
                            Text(Localizer.soundError(errorMessage, language: appLanguage))
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.warning)
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Theme.card)
                    .listRowSeparator(.hidden)
                } header: {
                    Text(Localizer.text(.addSound, language: appLanguage))
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.inkSecondary)
                }

                Section {
                    ForEach(store.options, id: \.self) { option in
                        HStack {
                            Text(option)
                                .font(Theme.bodyFont)
                                .foregroundColor(Theme.ink)
                            Spacer()
                            Button {
                                AudioManager.shared.speakText(option)
                            } label: {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Theme.accentCool)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Theme.card)
                        .listRowSeparator(.hidden)
                    }
                    .onDelete { offsets in
                        store.removeOptions(at: offsets)
                    }
                } header: {
                    Text(Localizer.text(.sounds, language: appLanguage))
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.inkSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle(Localizer.text(.soundSettings, language: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
    }

    private func addOption() {
        let result = store.addOption(newOption)
        if let error = result {
            errorMessage = error
        } else {
            errorMessage = ""
            newOption = ""
        }
    }
}

struct ContentView: View {
    @ObservedObject var timerManager: TimerManager
    @StateObject private var soundSettings = SoundSettingsStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var appear = false

    @State private var phase1Minutes: Double = 0
    @State private var phase1Seconds: Double = 50
    @State private var phase2Minutes: Double = 0
    @State private var phase2Seconds: Double = 10
    @State private var phase1Text: String = "meditation"
    @State private var phase2Text: String = "go"
    @State private var cycleCount: Double = 8
    @State private var cycleMax: Double = 32
    @AppStorage("TimeCycleAppLanguage") private var appLanguageRaw = AppLanguage.english.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .english
    }

    private var languageBadgeText: String {
        switch appLanguage {
        case .english:
            return "EN"
        case .chinese:
            return "中"
        }
    }

    private func toggleLanguage() {
        switch appLanguage {
        case .english:
            appLanguageRaw = AppLanguage.chinese.rawValue
        case .chinese:
            appLanguageRaw = AppLanguage.english.rawValue
        }
    }

    var body: some View {
        let maxSchedulableCycles = 32
        let cycles = max(1, Int(cycleCount.rounded()))
        let phase1Total = totalSeconds(minutes: phase1Minutes, seconds: phase1Seconds)
        let phase2Total = totalSeconds(minutes: phase2Minutes, seconds: phase2Seconds)
        let cycleDuration = phase1Total + phase2Total
        let totalDuration = cycleDuration * cycles
        let canRepeatMinute = cycleDuration > 0 && cycleDuration <= 60 && 60 % cycleDuration == 0

        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 18) {
                        headerView
                            .reveal(appear: appear, delay: 0.05)

                        Card {
                            HStack(spacing: 12) {
                                MetricBlock(title: Localizer.text(.cycle, language: appLanguage), value: formatDuration(cycleDuration, language: appLanguage))
                                Rectangle()
                                    .fill(Theme.cardStroke)
                                    .frame(width: 1, height: 44)
                                MetricBlock(title: Localizer.text(.total, language: appLanguage), value: formatDuration(totalDuration, language: appLanguage))
                                Rectangle()
                                    .fill(Theme.cardStroke)
                                    .frame(width: 1, height: 44)
                                MetricBlock(title: Localizer.text(.cycles, language: appLanguage), value: "\(cycles)")
                            }
                        }
                        .reveal(appear: appear, delay: 0.1)

                        PhaseSection(
                            title: Localizer.text(.phaseA, language: appLanguage),
                            accent: Theme.accentWarm,
                            totalSeconds: phase1Total,
                            options: soundSettings.options,
                            language: appLanguage,
                            minutes: $phase1Minutes,
                            seconds: $phase1Seconds,
                            text: $phase1Text
                        )
                        .disabled(timerManager.isRunning)
                        .reveal(appear: appear, delay: 0.15)

                        PhaseSection(
                            title: Localizer.text(.phaseB, language: appLanguage),
                            accent: Theme.accentCool,
                            totalSeconds: phase2Total,
                            options: soundSettings.options,
                            language: appLanguage,
                            minutes: $phase2Minutes,
                            seconds: $phase2Seconds,
                            text: $phase2Text
                        )
                        .disabled(timerManager.isRunning)
                        .reveal(appear: appear, delay: 0.2)

                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(Localizer.text(.cycles, language: appLanguage))
                                        .font(Theme.sectionFont)
                                        .foregroundColor(Theme.ink)
                                    Spacer()
                                    ValuePill("\(cycles)", tint: Theme.accentWarm, filled: true)
                                }

                                Slider(value: $cycleCount, in: 1...cycleMax, step: 1)
                                    .tint(Theme.accentWarm)
                                    .onChange(of: cycleCount, initial: false) { _, newValue in
                                        if newValue >= cycleMax {
                                            cycleMax += 16
                                        }
                                    }

                                HStack {
                                    Text(Localizer.text(.sessionLength, language: appLanguage))
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.inkSecondary)
                                    Spacer()
                                    Text(formatDuration(totalDuration, language: appLanguage))
                                        .font(Theme.bodyFont)
                                        .foregroundColor(Theme.ink)
                                }

                                if cycles > maxSchedulableCycles {
                                    if canRepeatMinute {
                                        HStack(spacing: 6) {
                                            Image(systemName: "repeat")
                                            Text(Localizer.text(.minuteAlignedInfo, language: appLanguage))
                                        }
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.accentCool)
                                    } else {
                                        HStack(spacing: 6) {
                                            Image(systemName: "info.circle")
                                            Text(Localizer.text(.scheduleInfo, language: appLanguage))
                                        }
                                        .font(Theme.captionFont)
                                        .foregroundColor(Theme.warning)
                                    }
                                }
                            }
                        }
                        .disabled(timerManager.isRunning)
                        .reveal(appear: appear, delay: 0.25)

                        Card {
                            HStack(spacing: 12) {
                                SettingTile {
                                    HStack {
                                        Text(Localizer.text(.language, language: appLanguage))
                                            .font(Theme.sectionFont)
                                            .foregroundColor(Theme.ink)
                                        Spacer()
                                        Button {
                                            toggleLanguage()
                                        } label: {
                                            ValuePill(languageBadgeText, tint: Theme.accentCool, filled: true)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }

                                NavigationLink {
                                    SoundSettingsView(store: soundSettings)
                                } label: {
                                    SettingTile {
                                        HStack {
                                            Text(Localizer.text(.soundSettings, language: appLanguage))
                                                .font(Theme.sectionFont)
                                                .foregroundColor(Theme.ink)
                                            Spacer()
                                            HStack(spacing: 6) {
                                                Image(systemName: "waveform")
                                                    .foregroundColor(Theme.inkSecondary)
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(Theme.inkSecondary)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .reveal(appear: appear, delay: 0.3)

                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(Localizer.text(.haptics, language: appLanguage))
                                    .font(Theme.sectionFont)
                                    .foregroundColor(Theme.ink)

                                Text(Localizer.text(.hapticsNote, language: appLanguage))
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.inkSecondary)
                            }
                        }
                        .reveal(appear: appear, delay: 0.35)

                        if !timerManager.statusMessage.isEmpty {
                            StatusBanner(text: Localizer.statusMessage(timerManager.statusMessage, language: appLanguage))
                                .reveal(appear: appear, delay: 0.4)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
            .onAppear {
                ensureSelectedSounds()
                timerManager.refreshScheduleIfNeeded()
                appear = true
            }
            .onChange(of: soundSettings.options, initial: false) { _, _ in
                ensureSelectedSounds()
            }
            .onChange(of: scenePhase, initial: false) { _, newPhase in
                if newPhase == .active {
                    timerManager.refreshScheduleIfNeeded()
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    ActionButton(
                        title: Localizer.text(.start, language: appLanguage),
                        systemImage: "play.fill",
                        gradient: LinearGradient(
                            colors: [Theme.accentWarm, Theme.accentCool],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isEnabled: !timerManager.isRunning
                    ) {
                        timerManager.startCycle(
                            phase1Seconds: phase1Total,
                            phase1Text: phase1Text,
                            phase2Seconds: phase2Total,
                            phase2Text: phase2Text,
                            cycles: cycles
                        )
                    }

                    ActionButton(
                        title: Localizer.text(.stop, language: appLanguage),
                        systemImage: "stop.fill",
                        gradient: LinearGradient(
                            colors: [Color(red: 0.32, green: 0.35, blue: 0.4), Color(red: 0.16, green: 0.18, blue: 0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        isEnabled: timerManager.isRunning
                    ) {
                        timerManager.stopTimer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Theme.cardStroke, lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }

    private var headerView: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Localizer.text(.appName, language: appLanguage))
                    .font(Theme.titleFont)
                    .foregroundColor(Theme.ink)
                Text(Localizer.text(.tagline, language: appLanguage))
                    .font(Theme.subtitleFont)
                    .foregroundColor(Theme.inkSecondary)
            }
        }
        .padding(.horizontal, 2)
    }

    private func ensureSelectedSounds() {
        guard let first = soundSettings.options.first else { return }
        if !soundSettings.options.contains(phase1Text) {
            phase1Text = first
        }
        if !soundSettings.options.contains(phase2Text) {
            phase2Text = first
        }
    }
}

private func totalSeconds(minutes: Double, seconds: Double) -> Int {
    let minuteValue = max(0, Int(minutes.rounded()))
    let secondValue = max(0, Int(seconds.rounded()))
    return minuteValue * 60 + secondValue
}

private func formatDuration(_ seconds: Int, language: AppLanguage) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let remaining = seconds % 60

    let paddedMinutes = minutes < 10 ? "0\(minutes)" : "\(minutes)"
    let paddedSeconds = remaining < 10 ? "0\(remaining)" : "\(remaining)"

    switch language {
    case .english:
        if hours > 0 {
            return "\(hours)h \(paddedMinutes)m \(paddedSeconds)s"
        }
        return "\(minutes)m \(paddedSeconds)s"
    case .chinese:
        if hours > 0 {
            return "\(hours)小时 \(paddedMinutes)分 \(paddedSeconds)秒"
        }
        return "\(minutes)分 \(paddedSeconds)秒"
    }
}

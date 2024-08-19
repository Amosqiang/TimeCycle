import SwiftUI
import AVFoundation
import BackgroundTasks

struct ContentView: View {
    @State private var interval: Int = 60
    @State private var textToSpeak: String = "z"
    @State private var isRunning: Bool = false
    @State private var timer: Timer? = nil
    @State private var textOptions = ["z", "Hello", "Test"]
    let synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(spacing: 20) {
            Text("Speech Timer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 50)

            Picker("Select Interval (seconds)", selection: $interval) {
                ForEach(1..<301, id: \.self) { number in
                    Text("\(number) sec")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
            .padding(.horizontal)

            Picker("Select Text to Speak", selection: $textToSpeak) {
                ForEach(textOptions, id: \.self) { option in
                    Text(option)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(maxWidth: .infinity)
            .clipped()
            .padding(.horizontal)

            HStack(spacing: 20) {
                Button(action: startTimer) {
                    Text("Start")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .disabled(isRunning)
                .opacity(isRunning ? 0.5 : 1.0)
                
                Button(action: stopTimer) {
                    Text("Stop")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .disabled(!isRunning)
                .opacity(isRunning ? 1.0 : 0.5)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .onAppear(perform: configureAudioSession)
        .onTapGesture {
            self.hideKeyboard()
        }
    }
    
    func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetoothA2DP, .allowAirPlay, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()  // 保持后台运行
    }

    func startTimer() {
        isRunning = true
        speakText()  // 立即发声
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { _ in
            speakText()
        }
        self.hideKeyboard()
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        self.hideKeyboard()
    }
    
    func speakText() {
        let utterance = AVSpeechUtterance(string: textToSpeak)
        synthesizer.speak(utterance)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


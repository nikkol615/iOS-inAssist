import AVFoundation
import Foundation

// MARK: - VoiceRecorder
// Инкапсулирует всю логику AVFoundation: запрос разрешения, запись .m4a,
// отправка на ML /api/v1/transcribe, возврат текста через колбэки.

final class VoiceRecorder: NSObject {

    enum State {
        case idle
        case recording
        case processing
    }

    // MARK: - Callbacks

    var onStateChange: ((State) -> Void)?
    var onTranscript: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Private

    private(set) var currentState: State = .idle {
        didSet { onStateChange?(currentState) }
    }

    private var recorder: AVAudioRecorder?
    private var outputURL: URL?

    // MARK: - Public API

    /// Запрашивает разрешение (если нужно) и начинает запись.
    func requestPermissionAndStart() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.startRecording()
                } else {
                    self.onError?(VoiceRecorderError.permissionDenied)
                }
            }
        }
    }

    /// Останавливает запись и запускает транскрипцию.
    func stop() {
        guard currentState == .recording else { return }
        recorder?.stop()
        // Завершение обрабатывается в audioRecorderDidFinishRecording
    }

    // MARK: - Private

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError?(error)
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice_\(UUID().uuidString).m4a")
        outputURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            currentState = .recording
        } catch {
            onError?(error)
        }
    }

    private func finishAndTranscribe() {
        guard let url = outputURL else {
            currentState = .idle
            return
        }
        currentState = .processing

        // Деактивируем аудио-сессию перед отправкой
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        APIClient.shared.transcribe(audioFileURL: url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.currentState = .idle
                // Удаляем временный файл
                try? FileManager.default.removeItem(at: url)
                self.outputURL = nil

                switch result {
                case .success(let text):
                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.onError?(VoiceRecorderError.emptyTranscript)
                    } else {
                        self.onTranscript?(text)
                    }
                case .failure(let error):
                    self.onError?(error)
                }
            }
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            finishAndTranscribe()
        } else {
            currentState = .idle
            onError?(VoiceRecorderError.recordingFailed)
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        currentState = .idle
        onError?(error ?? VoiceRecorderError.recordingFailed)
    }
}

// MARK: - VoiceRecorderError

enum VoiceRecorderError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case emptyTranscript

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Доступ к микрофону запрещён. Разрешите доступ в Настройках."
        case .recordingFailed:
            return "Не удалось записать аудио."
        case .emptyTranscript:
            return "Речь не распознана. Попробуйте ещё раз."
        }
    }
}

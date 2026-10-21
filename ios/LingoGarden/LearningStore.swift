import Foundation
import Combine
import AVFoundation

@MainActor final class LearningStore: ObservableObject {
    @Published private(set) var careers: [Career] = []
    @Published var progress: ProgressData { didSet { persist() } }
    @Published var activeLesson: Lesson?
    @Published var storageError: String?
    @Published var contentError: String?
    private let defaults: UserDefaults
    private let speaker = AVSpeechSynthesizer()
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: "garden-progress-v1"), let saved = try? JSONDecoder().decode(ProgressData.self, from: data) {
            progress = saved
        } else { progress = ProgressData() }
        do {
            guard let url = Bundle.main.url(forResource: "careers", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
            careers = try JSONDecoder().decode([Career].self, from: Data(contentsOf: url))
            if !careers.contains(where: { $0.id == progress.modeID }), let first = careers.first { progress.modeID = first.id }
        } catch { contentError = "课程内容未能加载，请检查应用安装。\n\(error.localizedDescription)" }
    }
    var career: Career? { careers.first { $0.id == progress.modeID } }
    var currentMistakes: [Mistake] { progress.mistakes.filter { $0.modeID == progress.modeID } }
    var currentGenerated: [Lesson] { progress.generated.filter { $0.modeID == progress.modeID } }
    var todayXP: Int { progress.daily[Self.dayKey()] ?? 0 }
    var streak: Int {
        let calendar = Calendar.current
        var date = Date()
        if !progress.days.contains(Self.dayKey(date)) { date = calendar.date(byAdding: .day, value: -1, to: date) ?? date }
        var result = 0
        while progress.days.contains(Self.dayKey(date)) {
            result += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return result
    }
    var reviewLesson: Lesson {
        Lesson(id: progress.modeID + "-review", title: (career?.name ?? "") + "错题复习", modeID: progress.modeID, questions: currentMistakes.map(\.question))
    }
    var recommended: Lesson? {
        if !currentMistakes.isEmpty { return reviewLesson }
        guard let career else { return nil }
        return [career.wordLesson, career.grammarLesson, career.sceneLesson].first { !progress.completed.contains($0.id) } ?? career.wordLesson
    }
    func switchMode(_ id: String) {
        guard careers.contains(where: { $0.id == id }) else { return }
        stopSpeaking()
        progress.modeID = id
    }
    func markWord(_ id: String) {
        if progress.knownWords.contains(id) { progress.knownWords.remove(id) } else { progress.knownWords.insert(id) }
    }
    func record(_ question: Question, lesson: Lesson, correct: Bool) {
        if correct { progress.mistakes.removeAll { $0.modeID == lesson.modeID && $0.question.id == question.id } }
        else if !progress.mistakes.contains(where: { $0.modeID == lesson.modeID && $0.question.id == question.id }) {
            progress.mistakes.append(Mistake(lessonID: lesson.id, modeID: lesson.modeID, question: question))
        }
    }
    func finish(_ lesson: Lesson, correct: Int) {
        let xp = correct * 5
        progress.xp += xp
        let day = Self.dayKey()
        progress.daily[day, default: 0] += xp
        progress.days.insert(day)
        if !lesson.id.hasSuffix("-review"), !lesson.questions.isEmpty, Double(correct) / Double(lesson.questions.count) >= 0.6 { progress.completed.insert(lesson.id) }
    }
    func speak(_ text: String) {
        speaker.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.43
        speaker.speak(utterance)
    }
    func stopSpeaking() { speaker.stopSpeaking(at: .immediate) }
    private func persist() {
        do { defaults.set(try JSONEncoder().encode(progress), forKey: "garden-progress-v1") }
        catch { storageError = "进度保存失败，请重试。" }
    }
    static func dayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

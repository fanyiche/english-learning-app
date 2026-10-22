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
    /// 今日到期复习的词与今天还可以学的新词。
    var dailyWords: (due: [Word], fresh: [Word]) {
        guard let career else { return ([], []) }
        let today = Self.dayKey()
        let words = career.allWords
        let due = words.filter { word in progress.reviews[word.id].map { $0.due <= today } ?? false }
        let addedToday = words.filter { progress.reviews[$0.id]?.added == today }.count
        let fresh = words.filter { progress.reviews[$0.id] == nil }.prefix(max(0, progress.newPerDay - addedToday))
        return (Array(due.prefix(30)), Array(fresh))
    }
    var dailyLesson: Lesson? {
        guard let career else { return nil }
        let (due, fresh) = dailyWords
        guard !due.isEmpty || !fresh.isEmpty else { return nil }
        let questions = (due + fresh).map { career.question(for: $0, drill: WordDrill.forBox(progress.reviews[$0.id]?.box)) }
        return Lesson(id: career.id + "-daily-" + Self.dayKey(), title: "今日记忆", modeID: career.id, questions: questions)
    }
    /// 第一个还有未完成课程的单元；全部完成后停在最后一个单元。
    var currentUnit: CourseUnit? {
        guard let career else { return nil }
        return career.allUnits.first { unit in career.lessons(for: unit).contains { !progress.completed.contains($0.id) } } ?? career.allUnits.last
    }
    var rememberedCount: Int { progress.reviews.values.filter { $0.box >= 4 }.count }
    var recommended: Lesson? {
        if !currentMistakes.isEmpty { return reviewLesson }
        if let dailyLesson { return dailyLesson }
        guard let career, let currentUnit else { return nil }
        return career.lessons(for: currentUnit).first { !progress.completed.contains($0.id) }
    }
    func switchMode(_ id: String) {
        guard careers.contains(where: { $0.id == id }) else { return }
        stopSpeaking()
        progress.modeID = id
    }
    func markWord(_ id: String) {
        if progress.knownWords.contains(id) { progress.knownWords.remove(id) } else {
            progress.knownWords.insert(id)
            // 标记已掌握的词直接进入长间隔复习，不再占用每日新词名额。
            if progress.reviews[id] == nil { progress.reviews[id] = WordReview(box: 4, due: Self.dayKey(offset: WordReview.intervals[3]), added: "") }
        }
    }
    func record(_ question: Question, lesson: Lesson, correct: Bool) {
        if let wordID = question.wordID { updateReview(wordID, correct: correct) }
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
        if !lesson.id.hasSuffix("-review"), !lesson.id.contains("-daily-"), !lesson.questions.isEmpty, Double(correct) / Double(lesson.questions.count) >= 0.6 { progress.completed.insert(lesson.id) }
    }
    /// 答对：升一级并按间隔推迟；当天已复习过的词不重复升级。答错：回到第一级，明天再复习。
    private func updateReview(_ wordID: String, correct: Bool) {
        let today = Self.dayKey()
        let existing = progress.reviews[wordID]
        var item = existing ?? WordReview(box: 0, due: today, added: today)
        if correct {
            guard existing == nil || item.due <= today else { return }
            item.box = min(item.box + 1, WordReview.intervals.count)
            item.due = Self.dayKey(offset: WordReview.intervals[item.box - 1])
        } else {
            item.box = 0
            item.due = Self.dayKey(offset: 1)
        }
        progress.reviews[wordID] = item
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
    static func dayKey(offset days: Int) -> String {
        dayKey(Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date())
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

import Foundation

struct Word: Codable, Identifiable {
    let id: String
    let term: String
    let meaning: String
    let example: String
    let translation: String
}
struct Grammar: Codable, Identifiable {
    let id: String
    let title: String
    let pattern: String
    let explanation: String
    let example: String
    let translation: String
    let prompt: String
    let options: [String]
    let answer: String
}
struct DialogueLine: Codable {
    let speaker: String
    let english: String
    let translation: String
}
struct Question: Codable, Identifiable {
    var id: String { prompt + "::" + answer }
    let type: String
    let prompt: String
    let english: String?
    let options: [String]?
    let answer: String
    let explain: String
    var wordID: String? = nil
    func accepts(_ value: String) -> Bool {
        func normalize(_ text: String) -> String {
            text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                .trimmingCharacters(in: CharacterSet(charactersIn: ".!?。！"))
        }
        return normalize(value) == normalize(answer)
    }
}
struct Lesson: Codable, Identifiable {
    let id: String
    let title: String
    let modeID: String
    let questions: [Question]
}
struct CourseUnit: Codable, Identifiable {
    let id: String
    let title: String
    let level: String?
    let words: [Word]
    let grammar: [Grammar]
    let dialogue: [DialogueLine]
}
/// 单词题型：按记忆阶段从易到难。
enum WordDrill: Int {
    case meaning, term, listen, cloze, spell
    /// 间隔重复的盒子越高，题型越难。
    static func forBox(_ box: Int?) -> WordDrill {
        switch box ?? 0 {
        case 0: return .meaning
        case 1: return .listen
        case 2: return .term
        case 3: return .cloze
        default: return .spell
        }
    }
}
struct Career: Codable, Identifiable {
    let id: String
    let name: String
    let english: String
    let subtitle: String
    let icon: String
    let symbol: String
    let words: [Word]
    let grammar: [Grammar]
    let dialogue: [DialogueLine]
    /// 第 2 单元起的扩展内容；顶层 words/grammar/dialogue 是第 1 单元，网页版和旧进度继续使用。
    let units: [CourseUnit]?
    var allUnits: [CourseUnit] {
        [CourseUnit(id: id, title: "基础核心", level: nil, words: words, grammar: grammar, dialogue: dialogue)] + (units ?? [])
    }
    var allWords: [Word] { allUnits.flatMap(\.words) }
    var allDialogue: [DialogueLine] { allUnits.flatMap(\.dialogue) }
    func unit(containing word: Word) -> CourseUnit? { allUnits.first { $0.words.contains { $0.id == word.id } } }
    func lessons(for unit: CourseUnit) -> [Lesson] { [wordLesson(unit), grammarLesson(unit), sceneLesson(unit)] }
    func wordLesson(_ unit: CourseUnit) -> Lesson {
        let cycle: [WordDrill] = [.meaning, .term, .listen, .cloze]
        return Lesson(id: unit.id + "-words", title: unit.title + " · 词汇", modeID: id, questions:
            unit.words.enumerated().map { index, word in question(for: word, drill: cycle[index % cycle.count]) })
    }
    func grammarLesson(_ unit: CourseUnit) -> Lesson {
        Lesson(id: unit.id + "-grammar", title: unit.title + " · 语法", modeID: id, questions: unit.grammar.map {
            Question(type: "choice", prompt: $0.prompt, english: $0.pattern, options: $0.options, answer: $0.answer, explain: $0.explanation + "\n" + $0.example)
        })
    }
    func sceneLesson(_ unit: CourseUnit) -> Lesson {
        Lesson(id: unit.id + "-scene", title: unit.title + " · 情景听力", modeID: id, questions: unit.dialogue.map { line in
            let others = unit.dialogue.filter { $0.english != line.english } + allDialogue.filter { $0.english != line.english }
            return Question(type: "listen", prompt: "听一听，这句话的意思是？", english: line.english, options: Self.options(answer: line.translation, from: others.map(\.translation), seed: line.english), answer: line.translation, explain: line.english + "\n" + line.translation)
        })
    }
    func question(for word: Word, drill: WordDrill) -> Question {
        let explain = "\(word.term)：\(word.meaning)\n\(word.example)\n\(word.translation)"
        let sameUnit = (unit(containing: word)?.words ?? []).filter { $0.id != word.id }
        let pool = Self.rotated(sameUnit, seed: word.id) + Self.rotated(allWords.filter { w in w.id != word.id && !sameUnit.contains { $0.id == w.id } }, seed: word.id)
        let meanings = Self.options(answer: word.meaning, from: pool.map(\.meaning), seed: word.id)
        let terms = Self.options(answer: word.term, from: pool.map(\.term), seed: word.id)
        switch drill {
        case .meaning:
            return Question(type: "choice", prompt: "「\(word.term)」是什么意思？", english: word.term, options: meanings, answer: word.meaning, explain: explain, wordID: word.id)
        case .term:
            return Question(type: "choice", prompt: "「\(word.meaning)」用英语怎么说？", english: nil, options: terms, answer: word.term, explain: explain, wordID: word.id)
        case .listen:
            return Question(type: "listen", prompt: "听一听，选择这个表达的含义", english: word.example, options: meanings, answer: word.meaning, explain: explain, wordID: word.id)
        case .cloze:
            guard let range = word.example.range(of: word.term, options: .caseInsensitive) else { return question(for: word, drill: .term) }
            return Question(type: "choice", prompt: "选词填空：" + word.translation, english: word.example.replacingCharacters(in: range, with: "____"), options: terms, answer: word.term, explain: explain, wordID: word.id)
        case .spell:
            return Question(type: "input", prompt: "拼写「\(word.meaning)」的英文", english: nil, options: nil, answer: word.term, explain: explain, wordID: word.id)
        }
    }
    /// 正确答案加两个不重复的干扰项，位置由内容决定，每次打开都一致。
    private static func options(answer: String, from candidates: [String], seed: String) -> [String] {
        var result: [String] = []
        for value in candidates where value != answer && !result.contains(value) && result.count < 2 { result.append(value) }
        result.insert(answer, at: stableHash(seed) % (result.count + 1))
        return result
    }
    private static func rotated<T>(_ items: [T], seed: String) -> [T] {
        guard !items.isEmpty else { return items }
        let offset = stableHash(seed) % items.count
        return Array(items[offset...] + items[..<offset])
    }
    private static func stableHash(_ text: String) -> Int {
        text.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
    }
}
struct Mistake: Codable, Identifiable {
    var id: String { lessonID + "::" + question.id }
    let lessonID: String
    let modeID: String
    let question: Question
}
/// 间隔重复记录：box 越高，下次复习间隔越长。
struct WordReview: Codable {
    var box: Int
    var due: String
    var added: String
    static let intervals = [1, 2, 4, 7, 15, 30, 60]
}
struct ProgressData: Codable {
    var modeID = "student"
    var name = "学习者"
    var xp = 0
    var goal = 20
    var daily: [String: Int] = [:]
    var days: Set<String> = []
    var completed: Set<String> = []
    var knownWords: Set<String> = []
    var mistakes: [Mistake] = []
    var generated: [Lesson] = []
    var aiURL = ""
    var reviews: [String: WordReview] = [:]
    var newPerDay = 10
    init() {}
    /// 旧版本保存的数据缺少新字段，逐项读取并用默认值补齐，升级后进度不丢失。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ProgressData()
        modeID = try c.decodeIfPresent(String.self, forKey: .modeID) ?? d.modeID
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? d.name
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? d.xp
        goal = try c.decodeIfPresent(Int.self, forKey: .goal) ?? d.goal
        daily = try c.decodeIfPresent([String: Int].self, forKey: .daily) ?? d.daily
        days = try c.decodeIfPresent(Set<String>.self, forKey: .days) ?? d.days
        completed = try c.decodeIfPresent(Set<String>.self, forKey: .completed) ?? d.completed
        knownWords = try c.decodeIfPresent(Set<String>.self, forKey: .knownWords) ?? d.knownWords
        mistakes = try c.decodeIfPresent([Mistake].self, forKey: .mistakes) ?? d.mistakes
        generated = try c.decodeIfPresent([Lesson].self, forKey: .generated) ?? d.generated
        aiURL = try c.decodeIfPresent(String.self, forKey: .aiURL) ?? d.aiURL
        reviews = try c.decodeIfPresent([String: WordReview].self, forKey: .reviews) ?? d.reviews
        newPerDay = try c.decodeIfPresent(Int.self, forKey: .newPerDay) ?? d.newPerDay
    }
}
struct TutorMessage: Codable, Identifiable {
    var id: String { role + content }
    let role: String
    let content: String
    enum CodingKeys: String, CodingKey { case role, content }
}

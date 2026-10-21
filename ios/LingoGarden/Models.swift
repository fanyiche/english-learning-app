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
    var wordLesson: Lesson {
        Lesson(id: id + "-words", title: name + "核心词汇", modeID: id, questions:
            words.enumerated().map { index, word in
                var options = [word.meaning] + words.filter { $0.id != word.id }.dropFirst(index % 3).prefix(2).map(\.meaning)
                if !options.isEmpty { options = Array(options.dropFirst(index % options.count)) + Array(options.prefix(index % options.count)) }
                return Question(type: index == 2 ? "listen" : "choice", prompt: index == 2 ? "听一听，选择这个表达的含义" : "「\(word.term)」是什么意思？", english: index == 2 ? word.example : word.term, options: options, answer: word.meaning, explain: "\(word.term)：\(word.meaning)\n\(word.example)\n\(word.translation)")
            })
    }
    var grammarLesson: Lesson {
        Lesson(id: id + "-grammar", title: name + "实用语法", modeID: id, questions: grammar.map {
            Question(type: "choice", prompt: $0.prompt, english: $0.pattern, options: $0.options, answer: $0.answer, explain: $0.explanation + "\n" + $0.example)
        })
    }
    var sceneLesson: Lesson {
        Lesson(id: id + "-scene", title: name + "情景听力", modeID: id, questions: dialogue.prefix(3).map { line in
            Question(type: "listen", prompt: "听一听，这句话的意思是？", english: line.english, options: [line.translation] + dialogue.filter { $0.english != line.english }.prefix(2).map(\.translation), answer: line.translation, explain: line.english + "\n" + line.translation)
        })
    }
}
struct Mistake: Codable, Identifiable {
    var id: String { lessonID + "::" + question.id }
    let lessonID: String
    let modeID: String
    let question: Question
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
}
struct TutorMessage: Codable, Identifiable {
    var id: String { role + content }
    let role: String
    let content: String
    enum CodingKeys: String, CodingKey { case role, content }
}

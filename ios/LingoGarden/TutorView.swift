import SwiftUI

private struct TutorRequest: Encodable {
    let messages: [TutorMessage]
    let mode: String
    let level = "零基础"
    let career: String
    let mistakes: [[String: String]]
}
private struct TutorResponse: Decodable { let content: String?; let error: String? }
private struct GeneratedCourse: Decodable {
    let title: String
    let questions: [Question]
    func validated(modeID: String) throws -> Lesson {
        guard !title.isEmpty, title.count <= 100, (3...8).contains(questions.count), Set(questions.map(\.id)).count == questions.count else { throw TutorError.invalidCourse }
        for question in questions {
            guard ["choice", "listen", "input"].contains(question.type), !question.prompt.isEmpty, !question.answer.isEmpty, !question.explain.isEmpty else { throw TutorError.invalidCourse }
            if question.type == "listen", (question.english ?? "").isEmpty { throw TutorError.invalidCourse }
            if question.type != "input" {
                guard let options = question.options, (2...4).contains(options.count), options.contains(question.answer), Set(options).count == options.count else { throw TutorError.invalidCourse }
            }
        }
        return Lesson(id: "ai-" + UUID().uuidString, title: title, modeID: modeID, questions: questions)
    }
}
private enum TutorError: LocalizedError {
    case invalidURL, invalidCourse, response(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "请先在「我的」中填写你信任的 HTTPS AI 服务地址。"
        case .invalidCourse: return "模型生成的课程格式不完整，请重试。"
        case .response(let message): return message
        }
    }
}
struct TutorView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var messages: [TutorMessage] = []
    @State private var input = ""
    @State private var mode = "chat"
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var requestTask: Task<Void, Never>?
    var body: some View {
        GardenScroll {
            Text("嗨，我是 Fern ✧").font(.largeTitle.bold())
            Text("围绕\(store.career?.name ?? "当前身份")的真实场景，一起练习英语。").font(.subheadline).foregroundStyle(.secondary)
            Picker("老师模式", selection: $mode) {
                Text("情景对话").tag("chat")
                Text("语法解释").tag("grammar")
                Text("生成课程").tag("course")
            }.pickerStyle(.segmented).disabled(busy)
            if store.progress.aiURL.isEmpty {
                Label("尚未连接本地 AI", systemImage: "network.slash").font(.headline)
                Text("在「我的」中设置运行 Ollama 的服务器地址。未连接时仍可在学习菜单使用全部内置课程。AI 不会在 iPhone 内自动运行。")
                    .font(.subheadline).foregroundStyle(.secondary).gardenCard()
            }
            ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                VStack(alignment: .leading, spacing: 8) {
                    Text(message.role == "user" ? "你" : "Fern · 本地 AI").font(.caption).foregroundStyle(GardenStyle.green)
                    Text(message.content).font(.body).textSelection(.enabled)
                }.frame(maxWidth: .infinity, alignment: .leading).gardenCard()
            }
            if busy { ProgressView("老师正在思考…") }
            if let errorMessage { Text(errorMessage).font(.subheadline).foregroundStyle(.red) }
            TextField(mode == "course" ? "例如：根据我的错题生成复习课程" : "输入想练习的内容…", text: $input, axis: .vertical)
                .lineLimit(2...5).textFieldStyle(.roundedBorder).disabled(busy)
                .onChange(of: input) { _, text in if text.count > 1500 { input = String(text.prefix(1500)) } }
            Button(busy ? "正在回复…" : "发送") { send() }.buttonStyle(GardenButton()).disabled(busy || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Text("发送后，对话、当前身份与最近错题将传给你配置的服务器。回答可能有误；生成的课程经格式检查后加入本模式学习菜单。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .onChange(of: mode) { _, _ in messages = []; errorMessage = nil }
        .onChange(of: store.progress.modeID) { _, _ in cancelConversation() }
        .onDisappear { cancelConversation() }
    }
    private func cancelConversation() {
        requestTask?.cancel(); requestTask = nil; busy = false; messages = []; errorMessage = nil
    }
    private func send() {
        guard !busy else { return }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard let base = URL(string: store.progress.aiURL), base.scheme == "https", base.host != nil, base.user == nil, base.password == nil else {
            errorMessage = TutorError.invalidURL.localizedDescription; return
        }
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.path = "/api/ai"; components?.query = nil; components?.fragment = nil
        guard let url = components?.url else { errorMessage = TutorError.invalidURL.localizedDescription; return }
        let user = TutorMessage(role: "user", content: text)
        let history = Array((messages + [user]).suffix(12))
        let currentMode = mode
        let careerID = store.progress.modeID
        let request = TutorRequest(messages: history, mode: mode, career: store.career?.name ?? "", mistakes: store.currentMistakes.prefix(8).map { ["prompt": $0.question.prompt, "answer": $0.question.answer] })
        input = ""; busy = true; errorMessage = nil; messages.append(user)
        requestTask = Task { @MainActor in
            do {
                var http = URLRequest(url: url)
                http.httpMethod = "POST"; http.timeoutInterval = 125
                http.setValue("application/json", forHTTPHeaderField: "Content-Type")
                http.httpBody = try JSONEncoder().encode(request)
                let (data, response) = try await URLSession.shared.data(for: http)
                try Task.checkCancellation()
                let result = try JSONDecoder().decode(TutorResponse.self, from: data)
                guard let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status), let content = result.content else { throw TutorError.response(result.error ?? "AI 服务响应失败，请检查模型是否运行。") }
                guard store.progress.modeID == careerID else { return }
                if currentMode == "course" {
                    let course = try JSONDecoder().decode(GeneratedCourse.self, from: Data(content.utf8)).validated(modeID: careerID)
                    store.progress.generated.append(course)
                    messages.append(TutorMessage(role: "assistant", content: "课程《\(course.title)》已加入\(store.career?.name ?? "当前")模式。到学习菜单即可练习。"))
                } else { messages.append(TutorMessage(role: "assistant", content: content)) }
            } catch is CancellationError { return }
            catch {
                if !Task.isCancelled { errorMessage = error.localizedDescription; input = text; if messages.last?.role == "user" { messages.removeLast() } }
            }
            if !Task.isCancelled { busy = false }
        }
    }
}

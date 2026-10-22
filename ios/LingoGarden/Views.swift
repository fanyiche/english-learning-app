import SwiftUI

enum GardenStyle {
    static let green = Color(red: 0.22, green: 0.47, blue: 0.36)
    static let ink = Color(red: 0.16, green: 0.24, blue: 0.20)
    static let background = Color(red: 0.97, green: 0.98, blue: 0.95)
    static let soft = Color(red: 0.91, green: 0.94, blue: 0.87)
}
extension View {
    func gardenCard() -> some View {
        padding(20).background(.background, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(GardenStyle.green.opacity(0.10)))
    }
}
struct GardenButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 15)
            .foregroundStyle(.white).background(GardenStyle.green.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14))
    }
}
struct GardenScroll<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 22) { content }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity) }
            .background(GardenStyle.background).foregroundStyle(GardenStyle.ink)
    }
}
struct GardenRoot: View {
    @EnvironmentObject private var store: LearningStore
    @State private var showModes = false
    var body: some View {
        Group {
            if let error = store.contentError {
                ContentUnavailableView("课程暂不可用", systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                TabView {
                    section("今日") { TodayView() }.tabItem { Label("今日", systemImage: "leaf") }
                    section("学习") { LibraryView() }.tabItem { Label("学习", systemImage: "books.vertical") }
                    section("听说") { SpeakingView() }.tabItem { Label("听说", systemImage: "waveform") }
                    section("AI 老师") { TutorView() }.tabItem { Label("AI 老师", systemImage: "sparkles") }
                    section("我的") { ProfileView() }.tabItem { Label("我的", systemImage: "person.crop.circle") }
                }
                .sheet(isPresented: $showModes) { ModePickerView() }
                .fullScreenCover(item: $store.activeLesson) { lesson in QuizView(lesson: lesson) }
            }
        }
        .alert("进度保存", isPresented: Binding(get: { store.storageError != nil }, set: { if !$0 { store.storageError = nil } })) {
            Button("知道了") { store.storageError = nil }
        } message: { Text(store.storageError ?? "") }
    }
    private func section<V: View>(_ title: String, @ViewBuilder content: () -> V) -> some View {
        NavigationStack {
            content().navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button { showModes = true } label: {
                            Label((store.career?.name ?? "选择") + "模式", systemImage: store.career?.symbol ?? "square.grid.2x2")
                                .font(.caption.weight(.semibold))
                        }.accessibilityIdentifier("switch-mode")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("\(store.progress.xp)", systemImage: "sparkle").font(.caption.weight(.semibold)).foregroundStyle(GardenStyle.green)
                    }
                }
        }.id(store.progress.modeID)
    }
}
struct ModePickerView: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            GardenScroll {
                Text("你想在哪个世界使用英语？").font(.title2.bold())
                Text("切换模式会更新词汇、语法与练习。各模式进度单独保留，累计 XP 与连续天数共享。")
                    .font(.subheadline).foregroundStyle(.secondary)
                ForEach(store.careers) { career in
                    Button {
                        store.switchMode(career.id)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: career.symbol).font(.title2).frame(width: 48, height: 48).background(GardenStyle.soft, in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(career.name).font(.headline)
                                Text(career.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: store.progress.modeID == career.id ? "checkmark.circle.fill" : "circle").foregroundStyle(GardenStyle.green)
                        }.gardenCard()
                    }.buttonStyle(.plain).accessibilityIdentifier("mode-" + career.id)
                }
            }.navigationTitle("学习模式").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}
struct TodayView: View {
    @EnvironmentObject private var store: LearningStore
    var body: some View {
        GardenScroll {
            VStack(alignment: .leading, spacing: 9) {
                Text("A LITTLE BETTER, EVERY DAY").font(.caption2).tracking(2).foregroundStyle(GardenStyle.green)
                Text("你好，\(store.progress.name) ☀").font(.largeTitle.bold())
                Text("学你需要的英语，让每一次表达更有底气。").font(.subheadline).foregroundStyle(.secondary)
            }
            if let career = store.career {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { Label(career.name + "模式", systemImage: career.symbol).font(.caption.weight(.medium)); Spacer(); Image(systemName: "leaf.fill") }
                    if let lesson = store.recommended {
                        Text(lesson.title).font(.title2.bold())
                        Text(summary(for: lesson)).font(.subheadline).foregroundStyle(.secondary)
                        Button { store.activeLesson = lesson } label: { Label(buttonTitle(for: lesson), systemImage: "arrow.right") }.buttonStyle(GardenButton())
                        Text("共 \(lesson.questions.count) 题 · 每答对一题 +5 XP").font(.caption2).foregroundStyle(.secondary)
                    } else {
                        Text("今天的任务都完成了").font(.title2.bold())
                        Text("明天会有新的复习和新词。也可以在「学习」里重温任意单元。").font(.subheadline).foregroundStyle(.secondary)
                    }
                }.padding(24).background(GardenStyle.soft, in: RoundedRectangle(cornerRadius: 24))
                VStack(alignment: .leading, spacing: 14) {
                    HStack { Text("每天一个小目标").font(.headline); Spacer(); Text("\(store.todayXP) / \(store.progress.goal) XP").font(.caption).foregroundStyle(GardenStyle.green) }
                    ProgressView(value: min(Double(store.todayXP), Double(store.progress.goal)), total: Double(store.progress.goal))
                    Text(store.todayXP >= store.progress.goal ? "今天的目标已完成，做得好！" : "一点点练习，也是一点点成长。").font(.caption).foregroundStyle(.secondary)
                }.gardenCard()
                if let unit = store.currentUnit {
                    Text("当前单元：" + unit.title).font(.title3.bold())
                    UnitMenu(career: career, unit: unit)
                }
                HStack {
                    Label("连续学习 \(store.streak) 天", systemImage: "flame")
                    Spacer()
                    Text("Lv.\(store.progress.xp / 100 + 1)")
                }.font(.subheadline.weight(.medium)).foregroundStyle(GardenStyle.green).gardenCard()
            }
        }
    }
    private func summary(for lesson: Lesson) -> String {
        if lesson.id.hasSuffix("-review") { return "先把做错的题弄懂，再开始今天的记忆。" }
        if lesson.id.contains("-daily-") {
            let (due, fresh) = store.dailyWords
            return "复习 \(due.count) 个 · 新词 \(fresh.count) 个。按记忆曲线安排，越熟的词隔得越久。"
        }
        return "今日记忆已完成，继续学习当前单元。"
    }
    private func buttonTitle(for lesson: Lesson) -> String {
        if lesson.id.hasSuffix("-review") { return "先复习错题" }
        return lesson.id.contains("-daily-") ? "开始今日记忆" : "继续学习"
    }
}
struct UnitMenu: View {
    @EnvironmentObject private var store: LearningStore
    let career: Career
    let unit: CourseUnit
    var body: some View {
        let lessons = career.lessons(for: unit)
        VStack(spacing: 12) {
            NavigationLink { WordsView(career: career, unit: unit) } label: { menuRow("词汇", detail: "\(unit.words.count) 个核心词 · 发音与例句", symbol: "character.book.closed.fill", lesson: lessons[0]) }
            NavigationLink { GrammarView(career: career, unit: unit) } label: { menuRow("语法", detail: "\(unit.grammar.count) 个实用句型 · 场景化讲解", symbol: "textformat.abc", lesson: lessons[1]) }
            NavigationLink { SceneView(career: career, unit: unit) } label: { menuRow("情景练习", detail: "\(unit.dialogue.count) 句对话 · 听力练习", symbol: "bubble.left.and.bubble.right.fill", lesson: lessons[2]) }
        }.buttonStyle(.plain)
    }
    private func menuRow(_ title: String, detail: String, symbol: String, lesson: Lesson) -> some View {
        HStack(spacing: 16) {
            Image(systemName: symbol).font(.title2).foregroundStyle(GardenStyle.green).frame(width: 48, height: 48).background(GardenStyle.soft, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) { Text(title).font(.headline); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer(minLength: 0)
            if store.progress.completed.contains(lesson.id) { Image(systemName: "checkmark.circle.fill").foregroundStyle(GardenStyle.green) }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }.gardenCard()
    }
}
struct LibraryView: View {
    @EnvironmentObject private var store: LearningStore
    var body: some View {
        GardenScroll {
            if let career = store.career {
                VStack(alignment: .leading, spacing: 8) {
                    Text(career.english).font(.caption2).tracking(2).foregroundStyle(GardenStyle.green)
                    Text(career.name + "英语").font(.largeTitle.bold())
                    Text(overview(career)).font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(Array(career.allUnits.enumerated()), id: \.element.id) { index, unit in
                    NavigationLink { UnitView(career: career, unit: unit) } label: { unitRow(career: career, unit: unit, number: index + 1) }.buttonStyle(.plain)
                }
                VStack(alignment: .leading, spacing: 16) {
                    Label("本模式错题本", systemImage: "arrow.counterclockwise").font(.headline)
                    Text("\(store.currentMistakes.count) 道待复习。答对后自动移除，不影响其他身份的错题。 ").font(.subheadline).foregroundStyle(.secondary)
                    Button("开始复习") { store.activeLesson = store.reviewLesson }.buttonStyle(GardenButton()).disabled(store.currentMistakes.isEmpty)
                }.gardenCard()
                ForEach(store.currentGenerated) { lesson in
                    Button { store.activeLesson = lesson } label: { Label(lesson.title, systemImage: "sparkles").frame(maxWidth: .infinity, alignment: .leading).gardenCard() }.buttonStyle(.plain)
                }
                Text("学过的单词会按记忆曲线自动安排到「今日」复习。切换身份不会清除学习记录。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.id(store.progress.modeID)
    }
    private func overview(_ career: Career) -> String {
        let learned = career.allWords.filter { store.progress.reviews[$0.id] != nil }.count
        return "\(career.allUnits.count) 个单元 · \(career.allWords.count) 个词 · 已学 \(learned) 个"
    }
    private func unitRow(career: Career, unit: CourseUnit, number: Int) -> some View {
        let done = career.lessons(for: unit).filter { store.progress.completed.contains($0.id) }.count
        let detail = [unit.level, "\(unit.words.count) 词 · \(unit.grammar.count) 语法"].compactMap { $0 }.joined(separator: " · ")
        return HStack(spacing: 16) {
            Text("\(number)").font(.title2.bold()).foregroundStyle(GardenStyle.green).frame(width: 48, height: 48).background(GardenStyle.soft, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 5) { Text(unit.title).font(.headline); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer(minLength: 0)
            Text(done == 3 ? "已完成" : "\(done)/3").font(.caption.weight(.semibold)).foregroundStyle(GardenStyle.green)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }.gardenCard()
    }
}
struct UnitView: View {
    let career: Career
    let unit: CourseUnit
    var body: some View {
        GardenScroll {
            if let level = unit.level { Text(level).font(.caption2).tracking(2).foregroundStyle(GardenStyle.green) }
            Text(unit.title).font(.largeTitle.bold())
            UnitMenu(career: career, unit: unit)
        }.navigationTitle(career.name + " · " + unit.title)
    }
}
struct WordsView: View {
    @EnvironmentObject private var store: LearningStore
    let career: Career
    let unit: CourseUnit
    var body: some View {
        GardenScroll {
            Text("先听一听，再试着用它说一句话。").font(.subheadline).foregroundStyle(.secondary)
            ForEach(unit.words) { word in
                VStack(alignment: .leading, spacing: 13) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) { Text(word.term).font(.title2.bold()); Text(word.meaning).font(.subheadline).foregroundStyle(.secondary) }
                        Spacer()
                        Button { store.speak(word.term) } label: { Image(systemName: "speaker.wave.2.fill").padding(12).background(GardenStyle.soft, in: Circle()) }.accessibilityLabel("朗读 " + word.term)
                    }
                    Text(word.example).font(.body)
                    Text(word.translation).font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("听例句") { store.speak(word.example) }.font(.caption)
                        Spacer()
                        Button { store.markWord(word.id) } label: { Label(store.progress.knownWords.contains(word.id) ? "已掌握" : "标记已掌握", systemImage: store.progress.knownWords.contains(word.id) ? "checkmark.circle.fill" : "circle") }.font(.caption)
                    }
                }.gardenCard()
            }
            Button("开始词汇练习") { store.activeLesson = career.wordLesson(unit) }.buttonStyle(GardenButton())
        }.navigationTitle(unit.title + " · 词汇").onDisappear { store.stopSpeaking() }
    }
}
struct GrammarView: View {
    @EnvironmentObject private var store: LearningStore
    let career: Career
    let unit: CourseUnit
    var body: some View {
        GardenScroll {
            Text("语法放进真实场景，理解才更轻松。").font(.subheadline).foregroundStyle(.secondary)
            ForEach(unit.grammar) { rule in
                VStack(alignment: .leading, spacing: 15) {
                    Text(rule.title).font(.headline)
                    Text(rule.pattern).font(.body.weight(.medium)).foregroundStyle(GardenStyle.green)
                    Text(rule.explanation).font(.subheadline).foregroundStyle(.secondary)
                    Divider()
                    Text(rule.example).font(.body)
                    Text(rule.translation).font(.caption).foregroundStyle(.secondary)
                    Button { store.speak(rule.example) } label: { Label("听例句", systemImage: "speaker.wave.2") }.font(.caption)
                }.gardenCard()
            }
            Button("开始语法练习") { store.activeLesson = career.grammarLesson(unit) }.buttonStyle(GardenButton())
        }.navigationTitle(unit.title + " · 语法").onDisappear { store.stopSpeaking() }
    }
}
struct SceneView: View {
    @EnvironmentObject private var store: LearningStore
    let career: Career
    let unit: CourseUnit
    var body: some View {
        GardenScroll {
            Text(unit.title).font(.title3.bold())
            Text("按顺序听一遍对话，再试试听力练习。").font(.subheadline).foregroundStyle(.secondary)
            ForEach(Array(unit.dialogue.enumerated()), id: \.offset) { index, line in
                VStack(alignment: .leading, spacing: 10) {
                    Text(line.speaker.uppercased()).font(.caption2.weight(.semibold)).tracking(1).foregroundStyle(GardenStyle.green)
                    Text(line.english).font(.body)
                    Text(line.translation).font(.caption).foregroundStyle(.secondary)
                    Button { store.speak(line.english) } label: { Label("朗读", systemImage: "speaker.wave.2") }.font(.caption)
                }.gardenCard().padding(index % 2 == 0 ? .trailing : .leading, 20)
            }
            Button("开始情景听力") { store.activeLesson = career.sceneLesson(unit) }.buttonStyle(GardenButton())
        }.navigationTitle(unit.title + " · 情景").onDisappear { store.stopSpeaking() }
    }
}
struct SpeakingView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var attempt = ""
    @State private var feedback = ""
    @State private var shift = 0
    var body: some View {
        GardenScroll {
            if let career = store.career, let line = todayLine(career) {
                Text("让英语，有你的声音。").font(.title.bold())
                Text(career.name + " · 今日跟读").font(.subheadline).foregroundStyle(.secondary)
                VStack(spacing: 20) {
                    Image(systemName: "waveform.circle.fill").font(.system(size: 75)).foregroundStyle(GardenStyle.green)
                    Text(line.english).font(.title2.weight(.medium)).multilineTextAlignment(.center)
                    Text(line.translation).font(.subheadline).foregroundStyle(.secondary)
                    Button { store.speak(line.english) } label: { Label("听一听，再跟读", systemImage: "speaker.wave.2") }.buttonStyle(GardenButton())
                    TextField("输入或用键盘麦克风听写", text: $attempt, axis: .vertical).textFieldStyle(.roundedBorder).autocorrectionDisabled().textInputAutocapitalization(.never)
                    HStack {
                        Button("换一句") { shift += 1; attempt = ""; feedback = ""; store.stopSpeaking() }
                        Spacer()
                        Button("检查表达") {
                            let q = Question(type: "input", prompt: "跟读", english: nil, options: nil, answer: line.english, explain: "")
                            feedback = q.accepts(attempt) ? "文字表达一致，做得好！试着不看文字再说一遍。" : "参考表达：" + line.english + "\n请再听一遍，注意每一个词。"
                        }.disabled(attempt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    if !feedback.isEmpty { Text(feedback).font(.subheadline).accessibilityLabel(feedback) }
                }.gardenCard()
                Text("可点击系统键盘上的麦克风进行听写；是否可用由 iPhone 的听写设置决定。此处比对识别文字，不提供专业发音评分。系统听写的隐私与联网行为以 Apple 设置为准。")
                    .font(.caption).foregroundStyle(.secondary)
                if let unit = store.currentUnit {
                    NavigationLink { SceneView(career: career, unit: unit) } label: { Label("更多" + career.name + "对话", systemImage: "bubble.left.and.bubble.right").frame(maxWidth: .infinity).gardenCard() }
                }
            }
        }.id(store.progress.modeID).onChange(of: store.progress.modeID) { _, _ in attempt = ""; feedback = ""; shift = 0 }.onDisappear { store.stopSpeaking() }
    }
    /// 每天自动换一句，也可以手动换。
    private func todayLine(_ career: Career) -> DialogueLine? {
        let lines = career.allDialogue
        guard !lines.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return lines[(day + shift) % lines.count]
    }
}
struct ProfileView: View {
    @EnvironmentObject private var store: LearningStore
    var body: some View {
        Form {
            Section("我的成长") {
                LabeledContent("累计 XP", value: "\(store.progress.xp)")
                LabeledContent("连续学习", value: "\(store.streak) 天")
                LabeledContent("完成课程", value: "\(store.progress.completed.count) 节")
                LabeledContent("已学单词", value: "\(store.progress.reviews.count) 个")
                LabeledContent("长期记住", value: "\(store.rememberedCount) 个")
            }
            Section("成就徽章") {
                achievement("第一颗种子", detail: "完成一节课程", earned: !store.progress.completed.isEmpty, symbol: "leaf.fill")
                achievement("三日向阳", detail: "连续学习三天", earned: store.streak >= 3, symbol: "sun.max.fill")
                achievement("点滴成光", detail: "累计获得 100 XP", earned: store.progress.xp >= 100, symbol: "sparkles")
                achievement("花园初成", detail: "完成三节课程", earned: store.progress.completed.count >= 3, symbol: "tree.fill")
            }
            Section("我的节奏") {
                TextField("称呼", text: $store.progress.name).onChange(of: store.progress.name) { _, name in if name.count > 16 { store.progress.name = String(name.prefix(16)) } }
                Picker("每日目标", selection: $store.progress.goal) { ForEach([10,20,30,50], id: \.self) { Text("\($0) XP").tag($0) } }
                Picker("每日新词", selection: $store.progress.newPerDay) { ForEach([5,10,15,20], id: \.self) { Text("\($0) 个").tag($0) } }
            }
            Section {
                TextField("https://你的 AI 服务地址", text: $store.progress.aiURL).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                Text("连接运行本地 Ollama 的 Node 服务，只填写你信任的 HTTPS 地址。默认不连接任何服务；没有模型时仍可离线学习。这里的本地 AI 位于你的服务器，不在 iPhone 内运行。").font(.caption).foregroundStyle(.secondary)
            } header: { Text("AI 老师 · 可选") }
            Section {
                Text("课程与学习进度存储在这台 iPhone 上，无需注册。删除 App 会清除记录，尚不支持跨设备同步。法律及医护内容仅用于英语学习，不替代专业判断。").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    private func achievement(_ title: String, detail: String, earned: Bool, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(earned ? GardenStyle.green : .gray).frame(width: 25)
            VStack(alignment: .leading) { Text(title); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer(); Text(earned ? "已获得" : "待解锁").font(.caption).foregroundStyle(.secondary)
        }
    }
}

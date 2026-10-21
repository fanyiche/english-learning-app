import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var store: LearningStore
    @Environment(\.dismiss) private var dismiss
    let lesson: Lesson
    @State private var index = 0
    @State private var selected = ""
    @State private var checked = false
    @State private var isCorrect = false
    @State private var correct = 0
    @State private var finished = false
    @State private var showTranscript = false
    @State private var confirmExit = false
    var body: some View {
        NavigationStack {
            GardenScroll {
                if finished {
                    VStack(spacing: 24) {
                        Image(systemName: "leaf.circle.fill").font(.system(size: 95)).foregroundStyle(GardenStyle.green)
                        Text("又向前走了一小步！").font(.title2.bold())
                        Text("本次答对 \(correct) / \(lesson.questions.count) 题").foregroundStyle(.secondary)
                        Text("+\(correct * 5) XP").font(.largeTitle.bold()).foregroundStyle(GardenStyle.green)
                        Text(correct * 5 >= lesson.questions.count * 3 ? "今天的努力，为你的小花园添了一片绿。" : "达到 60% 正确率即可完成课程，错题已自动保存。")
                            .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.secondary)
                        Button("回到学习") { dismiss() }.buttonStyle(GardenButton())
                    }.padding(.vertical, 40)
                } else if index < lesson.questions.count {
                    let question = lesson.questions[index]
                    ProgressView(value: Double(index), total: Double(lesson.questions.count))
                    Text("第 \(index + 1) / \(lesson.questions.count) 题").font(.caption).foregroundStyle(.secondary)
                    Text(question.prompt).font(.title2.bold())
                    if question.type == "listen", let english = question.english {
                        Button { store.speak(english) } label: { Label("点击播放", systemImage: "speaker.wave.2.fill").font(.title3).frame(maxWidth: .infinity).padding(25).background(GardenStyle.soft, in: RoundedRectangle(cornerRadius: 18)) }
                        Button(showTranscript ? "隐藏听力文本" : "显示听力文本") { showTranscript.toggle() }.font(.caption)
                        if showTranscript { Text(english).font(.body).foregroundStyle(.secondary) }
                    } else if let english = question.english {
                        Text(english).font(.title3).frame(maxWidth: .infinity, alignment: .leading).padding(20).background(GardenStyle.soft, in: RoundedRectangle(cornerRadius: 16))
                    }
                    if let options = question.options, !options.isEmpty {
                        ForEach(options, id: \.self) { option in
                            Button { selected = option } label: {
                                HStack { Text(option).multilineTextAlignment(.leading); Spacer(minLength: 8); Image(systemName: (checked && option == question.answer) || selected == option ? "checkmark.circle.fill" : "circle") }
                                    .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(selected == option || (checked && option == question.answer) ? GardenStyle.soft : Color.white, in: RoundedRectangle(cornerRadius: 15))
                                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(selected == option ? GardenStyle.green : GardenStyle.green.opacity(0.15)))
                            }.buttonStyle(.plain).disabled(checked)
                        }
                    } else {
                        TextField("输入你的答案", text: $selected).textFieldStyle(.roundedBorder).autocorrectionDisabled().textInputAutocapitalization(.never).disabled(checked)
                    }
                    if checked {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(isCorrect ? "答对了，做得好！" : "没关系，这是学习的机会", systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.counterclockwise").font(.headline)
                            if !isCorrect { Text("正确答案：" + question.answer).font(.subheadline) }
                            Text(question.explain).font(.subheadline).foregroundStyle(.secondary)
                        }.gardenCard()
                    }
                    Button(checked ? (index == lesson.questions.count - 1 ? "查看学习成果" : "继续") : "检查答案") {
                        if checked {
                            if index == lesson.questions.count - 1 {
                                store.finish(lesson, correct: correct)
                                finished = true
                            } else {
                                store.stopSpeaking()
                                index += 1; selected = ""; checked = false; showTranscript = false
                            }
                        } else {
                            isCorrect = question.accepts(selected)
                            if isCorrect { correct += 1 }
                            store.record(question, lesson: lesson, correct: isCorrect)
                            checked = true
                        }
                    }.buttonStyle(GardenButton()).disabled(!checked && selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    ContentUnavailableView("还没有待练习的题目", systemImage: "checkmark.circle")
                    Button("返回学习") { dismiss() }.buttonStyle(GardenButton())
                }
            }
            .navigationTitle(lesson.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { if finished { dismiss() } else { confirmExit = true } } } }
            .confirmationDialog("退出本次练习？已产生的错题会保留，XP 在完成练习后结算。", isPresented: $confirmExit, titleVisibility: .visible) {
                Button("退出练习", role: .destructive) { dismiss() }
                Button("继续学习", role: .cancel) {}
            }
        }.onDisappear { store.stopSpeaking() }
    }
}

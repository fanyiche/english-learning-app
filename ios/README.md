# 英语花园 · 原生 iPhone 应用

此目录为 SwiftUI 原生 iOS 工程，不使用网页套壳。最低 iOS 17；支持 iPhone。内置五种学习模式：学生、律师、餐馆从业者、医护人员、商务办公。

## 没有 Mac

可使用云端 Mac 编译：有 Windows 和免费 Apple ID 时，可走[个人侧载路线](WINDOWS-INSTALL.md)，通常约 7 天需续签；有付费会员时可走 TestFlight。已加入手动 GitHub Actions 模拟器编译检查；真正安装还需 Apple 签名和上传配置，见 [云端构建说明](CLOUD-BUILD.md)。此流程尚未在云端执行。

## 使用 Mac 安装到 iPhone

需要一台安装 Xcode 15 或更新版本的 Mac，以及用于签名的 Apple ID。连接较新系统的 iPhone 时，使用支持该设备系统版本的 Xcode。

1. 在 Mac 下载本仓库，打开 `ios/LingoGarden.xcodeproj`。
2. 选择 `LingoGarden` target → Signing & Capabilities。
3. 将 `com.example.LingoGarden` 改为自己唯一的 Bundle Identifier，并在 Team 中选择自己的开发团队。仓库不包含签名证书或开发团队信息。
4. 连接 iPhone，按系统提示信任电脑，并在设备设置中开启开发者模式。
5. 在 Xcode 顶部选择该 iPhone，点击 Run。首次安装可能还需要在设备中信任开发者。

可先选择 iPhone 模拟器运行。个人 Apple ID 可用于受限的开发调试；TestFlight 或 App Store 分发另需合适的 Apple Developer 资格、归档签名及审核。

本仓库尚未生成或验证 `.ipa`，没有 App Store 或 TestFlight 下载链接。当前云环境为 Linux，无法运行 Xcode、iOS 模拟器或执行设备签名。

## Mac 编译检查

```sh
xcodebuild \
  -project ios/LingoGarden.xcodeproj \
  -scheme LingoGarden \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/LingoGardenDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

上面是待在 Mac 执行的验证命令，当前没有执行过，不能当作编译已通过的证据。

## 当前功能

- 顶部身份菜单随时切换五种模式；每种有独立词汇、语法、对话入口。
- 40 个词汇：含中文含义、英文例句、中文例句释义、系统英语朗读与掌握标记。
- 15 个语法点：含句型、中文解释、场景例句与选择题。
- 各模式的双语情景对话、8 题词汇练习、3 题语法练习和 3 题听力练习，共 70 道题。
- 即时判分与解释、60% 完成门槛、每题 5 XP、连续学习、每日目标、4 种徽章。
- 错题按模式隔离，答对即移除。退出未完成练习不结算 XP，已产生错题仍保留。
- 推荐优先复习当前模式错题，随后是词汇、语法、情景。
- 使用 UserDefaults 保存本机进度；无需注册。跨设备同步、云备份恢复和账号系统尚未实现。
- 听说页提供系统朗读及输入比对；可通过系统键盘麦克风听写，没有声学发音评分。使用听写与否由用户控制，并遵循 Apple 的听写设置与隐私行为。

内置课程打包在 App 中，不需要 Node 服务、网络或 AI 模型。英语朗读依赖设备可用的英文语音。

## 可选 AI 老师

在“我的”中填写运行本仓库 Node 服务的 HTTPS 根地址。服务器需要同时运行 Ollama 并安装模型，配置见仓库根 README。不能填写 iPhone 自身的 localhost 来连接你的电脑。

- 对话、语法解释和生成课程均携带当前职业与最近错题。
- 生成课程经结构校验后保存为当前模式的可练习课程。
- 未连接时明确提示，不用固定答案冒充模型输出。
- 这是你配置的服务器上的本地模型，并非 iPhone 端大模型。发送后，对话及错题会传到该服务器；只应配置你信任的服务。
- 本应用要求 HTTPS，不全局关闭 iOS App Transport Security。公开部署前应为服务增加访问控制与限流。
- 真实模型推理、原生网络请求和手机端课程生成尚未在设备上验证。

## 内容更新与检查

课程的唯一编辑源为 `public/careers.json`。修改后运行 `npm run sync:courses`，将同一份内容复制到原生资源目录。`npm test` 会检查两份内容一致、各模式词汇和语法完整、练习可判分及路径隔离。

当前已完成 Swift 源码语法解析、Xcode 工程格式解析、资源引用核对和共享内容测试。这些静态检查无法证明 SwiftUI 类型检查、链接、设备权限或运行行为正确。

## 真机验收清单（待执行）

- 用 Xcode 编译并安装，冷启动正常，所有内置课程可离线打开。
- 逐一切换五种身份，词汇、语法、听力及推荐随之更新。
- 在餐馆模式答错一题，切换律师模式，错题不混入；切回来可复习。
- 完成练习，核对 XP、完成门槛、徽章与每日目标；退出重启后进度仍在。
- 关闭与继续练习、后台再前台、大号字体、VoiceOver、窄屏显示正常。
- 系统英文朗读、键盘听写、音频中断，以及可选 AI 服务的超时和错误提示正常。

上架前还需应用隐私说明、真实设备覆盖、App Store 元数据及内容审校。法律/医护内容仅用于英语学习。已加入 UserDefaults 所需的 PrivacyInfo.xcprivacy；正式发布时应核对当时 Apple 的申报要求和实际服务的数据处理行为。

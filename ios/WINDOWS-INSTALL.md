# 没有 Mac、没有付费会员：Windows 个人侧载

这是原生 SwiftUI iPhone 应用的个人调试安装路线。需要 Windows 电脑、USB 连接线、Apple ID、兼容的 iPhone（本项目最低 iOS 17）与用于签名的侧载工具。不需要越狱。免费开发签名通常约 7 天需续签，Apple 对免费账号的设备/应用数量等有限制，规则和工具兼容性可能变化。

## 当前状态

已准备 GitHub Actions 的真机未签名构建流程，以及生成 `.ipa` 的脚本。当前尚未推送或触发工作流，原生工程尚未经 Xcode 编译，因此**还没有真实生成或验证过的 iPhone 安装包**。打包脚本不产生 Apple 签名，不会让未签名包直接可安装。

## 第一步：在云端生成真机包

1. 将本仓库当前修改提交到自己的 GitHub 仓库默认分支，包括 `.github/workflows/ios-build.yml`。
2. GitHub 仓库 → Actions → iOS cloud build check → Run workflow。
3. 检查 `Build device IPA for personal re-signing` 任务是否成功；失败时查看 Xcode 诊断并修复编译问题，不能将源码 zip 当安装包使用。
4. 成功后下载 `LingoGarden-device-IPA-needs-personal-signing` artifact，解压得到 `LingoGarden-unsigned.ipa`。
5. 模拟器产物 `LingoGarden-simulator-not-for-iPhone-install` 无法用于真机安装，请不要混用。

云端 macOS runner 的可用额度/费用取决于 GitHub 账户和计划。流程支持手动启动，并在 codex/iphone-app 分支的相关文件推送时自动启动。当前没有进行任何付费构建或发布。

## 第二步：Windows 签名并安装

可评估 Sideloadly 等个人侧载工具。只从其官方网站 https://sideloadly.io/ 下载，核对当前 Windows、iPhone 系统、Apple 驱动及 Apple ID 登录要求。此工具为第三方软件，和本项目无关联。本次云环境访问该官网返回 HTTP 403，因此没有验证当前下载版本或最新兼容性，也没有下载或执行其程序。

通常的安装过程为：

1. 按工具官方说明安装 Windows 所需的 Apple 驱动/组件与侧载工具。
2. 用 USB 连接并解锁 iPhone，在手机上选择信任电脑。
3. 在工具中选择手机，导入云端生成的真机 `.ipa`，使用自己的 Apple ID 完成个人开发签名。账号、验证码等仅在你核实的工具/Apple 登录流程中处理，不要发给聊天助手。
4. 按 iPhone 的提示，在“设置 → 隐私与安全性”中启用开发者模式；若要求，在“设置 → 通用 → VPN 与设备管理”信任对应开发者。
5. 打开英语花园，检查五模式、朗读、答题和保存。遇到安装错误时记录错误信息，不要提交密码、验证码、完整设备标识或证书私钥。

免费签名通常约 7 天到期。到期前使用同一 Apple ID、相同 Bundle ID 和同一 App 续签；不要先删除 App，以免丢失本机进度。工具可能支持自动刷新，但依赖其当前版本、电脑与手机连接条件，不能保证永久自动续签。

## 如果只有 iPhone

这条个人侧载路线通常无法仅靠 iPhone 完成。可借用一台可信任的 Windows 电脑进行安装/续签，或使用需要合适付费开发者资格的 TestFlight 分发路线。地区限定的其他分发渠道并非所有设备和账号都可用。

本项目没有企业分发证书、可直接安装链接或无需签名的 IPA；不会提供越狱、共享来源不明证书或绕过 Apple 签名校验的方法。

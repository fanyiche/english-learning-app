# 没有 Mac：云端编译与 iPhone 安装

不用购买 Mac。原生 iOS 应用仍必须在 macOS/Xcode 环境编译，但可以使用云端 Mac。编译检查与签名分发是两个独立阶段。

## 1. 已准备：GitHub Actions 云端编译检查

工作流文件：`.github/workflows/ios-build.yml`。

将本地修改提交到自己的 GitHub 仓库后，在仓库页面进入 Actions → iOS cloud build check → Run workflow。默认分支必须存在该工作流，页面才会显示手动运行入口。也支持 codex/iphone-app 分支相关文件推送时自动启动。只需浏览器，不要求自己的电脑运行 macOS。

该手动流程在 GitHub 托管的 macOS runner 上执行课程测试、Xcode 模拟器编译及真机未签名编译，分开保留产物与诊断 7 天。不需要 Apple 证书。私有仓库的 runner 分钟数和费用取决于 GitHub 账户与当前计划；触发前查看自己账户的 Actions 额度。

**模拟器产物不能装到真实 iPhone；真机 IPA 仍需个人签名。** 工作流尚未推送或触发，不能声称云端编译已经通过。此阶段首先发现和修复原生编译问题。

## 2. 无付费会员：Windows 个人侧载

已增加未签名真机 IPA 的云端构建任务。可在 Windows 上使用免费 Apple ID 和兼容的侧载工具进行个人开发签名，通常约 7 天需续签。详见 [Windows 安装说明](WINDOWS-INSTALL.md)。这条路线仍未生成真实构建，也未验证第三方工具兼容性。

## 3. 真机分发：Apple Developer + TestFlight

推荐给没有 Mac、希望使用原生 App 的用户。需要付费 Apple Developer 会员；具体资格、费用和流程以 Apple 当地页面为准。

需要完成的配置：

1. 注册开发者会员，在 Apple Developer / App Store Connect 建立自己的应用标识和应用记录。Bundle ID 必须一致，不能继续使用工程里的示例标识。
2. 准备用于 App Store 分发的签名证书及对应私钥、描述文件。没有 Mac 时可以使用云端 Mac，或支持代管 iOS 签名的构建服务完成初始配置。
3. 在构建平台的加密设置中配置证书、证书密码与 App Store Connect 上传权限。**不要将账号密码、验证码、私钥或证书内容发到聊天中，也不要提交到仓库。**
4. 后续配置云端真机归档、签名和上传流程。目前的 `ios-build.yml` 编译模拟器和未签名真机包，没有 Apple 分发签名或上传步骤。
5. 上传成功并完成 Apple 处理/必要审核后，通过 TestFlight 邀请链接在 iPhone 安装。外部测试可能需要 Beta App Review；TestFlight 构建有有效期，后续需要更新。

当前仓库不包含签名身份、Apple 账号绑定、真机归档或 TestFlight 发布记录。开通会员本身不会自动生成安装包；还需完成签名与上传配置。

## 4. 主屏幕网页版本

现有网页版本支持相同的五种学习模式。将 Node 应用部署到可访问的 HTTPS 服务后，在 iPhone Safari 打开 → 分享 → 添加到主屏幕。核心课程与本机进度支持离线使用。

这种方式不经过 App Store，不需要 Apple Developer 会员，但属于可安装网页应用，和原生 SwiftUI App 是两种交付形式。当前还没有部署完成的公网使用链接。AI 老师仍需要运行模型的服务器，不会自动在 iPhone 上运行。

# 应用内标准功能键

当以下应用在前台时，直接按 F1–F12 即发送标准功能键，Shift / Control / Option / Command 组合仍可使用。F3 在这些应用中为 F3，其他应用中为 Globe（Fn）。系统的标准功能键开关保持 Off；切换应用不修改系统开关。

- Minecraft 与其他 Java 桌面程序：匹配以 `/bin/java` 结尾的进程路径，以及 OpenJDK / LWJGL 应用标识。
- macOS 屏幕共享、Apple Remote Desktop。
- Microsoft Remote Desktop / Windows App。
- TeamViewer、AnyDesk、RustDesk、Jump Desktop。
- Parsec、Moonlight、Splashtop。
- VNC Viewer、TigerVNC、NoMachine、Screens、Royal TSX。
- ToDesk、向日葵（Sunlogin）、网易 UU 远程。
- Chrome Remote Desktop 独立应用窗口（PWA），兼容多 Chrome 配置文件。

应用按 bundle identifier 或可执行文件路径匹配。客户端的不同版本或自定义名称可能需要补充标识；普通浏览器标签页中的远程桌面不包含在此规则中，以免影响浏览器内其他网页。远程端能否收到某个快捷键，还取决于客户端自己的按键转发设置。

## 添加应用

在 Karabiner-EventViewer 的 Frontmost Application 中查看目标窗口的 bundle identifier / file path。在 `config/karabiner-profile.json` 第一条复杂规则的 `frontmost_application_if` 中补充对应正则表达式；12 个 F 键的条件需要同步修改。安装后也可在 Karabiner 的 Complex Modifications 中直接编辑此规则。

规则位于列表开头，优先于其他复杂修改。它在标准功能键模式关闭时输出 `fn+F1–F12`，避免后续媒体键转换；这遵循 [Karabiner 官方功能键说明](https://karabiner-elements.pqrs.org/docs/help/how-to/function-keys/)。

## Chrome Remote Desktop

使用从 `remotedesktop.google.com` 安装的独立 PWA 窗口。普通 Chrome 窗口和其他 PWA 不受此规则影响。规则包含当前官方 PWA 标识、多配置文件前缀和旧版 Chrome 应用标识，并按应用名称路径提供后备匹配。

参考：[Google 官方 PWA 清单](https://remotedesktop.google.com/_/RemotingUi/manifest.json)、[Chromium 应用标识生成逻辑](https://github.com/chromium/chromium/blob/main/chrome/browser/web_applications/app_id_helpers.cc)。UU 远程应用标识为 `com.netease.uuremote`，来自[官方安装包](https://uuyc.163.com/download/)。

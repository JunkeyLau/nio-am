# NIO Link 横屏测试

记录一代 NIO Phone 在 Cedar S 横屏车机上通过 NIO Link 显示 Apple Music 的测试。用于定位竖屏窄窗和黑边出现在手机应用窗口还是车机显示阶段。

## 停车后测试

1. 用 USB 数据线把 NIO Phone 连到 Mac，在手机上开启 USB 调试并允许连接。
2. 在车机「天空视窗」里打开要测试的应用，保持出现黑边的页面。如果应用也能从「NIO Link 应用」打开，可以用同一页面做对照。
3. 双击 [窗口检测脚本](nio-link-window-check-2026-11-11-v2.command)。输出包含逻辑屏幕、显示区域、父窗口和应用窗口的像素尺寸。

脚本默认读取横屏测试版的包名。检测其他应用时，可以在终端传入该应用的包名。例如，检测官方 Apple Music：

~~~sh
./nio-link-window-check-2026-11-11-v2.command com.apple.android.music
~~~

如果手机报告的应用窗口已是横屏，车机画面仍是竖窗，优先检查车机的显示方式。如果逻辑屏幕是横屏而应用窗口仍是竖屏，优先检查手机侧的窗口和方向设置。

脚本已用模拟数据验证。Cedar S 实车窗口、安装、登录和播放待测。仓库提供测试说明和诊断脚本。Apple Music 安装包请从 Apple 官方渠道获取。

[蔚来天空视窗使用指南](https://phone.nio.com/niolink-guide/how-to-use-nio-phone-in-the-vehicle-centeral-control-screen)

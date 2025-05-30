import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    
    // 🔥 新增：设置16:9比例的默认窗口大小（1280x720）
    let defaultWidth: CGFloat = 1280
    let defaultHeight: CGFloat = 720
    let screenFrame = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    
    // 计算居中位置
    let x = (screenFrame.width - defaultWidth) / 2
    let y = (screenFrame.height - defaultHeight) / 2
    
    let windowFrame = CGRect(x: x, y: y, width: defaultWidth, height: defaultHeight)
    
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // 🔥 新增：设置窗口属性
    self.minSize = CGSize(width: 960, height: 540) // 最小尺寸也保持16:9比例
    self.title = "Send To Myself"

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

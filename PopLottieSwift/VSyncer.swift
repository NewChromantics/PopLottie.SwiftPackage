import Foundation
import QuartzCore
import CoreVideo

class VSyncer
{
	public var Callback : ()->Void
	
	
	init(Callback:@escaping ()->Void)
	{
		self.Callback = Callback
		
		//	macos 14.0 has CADisplayLink but no way to use it
#if os(macOS)
		let timer = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(OnVsync), userInfo: nil, repeats: true)
#else
		let displayLink = CADisplayLink(target: self, selector: #selector(OnVsync))
		displayLink.add(to: .current, forMode: .default)
#endif
	}
	
	@objc func OnVsync()
	{
		Callback()
	}
}



/*
internal protocol DisplayLinkProtocol: AnyObject
{
	var callback: () -> Void { get set }
	func activate()
}

final class DisplayLink: DisplayLinkProtocol {
    var callback: () -> Void = {}
    private var link: CVDisplayLink?

    deinit {
        guard let link = link else {
            return
        }

        CVDisplayLinkStop(link)
    }

    func activate() {
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let link = link else {
            return
        }

        let opaquePointerToSelf = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkSetOutputCallback(link, _imageEngineDisplayLinkCallback, opaquePointerToSelf)

        CVDisplayLinkStart(link)
    }

    @objc func screenDidRender() {
        DispatchQueue.main.async(execute: callback)
    }
}

// swiftlint:disable:next function_parameter_count
private func _imageEngineDisplayLinkCallback(displayLink: CVDisplayLink,
                                             _ now: UnsafePointer<CVTimeStamp>,
                                             _ outputTime: UnsafePointer<CVTimeStamp>,
                                             _ flagsIn: CVOptionFlags,
                                             _ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
                                             _ displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn {
    unsafeBitCast(displayLinkContext, to: DisplayLink.self).screenDidRender()
    return kCVReturnSuccess
}
*/

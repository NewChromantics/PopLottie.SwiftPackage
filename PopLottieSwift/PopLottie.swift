import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
#else//macos
import AppKit
typealias UIView = NSView
typealias UIColor = NSColor
typealias UIRect = NSRect
typealias UIViewRepresentable = NSViewRepresentable
#endif




class RenderView : UIView
{
	//var wantsLayer: Bool	{	return true	}
	//	gr: don't seem to need this
	//override var wantsUpdateLayer: Bool { return true	}
	public var renderer : AnimationRenderer
	var vsync : VSyncer? = nil

#if os(macOS)
	override var isFlipped: Bool { return true	}
#endif
	
	required init?(coder: NSCoder)
	{
		fatalError("init(coder:) has not been implemented")
	}

	//	on macos this is CALayer? on ios, it's just CALayer. So this little wrapper makes them the same
	var viewLayer : CALayer?
	{
		return self.layer
	}
	
	var shapeRootLayer = CALayer()
	
	init(renderer:AnimationRenderer)
	{
		self.renderer = renderer;
		
		super.init(frame: .zero)
		// Make this a layer-hosting view. First set the layer, then set wantsLayer to true.
		
#if os(macOS)
		wantsLayer = true
		//self.needsLayout = true
#endif
		viewLayer!.addSublayer(shapeRootLayer)

		vsync = VSyncer(Callback: Render)
	}
	
	
	func startRenderLoop()
	{
		
	}


	
#if os(macOS)
	override func layout()
	{
		super.layout()
		OnContentsChanged()
	}
#else
	override func layoutSubviews()
	{
		super.layoutSubviews()
		OnContentsChanged()
	}
#endif
	
	func UpdateLayer(layer:CAShapeLayer,shape:AnimationShape)
	{
		//	gr: we need some caching here!
		//		esp with CreateCGPath
		
		CATransaction.begin()
		//	turn off animations for a change of the layer
		//	gr: there's still one ghosting after this, but that may be animation/lerping, rather than CALayer
		CATransaction.setDisableActions(true)
		
		layer.path = shape.CreateCGPath()
		layer.fillColor = shape.FillColour?.cgColor
		layer.strokeColor = shape.StrokeColour?.cgColor
		layer.lineWidth = CGFloat(shape.StrokeWidth)
		layer.fillRule = CAShapeLayerFillRule.evenOdd
		
		CATransaction.commit()
	}

	func OnContentsChanged()
	{
		let contentRect = self.bounds
		
		//shapeRootLayer.bounds = self.bounds
		shapeRootLayer.frame = contentRect
		
		let AnimFrame = renderer.Render(contentRect: contentRect)
		let Shapes = AnimFrame.GetShapes(IncludeDebug:false)
		
		while ( shapeRootLayer.sublayers?.count ?? 0 > Shapes.count )
		{
			shapeRootLayer.sublayers!.removeLast()
		}
		while ( shapeRootLayer.sublayers?.count ?? 0 < Shapes.count )
		{
			/*	gr: may need to do content flipping in an overloaded layer
			with
			-(BOOL)contentsAreFlipped {
				return YES;
			}
			 */
			shapeRootLayer.addSublayer( CAShapeLayer() )
		}

		//	update sublayers to match new shapes
		//	gr: todo: map these for animations, but make sure we keep the order that comes in
		if var SubLayers = shapeRootLayer.sublayers
		{
			for Index in 0...Shapes.count-1
			{
				let Layer = SubLayers[Index] as! CAShapeLayer
				let Shape = Shapes[Index]
				Layer.frame = contentRect
				//Layer.bounds = contentRect
				UpdateLayer( layer:Layer, shape:Shape )
			}
		}
	}
	
	@objc func Render()
	{
		//self.layer?.setNeedsDisplay()
		OnContentsChanged()
	}

}

struct RenderViewRep : UIViewRepresentable
{
	typealias UIViewType = RenderView
	typealias NSViewType = RenderView
	
	var renderer : AnimationRenderer
	
	init(renderer:AnimationRenderer)
	{
		self.renderer = renderer
		//contentLayer.contentsGravity = .resizeAspect
	}

	func makeUIView(context: Context) -> RenderView 
	{
		let view = RenderView(renderer: renderer)
		return view
	}
	
	func makeNSView(context: Context) -> RenderView
	{
		let view = RenderView(renderer: renderer)
		return view
	}

	//	gr: this occurs when the RenderViewRep() is re-initialised, (from uiview redraw)
	//		but the UIView underneath has persisted
	func updateUIView(_ view: RenderView, context: Context)
	{
		view.renderer = self.renderer
	}
	func updateNSView(_ view: RenderView, context: Context)
	{
		updateUIView(view,context: context)
	}
}





public struct LottieView : View, AnimationRenderer
{
	public var fileUrl : URL?=nil
	public var filename : String=""
	public var scaleMode = ScaleMode.ScaleToFit

	//	this is essentially state
	public var startTime : Date
	var animation : PathAnimation? = nil
	public var OnPreRender : (AnimationFrame)->Void

	var animTime : TimeInterval
	{
		//	now -> old time is backwards
		return -startTime.timeIntervalSinceNow
	}
	
	func Render(contentRect: CGRect) -> AnimationFrame
	{
		if let anim = animation
		{
			let AnimTime = animTime * 1.0
			let IncludeHiddenLayers = false	//	need to keep hidden layers to avoid CAShapeLayer implicit animations
			let Layers = anim.Render(PlayTime: AnimTime, contentRect: contentRect, scaleMode: scaleMode, IncludeHiddenLayers: IncludeHiddenLayers)
			OnPreRender(Layers)
			return Layers
		}
		return AnimationFrame()
	}
	
	public init(resourceFilename:String)
	{
		print("lottie init")
		let ResourceUrl = Bundle.main.url(forResource: resourceFilename, withExtension: "json")
		let noop : (AnimationFrame)->Void = {_ in }
		self.init( filename: ResourceUrl!, OnPreRender:noop )
		self.filename = resourceFilename
	}
	
	public init(resourceFilename:String,OnPreRender:@escaping (AnimationFrame)->Void)
	{
		print("lottie init")
		let ResourceUrl = Bundle.main.url(forResource: resourceFilename, withExtension: "json")
		self.init( filename: ResourceUrl!, OnPreRender:OnPreRender )
		self.filename = resourceFilename
	}

	public init(filename:URL,OnPreRender:@escaping (AnimationFrame)->Void)
	{
		self.fileUrl = filename
		self.startTime = Date.now
		self.animation = LottieAnimation(filename: filename)
		self.OnPreRender = OnPreRender
	}
		
	//	use pre-existing/loaded doc
	public init(lottie:Root,OnPreRender:@escaping (AnimationFrame)->Void)
	{
		self.startTime = Date.now
		self.animation = LottieAnimation(lottie: lottie)
		self.OnPreRender = OnPreRender
	}

	public var body: some View
	{
		ZStack()
		{
			/*
			Rectangle()
				.foregroundColor(Color.red)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		
			Text("\(animTime)secs")	//	this is not state, so wont update
				.font(.system(size: 20))
				.foregroundColor(Color.yellow)
			 */
			RenderViewRep(renderer: self)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
		}
	}
}

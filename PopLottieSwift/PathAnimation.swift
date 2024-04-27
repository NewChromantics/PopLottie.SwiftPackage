import Foundation
import SwiftUI
import QuartzCore
public typealias Vector2 = CGPoint
public typealias FrameNumber = Double


//	gr: using CGColor ends up with OS calls and retains and such
//		swift color also has extra work, so lets have a really simple, dumb colour type and do minimal conversion in specific renderers
struct AnimationColour
{
	var red,green,blue : Double
	var alpha = 1.0
	
	var cgColor : CGColor	{	return CGColor(red:red,green: green,blue: blue,alpha: alpha)	}
	
	static public var magenta : AnimationColour	{	return AnimationColour(red:1,green:0,blue:1)	}
	static public var blue : AnimationColour	{	return AnimationColour(red:0,green:0,blue:1)	}
}


extension CGColor
{
	static public var green : CGColor	{	return CGColor(red:0,green:1,blue:0,alpha:1)	}
	static public var yellow : CGColor	{	return CGColor(red:1,green:1,blue:0,alpha:1)	}
	static public var red : CGColor		{	return CGColor(red:1,green:0,blue:0,alpha:1)	}
	static public var blue : CGColor	{	return CGColor(red:0,green:0,blue:1,alpha:1)	}
	static public var magenta : CGColor	{	return CGColor(red:1,green:0,blue:1,alpha:1)	}

	public func withMultAlpha(_ AlphaMultiplier:CGFloat) -> CGColor
	{
		return self.copy(alpha: self.alpha * AlphaMultiplier)!
	}

	public func withMultAlpha(_ AlphaMultiplier:Float) -> CGColor
	{
		return self.copy(alpha: self.alpha * CGFloat(AlphaMultiplier) )!
	}
}

extension Vector2
{
	init(_ x:Double=0,_ y:Double=0)
	{
		self.init(x:x,y:y)
	}
	
	init(_ x:Float=0,_ y:Float=0)
	{
		self.init(x:Double(x),y:Double(y))
	}
	
	static var one : Vector2	{	return Vector2(1.0,1.0)	}
	
	static func -=(lhs: inout Vector2, rhs: Vector2)
	{
		lhs.x -= rhs.x
		lhs.y -= rhs.y
	}
	
	static func -(lhs: Vector2, rhs: Vector2) -> Vector2
	{
		let x = lhs.x - rhs.x
		let y = lhs.y - rhs.y
		return Vector2( x:x, y:y )
	}
	
	static func +(lhs: Vector2, rhs: Vector2) -> Vector2
	{
		let x = lhs.x + rhs.x
		let y = lhs.y + rhs.y
		return Vector2( x:x, y:y )
	}
	
	static func /(lhs: Vector2, rhs: Vector2) -> Vector2
	{
		let x = lhs.x / rhs.x
		let y = lhs.y / rhs.y
		return Vector2( x:x, y:y )
	}
	
	static func /(lhs: Vector2, rhs: Double) -> Vector2
	{
		let x = lhs.x / rhs
		let y = lhs.y / rhs
		return Vector2( x:x, y:y )
	}
	
	static func *=(lhs: inout Vector2, rhs: Vector2)
	{
		lhs.x *= rhs.x
		lhs.y *= rhs.y
	}
	
	static func +=(lhs: inout Vector2, rhs: Vector2)
	{
		lhs.x += rhs.x
		lhs.y += rhs.y
	}
	
	mutating func Rotate(Degrees:Double)
	{
		if ( Degrees < 0.0001 && Degrees > -0.0001 )
		{
			return;
		}
		let rad = DegreesToRadians(Degrees: Degrees)
		
		let cs = cos(rad)
		let sn = sin(rad)
		let newx = x * cs - y * sn
		let newy = x * sn + y * cs
		self.x = newx
		self.y = newy
	}
}

extension CGRect
{
	var min : Vector2
	{
		return Vector2( x:self.minX, y:self.minY )
	}
	
	var max : Vector2
	{
		return Vector2( x:self.maxX, y:self.maxY )
	}
	
	static func MinMaxRect(_ minx:CGFloat,_ miny:CGFloat,_ maxx:CGFloat,_ maxy:CGFloat) -> CGRect
	{
		let w = maxx - minx
		let h = maxy - miny
		return CGRect(x:minx, y:miny, width: w, height: h )
	}
}

//	this names match unity's names
public enum ScaleMode
{
	case ScaleToFit
	case StretchToFill
	case ScaleAndCrop
}


//	wrapper on top of an animation+state (rather than using a function pointer)
protocol AnimationRenderer
{
	func Render(contentRect:CGRect) -> AnimationFrame
}


struct AnimationFrame
{
	var shapes : [AnimationShape] = []
	var CanvasRect = CGRect()
	
	public mutating func AddShape(_ shape:AnimationShape)
	{
		shapes.append(shape)
	}
	
	func GetShapes(IncludeDebug:Bool) -> [AnimationShape]
	{
		//	gotta put debug first so it's at the back!
		var Shapes : [AnimationShape] = []
		if ( IncludeDebug )
		{
			let RectPath = AnimationPath.CreateRect(Rect:self.CanvasRect)
			var RectShape = AnimationShape(Paths: [RectPath])
			RectShape.FillColour = AnimationColour.magenta
			RectShape.StrokeColour = AnimationColour.blue
			RectShape.FillColour!.alpha = 0.2
			RectShape.StrokeColour!.alpha = 0.8
			RectShape.StrokeWidth = 3
			Shapes.append(RectShape)
		}
		Shapes.append(contentsOf: self.shapes)
		return Shapes
	}
}

struct BezierPoint
{
	public var ControlPointIn = Vector2()
	public var ControlPointOut = Vector2()
	public var Position = Vector2()
	
	init()
	{
	}
	
	//	single position structure to turn this into a line (I hope)
	init(Position:Vector2)
	{
		self.Position = Position
		ControlPointIn = Position
		ControlPointOut = Position
	}
}
	
struct Ellipse
{
	public var Center = Vector2()
	public var Radius = Vector2()
}
	

struct AnimationPath
{
	public var BezierPath : [BezierPoint] = []
	//public Vector3[]		LinearPath;
	public var EllipsePath : Ellipse? = nil
	public var path : CGPath?
	
	init(_ path:[BezierPoint])
	{
		BezierPath = path
		self.path = nil
	}

	init(_ ellipse:Ellipse)
	{
		EllipsePath = ellipse
		self.path = nil
	}
	
	static func CreateRect(Center:Vector2,Size:Vector2) -> AnimationPath
	{
		let l = Center.x - (Size.x/2.0)
		let r = Center.x + (Size.x/2.0)
		let t = Center.y - (Size.y/2.0)
		let b = Center.y + (Size.y/2.0)
		let tl = BezierPoint( Position:Vector2(l,t) )
		let tr = BezierPoint( Position:Vector2(r,t) )
		let br = BezierPoint( Position:Vector2(r,b) )
		let bl = BezierPoint( Position:Vector2(l,b) )
		var Points = [tl,tr,br,bl]

		return AnimationPath(Points)
	}
	
	static func CreateRect(Rect:CGRect) -> AnimationPath
	{
		var Center = Vector2( Rect.midX, Rect.midY )
		var Size = Vector2( Rect.width, Rect.height )
		return CreateRect(Center: Center, Size: Size)
	}
}

//	we return shapes instead of layers as rebuilding CALayer sublayers is expensive
//	and we can optimise at the renderer level (including animating properties)
//	structs match c# version. One shape (with same styling) can have multiple subshapes (eg. for holes)
struct AnimationShape
{
	public var Paths : [AnimationPath]
	//	gr: we use CGColor here instead of Color, so the caller needs to do Swift colour resolving
	//		Color.cgColor is deprecated and will return nil for things like Color.yellow (as there is no CGColor.yellow)
	public var FillColour : AnimationColour? = nil
	public var StrokeColour : AnimationColour? = nil
	public var StrokeWidth : CGFloat = 1
	
	func CreateCGPath() -> CGPath
	{
		let Shape = CGMutablePath()
		
		for path in Paths
		{
			if ( !path.BezierPath.isEmpty )
			{
				Shape.move(to: path.BezierPath[0].Position )
				for point in path.BezierPath
				{
					//	https://developer.apple.com/documentation/uikit/uibezierpath/1624357-addcurve
					//	this might be different to unity's...
					Shape.addCurve(to: point.Position, control1: point.ControlPointIn, control2: point.ControlPointOut)
				}
				Shape.closeSubpath()
			}
			if let ellipse = path.EllipsePath
			{
				//Shape.move(to: ellipse.Center )
				//	gr: like unity... no xy ellipse, need to make a path
				Shape.addArc(center: ellipse.Center, radius: ellipse.Radius.x, startAngle: 0, endAngle:DegreesToRadians(Degrees: 359.99), clockwise: false)
				Shape.closeSubpath()
			}
		}
		return Shape
	}
	
	public var Visible : Bool
	{
		if let fill = FillColour
		{
			if ( fill.alpha > 0 )
			{
				return true
			}
		}
		if let stroke = StrokeColour
		{
			if ( stroke.alpha > 0 && StrokeWidth > 0 )
			{
				return true
			}
		}
		return false
	}

}

protocol PathAnimation
{
	//	this should _probably_ return paths, and the renderer manage layers...
	func RenderFrame(frameNumber:FrameNumber,contentRect:CGRect,scaleMode:ScaleMode,IncludeHiddenLayers:Bool) -> AnimationFrame
	func TimeToFrame(PlayTime:TimeInterval,Looped:Bool) -> FrameNumber
}


extension PathAnimation
{
	func Render(PlayTime:TimeInterval,contentRect:CGRect,scaleMode:ScaleMode,IncludeHiddenLayers:Bool) -> AnimationFrame
	{
		//	get the time, move it to lottie-anim space and loop it
		var Frame = TimeToFrame(PlayTime: PlayTime,Looped:true)
		if ( Frame.isNaN )
		{
			Frame = 0.0
		}
		return RenderFrame( frameNumber:Frame, contentRect:contentRect, scaleMode:scaleMode, IncludeHiddenLayers: IncludeHiddenLayers)
	}
}


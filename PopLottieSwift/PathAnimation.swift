import Foundation
import SwiftUI
import QuartzCore
public typealias Vector2 = CGPoint
public typealias FrameNumber = Double


//	gr: using CGColor ends up with OS calls and retains and such
//		swift color also has extra work, so lets have a really simple, dumb colour type and do minimal conversion in specific renderers
public struct AnimationColour
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


public class AnimationFrame
{
	public var shapes : [AnimationShape] = []
	var CanvasRect = CGRect()
	
	public init()
	{
	}
	
	public init(shapes:[AnimationShape])
	{
		self.shapes = shapes
	}
	
	public func AddShape(_ shape:AnimationShape)
	{
		shapes.append(shape)
	}
	
	public func GetShape(Name MatchName:String) -> AnimationShape?
	{
		let Matches = shapes.filter { shape in shape.Name==MatchName }
		if ( Matches.count == 0 )
		{
			return nil
		}
		return Matches[0]
	}
	
	func GetShapes(IncludeDebug:Bool) -> [AnimationShape]
	{
		//	gotta put debug first so it's at the back!
		var Shapes : [AnimationShape] = []
		if ( IncludeDebug )
		{
			let RectPath = AnimationPath.CreateRect(Rect:self.CanvasRect)
			var RectShape = AnimationShape(Paths: [RectPath], Name:"Canvas Rect")
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

public struct BezierPoint
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
	
public struct Ellipse
{
	public var Center = Vector2()
	public var Radius = Vector2()
}

public enum TextJustify : Int
{
	//	gr: note these numbers match lottie's spec, if these ever want to be reused, make it abstract here
	case Left = 0
	case Right = 1
	case Center = 2
	case JustifyWithLastLineLeft = 3
	case JustifyWithLastLineRight = 4
	case JustifyWithLastLineCenter = 5
	case JustifyWithLastLineFull = 6
}

public struct AnimationText
{
	public var Text : String
	public var FontName = "Arial"	//	always expected if text specified
	
	//	text needs specific layout...
	//	but in the path generation, we dont have glyph dimensions & spacing
	//	should we calculate generically?
	public var FontSize = 42.0
	public var Position = Vector2()
	public var Justify = TextJustify.Center
}

public class AnimationPath
{
	public var BezierPath : [BezierPoint] = []
	//public Vector3[]		LinearPath;
	public var EllipsePath : Ellipse? = nil
	public var Text : AnimationText? = nil
	
	init(_ path:[BezierPoint])
	{
		BezierPath = path
	}

	init(_ ellipse:Ellipse)
	{
		EllipsePath = ellipse
	}
	
	init(_ text:AnimationText)
	{
		Text = text
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

struct GlyphMeta
{
	var Glyph : CGGlyph	//	int
	var BoundingRect : CGRect
}

extension unichar : ExpressibleByUnicodeScalarLiteral {
	public typealias UnicodeScalarLiteralType = UnicodeScalar

	public init(unicodeScalarLiteral scalar: UnicodeScalar) {
		self.init(scalar.value)
	}
}

//	we return shapes instead of layers as rebuilding CALayer sublayers is expensive
//	and we can optimise at the renderer level (including animating properties)
//	structs match c# version. One shape (with same styling) can have multiple subshapes (eg. for holes)
public class AnimationShape
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
			
			if let text = path.Text
			{
				//	CATextLayer doesn't give us enough
				//	flexibility, so instead compute each glyph!
				//	this at least lets us do all the positioning in lottie render code
				let FontTransform : UnsafePointer<CGAffineTransform>? = nil
				let FontName = text.FontName as CFString
				let FontOptions = CTFontOptions()//.preferSystemFont
				let Font : CTFont = CTFontCreateWithNameAndOptions(FontName, CGFloat(text.FontSize), FontTransform, FontOptions )
				let FontCg = CTFontCopyGraphicsFont(Font, nil)
				
				//	glyphnames are verbose, like exclamationmark. We need the unichar
				//let Glyphs : [CGGlyph] = text.Text.map{ CTFontGetGlyphWithName( Font, String($0) as CFString ) }
				let Chars = text.Text.map{ Char in Char.utf16.first! }
				var GlyphsArray = UnsafeMutablePointer<CGGlyph>.allocate(capacity: Chars.count)
				CTFontGetGlyphsForCharacters( Font, Chars, GlyphsArray, Chars.count)
				var Glyphs = Array(UnsafeBufferPointer(start: GlyphsArray, count: Chars.count))
				//var Glyphs : [CGGlyph] = (0...Chars.count-1).map{ i in GlyphsArray[i] }

				//	glyph is an index into the font. 0 is a missing char (eg. space)
				//var Glyph = CTFontGetGlyphWithName( Font, CharString )
				//var GlyphRects : [CGRect] = []
				var GlyphRectMutables = UnsafeMutablePointer<CGRect>.allocate(capacity: Glyphs.count)
				var GlyphAdvancesMutables = UnsafeMutablePointer<CGSize>.allocate(capacity: Glyphs.count)

				var TextRect = CTFontGetBoundingRectsForGlyphs( Font, CTFontOrientation.horizontal, Glyphs, GlyphRectMutables, Glyphs.count )
				var TextWidth = CTFontGetAdvancesForGlyphs( Font, CTFontOrientation.horizontal, Glyphs, GlyphAdvancesMutables, Glyphs.count )

				var TextOrigin = text.Position;
				//	justify text rect
				if ( text.Justify == TextJustify.Center )
				{
					TextOrigin.x -= TextWidth / 2.0
				}
				
				
				//	draw each char
				var CharacterTransform = CGAffineTransform(translationX: TextOrigin.x, y: TextOrigin.y )
				for g in 0...Glyphs.count-1
				{
					let Glyph = Glyphs[g]
					let GlyphRect = GlyphRectMutables[g]
					let GlyphAdvance = GlyphAdvancesMutables[g]
					
					//	0 = missing (including space)
					if ( Glyph != 0 )
					{
						//	glyphs are upside down!
						var RenderTransform = CharacterTransform.scaledBy(x: 1, y: -1)
						let GlyphPath = CTFontCreatePathForGlyph( Font, Glyph, &RenderTransform )
						if let Path = GlyphPath
						{
							Shape.addPath(Path)
						}
					}
					//	gr: does rect origin handle kerning etc?
					//	todo: line feeds? or should always have been handled by animation parser?
					//CharacterTransform = CharacterTransform.translatedBy(x: GlyphRect.width, y: 0)
					CharacterTransform = CharacterTransform.translatedBy(x: GlyphAdvance.width, y: 0)
				}
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

public protocol PathAnimation
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


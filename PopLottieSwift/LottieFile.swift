import QuartzCore

enum Parse : Error
{
	case parseException(String)
}

enum Render : Error
{
	case renderException(String)
}

//	gr: need to find documentation on what the different versions represent
//		https://lottiefiles.github.io/lottie-docs/breakdown/bouncy_ball/#top-level
//		docs are 5.5.2
let LottieFormatVersion = "5.5.2"

public enum ShapeType : String
{
	case Fill = "fl"
	case Stroke = "st"
	case Transform = "tr"
	case Group = "gr"
	case Path = "sh"
	case Ellipse = "el"
	case TrimPath = "tm"		//	path trimmer, to modify (trim) a sibling shape
	case Rectangle = "rc"
	case Merge = "mm"
	
	case Unknown = "??"		//	gr: instead of throwing and complicating swift, have a dummy value
}
func GetShapeType(_ type:String?) -> ShapeType
{
	//	gr: these ifs are for debugging
	if ( type == nil )
	{
		return ShapeType.Unknown
	}
	let Parsed = ShapeType(rawValue: type ?? ShapeType.Unknown.rawValue)
	if ( Parsed == nil )
	{
		return ShapeType.Unknown
	}
	return Parsed ?? ShapeType.Unknown
}


//	https://lottiefiles.github.io/lottie-docs/layers/#layers
public enum LayerType : Int
{
	case Precomposition = 0
	case SolidColour = 1
	case Image = 2
	case Empty = 3
	case Shape = 4
	case Text = 5
	case Audio = 6
	case VideoPlaceholder = 7
	case ImageSequence = 8
	case Video = 9
	case ImagePlaceholder = 10
	case Guide = 11
	case Adjustment = 12
	case Camera3D = 13
	case Light = 14
	case Data = 15

	case Unknown = 999	//	gr: instead of throwing and complicating swift, have a dummy value
}
func GetlayerType(_ type:Int) -> LayerType
{
	let Parsed = LayerType(rawValue: type ?? LayerType.Unknown.rawValue)
	if ( Parsed == nil )
	{
		return LayerType.Unknown
	}
	return Parsed ?? LayerType.Unknown
}

public struct TextStyle : Decodable
{
	var sw : AnimatedNumber	//	stroke width
	var sc : AnimatedColour	//	stroke colour
	var sh : AnimatedNumber	//	stroke hue
	var ss : AnimatedNumber	//	stroke saturation
	var sb : AnimatedNumber	//	Stroke Brightness
	var so : AnimatedNumber	//	Stroke Opacity
	var fc : AnimatedColour	//	Fill Color
	var fh : AnimatedNumber	//	Fill Hue
	var fs : AnimatedNumber	//	Fill Saturation
	var fb : AnimatedNumber	//	Fill Brightness
	var fo : AnimatedNumber	//	Fill Opacity
	var t : AnimatedNumber	//	Letter Spacing
	var bl : AnimatedNumber	//	Blur
	var ls : AnimatedNumber	//	Line spacing
}

public struct TextRangeSelector : Decodable
{
}

public struct TextRange : Decodable
{
	var nm : String
	var s : TextRangeSelector
	var a : TextStyle
}



public struct TextDocument : Decodable
{
	var f : String		//	font family
	var FontFamily : String	{f}
	var fc : [Double]	//	fill colour
	var FillColour : AnimationColour	{	AnimationColour(red: fc[0], green: fc[1], blue: fc[2] )	}
	var sc : [Double]	//	stroke colour
	var StrokeColour : AnimationColour	{	AnimationColour(red: sc[0], green: sc[1], blue: sc[2] )	}
	var sw : Double	//	stroke width
	var StrokeWidth : Double	{sw}
	var of : Bool	//	render stroke above fill
	var s : Double	//	font size
	var FontSize : Double	{s}
	var lh : Double	//	line height (distance between lines on multine or wrapped text)
	var LineHeight : Double {lh}
	var sz : [Float]?	//	size of containing text box
	var ps : [Float]?	//	position of text box
	var t : String		//	text seperated with \r newlines
	var TextLines : [String]	{	t.components(separatedBy: "\r")	}
	var j : Int
	var Justify : TextJustify	{	TextJustify(rawValue: j) ?? TextJustify.Left	}
	
}

public struct TextDocumentKeyframe : Decodable
{
	var s : TextDocument
	var Text : TextDocument	{	s	}
	var t : FrameNumber		//	time (appearance only? where is end?)
	var Time : FrameNumber	{	t	}
}

public struct AnimatedTextDocument : Decodable
{
	var k : [TextDocumentKeyframe]
	var Keyframes : [TextDocumentKeyframe]	{	k	}
	var x : String?	//	expression
	var sid : String?	//	string id?
}



public enum TextGrouping : Int
{
	case Characters = 1
	case Word = 2
	case Line = 3
	case All = 4
}


//	https://lottiefiles.github.io/lottie-docs/text/#text-alignment-options
public struct TextAlignment : Decodable
{
	var a : AnimatedVector	//	group alignment
	var g : Int	//	Anchor point grouping
	var Grouping : TextGrouping {	TextGrouping(rawValue: g) ?? TextGrouping.Characters }
}

//	Uses the path described by a layer mask to put the text on said path.
struct TextFollowPath : Decodable
{
	var m : Int?	//	index of mask to use
	var f : AnimatedNumber?	//	First margin
	var l : AnimatedNumber?	//	Last margin
	var r : AnimatedNumber?	//	reverse path
	var a : AnimatedNumber?	//	force alignment
	var p : AnimatedNumber?	//	perpendicular to path
}


public struct TextData : Decodable
{
	var a : [TextRange]
	var d : AnimatedTextDocument
	var m : TextAlignment
	var p : TextFollowPath
}

public class Shape : Decodable//, Hashable
{
	static func == (lhs: Shape, rhs: Shape) -> Bool 
	{
		//	gr: not sure this is unique...
		return lhs.ind == rhs.ind
	}
	
	public var ind : Int?
	public var np : Int?		//	number of properties
	public var cix : Int?	//	property index
	public var ix : Int?		//	property index
	public var bm : Int?		//	blend mode
	public var BlendMode : Int	{	bm ?? 0	}
	public var d : Int?	//	shape direction, 1 = normal, 3=reversed
	public var Direction : Int	{	d ?? 1	}
	public var nm : String?		// = "Lottie File"
	public var Name : String { nm ?? "Unnamed"	}
	public var mn : String?
	public var MatchName  : String { mn ?? "" }
	public var hd : Bool?	//	i think sometimes this might an int. Newtonsoft is very strict with types
	public var Hidden : Bool	{	hd ?? false	}
	public var Visible : Bool	{	!Hidden	}
	public var ty : String?
	public var type : ShapeType	{	GetShapeType(ty)	}
}

public struct PathTrim
{
	public var Start : CGFloat = 0
	public var End : CGFloat = 0
	public var Offset : CGFloat = 0
	
	public var IsDefault : Bool	{	Start==0 && End==1	}
	
	public static func GetDefault() -> PathTrim
	{
		var Default = PathTrim()
		Default.Start = 0;
		Default.Offset = 0;
		Default.End = 1;
		return Default;
	}
}


struct ShapeStyle
{
	public var	FillColour : AnimationColour?
	public var	StrokeColour : AnimationColour?
	public var	StrokeWidth : CGFloat?
	public var	IsStroked : Bool	{	return StrokeColour != nil	}
	public var	IsFilled : Bool 	{	return FillColour != nil	}
}

//	gr: we have this only in c# to aid JSON parsing... keeping it here for consistency, but may not be needed in swift
public struct ShapeWrapper : Decodable
{
	public var TheShape : Shape;
	public var type : ShapeType	{	TheShape.type	}
	
	var ty : String
	
	enum CodingKeys: CodingKey 
	{
		case ty
	}
	
	public init(from decoder: Decoder) throws 
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.ty = try container.decode(String.self, forKey: .ty)
		let type = GetShapeType(self.ty)
		self.TheShape = try ShapeWrapper.DecodeShape(shapeType: type, decoder: decoder)
	}
		
	static func DecodeShape(shapeType:ShapeType,decoder:Decoder) throws -> Shape
	{
		switch(shapeType)
		{
		case ShapeType.Group:		return try ShapeGroup(from:decoder)
		case ShapeType.Path:		return try ShapePath(from:decoder)
		case ShapeType.Ellipse:		return try ShapeEllipse(from:decoder)
		case ShapeType.Transform:	return try ShapeTransform(from:decoder)
		case ShapeType.TrimPath:	return try ShapeTrimPath(from:decoder)
		case ShapeType.Fill:		return try ShapeFillAndStroke(from:decoder)
		case ShapeType.Stroke:		return try ShapeFillAndStroke(from:decoder)
		case ShapeType.Rectangle:	return try ShapeRectangle(from:decoder)
		case ShapeType.Merge:		return try ShapeMerge(from:decoder)
		default:	throw Parse.parseException("Uhandled shape type \(shapeType)")
		}
	}
	
}


//	instead of having two shape types for fill & stroke, we just lump em together
class ShapeFillAndStroke : Shape
{
	var c : AnimatedColour //	colour
	var Fill_Colour : AnimatedColour	{	c	}
	var Stroke_Colour : AnimatedColour	{	c	}
	
	/*
	//var int				r;	//	fill rule
	var o : AnimatedNumber	//	opacity?
	var w : AnimatedNumber	//	width
	var Stroke_Width : AnimatedNumber	{	w	}
	*/
	enum CodingKeys: CodingKey
	{
		case c
	}
	
	required init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.c = try container.decode(AnimatedColour.self, forKey: .c)
		try super.init(from:decoder)
	}

	func GetWidth(_ Frame:FrameNumber) -> CGFloat
	{
		/*
		var Value = w.GetValue(Frame);
		//	gr: it kinda looks like unity's width is radius, and lotties is diameter, as it's consistently a bit thick
		Value *= 0.8f;
		return Value;
		 */
		return 1.0
	}
	func GetColour(_ Frame:FrameNumber) -> AnimationColour
	{
		return c.GetColour(Frame);
	}
}


//	this seems slower as class
struct Bezier : Decodable
{
	public struct ControlPoint
	{
		public var InTangent = Vector2()
		public var OutTangent = Vector2()
		public var Position = Vector2()
	}
	
	public var i : [[CGFloat]]	//	in-tangents
	public var o : [[CGFloat]]	//	out-tangents
	public var v : [[CGFloat]]	//	vertexes
	public var c : Bool
	public var Closed : Bool	{	c	}

	func GetControlPoints(_ Trim:PathTrim) -> [ControlPoint]
	{
		var PointCount = v.count;
		var Points = [ControlPoint](repeating: ControlPoint(), count: PointCount)
		for Index in 0...PointCount-1
		//for ( var Index=0;	Index<PointCount;	Index++ )
		{
			Points[Index].Position.x = v[Index][0];
			Points[Index].Position.y = v[Index][1];
			Points[Index].InTangent.x = i[Index][0];
			Points[Index].InTangent.y = i[Index][1];
			Points[Index].OutTangent.x = o[Index][0];
			Points[Index].OutTangent.y = o[Index][1];
		}
		
		//	todo: trim points
		//		need to work out where in the path we cut, then calc new control points
		//	if there's an offset... we need to calculate ALL of them?
		if ( Trim.IsDefault )
		{
			return Points;
		}
		
		//	gr: this doesn't wrap. if start > end, then it goes backwards
		//		but offset does make it wrap
		//	gr: the values are in path-distance (0-1), rather than indexes
		var StartTime = (Trim.Start + Trim.Offset);
		var EndTime = (Trim.End + Trim.Offset);
		if ( Trim.End < Trim.Start )
		{
			var Temp = StartTime;
			StartTime = EndTime;
			EndTime = Temp;
		}
		
		//	todo: slice up bezier. Unfortunetly as the offsets are in distance, not control points
		//		we have to calculate where to cut, but hopefully that still leaves just two cut segments and then originals inbetween
		return Points;
	}
	
}

struct AnimatedBezier : Decodable
{
	public var a : Int
	public var Animated : Bool{	return a != 0	}
	//	if not animated, k==Vector3
	public var k : [Bezier]	//	frames, sometimes one, sometimes an array (so custom init)
	public var ix : Int;	//	property index
	
	public func GetBezier(_ Frame:FrameNumber) -> Bezier
	{
		return k[0];
	}
	
	enum CodingKeys: CodingKey {
		case a
		case k
		case ix
	}
	
	init(from decoder: Decoder) throws 
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.a = try container.decode(Int.self, forKey: .a)
		
		if let ks = try? container.decode([Bezier].self, forKey: .k)
		{
			self.k = ks
		}
		else if let k = try? container.decode(Bezier.self, forKey: .k)
		{
			self.k = [k]
		}
		else
		{
			throw Parse.parseException(".k bezier not single item nor array of beziers")
		}

		self.ix = try container.decode(Int.self, forKey: .ix)
	}
}


//	gr: faster as class. Struct is copying too many elements
public class Frame_FloatArray : Decodable, IFrame
{
	//	gr: all these are optional as you sometimes get a terminating frame which is just a time
	var i : ValueCurve?
	var o : ValueCurve?
	var h : Int?
	var HoldingFrame : Bool	{	h != 0	}
	var t : Double
	var s : [Float]? = nil	//	start value
	//	gr: e sometimes missing for .to & .ti
	var e : [Float]? = nil	//	end value
	var to : [Float]? = nil	//	end value
	var ti : [Float]? = nil	//	end value

	var Frame : FrameNumber	{	FrameNumber(t)	}
	var IsTerminatingFrame : Bool {	s==nil	}
	
	
	enum CodingKeys: CodingKey {
		case i
		case o
		case h
		case t
		case s
		case e
	}
	
	init(t:FrameNumber)
	{
		self.t = t
	}
	
	required public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.i = try container.decodeIfPresent(ValueCurve.self, forKey: .i)
		self.o = try container.decodeIfPresent(ValueCurve.self, forKey: .o)
		self.h = try container.decodeIfPresent(Int.self, forKey: .h)
		self.t = try container.decode(Double.self, forKey: .t)
		self.s = try container.decodeIfPresent([Float].self, forKey: .s)
		self.e = try container.decodeIfPresent([Float].self, forKey: .e)
	}
	
	init(Frames:[Float])
	{
		self.s = Frames
		self.t = -123	//	should never be used as we have no e
	}
	
	/*
	enum CodingKeys: CodingKey
	{
		case h,t,s,e
	}
	
	required init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.h = try container.decode(h.self, forKey: .h)
		self.t = try container.decode(t.self, forKey: .t)
		self.s = try container.decode(s.self, forKey: .s)
		self.e = try container.decode(e.self, forKey: .e)

		try super.init(from: decoder)
	}
	 */

	
	
	func LerpTo(_ Next:Frame_FloatArray,_ Lerp:Float?) -> [Float]?
	{
		var NextValues = Next.s;
		var PrevValues = self.s;
		if ( Lerp == nil )
		{
			return PrevValues;
		}

		//	this happens on terminator frames
		if ( NextValues == nil )
		{
			if ( self.e != nil )
			{
				NextValues = self.e;
			}
		}

		if ( NextValues == nil )
		{
			NextValues = PrevValues;
		}
		
		if ( PrevValues == nil || NextValues == nil )
		{
			return nil;
		}
		
		//	lerp each member
		var Values = [Float](repeating:0, count:s!.count)
		for v in 0...Values.count-1
		{
			Values[v] = try! IFrameFuncs.Interpolate( v, PrevValues!, NextValues!, Lerp!, i, o );
			//Values[v] = PrevValues![v]
		}
		return Values;
	}
}

struct ValueCurve : Decodable
{
	var x : [Float]	//	time X axis
	var y : [Float]	//	value Y axis

	//	gr: sometimes not an array, just x:0 y:1
	//		so we need a custom init again
	enum CodingKeys: CodingKey {
		case x
		case y
	}
	
	init(from decoder: Decoder) throws 
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		if let xs = try? container.decode([Float].self, forKey: .x)
		{
			self.x = xs
		}
		else if let x = try? container.decode(Float.self, forKey: .x)
		{
			self.x = [x]
		}
		else
		{
			throw Parse.parseException("ValueCurve with no [decodable] x")
		}

		if let ys = try? container.decode([Float].self, forKey: .y)
		{
			self.y = ys
		}
		else if let y = try? container.decode(Float.self, forKey: .y)
		{
			self.y = [y]
		}
		else
		{
			throw Parse.parseException("ValueCurve with no [decodable] x")
		}
	}
}

protocol IFrame
{
	var Frame : FrameNumber { get }
	var IsTerminatingFrame : Bool {get }	//	if this frame is just an end frame with no values, we wont try and read them
}

class Mathf
{
	static func Lerp(_ Prev:Float,_ Next:Float,_ Time:Float) -> Float
	{
		return Prev + ( (Next-Prev) * Time )
	}
}

class IFrameFuncs
{
	static func GetSlope(_ aT:Float,_ aA1:Float,_ aA2:Float) -> Float
	{
		//func A(_ aA1:Float,_ aA2:Float) -> Float { return 1.0 - 3.0 * aA2 + 3.0 * aA1; }
		//func B(_ aA1:Float,_ aA2:Float) -> Float { return 3.0 * aA2 - 6.0 * aA1; }
		//func C(_ aA1:Float) -> Float { return 3.0 * aA1; }
		let A = 1.0 - 3.0 * aA2 + 3.0 * aA1
		let B = 3.0 * aA2 - 6.0 * aA1;
		let C = 3.0 * aA1

		return 3.0 * A * aT * aT + 2.0 * B * aT + C;
	}

	static func GetBezierValue(_ p0:Float,_ p1:Float,_ p2:Float,_ p3:Float,_ Time:Float) -> Float
	{
		var t = Time;
		//	https://morethandev.hashnode.dev/demystifying-the-cubic-bezier-function-ft-javascript
		return (1 - t) * (1 - t) * (1 - t) * p0
				+
				3 * (1 - t) * (1 - t) * t * p1
				+
				3 * (1 - t) * t * t * p2
				+
				t * t * t * p3;
	}


	static func Interpolate(_ Prev:Float,_ Next:Float,_ Time:Float,_ InX:Float?,_ InY:Float?,_ OutX:Float?,_ OutY:Float?) -> Float
	{
		//	from docs
		//	The y axis represents the value interpolation factor, a value of 0 represents the value at the current keyframe, a value of 1 represents the value at the next keyframe
		var LinearValue = Mathf.Lerp( Prev, Next, Time );
		
		
		func GetCurveX(_ Start:Float,_ EaseOut:Float,_ EaseIn:Float,_ End:Float,_ Time:Float) -> Float
		{
			//return GetBezierValue( Start, EaseOut, EaseIn, End, Time );
			//	https://github.com/Samsung/rlottie/blob/d40008707addacb636ff435236d31c694ce2b6cf/src/vector/vinterpolator.cpp#L86
			//	newton raphson iterating to find tighter point on the curve
			var aX = Time;
			var aGuessT = Time;

			//for it in 0...10	//	gr: this while loop does seem a tiny bit faster...
			var it = 10
			while ( it > 0 )
			{
				it-=1
				var CurrentX = GetBezierValue( Start, EaseOut, EaseIn, End, aGuessT ) - aX;
				var Slope = GetSlope( aGuessT, EaseOut, EaseIn );
				if ( Slope <= 0.0001 )
				{
					break;
				}
				aGuessT -= CurrentX / Slope;
			}
			return aGuessT;
		}
		
		
		if ( InX != nil )
		{
			var Start = Vector2.zero;
			var EaseOut = Vector2( OutX!, OutY! );
			var EaseIn = Vector2( InX!, InY! );
			var End = Vector2.one;

			//	https://github.com/airbnb/lottie-ios/blob/41dfe7b0d8c3349adc7a5a03a1c6aaac8746433d/Sources/Private/Utility/Primitives/UnitBezier.swift#L36
			//	uses https://github.com/gnustep/libs-quartzcore/blob/master/Source/CAMediaTimingFunction.m#L204C13-L204C25
			//	solve time first
			var CurveTime = GetCurveX( Float(Start.x), Float(EaseOut.x), Float(EaseIn.x), Float(End.x), Time );
			
			//	solve value
			var CurveValue = GetBezierValue( Float(Start.y), Float(EaseOut.y), Float(EaseIn.y), Float(End.y), CurveTime );
			var FinalValue = Mathf.Lerp( Prev, Next, CurveValue );
			return FinalValue;
		}
		return LinearValue;
	}
	
	static func Interpolate(_ Component:Int,_ Prev:[Float],_ Next:[Float],_ Time:Float,_ In:ValueCurve?,_ Out:ValueCurve?) throws -> Float
	{
		if ( Component < 0 || Component >= Prev.count )
		{
			throw Parse.parseException("Interpolate out of bounds");
		}
		var EaseInX = In?.x;
		//var EaseInY = In?.y;
		//var EaseOutX = Out?.x;
		//var EaseOutY = Out?.y;
		//	somtimes the curve has fewer components than the object... should this be linear for that component, or spread?
		var EaseComponent = Component;
		if ( EaseInX != nil )
		{
			EaseComponent = min( Component, EaseInX!.count-1 );
		}
		return Interpolate( Prev[Component], Next[Component], Time, In?.x[EaseComponent], In?.y[EaseComponent], Out?.x[EaseComponent], Out?.y[EaseComponent] );
	}

	
	//	returns null for Time, if both are same frame
	//static (FRAMETYPE,float?,FRAMETYPE) GetPrevNextFramesAtFrame<FRAMETYPE>(List<FRAMETYPE> Frames,FrameNumber TargetFrame) where FRAMETYPE : IFrame
	static func GetPrevNextFramesAtFrame<FRAMETYPE:IFrame>(Frames:[FRAMETYPE],TargetFrame:FrameNumber) throws -> (FRAMETYPE,Float?,FRAMETYPE)
	{
		//	gr: we should never have zero frames coming in
		if ( Frames.count == 0 )
		{
			throw Render.renderException("GetPrevNextFramesAtFrame missing frames");
		}
		
		if ( Frames.count == 1 )
		{
			return (Frames[0],nil,Frames[0]);
		}
		
		//	find previous & next frames
		var PrevIndex = 0;
		for f in 0...Frames.count-1
		{
			var ThisFrame = Frames[f];
			//	terminating frames have no values
			if ( ThisFrame.IsTerminatingFrame )
			{
				if ( f != Frames.count-1 )
				{
					print("Terminator frame in middle of sequence {f}/{Frames.Count-1}");
				}
				break;
			}
			if ( ThisFrame.Frame > TargetFrame )
			{
				break;
			}
			PrevIndex = f;
		}
		var NextIndex = min(PrevIndex + 1, Frames.count-1);
		var Prev = Frames[PrevIndex];
		var Next = Frames[NextIndex];

		//	allow some optimisations by inferring that there is nothing to lerp between
		if ( PrevIndex == NextIndex )
		{
			return (Prev,nil,Prev);
		}
		
		//	get the lerp(time) between prev & next
		func Range(_ Min:Double,_ Max:Double,_ Value:Double) -> Float
		{
			if ( Max-Min <= 0 )
			{
				return 0;
			}
			return Float( (Value-Min)/(Max-Min) )
		}
		
		/*
		if ( Next.IsTerminatingFrame )
		{
			//return (Prev,nil,Next);
		}
		 */
		
		//var Lerp = Mathf.InverseLerp( Prev.Frame, Next.Frame, TargetFrame );
		var Lerp = Range( Prev.Frame, Next.Frame, TargetFrame );
		if ( Lerp <= 0 )
		{
			Lerp = 0;
			return (Prev,nil,Next);
		}
		if ( Lerp >= 1 )
		{
			Lerp = 1;
		}
		return (Prev,Lerp,Next);
	}
	
}


//[JsonConverter(typeof(KeyframedConvertor<Keyframed_FloatArray,Frame_FloatArray>))]
public struct Keyframed_FloatArray : Decodable//: IKeyframed<Frame_FloatArray>
{
	var Frames : [Frame_FloatArray]

	enum CodingKeys: CodingKey 
	{
		//	gr: we ARE k, we don't contain k
		//case k
		case t
	}
	
	public init(from decoder: Decoder) throws
	{
		self.Frames = []

		//	k(which is us) may be
		//		- a number
		//		- array of numbers
		//		- object(curve?)
		//		- array of objects
		//		- array of array of numbers
		if let Dictionary = try? decoder.container(keyedBy: CodingKeys.self)
		{
			//	gr: this doesn't really happen, because we never match the coding keys?
			throw Parse.parseException("Keyframed_FloatArray dictionary")
		}
		else if let SingleValue = try? decoder.singleValueContainer()
		{
			if let Number = try? SingleValue.decode(Float.self)
			{
				AddFrame(Numbers: [Number])
			}
			else if let Number = try? SingleValue.decode(Int.self)
			{
				AddFrame(Numbers: [Float(Number)])
			}
			else if let Numbers = try? SingleValue.decode([Int].self)
			{
				AddFrame(Numbers: Numbers.map{ i in Float(i) } )
			}
			else if let Numbers = try? SingleValue.decode([Float].self)
			{
				AddFrame(Numbers: Numbers)
			}
			else if let Frames = try? SingleValue.decode([Frame_FloatArray].self)
			{
				AddFrame(Frames)
			}
			else if let Frame = try? SingleValue.decode(Frame_FloatArray.self)
			{
				AddFrame([Frame])
			}
			else
			{
				throw Parse.parseException("Keyframed_FloatArray value not Number or array of Numbers")
			}
		}
		else
		{
			throw Parse.parseException("Keyframed_FloatArray unhandled type; not single-value")
		}
		
		if ( Frames.isEmpty )
		{
			throw Parse.parseException("Decoded Keyframed_FloatArray with no frames")
		}
	}
	
	mutating func AddFrame(Numbers:[Float])
	{
		var Frame = Frame_FloatArray(Frames:Numbers)
		AddFrame([Frame]);
	}
/*
	public void AddFrame(JObject Object,JsonSerializer Serializer)
	{
		AddFrame( Object.ToObject<Frame_FloatArray>(Serializer) );
	}
	*/
	mutating func AddFrame(_ Frames:[Frame_FloatArray])
	{
		//Frames = Frames ?? new();
		self.Frames.append(contentsOf: Frames)
	}

	func GetValue(_ Frame:FrameNumber) -> [Float]
	{
		//	gr: we dont allow init with no frames, so this shouldn't happen
		if ( Frames.count == 0 )
		{
			//throw Parse.parseException("{GetType().Name}::GetValue missing frames");
			print("{GetType().Name}::GetValue missing frames");
			return [456.789]
		}
		
		var (Prev,Lerp,Next) = try! IFrameFuncs.GetPrevNextFramesAtFrame(Frames:Frames,TargetFrame:Frame);
		var LerpedValues = Prev.LerpTo(Next,Lerp);
		/*if ( LerpedValues?.count ?? 0 == 0 )
		{
			throw Render.renderException("Lerping frames resulting in missing data");
		}*/
		return LerpedValues!;
	}
}


struct Frame_Float : Decodable, IFrame
{
	var i : ValueCurve?	//	ease in value
	var o : ValueCurve?	//	ease out value
	var t : Float	//	time
	var s : [Float]?	//	value at time
	var e : [Float]?	//	end value
	var Frame : FrameNumber	{	FrameNumber(t)	}
	var IsTerminatingFrame : Bool {	s==nil	}

	func LerpTo(_ Next:Frame_Float,_ Lerp:Float?) -> Float?
	{
		var NextValues = Next.s;
		var PrevValues = self.s;
		if ( Lerp == nil )
		{
			return PrevValues?[0];
		}

		//	this happens on terminator frames
		if ( NextValues == nil )
		{
			if ( self.e != nil )
			{
				NextValues = self.e;
			}
		}

		if ( NextValues == nil )
		{
			NextValues = PrevValues;
		}
		
		if ( PrevValues == nil || NextValues == nil )
		{
			return nil;
		}
		
		//	lerp each member
		var Values = [Float](repeating:0, count:s!.count)
		for v in 0...Values.count-1
		{
			Values[v] = try! IFrameFuncs.Interpolate( v, PrevValues!, NextValues!, Lerp!, i, o );
		}
		return Values[0];
	}
	/*
	public float		LerpTo(Frame_Float Next,float? Lerp)
	{
		float[] NextValues = Next.s;
		float[] PrevValues = this.s;

		if ( Lerp == null )
			return PrevValues[0];

		//	this happens on terminator frames
		if ( NextValues == null )
			if ( this.e != null )
				NextValues = this.e;

		if ( NextValues == null )
			NextValues = PrevValues;

		if ( PrevValues == null || NextValues == null )
			throw new Exception($"{GetType().Name}::Lerp prev or next frame values");

		//	lerp each member
		var Values = new float[s.Length];
		for ( int v=0;	v<Values.Length;	v++ )
			Values[v] = IFrame.Interpolate( v, PrevValues, NextValues, Lerp.Value, i, o );
		return Values[0];
	}
	*/
}


//[JsonConverter(typeof(KeyframedConvertor<Keyframed_FloatArray,Frame_FloatArray>))]
struct Keyframed_Float : Decodable//: IKeyframed<Frame_FloatArray>
{
	var Frames : [Frame_Float]
	
	init(from decoder: Decoder) throws
	{
		self.Frames = []

		//	k(which is us) may be
		//		- a number
		//		- array of numbers
		//		- object(curve?)
		//		- array of objects
		//		- array of array of numbers
		//if let Dictionary = try decoder.container(keyedBy: CodingKeys.self)
		if let SingleValue = try? decoder.singleValueContainer()
		{
			if let Number = try? SingleValue.decode(Float.self)
			{
				AddFrame(Numbers: [Number])
			}
			else if let Numbers = try? SingleValue.decode([Float].self)
			{
				AddFrame(Numbers: Numbers)
			}
			else if let Frame = try? SingleValue.decode(Frame_Float.self)
			{
				AddFrame([Frame])
			}
			else if let Frames = try? SingleValue.decode([Frame_Float].self)
			{
				AddFrame(Frames)
			}
			else
			{
				throw Parse.parseException("Keyframed_FloatArray value not Number or array of Numbers")
			}
		}
		else
		{
			throw Parse.parseException("Keyframed_FloatArray unhandled type; not single-value")
		}
	}
	
	mutating func AddFrame(Numbers:[Float])
	{
		var Frame = Frame_Float(t:-123);
		Frame.s = Numbers;
		Frame.t = -123;	//	if being added here, it shouldnt be keyframed
		//Frame.e = new []{Number};
		AddFrame([Frame]);
	}
/*
	public void AddFrame(JObject Object,JsonSerializer Serializer)
	{
		AddFrame( Object.ToObject<Frame_FloatArray>(Serializer) );
	}
	*/
	mutating func AddFrame(_ Frames:[Frame_Float])
	{
		//Frames = Frames ?? new();
		self.Frames.append(contentsOf: Frames)
	}

	func GetValue(_ Frame:FrameNumber) throws -> Float
	{
		if ( Frames.count == 0 )
		{
			throw Parse.parseException("{GetType().Name}::GetValue missing frames");
		}
		
		var (Prev,Lerp,Next) : (Frame_Float,Float?,Frame_Float) = try IFrameFuncs.GetPrevNextFramesAtFrame(Frames:Frames,TargetFrame:Frame);

		return Prev.LerpTo(Next,Lerp)!;
	}
}

public struct AnimatedNumber : Decodable
{
	var a : Int
	var Animated : Bool	{	a != 0	}
	
	var k : Keyframed_Float	//	frames
	
	func GetValue(_ Frame:FrameNumber) -> Float
	{
		return try! k.GetValue(Frame);
	}
}

public struct AnimatedColour : Decodable
{
	var a : Int
	var Animated : Bool	{ a != 0 }
	//	if not animated, k==Vector3
	var k : [CGFloat]	//	3/4 elements 0..1
	var ix : Int?	//	property index
	
	func GetColour(_ Frame:FrameNumber) -> AnimationColour
	{
		if ( Animated )
		{
			print("todo: animating colour");
		}
		var Alpha = k.count == 4 ? k[3] : 1;
		if ( k.count < 3 )
		{
			return AnimationColour.magenta;
		}
		return AnimationColour(red:k[0],green:k[1],blue:k[2],alpha:Alpha);
	}
}


public class AnimatedVector : Decodable
{
	public var a : Int? = 0
	public var Animated : Bool{	a ?? 0 != 0	}
	public var s : Bool? = false
	
	//	the vector .p(this) is split into components instead of arrays of values
	public var SplitVector : Bool	{	s ?? false	}
	public var x : AnimatedVector? = nil
	public var y : AnimatedVector? = nil
	
	//	keyframes when NOT split vector
	public var k : Keyframed_FloatArray? = nil
/*
	enum CodingKeys: CodingKey
	{
		case a
		case s
		case x
		case y
		case k
	}
	
	required init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.a = try container.decode(Int.self, forKey: .it)

		try super.init(from: decoder)
	}
*/
	
	public func GetValue(_ Frame:FrameNumber) -> Float
	{
		if ( SplitVector )
		{
			return x!.GetValueArray(Frame)[0];
		}
		return try! k!.GetValue(Frame)[0];
	}
	
	
	public func GetValueArray(_ Frame:FrameNumber) -> [Float]
	{
		if ( SplitVector )
		{
			var v0 = x!.GetValueArray(Frame)[0];
			var v1 = y!.GetValueArray(Frame)[0];
			return [v0,v1]
		}
		return try! k!.GetValue(Frame);
	}
	
	public func GetValueVec2(_ Frame:FrameNumber) -> Vector2
	{
		var Values = GetValueArray(Frame);
		if ( Values.count == 0 )
		{
			//throw Parse.parseException("{GetType().Name}::GetValue(vec2) missing frames");
			print("Animated vector with no values")
			return Vector2(123.456,123.456)
		}

		//	1D scale... usually
		if ( Values.count == 1 )
		{
			return Vector2(Values[0],Values[0]);
		}
		return Vector2(Values[0],Values[1]);
	}
}


class ShapePath : Shape
{
	public var ks : AnimatedBezier	//	bezier for path
	public var Path_Bezier : AnimatedBezier	{	ks	}
	
	enum CodingKeys: CodingKey
	{
		case ks
	}

	required init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.ks = try container.decode(AnimatedBezier.self, forKey: .ks)
		try super.init(from:decoder)
	}
}

//	https://lottiefiles.github.io/lottie-docs/shapes/#merge
class ShapeMerge : Shape
{
	public var mm : Int = 0
	public var MergeMode : Int	{	mm	}	//	todo: enum
}
	
class ShapeRectangle : Shape
{
	public var p : AnimatedVector
	public var s : AnimatedVector
	public var r : AnimatedVector
	public var Center : AnimatedVector	{p}
	public var Size : AnimatedVector	{s}
	public var CornerRadius : AnimatedVector	{r}
	
	enum CodingKeys: CodingKey
	{
		case p
		case s
		case r
	}
	
	required init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.p = try container.decode(AnimatedVector.self, forKey: .p)
		self.s = try container.decode(AnimatedVector.self, forKey: .s)
		self.r = try container.decode(AnimatedVector.self, forKey: .r)

		try super.init(from: decoder)
	}
}

class ShapeTrimPath : Shape
{
	/*
	public var s : AnimatedNumber	//	segment start
	public var e : AnimatedNumber	//	segment end
	public var o : AnimatedNumber	//	offset
	 */
	public var m : Int = 0
	public var TrimMultipleShapes : Int	{	return m	}
	
	required init(from:Decoder) throws
	{
		try super.init(from:from)
	}
	
	public func GetTrim(_ Frame:FrameNumber) -> PathTrim
	{
		/*
		//	https://lottiefiles.github.io/lottie-docs/shapes/#trim-path
		//	start & end is 0-100%, offset is an angle up to 360
		var Trim = PathTrim.GetDefault();
		Trim.Start = s.GetValue(Frame) / 100f;
		Trim.End = e.GetValue(Frame) / 100f;
		Trim.Offset = o.GetValue(Frame) / 360f;
		return Trim;
		*/
		return PathTrim()
	}
}

class ShapeEllipse : Shape
{
	public var s : AnimatedVector
	public var p : AnimatedVector
	public var Size : AnimatedVector	{	return s	}
	public var Center : AnimatedVector	{	return p	}
	
	enum CodingKeys: CodingKey
	{
		case s,p
	}
	
	required init(from decoder:Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.s = try container.decode(AnimatedVector.self, forKey: .s)
		self.p = try container.decode(AnimatedVector.self, forKey: .p)
		try super.init(from:decoder)
	}
}

class ShapeGroup : Shape
{
	public var it : [ShapeWrapper] = []	//	children
	public var ChildrenFrontToBack : [Shape]	{	it.map{ sw in sw.TheShape }	}
	public var ChildrenBackToFront : [Shape]	{	ChildrenFrontToBack.reversed()	}
	
	enum CodingKeys: CodingKey
	{
		case it
	}
	
	required init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.it = try container.decode([ShapeWrapper].self, forKey: .it)

		try super.init(from: decoder)
	}
	
	
	func GetChild(_ MatchType:ShapeType) -> Shape?
	{
		//	handle multiple instances
		for s in it
		{
			if ( s.type == MatchType )
			{
				return s.TheShape;
			}
		}
		return nil
	}
	
	func GetTransformer(_ Frame:FrameNumber) -> Transformer
	{
		var Transform = GetChild(ShapeType.Transform) as? ShapeTransform;
		if let t = Transform
		{
			return t.GetTransformer(Frame);
		}
		return Transformer()
	}
	
	//	this comes from the transform, but we're just not keeping it with it
	func GetAlpha(_ Frame:FrameNumber) -> Float
	{
		var Transform = GetChild(ShapeType.Transform) as? ShapeTransform;
		if ( Transform == nil )
		{
			return 1.0;
		}
		return Transform!.GetAlpha(Frame);
	}
	
	func GetPathTrim(_ Frame:FrameNumber) -> PathTrim
	{
		var TrimShape = GetChild(ShapeType.TrimPath) as? ShapeTrimPath;
		if let trim = TrimShape
		{
			return trim.GetTrim(Frame);
		}
		return PathTrim.GetDefault();
	}
	
	func GetShapeStyle(_ Frame:FrameNumber) -> ShapeStyle?
	{
		var Fill = GetChild(ShapeType.Fill) as? ShapeFillAndStroke;
		var Stroke = GetChild(ShapeType.Stroke) as? ShapeFillAndStroke;
		var Style = ShapeStyle();
		if ( Fill != nil )
		{
			Style.FillColour = Fill?.GetColour(Frame);
		}
		if ( Stroke != nil )
		{
			Style.StrokeColour = Stroke?.GetColour(Frame);
			Style.StrokeWidth = Stroke?.GetWidth(Frame);
		}
		if ( Fill == nil && Stroke == nil )
		{
			return nil
		}
		return Style;
	}

}


public class ShapeTransform : Shape
{
	//	transform
	public var p : AnimatedVector	//	translation
	public var a : AnimatedVector	//	anchor
	
	//	gr: not parsing as mix of animated & not
	public var s : AnimatedVector	//	scale
	public var r : AnimatedVector	//	rotation
	public var o : AnimatedNumber	//	opacity

	enum CodingKeys: CodingKey
	{
		case p,a,s,r,o
	}
	
	required init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.p = try container.decode(AnimatedVector.self, forKey: .p)
		self.a = try container.decode(AnimatedVector.self, forKey: .a)
		self.s = try container.decode(AnimatedVector.self, forKey: .s)
		self.r = try container.decode(AnimatedVector.self, forKey: .r)
		self.o = try container.decode(AnimatedNumber.self, forKey: .o)

		try super.init(from: decoder)
	}
	
	func GetTransformer(_ Frame:FrameNumber) -> Transformer
	{
		var Anchor = a.GetValueVec2(Frame);
		var Position = p.GetValueVec2(Frame);
		var FullScale = Vector2(100.0,100.0);
		var Scale = s.GetValueVec2(Frame) / FullScale;
		var Rotation = r.GetValue(Frame);
		return Transformer( Position, Anchor, Scale, Double(Rotation) );
	}
	
	func GetAlpha(_ Frame:FrameNumber) -> Float
	{
		var Opacity = o.GetValue(Frame);
		var Alpha = Opacity / 100.00;
		return Alpha;
	}
}


//	struct ideally, but to include pointer to parent, can't be a struct
public class Transformer
{
	public var	Parent : Transformer? = nil
	var			Scale = Vector2.one
	var			Translation = Vector2()
	var			Anchor = Vector2()
	var			RotationDegrees : Double = 0

	init()
	{
	}
	
	init(_ Translation:Vector2,_ Anchor:Vector2,_ Scale:Vector2,_ RotationDegrees:Double)
	{
		self.Translation = Translation;
		self.Anchor = Anchor;
		self.Scale = Scale;
		self.Parent = nil;
		self.RotationDegrees = RotationDegrees;
	}

	func LocalToParentPosition(_ _LocalPosition:Vector2) -> Vector2
	{
		var LocalPosition = _LocalPosition
		//	0,0 anchor and 0,0 translation is topleft
		//	20,0 anchor and 0,0 position, makes 0,0 offscreen (-20,0)
		//	anchor 20, pos 100, makes 0,0 at 80,0
		//	scale applies after offset
		LocalPosition -= Anchor;
		//LocalPosition = Quaternion.AngleAxis(RotationDegrees, Vector3.forward) * LocalPosition;
		LocalPosition.Rotate(Degrees:RotationDegrees)
		//	apply rotation here
		LocalPosition *= Scale;
		LocalPosition += Translation;
		return LocalPosition;
	}
	
	func LocalToParentSize(_ _LocalSize:Vector2) -> Vector2
	{
		var LocalSize = _LocalSize
		LocalSize *= Scale;
		return LocalSize;
	}
	
	func LocalToWorldPosition(_ LocalPosition:Vector2) -> Vector2
	{
		var ParentPosition = LocalToParentPosition(LocalPosition);
		var WorldPosition = ParentPosition;
		if let parent = Parent
		{
			WorldPosition = parent.LocalToWorldPosition(ParentPosition);
		}
		return WorldPosition;
	}
	
	func LocalToWorldPosition(_ LocalRect:CGRect) -> CGRect
	{
		var ParentMin = LocalToParentPosition(LocalRect.min);
		var ParentMax = LocalToParentPosition(LocalRect.max);
		var WorldMin = ParentMin;
		var WorldMax = ParentMax;
		if let parent = Parent
		{
			WorldMin = parent.LocalToWorldPosition(ParentMin);
			WorldMax = parent.LocalToWorldPosition(ParentMax);
		}
		return CGRect.MinMaxRect( WorldMin.x, WorldMin.y,WorldMax.x,WorldMax.y);
	}
	
	func LocalToWorldSize(_ LocalSize:Vector2) -> Vector2
	{
		var ParentSize = LocalToParentSize(LocalSize);
		var WorldSize = ParentSize;
		if let parent = Parent
		{
			WorldSize = parent.LocalToWorldSize(ParentSize);
		}
		return WorldSize;
	}
	func LocalToWorldSize(_ LocalSize:CGFloat) -> CGFloat
	{
		//	expected to be used in 1D cases anyway
		var Size2 = Vector2(LocalSize,LocalSize);
		Size2 = LocalToWorldSize(Size2);
		return Size2.x;
	}
	
}

public struct LayerMeta : Decodable, Identifiable	//	shape layer
{
	//	gr: the layer type doesn't have a built in uid unless it needs it for parenting...
	//		can we generate one here with a uuid fallback?
	public var id = UUID()
	
	public func IsVisible(_ Frame:FrameNumber) -> Bool
	{
		if ( Frame < FirstKeyFrame )
		{
			return false;
		}
		if ( Frame > LastKeyFrame )
		{
			return false;
		}
		/*
		if ( Time < StartTime )
			return false;
			*/
		return true;
	}

	public var ip : Double
	public var FirstKeyFrame : FrameNumber	{	ip	}	//	visible after this
	public var op : Double;	//	= 10
	public var LastKeyFrame : FrameNumber	{	op	}		//	invisible after this (time?)
	
	public var nm : String;// = "Lottie File"
	public var Name : String { nm ?? "Unnamed"	}

	public var refId : String?
	public var ResourceId : String { refId ?? ""	}
	public var ind : Int?
	public var LayerId : Int { ind ?? 0	}	//	for parenting
	public var parent : Int? = nil
	
	public var st : Double
	public var StartTime : FrameNumber { st }

	public var ddd : Int
	public var ThreeDimensions : Bool	{	ddd == 3	}
	public var ty : Int
	public var type : LayerType	{	GetlayerType(ty)	}
	public var sr : Int
	public var ks : ShapeTransform
	public var Transform : ShapeTransform	{	ks	}	//	gr: this is not really a shape, but has same properties & interface (all the derived parts in ShapeTransform)
	public var ao : Int
	public var AutoOrient : Bool { return ao != 0	}
	public var bm : Int?
	public var BlendMode : Int	{	bm ?? 0 }

	//	text layer
	var t : TextData?
	public var Text : TextData?	{	t	}
	
	//	shape layer
	public var shapes : [ShapeWrapper]?
	public var Shapes : [ShapeWrapper]	{	return shapes ?? []	}
	public var ChildrenFrontToBack : [Shape]	{	Shapes.map{ sw in sw.TheShape }	}
	public var ChildrenBackToFront : [Shape]	{	ChildrenFrontToBack.reversed()	}
	
	
	
	//	only needed because of id
	enum CodingKeys: CodingKey {
		case ip
		case op
		case nm
		case refId
		case ind
		case parent
		case st
		case ddd
		case ty
		case sr
		case ks
		case ao
		case bm
		case shapes
		case t
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.ip = try container.decode(Double.self, forKey: .ip)
		self.op = try container.decode(Double.self, forKey: .op)
		self.nm = try container.decode(String.self, forKey: .nm)
		self.refId = try container.decodeIfPresent(String.self, forKey: .refId)
		self.ind = try container.decodeIfPresent(Int.self, forKey: .ind)
		self.parent = try container.decodeIfPresent(Int.self, forKey: .parent)
		self.st = try container.decode(Double.self, forKey: .st)
		self.ddd = try container.decode(Int.self, forKey: .ddd)
		self.ty = try container.decode(Int.self, forKey: .ty)
		self.sr = try container.decode(Int.self, forKey: .sr)
		self.ks = try container.decode(ShapeTransform.self, forKey: .ks)
		self.ao = try container.decode(Int.self, forKey: .ao)
		self.bm = try container.decodeIfPresent(Int.self, forKey: .bm)
		
		//	shape layer
		self.shapes = try container.decodeIfPresent([ShapeWrapper].self, forKey: .shapes)
		
		//	text layer
		self.t = try container.decodeIfPresent(TextData.self, forKey: .t)
	}
	
	
}


//	seems a little faster as struct
public class Root : Decodable
{
	public func FrameToTime(_ FrameNumber:FrameNumber) -> TimeInterval
	{
		var Frame = FrameNumber
		Frame -= FirstKeyFrame
		return TimeInterval( Frame / FramesPerSecond)
	}
		
	public func TimeToFrame(_ Time:TimeInterval,Looped:Bool) -> Double
	{
		var Duration = Duration//.TotalSeconds;
		var Time_TotalSeconds = Time
		var TimeSecs = Looped ? TimeInterval( Time_TotalSeconds.truncatingRemainder(dividingBy: Duration) ) : TimeInterval( min( Time_TotalSeconds, Duration ) )
		var Frame = (TimeSecs * FramesPerSecond)
		Frame += Double(FirstKeyFrame)
		return Double(Frame)
	}
	
	public var v : String	//"5.9.2"
	public var fr : Double
	public var FramesPerSecond : Double { fr	}
	public var ip : Double
	public var FirstKeyFrame : FrameNumber { FrameNumber(ip)	}
	public var FirstKeyFrameTime : TimeInterval	{ FrameToTime(FirstKeyFrame)	}
	public var op : Float	//	= 10
	public var LastKeyFrame : Float { op }
	public var LastKeyFrameTime : TimeInterval {	FrameToTime(FrameNumber(LastKeyFrame))	}
	public var Duration : TimeInterval { LastKeyFrameTime - FirstKeyFrameTime	}
	public var w : CGFloat//int	//: = 100
	public var h : CGFloat//int//: = 100
	public var nm : String// = "Lottie File"
	public var Name : String {	nm ?? "Unnamed"	}
	public var ddd : Int = 0	//	not sure what this is, but when it's 3 "things are reversed"

	//public var AssetMeta[]	assets;
	public var layers : [LayerMeta]
	public var LayersFrontToBack : [LayerMeta]	{	layers	}
	public var LayersBackToFront : [LayerMeta]	{	LayersFrontToBack.reversed()	}
	//public var MarkerMeta[]	markers;
/*
	public var AssetMeta[]	Assets => assets ?? Array.Empty<AssetMeta>();
	public var LayerMeta[]	Layers => layers ?? Array.Empty<LayerMeta>();
	public var MarkerMeta[]	Markers => markers ?? Array.Empty<MarkerMeta>();
 */
	
	public init(Width:Int,Height:Int,Name:String,DurationSeconds:Double)
	{
		layers = []
		v = LottieFormatVersion
		fr = 15
		ip = 0.0
		op = Float(DurationSeconds)
		w  = CGFloat(Width)
		h = CGFloat(Height)
		nm = Name

	}
	
}



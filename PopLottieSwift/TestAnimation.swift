import Foundation
import SwiftUI

public func DegreesToRadians(Degrees:Double) -> Double
{
	//	gr: at some point, this double overflows into a negative number, and quartz doesn't like it
	//		can we have negatives at all?
	var Deg = Degrees
	/*
	if ( Deg > 360.0 * 1000.0 )
	{
		Deg = Deg.truncatingRemainder(dividingBy: 360.0)	//	modulous
	}
	//	beware of infinite loops
	//	gr: what if input is inf/nan etc
	//	gr: making this 0...1000 loop is SO expensive
	
	var Safety = 1000
	while ( Deg < 0.0 && Safety > 0 )
	{
		Safety -= 1
		Deg += 360.0
	}
*/
	let Rad = Degrees * (Double.pi/180.0)
	return Rad
}



class TestAnimation : PathAnimation
{
	//@Environment(\.self) var environment	//	for swift color conversion
	
	func RenderFrame(frameNumber: Double, contentRect: CGRect, scaleMode: ScaleMode,IncludeHiddenLayers:Bool) -> AnimationFrame
	{
		let Circle = MakeCirclePath(Bounds: contentRect,frameNumber:frameNumber)
		return AnimationFrame(shapes: [Circle])
	}
	
	func TimeToFrame(PlayTime: TimeInterval, Looped: Bool) -> Double 
	{
		return PlayTime
		//return Double.nan
	}
	
	var SliceWidth = 0.60

	
	func MakeCirclePath(Bounds:CGRect,frameNumber:Double) -> AnimationShape
	{
		let path = CGMutablePath()

		let x = Bounds.minX + (Bounds.width/2.0)
		let y = Bounds.minY + (Bounds.height/2.0)
		let rad = Bounds.height * 0.5

		let AngleDegrees = frameNumber * 2.0 * 360.0
		
		let StartAngle = DegreesToRadians(Degrees: AngleDegrees )
		let EndAngle = DegreesToRadians(Degrees: AngleDegrees + (360.0*SliceWidth) )

		path.addArc(center: CGPoint(x:x,y:y),
					radius: rad,
					startAngle: StartAngle,
					endAngle: EndAngle,
					clockwise: false)

		//var shape = AnimationShape(Paths: [path])
		var shape = AnimationShape(Paths: [], Name:"Test Circle")
		shape.FillColour = AnimationColour(red: 0, green: 1, blue: 1, alpha: 0.7)
		shape.StrokeColour = AnimationColour(red: 0, green: 0, blue: 0, alpha: 0.7)
		shape.StrokeWidth = 20
		return shape
	}

}



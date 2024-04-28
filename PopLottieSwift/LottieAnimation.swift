//import Foundation
import QuartzCore



var LottieAnimationCache : [URL:LottieLoadWrapper] = [:]


func GetLottieAnimation(Url:URL) async throws -> Root
{
	//	if it doesnt exist, start loading it... also need pending loads...
	var Loader = LottieAnimationCache[Url]
	if Loader == nil
	{
		Loader = LottieLoadWrapper(Url: Url)
		LottieAnimationCache[Url] = Loader
	}
	
	return try await Loader!.WaitForAnimation()
}


//	we need a wrapper to keep the state of the load, so we
//	- dont load 100 of the same anims at once
//	- dont keep reloading bad anims
class LottieLoadWrapper
{
	//var root : Root? = nil		//	finished load
	var animationPromise = GrahamsPromise<Root>() //Task<Root,Error>
	//var loadTaskPromise = Task<Root,Never>
	
	//	url is also dictionary key
	init(Url:URL)
	{
		/*loadTaskPromise =*/ Task
		{
			return try await Load(Url:Url)
		}
	}
	
	func Load(Url:URL) async throws -> Root
	{
		do
		{
			print("Decoding lottie animation \(Url)")
			let Json = try String(contentsOf: Url)
			let JsonData = Json.data(using: .utf8)!
			let Animation = try JSONDecoder().decode( Root.self, from: JsonData )
			animationPromise.resolve(Animation)
			return Animation
		}
		catch
		{
			print(error)
			animationPromise.reject(error)
			throw error
		}
	}
	
	public func WaitForAnimation() async throws -> Root
	{
		return try await animationPromise.Wait()
	}
}




//	struct to allow auto hashable
class LottieAnimation : PathAnimation
{
	var lottie : Root? = nil
	/*
	static func == (lhs: LottieAnimation, rhs: LottieAnimation) -> Bool
	{
		return lhs.lottie == rhs.lottie
	}
	func hash(into hasher: inout Hasher)
	{
		hasher.combine(lottie)
	}
	*/
	init(filename:URL)
	{
		Task()
		{
			do
			{
				lottie = await try GetLottieAnimation(Url: filename)
			}
			catch
			{
				OnError(error.localizedDescription)
			}
		}
	}
	
	init(lottie:Root)
	{
		self.lottie = lottie
	}
	
	func OnError(_ error:String)
	{
		//	todo: change graphics to an error (X!)
	}
	
	
	func TimeToFrame(PlayTime: TimeInterval, Looped: Bool) -> FrameNumber
	{
		if let Anim = lottie
		{
			return Anim.TimeToFrame( PlayTime, Looped: Looped )
		}
		return FrameNumber.nan
	}
	
	
	func RenderFrame(frameNumber: FrameNumber, contentRect: CGRect, scaleMode: ScaleMode,IncludeHiddenLayers:Bool) -> AnimationFrame
	{
		do
		{
			if let Anim = lottie
			{
				return try Render( lottie: Anim, Frame: frameNumber, ContentRect: contentRect, scaleMode: scaleMode,IncludeHiddenLayers:IncludeHiddenLayers)
			}
		}
		catch
		{
			print(error)
		}
		return AnimationFrame()
	}
	
	
	//	like for like source of the c# Render()
	func Render(lottie:Root,Frame:FrameNumber,ContentRect:CGRect,scaleMode:ScaleMode,IncludeHiddenLayers:Bool) throws -> AnimationFrame
	{
		//Debug.Log($"Time = {Time.TotalSeconds} ({lottie.FirstKeyframe.TotalSeconds}...{lottie.LastKeyframe.TotalSeconds})");

		//	work out the placement of the canvas - all the shapes are in THIS canvas space
		var LottieCanvasRect = CGRect(x:0,y:0,width:lottie.w,height:lottie.h)

		var OutputFrame = AnimationFrame()
		func AddRenderShape(_ NewShape:AnimationShape)
		{
			OutputFrame.AddShape(NewShape);
		}

		//	scale-to-canvas transformer
		var ExtraScale = 1.0;	//	for debug zooming
		var ScaleToCanvasWidth = (ContentRect.width / lottie.w)*ExtraScale;
		var ScaleToCanvasHeight = (ContentRect.height / lottie.h)*ExtraScale;
		var Stretch = scaleMode == ScaleMode.StretchToFill;
		
		//	todo: handle scale + crop (scale up)
		//	todo: fit height or width, whichever is smaller
		var FitHeight = ScaleToCanvasHeight <= ScaleToCanvasWidth;
		if ( scaleMode == ScaleMode.ScaleAndCrop )
		{
			FitHeight = !FitHeight;
		}
		
		var ScaleToCanvasUniform = FitHeight ? ScaleToCanvasHeight : ScaleToCanvasWidth;
		var ScaleToCanvas = Stretch ? Vector2( ScaleToCanvasWidth, ScaleToCanvasHeight ) : Vector2( ScaleToCanvasUniform, ScaleToCanvasUniform );
		
		//	gr: work this out properly....
		var CenterAlign = true;
		var RootTransformer = Transformer( ContentRect.min, Vector2.zero, ScaleToCanvas, 0.0 );
		OutputFrame.CanvasRect = RootTransformer.LocalToWorldPosition(LottieCanvasRect);
		if ( CenterAlign )
		{
			var Centering = (ContentRect.max - OutputFrame.CanvasRect.max)/2.0;
			RootTransformer = Transformer( ContentRect.min + Centering, Vector2.zero, ScaleToCanvas, 0.0 );
			//	re-write canvas to make sure this is correct
			OutputFrame.CanvasRect = RootTransformer.LocalToWorldPosition(LottieCanvasRect);
		}
		
		var CurrentPaths : [AnimationPath] = []
		func BeginShape() throws
		{
			//	clean off old shape
			if ( CurrentPaths.count != 0 )
			{
				throw fatalError("Finished off old shape?");
			}
		}
		func FinishLayerShape() throws
		{
			//	clean off old shape
			if ( CurrentPaths.count != 0 )
			{
				throw fatalError("Finished off old shape?");
			}
		}
		
		func RenderText(_ Text:TextData,_ ParentTransform:Transformer,_ LayerAlpha:Float, LayerName:String) throws
		{
			for TextFrame in Text.d.Keyframes
			{
				var FillColour = TextFrame.Text.FillColour
				var StrokeColour = TextFrame.Text.StrokeColour
				let StrokeWidth = TextFrame.Text.StrokeWidth
				FillColour.alpha *= Double(LayerAlpha)
				StrokeColour.alpha *= Double(LayerAlpha)

				var Paths : [AnimationPath] = []
				//	gr: need to generate a transform specifically for glyphs here hmm
				var LinePosition = Vector2(0.0,0.0)
				let FontSize = ParentTransform.LocalToWorldSize( CGFloat(TextFrame.Text.FontSize) )
				for Line in TextFrame.s.TextLines
				{
					var WorldPosition = ParentTransform.LocalToWorldPosition(LinePosition)
					var TextPath = AnimationText(Text: Line, FontName: TextFrame.Text.FontFamily, FontSize: FontSize, Position: WorldPosition )
					var Path = AnimationPath(TextPath)
					Paths.append( Path )
					//	gr: need to scale this too?
					LinePosition.y += TextFrame.Text.LineHeight
				}
				var Shape = AnimationShape(Paths: Paths, Name:LayerName)
				Shape.FillColour = FillColour
				Shape.StrokeColour = StrokeColour
				Shape.StrokeWidth = StrokeWidth
				AddRenderShape(Shape)
			}
		}
		
		func RenderGroup(_ Group:ShapeGroup,_ ParentTransform:Transformer,_ LayerAlpha:Float, LayerName:String) throws
		{
			//	run through sub shapes
			var Children = Group.ChildrenBackToFront;

			//	elements (shapes) in the layer may be in the wrong order, so need to pre-extract style & transform
			var GroupTransform = try Group.GetTransformer(Frame);
			GroupTransform.Parent = ParentTransform;
			var GroupStyleMaybe = Group.GetShapeStyle(Frame);
			var GroupStyle = GroupStyleMaybe ?? ShapeStyle();
			var GroupAlpha = Group.GetAlpha(Frame);
			GroupAlpha *= LayerAlpha;
			
			
			func AddPath(_ NewPath:AnimationPath)
			{
				CurrentPaths.append(NewPath);
			}
			
			
			func FinishShape()
			{
				var FillColour = GroupStyle.FillColour
				var StrokeColour = GroupStyle.StrokeColour
				var StrokeWidth = GroupTransform.LocalToWorldSize( GroupStyle.StrokeWidth ?? 1 );
				FillColour?.alpha *= Double(GroupAlpha)
				StrokeColour?.alpha *= Double(GroupAlpha)

				var NewShape = AnimationShape(Paths: CurrentPaths, Name:LayerName);
			
				if ( GroupStyle.IsStroked )
				{
					NewShape.StrokeColour = StrokeColour;
					NewShape.StrokeWidth = StrokeWidth;
				}
				if ( GroupStyle.IsFilled )
				{
					NewShape.FillColour = FillColour;
				}
				
				CurrentPaths = []
				AddRenderShape(NewShape);
			}
			
			func RenderChild(_ Child:Shape) throws
			{
				//	force visible with debug
				if ( !Child.Visible && !IncludeHiddenLayers )
				{
					return;
				}
				
				if let path = Child as? ShapePath
				{
					var Trim = Group.GetPathTrim(Frame);
					var Bezier = path.Path_Bezier.GetBezier(Frame);
					var Points = Bezier.GetControlPoints(Trim);
					var RenderPoints : [BezierPoint] = []
					
					func CurveToPoint(_ Point:Bezier.ControlPoint,_ PrevPoint:Bezier.ControlPoint)
					{
						//	gr: working out this took quite a bit of time.
						//		the cubic bezier needs 4 points; Prev(start), tangent for first half of line(start+out), tangent for 2nd half(end+in), and the end
						var cp0 = PrevPoint.Position + PrevPoint.OutTangent;
						var cp1 = Point.Position + Point.InTangent;
						
						var VertexPosition = GroupTransform.LocalToWorldPosition(Point.Position);
						var ControlPoint0 = GroupTransform.LocalToWorldPosition(cp0);
						var ControlPoint1 = GroupTransform.LocalToWorldPosition(cp1);
						
						var BezierPoint = BezierPoint();
						BezierPoint.ControlPointIn = ControlPoint0;
						BezierPoint.ControlPointOut = ControlPoint1;
						BezierPoint.Position = VertexPosition;
						RenderPoints.append(BezierPoint);
					}
					
					for p in 0...Points.count-1
					{
						var PrevIndex = (p==0 ? Points.count-1 : p-1);
						var Point = Points[p];
						var PrevPoint = Points[PrevIndex];
						var VertexPosition = GroupTransform.LocalToWorldPosition(Point.Position);
						//	skipping first one gives a more solid result, so wondering if
						//	we need to be doing a mix of p and p+1...
						if ( p==0 )
						{
							var BezierPoint = BezierPoint();
							BezierPoint.ControlPointIn = VertexPosition;
							BezierPoint.ControlPointOut = VertexPosition;
							BezierPoint.Position = VertexPosition;
							RenderPoints.append(BezierPoint);
						}
						else
						{
							CurveToPoint(Point,PrevPoint);
						}
					}
					
					if ( Bezier.Closed && Points.count > 1 )
					{
						if ( Trim.IsDefault )
						{
							CurveToPoint( Points[0], Points[Points.count-1] );
						}
					}
					
					AddPath( AnimationPath(RenderPoints) );
				}

				if let ellipse = Child as? ShapeEllipse
				{
					var RenderEllipse = Ellipse()
					var EllipseSize = GroupTransform.LocalToWorldSize(try ellipse.Size.GetValueVec2(Frame));
					var LocalCenter = try ellipse.Center.GetValueVec2(Frame);
					var EllipseCenter = GroupTransform.LocalToWorldPosition(LocalCenter);
					
					RenderEllipse.Center = EllipseCenter;
					RenderEllipse.Radius = EllipseSize;
					AddPath( AnimationPath(RenderEllipse) );
				}
		
				if let rectangle = Child as? ShapeRectangle
				{
					var LocalSize = try rectangle.Size.GetValueVec2(Frame)
					var LocalCenter = try rectangle.Center.GetValueVec2(Frame)
					var RectCenter = GroupTransform.LocalToWorldPosition(LocalCenter);
					var RectSize = GroupTransform.LocalToWorldSize(LocalSize)
					
					let Path = AnimationPath.CreateRect(Center: RectCenter, Size: RectSize)
					AddPath( Path )
				}
		
				if let subgroup = Child as? ShapeGroup
				{
					do
					{
						try RenderGroup(subgroup,GroupTransform,GroupAlpha, LayerName:LayerName);
					}
					catch
					{
						print(error)
					}
				}
			}
			
			//	gr: we need to break paths when styles change
			//		but if we have layer->shape->group->group->shape we need to NOT break paths
			if ( GroupStyleMaybe != nil )
			{
				try! BeginShape()
			}
			
			
			for Child in Children	//	Children = [Shape]
			{
				do
				{
					try RenderChild(Child);
				}
				catch
				{
					print(error)
				}
			}
			
			if ( GroupStyleMaybe != nil )
			{
				FinishShape();
			}
		}
	
		//	layers go front to back
		for Layer in lottie.LayersBackToFront
		{
			if ( !Layer.IsVisible(Frame) && !IncludeHiddenLayers )
			{
				continue;
			}
			
			var ParentTransformer = RootTransformer;
			if ( Layer.parent != nil )
			{
				var ParentLayers = lottie.layers.filter{ l in return l.LayerId == Layer.parent! }
				if ( ParentLayers.count != 1 )
				{
					print("Too few or too many parent layers for {Layer.Name} (parent={Layer.parent})")
				}
				else
				{
					var ParentLayerTransform = try ParentLayers[0].Transform.GetTransformer(Frame);
					ParentLayerTransform.Parent = ParentTransformer;
					ParentTransformer = ParentLayerTransform;
				}
			}
			
			var LayerTransform = try Layer.Transform.GetTransformer(Frame);
			LayerTransform.Parent = ParentTransformer;
			var LayerOpacity = Layer.Transform.GetAlpha(Frame);
			
			//	skip hidden layers
			if ( LayerOpacity <= 0 && !IncludeHiddenLayers )
			{
				continue;
			}

			try BeginShape();
			
			//	if Layer.type == LayerType.Text
			if let text = Layer.Text
			{
				do
				{
					try RenderText( text, LayerTransform, LayerOpacity, LayerName:Layer.Name)
				}
				catch
				{
					print(error)
				}
			}
			
			//	gr: if Layer.type == LayerType.Shape
			//	render the shape
			for Shape in Layer.ChildrenBackToFront
			{
				do
				{
					if let group = Shape as? ShapeGroup
					{
						try RenderGroup(group,LayerTransform,LayerOpacity, LayerName:Layer.Name);
					}
					else
					{
						print("Not a group...")
					}
				}
				catch
				{
					print(error)
				}
			}
			try FinishLayerShape();
		}
		
		return OutputFrame;
	}
	
}

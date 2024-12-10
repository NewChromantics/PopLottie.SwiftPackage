
public class GrahamsPromise<T>
{
	var result : T? = nil
	var error : Error? = nil
	
	public init()
	{
	}
	
	public func Wait() async throws -> T
	{
		//	spin! yuck!
		while ( true )
		{
			//	throws when task cancelled
			await try Task.sleep(nanoseconds: 1_000_000)
			if let result
			{
				return result
			}
			if let error
			{
				throw error
			}
		}
	}
	
	public func resolve(_ value:T)
	{
		result = value
	}
	
	public func reject(_ exception:Error)
	{
		error = exception
	}
}

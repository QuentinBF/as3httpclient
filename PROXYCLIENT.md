# Description
This library is an extension of [as3httpclient](https://github.com/gabriel/as3httpclient) that gets around the socket and security issues inherent with making raw http socket requests from flash player, by using a proxy file to interpret requests. This allows full communication with RESTful webservices.

## Operation
The client accepts all the same requests as the base client, but instead of using a socket connection, turns the request into a custom http post request, with the headers, method, body, etc. passed through as meta data. This is then interpreted by a server side php proxy file into the real request. 

When a response is received by the proxy, it then translates this back into a meta data format that flash can receive via URLLoader. This is then decoded by the client and returned in the same format as the base class. 

This allows seamless migration from as3httpclientlib projects with only a few lines needing to change.

## Usage
Usage matches that of as3httpclientlib , apart from the client constructor, where you need to pass the url of the php proxy file.

	package  
	{
		import com.hurlant.util.Base64;
		import com.lookmum.httpclient.util.HttpProxyClient;
		import flash.display.Sprite;
		import org.httpclient.events.HttpDataEvent;
		import org.httpclient.events.HttpRequestEvent;
		import org.httpclient.events.HttpResponseEvent;
		import org.httpclient.events.HttpStatusEvent;
		import org.httpclient.http.Put;

		public class Example1 extends Sprite
		{

			public function Example1() 
			{
				var client:HttpProxyClient = new HttpProxyClient('http://mysite.com/flashrestproxy.php');
				var request:Put = new Put();
				request.addHeader('someHeader', 'someValue');
				var formData:Array = [ 
					{ name:'food1', value:'eggs' },
					{ name:'food2', value:'fish' }
				];
				request.setFormData(formData);
				var username:String = 'myusername';
				var password:String = 'mypassword';
				var credentials:String = Base64.encode(username + ':' + password);
				request.addHeader('Authorization: Basic ', credentials);
				client.request(new URI('http://mysite.com/myrestwebservice/foods'), request);
				client.addEventListener(HttpStatusEvent.STATUS, onStatus);
				client.addEventListener(HttpDataEvent.DATA, onData);
				client.addEventListener(HttpResponseEvent.COMPLETE, onResponse);
				client.addEventListener(HttpRequestEvent.COMPLETE, onRequest);
				client.addEventListener(HttpRequestEvent.CONNECT, onRequest);
			}
			private function onRequest(e:HttpRequestEvent):void 
			{
				trace( "Example1.onRequest > e : " + e );
				
			}
			private function onResponse(e:HttpResponseEvent):void 
			{
				trace( "Example1.onResponse > e : " + e );
				trace( "e.response : " + e.response );
			}
			private function onData(e:HttpDataEvent):void 
			{
				trace( "Example1.onData > e : " + e.readUTFBytes() );	
			}
			private function onStatus(e:HttpStatusEvent):void 
			{
				trace( "Example1.onStatus > e : " + e );
			}
		}
	}

## Issues
As the client uses URLloader to send and recieve requests in text format. The client cannot be used for communication involving binary data

The php proxy must be installed on a server that has the CURLLib module installed in order to make http requests. Most servers will have this but it's worth checking your phpinfo just incase.

The headers passed through may not contain the text `[body]` this will make the deserialisation go loopy.

## TODO
Mirror the timeout support of as3httpclientlib.

Write proxies for other languages.

Support for php modules besides CURLLib.
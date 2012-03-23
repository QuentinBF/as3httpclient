/**
 * @author Phil Douglas
 * @version 0.1 Alpha
 * 
 * An extension of as3httpclientlib to allow restful communication from flash player on the web
 * 
 * http://www.lookmumimontheinternet.com/
 * 
 * Copyright (c) 2009 Phil Douglas
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 * 
 */
package org.httpclient 
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	import org.httpclient.events.HttpDataEvent;
	import org.httpclient.events.HttpErrorEvent;
	import org.httpclient.events.HttpRequestEvent;
	import org.httpclient.events.HttpResponseEvent;
	import org.httpclient.events.HttpStatusEvent;
	import org.httpclient.HttpHeader;
	import org.httpclient.HttpRequest;
	import org.httpclient.HttpResponse;
	import org.httpclient.Log;

	import com.adobe.net.URI;
	import org.httpclient.HttpClient;
    
	[Event(name=Event.CLOSE, type="flash.events.Event")]  

	[Event(name=HttpRequestEvent.CONNECT, type="org.httpclient.events.HttpRequestEvent")]
	[Event(name=HttpResponseEvent.COMPLETE, type="org.httpclient.events.HttpResponseEvent")]

	[Event(name=HttpDataEvent.DATA, type="org.httpclient.events.HttpDataEvent")]     
	[Event(name=HttpStatusEvent.STATUS, type="org.httpclient.events.HttpStatusEvent")]
	[Event(name=HttpRequestEvent.COMPLETE, type="org.httpclient.events.HttpRequestEvent")]  
	[Event(name=HttpErrorEvent.ERROR, type="org.httpclient.events.HttpErrorEvent")]  
	[Event(name=HttpErrorEvent.TIMEOUT_ERROR, type="org.httpclient.events.HttpErrorEvent")]    
	[Event(name=IOErrorEvent.IO_ERROR, type="flash.events.IOErrorEvent")]  
	[Event(name=SecurityErrorEvent.SECURITY_ERROR, type="flash.events.SecurityErrorEvent")]  
	

	public class HttpProxyClient extends HttpClient
	{
		private var _loader:URLLoader
		private var _flashProxy:URI;
		/**
		 * Create HTTP client
		 * @param	flashProxy URI
		 * @param	proxy URI
		 */
		public function HttpProxyClient(flashProxy:URI, proxy:URI = null) 
		{
			super(proxy);
			_flashProxy = flashProxy;
		}
		/**
		 * Load a generic request.
		 * @param	uri URI
		 * @param	request HTTP request
		 * @param	timeout Timeout (in millis)
		 */
		override public function request(uri:URI, request:HttpRequest, timeout:int = 60000):void 
		{
			//turn the request headers into meta data
			var header:String = '[URI]\n' + uri.toString() + '\n';
			header += '[method]\n' + request.method + '\n';
			header += '[header]\n' + request.header + '\n';
			//serialise the body
			var data:String;
			var body:String;
			if (request.body) {
				body = '[body]\n' + request.body;
			}else {
				//empty body
				body = '[body]'
			}
			//stitch header data and request body together
			data = header + body;
			//construct the new urlrequest
			var urlRequest:URLRequest = new URLRequest(_flashProxy.toString());
			urlRequest.data = data;
			urlRequest.method = URLRequestMethod.POST;
			//make the request
			_loader = new URLLoader(urlRequest);
			_loader.addEventListener(Event.COMPLETE, onComplete);
			_loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			dispatchEvent(new HttpRequestEvent(request, request.header.toString(), HttpRequestEvent.CONNECT));
			dispatchEvent(new HttpRequestEvent(request, request.header.toString()));
		}
		private function onStatus(e:HTTPStatusEvent):void 
		{
			if (e.status != 0 && e.status != 200) {
				dispatchEvent(new HttpErrorEvent(HttpErrorEvent.ERROR));
			}
		}
		private function onIOError(e:IOErrorEvent):void 
		{
			dispatchEvent(e.clone());
		}
		private function onSecurityError(e:SecurityErrorEvent):void 
		{
			dispatchEvent(e.clone());
		}
		private function onComplete(e:Event):void 
		{
			var data:String = e.target.data;
			var header:String = data.substring(data.indexOf('[header]') + 9, data.indexOf('[body]'));
			var body:String = data.substring(data.indexOf('[body]') + 7, data.length);
			var lines:Array = header.split('\n');
			var line:String = lines[0].substr(0, lines[0].length - 1);
			var matches:Array = line.match(/\AHTTP(?:\/(\d+\.\d+))?\s+(\d\d\d)\s*(.*)\z/);
			if (!matches) throw new Error("Invalid header: " + line + ", matches: " + matches);
			var version:String = matches[1];
			var code:String = matches[2];
			var message:String = matches[3];
			var headers:Array = [];      
			for(var i:Number = 1; i < lines.length; i++) {
				line = lines[i];
				if (line == '' || line == '\n' || line == '\r') continue;
				var index:int = line.indexOf(":");
				if (index != -1) {
					var name:String = line.substring(0, index);
					var value:String = line.substring(index + 1, line.length);
					headers.push({ name: name, value: value });
				} else {
					Log.warn("Invalid header: " + line);
				}
			}
			
			var httpResponse:HttpResponse = new HttpResponse(version, code, message, new HttpHeader(headers));
			
			//construct status event
			dispatchEvent(new HttpStatusEvent(httpResponse));
			
			//construct response event
			dispatchEvent(new HttpResponseEvent(httpResponse));
			
			//construct http data event
			//convert to bytes so behaves the same as standard httpclient.
			var bytes:ByteArray = new ByteArray();
			bytes.writeUTFBytes(body);
			bytes.position = 0;
			dispatchEvent(new HttpDataEvent(bytes));
		}
		
		
	}
	
}

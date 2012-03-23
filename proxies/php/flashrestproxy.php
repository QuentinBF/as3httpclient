<?php
/*
 * @author Phil Douglas
 * @version 0.1 Alpha
 * 
 * An extension of as3httpclientlib to allow restful communication from flash player on the web
 * 
 * http://code.google.com/p/as3httpproxyclientlib
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

//check that method is post
$method = strtoupper($_SERVER["REQUEST_METHOD"]);
if($method != "POST") {
	//error wrong method
	return;
}
//load the post vars
$raw_post = file_get_contents("php://input");
//seperate meta info and body
//get the uri
$start = strpos($raw_post, '[URI]') + 6;
$end = strpos($raw_post, '[method]') - $start - 1;
$uri = substr($raw_post, $start, $end);
//get the method
$start = strpos($raw_post, '[method]') + 9;
$end = strpos($raw_post, '[header]') - $start - 1;
$method = strtoupper(substr($raw_post, $start, $end));
//get the header
$start = strpos($raw_post, '[header]') + 9;
$end = strpos($raw_post, '[body]') - $start - 1;
$header = substr($raw_post, $start, $end);
$headers = explode("\n", $header);
for($i = 0; $i < count($headers); $i++ ) {
	$value = $headers[$i];
	echo("[value]".$value."\n");
}
//get the body
$start = strpos($raw_post, '[body]') + 7;
if($start)$body = substr($raw_post, $start);
//construct the real request
$ch = curl_init();
function readHeader($ch, $header) {
	global $headers;
	$headers[] = $header;
	return strlen($header);
}
curl_setopt($ch, CURLOPT_VERBOSE, 1);
curl_setopt($ch, CURLOPT_URL, $uri);
curl_setopt($ch, CURLOPT_HEADER, 0);
curl_setopt($ch, CURLOPT_HEADERFUNCTION, readHeader);
curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
if($body) curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
$headers = array();
//make the request
$response = curl_exec($ch);
//convert the result headers into meta info
$responseheader = "[header]\n";
for($i = 0; $i < count($headers); $i++ ) {
	$value = $headers[$i];
    $responseheader = $responseheader.$value;
}
$responsebody = "[body]\n".$response;
curl_close($ch);
//return the result
echo($responseheader ."\n". $responsebody);
?>
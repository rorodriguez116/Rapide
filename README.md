# Rapide
Rapide is a fast and lightweight combine-based wrapper on URLSession. Rapide provides a simple and easy to use API for performing REST request and effortless mapping from and to JSON models, using Swift's native Codable and Decodable protocols.

### Usage
As an example, we'll perform a get request to the following API: 
<code>https://openexchangerates.org/api/convert/2000/GBP/EUR?app_id=XYZ<code>
<pre>
<code>
Rapide
.https
.host("openexhangerates.org")
.path("/api/convert/2000/GBP/EUR")
.params(["app_id":"XYZ"])
.execute(.post, expect: UserJSON.self)
</code>
</pre>
The presented code is very easy to read. First we specify the connection scheme we want to use, Rapide offers http, https and ftp. Then we provide the host and path to our API, the parameters we want to pass the API to and we finalize calling execute, which will return a combine publisher that will execute the specified http method and map the response to the provided Codable conforming type. 

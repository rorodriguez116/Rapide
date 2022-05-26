# Rapide
Rapide is a fast and lightweight combine-based wrapper on URLSession. Rapide provides a simple and easy to use API for performing REST request and effortless mapping from and to JSON models, using Swift's native Codable and Decodable protocols.

### Usage
As an example, we'll perform a get request to the following API: 
`https://openexchangerates.org/api/convert/2000/GBP/EUR?app_id=XYZ<code>`

```
Rapide
    .https
    .host("openexhangerates.org")
    .path("/api/convert/2000/GBP/EUR")
    .authorization(.none)
    .params(["app_id":"XYZ"])
    .execute(.get, decoding: String.self, customErrorType: MyErrorType.self)
    .sink { completion in
        if case let .failure(error) = completion {
            if let err = error as? MyErrorType {
                // Handle your custom error
                print(err.myCustomProperty)
            } else {
                // Handle error 
                print(error)
            }
        }
    } receiveValue: { val in
        // success
    }
    .store(in: &self.subscriptions)
```

This code snippet is very easy to read. First we specify the connection scheme we want to use, Rapide offers http, https and ftp. Then we provide the host and path to our API, the parameters we want to pass the API to and we finalize calling execute, which will return a combine publisher that will execute the specified http method and map the response to the provided Codable conforming type. 

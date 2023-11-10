# glatus

Gleam bindings to the API of the Gatus health check tool.

[![Package Version](https://img.shields.io/hexpm/v/glatus)](https://hex.pm/packages/glatus)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glatus/)

```sh
gleam add glatus
```
```gleam
import glatus
import gleam/httpc

pub fn main() {
  // Build a request
  let request =
    glatus.statuses_request(host: "status.lpil.uk", page: 1)

  // Send the request with a HTTP client
  let assert Ok(response) = httpc.send(request)

  // Decode the response
  let information = glatus.handle_statuses_response(response)
}
```

Documentation can be found at <https://hexdocs.pm/glatus>.

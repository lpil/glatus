import glatus.{ConditionResult, Endpoint, StatusResult}
import gleam/httpc
import gleam/json
import gleeunit
import gleeunit/should
import simplifile

pub fn main() {
  gleeunit.main()
}

pub fn statuses_test() {
  let assert Ok(response) =
    "status.lpil.uk"
    |> glatus.statuses_request(page: 1)
    |> httpc.send
  let assert Ok(_) = glatus.handle_statuses_response(response)
}

pub fn gleam_website_endpoint_test() {
  let assert Ok(response) =
    "status.lpil.uk"
    |> glatus.endpoint_request(endpoint_key: "_gleam-run", page: 1)
    |> httpc.send
  let assert Ok(_) = glatus.handle_endpoint_response(response)
}

pub fn decode_endpoints_test() {
  let assert Ok(json) = simplifile.read("test/statuses.json")
  let assert Ok(data) = json.parse(json, glatus.endpoints_decoder())
  data
  |> should.equal([
    Endpoint(
      name: "gleam.run",
      key: "_gleam-run",
      results: [
        StatusResult(
          status: 200,
          hostname: "gleam.run",
          duration: 68_053_998,
          condition_results: [
            ConditionResult(condition: "[STATUS] == 200", success: True),
            ConditionResult(condition: "[RESPONSE_TIME] 500", success: True),
          ],
          success: True,
          timestamp: "2023-11-10T11:33:49.523233409Z",
        ),
        StatusResult(
          status: 200,
          hostname: "gleam.run",
          duration: 51_742_575,
          condition_results: [
            ConditionResult(condition: "[STATUS] == 200", success: True),
            ConditionResult(condition: "[RESPONSE_TIME] 500", success: True),
          ],
          success: True,
          timestamp: "2023-11-10T11:34:55.471397756Z",
        ),
        StatusResult(
          status: 200,
          hostname: "gleam.run",
          duration: 52_256_811,
          condition_results: [
            ConditionResult(condition: "[STATUS] == 200", success: True),
            ConditionResult(condition: "[RESPONSE_TIME] 500", success: True),
          ],
          success: True,
          timestamp: "2023-11-10T11:36:05.465999106Z",
        ),
      ],
      events: [],
    ),
    Endpoint(
      name: "packages.gleam.run",
      key: "_packages-gleam-run",
      results: [
        StatusResult(
          status: 200,
          hostname: "packages.gleam.run",
          duration: 131_461_823,
          condition_results: [
            ConditionResult(condition: "[STATUS] == 200", success: True),
            ConditionResult(condition: "[RESPONSE_TIME] 500", success: True),
          ],
          success: True,
          timestamp: "2023-11-10T11:33:49.655064634Z",
        ),
        StatusResult(
          status: 200,
          hostname: "packages.gleam.run",
          duration: 123_535_226,
          condition_results: [
            ConditionResult(condition: "[STATUS] == 200", success: True),
            ConditionResult(condition: "[RESPONSE_TIME] 500", success: True),
          ],
          success: True,
          timestamp: "2023-11-10T11:34:55.595285218Z",
        ),
        StatusResult(
          status: 200,
          hostname: "packages.gleam.run",
          duration: 136_001_386,
          condition_results: [
            ConditionResult(condition: "[STATUS] == 200", success: True),
            ConditionResult(condition: "[RESPONSE_TIME] 500", success: True),
          ],
          success: True,
          timestamp: "2023-11-10T11:36:05.60236206Z",
        ),
      ],
      events: [],
    ),
  ])
}

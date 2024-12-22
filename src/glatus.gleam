import gleam/bool
import gleam/dynamic/decode.{type Decoder}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/result

pub type Error {
  UnexpectedResonse(status: Int, body: String)
  UnexpectedPayload(json.DecodeError)
}

pub type Endpoint {
  Endpoint(
    name: String,
    key: String,
    results: List(StatusResult),
    /// This field is not populated by the `/api/v1/endpoints/statuses` endpoint.
    /// It is populated by then `/api/v1/endpoints/:key/statuses` endpoint.
    events: List(StatusEvent),
  )
}

pub type StatusResult {
  StatusResult(
    status: Int,
    hostname: String,
    duration: Int,
    condition_results: List(ConditionResult),
    success: Bool,
    timestamp: String,
  )
}

pub type ConditionResult {
  ConditionResult(condition: String, success: Bool)
}

pub type StatusEvent {
  StatusEvent(type_: StatusEventType, timestamp: String)
}

pub type StatusEventType {
  Start
  Healthly
  Unhealthly
}

/// Create a request to fetch a list of all `Endpoint`s from a Gatus instance.
///
/// Send this request with a HTTP client such as `gleam_httpc` or `gleam_fetch`
/// and handle the result with the `handle_statuses_response` function.
///
pub fn statuses_request(host host: String, page page: Int) -> Request(String) {
  request.new()
  |> request.set_host(host)
  |> request.set_path("/api/v1/endpoints/statuses")
  |> request.set_query([#("page", int.to_string(page))])
}

/// Check and decode a response from the `/api/v1/endpoints/statuses` endpoint.
///
pub fn handle_statuses_response(
  response: Response(String),
) -> Result(List(Endpoint), Error) {
  use <- bool.guard(
    when: response.status != 200,
    return: Error(UnexpectedResonse(response.status, response.body)),
  )

  response.body
  |> json.parse(endpoints_decoder())
  |> result.map_error(UnexpectedPayload)
}

/// Create a request to fetch the status information from a specific `Endpoint`.
///
/// Send this request with a HTTP client such as `gleam_httpc` or `gleam_fetch`
/// and handle the result with the `handle_endpoint_response` function.
///
pub fn endpoint_request(
  host host: String,
  endpoint_key key: String,
  page page: Int,
) -> Request(String) {
  request.new()
  |> request.set_host(host)
  |> request.set_path("/api/v1/endpoints/" <> key <> "/statuses")
  |> request.set_query([#("page", int.to_string(page))])
}

/// Check and decode a response from the `/api/v1/endpoints/statuses` endpoint.
///
pub fn handle_endpoint_response(
  response: Response(String),
) -> Result(Endpoint, Error) {
  use <- bool.guard(
    when: response.status != 200,
    return: Error(UnexpectedResonse(response.status, response.body)),
  )

  response.body
  |> json.parse(endpoint_decoder())
  |> result.map_error(UnexpectedPayload)
}

/// Decode a list of `Endpoint`s.
///
pub fn endpoints_decoder() -> Decoder(List(Endpoint)) {
  decode.list(endpoint_decoder())
}

pub fn endpoint_decoder() -> Decoder(Endpoint) {
  use name <- decode.field("name", decode.string)
  use key <- decode.field("key", decode.string)
  use results <- decode.field("results", decode.list(decode_status_result()))
  use events <- decode.optional_field(
    "events",
    [],
    decode.list(status_events_decoder()),
  )
  decode.success(Endpoint(name:, key:, results:, events:))
}

fn decode_status_result() -> Decoder(StatusResult) {
  use status <- decode.field("status", decode.int)
  use hostname <- decode.field("hostname", decode.string)
  use duration <- decode.field("duration", decode.int)
  use condition_results <- decode.field(
    "conditionResults",
    decode.list(condition_results_decoder()),
  )
  use success <- decode.field("success", decode.bool)
  use timestamp <- decode.field("timestamp", decode.string)
  decode.success(StatusResult(
    status:,
    hostname:,
    duration:,
    condition_results:,
    success:,
    timestamp:,
  ))
}

fn condition_results_decoder() -> Decoder(ConditionResult) {
  use condition <- decode.field("condition", decode.string)
  use success <- decode.field("success", decode.bool)
  decode.success(ConditionResult(condition:, success:))
}

fn status_events_decoder() -> Decoder(StatusEvent) {
  use type_ <- decode.field("type", status_event_type_decoder())
  use timestamp <- decode.field("timestamp", decode.string)
  decode.success(StatusEvent(type_:, timestamp:))
}

fn status_event_type_decoder() -> Decoder(StatusEventType) {
  decode.string
  |> decode.then(fn(event) {
    case event {
      "START" -> decode.success(Start)
      "HEALTHY" -> decode.success(Healthly)
      "UNHEALTHY" -> decode.success(Unhealthly)
      _ -> decode.failure(Start, "StatusEventType")
    }
  })
}

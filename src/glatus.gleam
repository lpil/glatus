import gleam/dynamic.{type DecodeErrors, type Decoder, type Dynamic}
import gleam/option
import gleam/int
import gleam/bool
import gleam/json
import gleam/result
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}

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
pub fn statuses_request(host: String, page page: Int) -> Request(String) {
  request.new()
  |> request.set_host(host)
  |> request.set_path("/api/v1/endpoints/statuses")
  |> request.set_query([#("page", int.to_string(page))])
}

pub fn handle_statuses_response(
  response: Response(String),
) -> Result(List(Endpoint), Error) {
  use <- bool.guard(
    when: response.status != 200,
    return: Error(UnexpectedResonse(response.status, response.body)),
  )

  response.body
  |> json.decode(decode_endpoints)
  |> result.map_error(UnexpectedPayload)
}

/// Decode a list of `Endpoint`s from `Dynamic`.
///
pub fn decode_endpoints(data: Dynamic) -> Result(List(Endpoint), DecodeErrors) {
  dynamic.list(decode_endpoint)(data)
}

pub fn decode_endpoint(data: Dynamic) -> Result(Endpoint, DecodeErrors) {
  dynamic.decode4(
    Endpoint,
    dynamic.field("name", dynamic.string),
    dynamic.field("key", dynamic.string),
    dynamic.field("results", dynamic.list(decode_status_result)),
    optional_field_of_list("events", decode_status_event),
  )(data)
}

fn decode_status_result(data: Dynamic) -> Result(StatusResult, DecodeErrors) {
  dynamic.decode6(
    StatusResult,
    dynamic.field("status", dynamic.int),
    dynamic.field("hostname", dynamic.string),
    dynamic.field("duration", dynamic.int),
    dynamic.field("conditionResults", dynamic.list(decode_condition_result)),
    dynamic.field("success", dynamic.bool),
    dynamic.field("timestamp", dynamic.string),
  )(data)
}

fn decode_condition_result(
  data: Dynamic,
) -> Result(ConditionResult, DecodeErrors) {
  dynamic.decode2(
    ConditionResult,
    dynamic.field("condition", dynamic.string),
    dynamic.field("success", dynamic.bool),
  )(data)
}

fn decode_status_event(data: Dynamic) -> Result(StatusEvent, DecodeErrors) {
  dynamic.decode2(
    StatusEvent,
    dynamic.field("type", decode_status_event_type),
    dynamic.field("timestamp", dynamic.string),
  )(data)
}

fn decode_status_event_type(
  data: Dynamic,
) -> Result(StatusEventType, DecodeErrors) {
  use event <- result.try(dynamic.string(data))
  case event {
    "start" -> Ok(Start)
    "healthy" -> Ok(Healthly)
    "unhealthy" -> Ok(Unhealthly)
    _ ->
      Error([
        dynamic.DecodeError(
          expected: "Status event type",
          found: "String",
          path: [],
        ),
      ])
  }
}

fn optional_field_of_list(
  field: String,
  decoder: Decoder(a),
) -> Decoder(List(a)) {
  let field_decoder = dynamic.optional_field(field, dynamic.list(decoder))
  fn(data) {
    field_decoder(data)
    |> result.map(option.unwrap(_, []))
  }
}

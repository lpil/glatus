import gleam/dynamic.{type DecodeErrors, type Decoder, type Dynamic}
import gleam/option
import gleam/result

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

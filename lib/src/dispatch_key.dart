/// Key that enables dispatching of events and requests. Every [Event]
/// and [Request] is associated with a specific key, and that key must
/// be used in order to dispatch an item to that event stream.
///
/// One key can be used for multiple events.
class DispatchKey {
  String name;
  DispatchKey([this.name]);
}

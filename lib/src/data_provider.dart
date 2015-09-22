library w_module.src.data_provider;

abstract class DataProvider<ApiT, EventsT> {
  ApiT _api;
  ApiT get api => _api;

  EventsT _events;
  EventsT get events => _events;

  DataProvider(this._api, this._events);
}

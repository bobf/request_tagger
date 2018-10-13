# RequestTagger

Inject a request ID tag into all _ActiveRecord_ queries and HTTP requests made within your [_Rails_] application.

Any web service requests or database queries your application makes in a given request can be tied together by coalescing your log files in your favourite log aggregator, giving a full picture of every request on your system.

An incoming HTTP header is used as the ID for all subsequent requests.

SQL queries are prepended with a comment that will look something like this:

```sql
/* request-id: abc123 */ SELECT * FROM ...
```

HTTP requests will include an extra header:

```
X-Request-Id: abc123
```

The implementation has borrowed ideas from _RSpec's_ `allow_any_instance_of` and _webmock's_ `stub_request`. Their source code was used as an invaluable reference during development. Thanks to the developers of both libraries for their hard work.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'request_tagger'
```

And then rebuild your bundle:

```bash
$ bundle install
```

## Usage

The only things you need to do are create an initializer:

```ruby
# config/initializers/request_tagger.rb
RequestTagger.start
```

and include the `RequestTagger::TagRequests` module in your base controller:

```ruby
class ApplicationController < ActionController::Base
  include RequestTagger::TagRequests
end
```

You can pass the following options to `RequestTagger.start` (values shown are the defaults):

```ruby
RequestTagger.start(
  tag_sql: true, # Tag all ActiveRecord SQL queries
  tag_http: true, # Tag all HTTP requests
  http_tag_name: 'X-Request-Id', # Header to use for outbound requests
  sql_tag_name: 'request-id', # Identifier to use in SQL tags
  header: 'HTTP_X_REQUEST_ID' # Header to watch for inbound requests*
)
```

\* Note that an inbound HTTP header e.g. `X-Request-Id` will be transformed by Rack to `HTTP_X_REQUEST_ID` so take this into account when setting the `header` option.

An example usage would be the `$request_id` variable provided by _nginx_:

```
location / {
    proxy_set_header X-Request-Id $request_id;
}
```

### Setting a request ID manually

If you want to manually assign the request ID to be used in tags, just add overwrite the following method in your base controller:

```ruby
  private

  def __request_tagger__set_request_id__
    RequestTagger.request_id = 'my-custom-request-id'
  end
```

### Caveats

- Only web requests made by _Net::HTTP_ are intercepted. Most popular HTTP libraries use this at their core, including _Faraday_ and _HTTParty_ so this should cover the vast majority of cases but feel free to submit a pull request to add more drivers.
- Since _Net::HTTP_ and _ActiveRecord_ are monkeypatched in similar ways to how _RSpec_ and _webmock_ operate, you probably do not want to enable _RequestTagger_ in your test environment. Use `unless Rails.env.test?` in your initializer.

## Development

Clone the repository and submit a pull requests to fix any bugs or add any new features.

Write tests for any new code you write and ensure all tests pass before submitting:

```bash
$ bin/rspec
```

Please also run _Rubocop_ and fix any issues before making a pull request:

```bash
$ bin/rubocop
```

## License

_RequestTagger_ is licensed under the MIT license. Do whatever you like with the code, just give credit where it's due.

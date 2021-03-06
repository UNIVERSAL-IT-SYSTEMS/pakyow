# Calls an app route and returns a response, just like an HTTP request!
#
Pakyow::Realtime.handler :'call-route' do |message, session, response|
  env = Rack::MockRequest.env_for(message['uri'], method: message['method'])
  env['pakyow.socket'] = true
  env['pakyow.data'] = message['input']
  env['rack.session'] = session

  # TODO: in production we want to push the message to a queue and
  # let the next available app instance pick it up, rather than
  # the current instance to handle all traffic on this socket

  context = Pakyow::CallContext.new(env)
  context.process
  res = context.finish

  container = message['container']
  partial = message['partial']

  composer = context.presenter.composer

  if container
    body = composer.container(container.to_sym).includes(composer.partials).to_s
  elsif partial
    body = composer.partial(partial.to_sym).includes(composer.partials).to_s
  else
    body = res[2].body
  end

  response[:status]  = res[0]
  response[:headers] = res[1]
  response[:body]    = body.is_a?(StringIO) ? body.read : body
  response
end

SMSProvider = require('./SMSProvider')

module.exports = (Promise, logger, options) ->

  class TwilioSMSProvider extends SMSProvider
    constructor: (options) ->
      if typeof options is 'undefined'
        throw new Error 'Must pass options'

      if typeof options.accountSid is 'undefined' or typeof options.authToken is 'undefined'
        throw new Error 'Must set accountSid and authToken'

      if typeof options.fromNumber is 'undefined'
        throw new Error 'Must set fromNumber'

      # require the Twilio module and create a REST client
      @client = require("twilio")(options.accountSid, options.authToken);
      @client.messages.create = Promise.promisify(client.messages.create)

    sendSMSMessage: (toNumber, message) ->
      return client.messages.create({
            to: toNumber,
            from: options.fromNumber,
            body: message})


  provider = new TwilioSMSProvider(options)

  # Pass back the message method
  return provider

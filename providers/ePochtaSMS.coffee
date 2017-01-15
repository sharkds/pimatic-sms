SMSProvider = require('./SMSProvider')
debug = require('debug')('pimatic-sms')

module.exports = (Promise, options) ->

  class ePochtaSMSProvider extends SMSProvider
    constructor: (options) ->
      if typeof options is 'undefined'
        throw new Error 'Must pass options'

      if typeof options.login is 'undefined' or typeof options.password is 'undefined'
        throw new Error 'Must set login and password'

      if typeof options.fromNumber is 'undefined'
        throw new Error 'Must set fromNumber'

      @rp = require('request-promise')

    sendSMSMessage: (toNumber, message) ->
      numbers = '';

      toNumber.split(',').map (num) ->
        numbers += '<number>' + num.replace(/\s/g, '') + '</number>';
        return

      body = '<?xml version="1.0" encoding="UTF-8"?>
<SMS>
<operations>
<operation>SEND</operation>
</operations>
<authentification>
<username>' + options.login + '</username>
<password>' + options.password + '</password>
</authentification>
<message>
<sender>' + options.fromNumber + '</sender>
<text>' + message + '</text>       
</message>
<numbers>' + numbers + '</numbers>
</SMS>'

      rpoptions = {
          method: 'POST'
          uri: 'http://api.myatompark.com/members/sms/xml.php'
          body: body
      }

      return @rp(rpoptions).then( (response) =>
              debug('Successfully Sent SMS!')
          )

    destroy: () =>
      @rp = null

  provider = new ePochtaSMSProvider(options)

  # Pass back the message method
  return provider

# #TTS Plugin

# This is an plugin to read text to speech from the audio speaker

# ##The plugin code
module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  #util = env.require 'util'
  M = env.matcher

  # Load our extra libraries
  phone = require('node-phonenumber')
  phoneUtil = phone.PhoneNumberUtil.getInstance()

  # Load all available providers
  providers = {}
  for key, val of require('./providers')
    providers[key] = val

  # SMS Plugin
  class SMSPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, @config) =>

      # Setup a blank method
      @sendSMSMessage = () ->
        return new Promise(resolve,reject) ->
          reject('No Valid Provider Specified')

      # ADD SMS PROVIDER CONFIG HERE
      if @config.provider is "twilio" and providers.hasOwnProperty 'twilio'
        if (@config.twilioAccountSid? is "" or @config.twilioAuthToken is "")
          return env.logging.error "We need AccountSid and AuthToken when using provider 'twilio'"
        else
          @sendSMSMessage = providers['twilio'](Promise, {
            accountSid: @config.twilioAccountSid,
            authToken: @config.twilioAuthToken,
            fromNumber: @config.fromNumber
            })

      @framework.ruleManager.addActionProvider(new SMSActionProvider @framework, @)

  # Create a instance of my plugin
  plugin = new SMSPlugin

  class SMSActionProvider extends env.actions.ActionProvider

    constructor: (@framework, @plugin) ->
      return

    parseAction: (input, context) =>
      # Helper to convert 'some text' to [ '"some text"' ]
      strToTokens = (str) => ["\"#{str}\""]

      textTokens = strToTokens ""
      toNumberTokens = strToTokens @plugin.config.toNumber || ""

      setText = (m, tokens) => textTokens = tokens
      setToNumber = (m, tokens) => toNumberTokens = tokens

      m = M(input, context)
        .match(['send ','write ','compose '], optional: yes)
        .match(['sms ','text '])
        .match(['message '], optional: yes)
        .matchStringWithVars(setText)

      if @plugin.config.toNumber?
        next = m.match([' to number ',' to phone ']).matchStringWithVars(setToNumber)
        if next.hadMatch() then m = next
      else
        m.match([' to number ',' to phone ']).matchStringWithVars(setToNumber)

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(textTokens)
        assert Array.isArray(toNumberTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SMSActionHandler(
            @framework, textTokens, toNumberTokens, @plugin.sendSMSMessage, @plugin.config.numberFormatCountry
          )
        }

  plugin.SMSActionProvider = SMSActionProvider

  class SMSActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @textTokens, @toNumberTokens, @sendSMSMessage, @numberFormatCountry) ->
      return

    executeAction: (simulate, context) ->
      Promise.all( [
        @framework.variableManager.evaluateStringExpression(@textTokens)
        @framework.variableManager.evaluateStringExpression(@toNumberTokens)
      ]).then( ([text, toNumber]) =>
        return new Promise((resolve, reject) =>

          if toNumber is ""
            return reject(__("No To Phone Number Specified"))
          # if toNumber is ""
          #   return reject(__("No Text Specified to post! Ignoring"))

          formattedToNumber = phoneUtil.format(phoneUtil.parse(toNumber,@numberFormatCountry), phone.PhoneNumberFormat.E164);

          if simulate
            return resolve(__("Would send SMS #{message} to #{toNumber}"))
          else
            return @sendSMSMessage(formattedToNumber, text).then( (message) ->
              if (message.price is null)
                env.logger.debug "SMS sent to #{message.to} for free!"
                resolve __("SMS sent to #{message.to} for free!")
              else
                env.logger.debug "SMS sent to #{message.to} and cost #{message.price} #{message.price_unit}"
                resolve __("SMS sent to #{message.to} and cost #{message.price} #{message.price_unit}")
            , (rejection) ->
                reject rejection.message
            )
        )
      )

  plugin.SMSActionHandler = SMSActionHandler

  # and return it to the framework.
  return plugin

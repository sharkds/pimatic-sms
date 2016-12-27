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

  # SMS Plugin
  class SMSPlugin extends env.plugins.Plugin

    # ####init()
    init: (app, @framework, @config) =>

      # Load all available providers
      @providers = {}
      getClassOf = Function.prototype.call.bind(Object.prototype.toString);
      SMSProvider = require('./providers/SMSProvider')

      for key, provider of require('./providers')
        @providers[key] = provider

      if (@providers.length is 0 or @config.provider.length is 0) then throw new Error("No Providers Available!")

      # ADD SMS PROVIDER CONFIG HERE
      if @config.provider is "twilio" and @providers.hasOwnProperty 'twilio'
        if (@config.twilioAccountSid? is "" or @config.twilioAuthToken is "")
          return env.logger.error "We need AccountSid and AuthToken when using provider 'twilio'"
        else
          @provider = @providers['twilio'](Promise, {
            accountSid: @config.twilioAccountSid,
            authToken: @config.twilioAuthToken,
            fromNumber: @config.fromNumber
            })
      else if @config.provider is "threehk" and @providers.hasOwnProperty 'threehk'
        if (@config.threehkPassword is "")
          return env.logger.error "We need password when using provider 'threehk'"
        else
          mobileLoginNumber = phoneUtil.format(phoneUtil.parse(@config.fromNumber,'HK'), phone.PhoneNumberFormat.NATIONAL).replace(/ /,'').trim();
          @provider = @providers['threehk'](Promise, {
            mobileNumber: mobileLoginNumber,
            password: @config.threehkPassword,
            })
      else
        throw new Error("Invalid Provider Specified!")

      @framework.ruleManager.addActionProvider(new SMSActionProvider @framework, @)

    destroy: () =>
      for key, provider of @providers
        provider.destroy()
      super()

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
            @framework, textTokens, toNumberTokens, @plugin.provider, @plugin.config.numberFormatCountry
          )
        }

  plugin.SMSActionProvider = SMSActionProvider

  class SMSActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @textTokens, @toNumberTokens, @provider, @numberFormatCountry) ->
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
            return @provider.sendSMSMessage(formattedToNumber, text).then( (message) =>
                if (@provider.hasPriceInfo)
                    if (message.price is null)
                      env.logger.debug "SMS sent to #{toNumber} for free!"
                      resolve __("SMS sent to #{toNumber} for free!")
                    else
                      env.logger.debug "SMS sent to #{toNumber} and cost #{message.price} #{message.price_unit}"
                      resolve __("SMS sent to #{toNumber} and cost #{message.price} #{message.price_unit}")
                else
                    env.logger.debug "SMS sent to #{toNumber}"
                    resolve __("SMS sent to #{toNumber}")
            , (rejection) ->
              reject rejection.message
              )
        )
      )

  plugin.SMSActionHandler = SMSActionHandler

  # and return it to the framework.
  return plugin

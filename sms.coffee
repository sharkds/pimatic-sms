# #TTS Plugin

# This is an plugin to read text to speech from the audio speaker

# ##The plugin code
module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  #util = env.require 'util'
  M = env.matcher

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
      toNumberTokens = strToTokens ""

      setText = (m, tokens) => textTokens = tokens
      setToNumber = (m, tokens) => toNumberTokens = tokens

      m = M(input, context)
        .match(['send ','write ','compose '], optional: yes)
        .match(['sms ','text '])
        .match(['message '], optional: yes)
        .matchStringWithVars(setText)
        .match([' to number ',' to phone '])
        .matchStringWithVars(setToNumber)

      # next = m.match([' ignore',' no unfurl',' do not unfurl']).match([' links'])
      # if next.hadMatch()
      #   unfurlLinks = false
      #   m = next

      if m.hadMatch()
        match = m.getFullMatch()

        assert Array.isArray(textTokens)
        assert Array.isArray(toNumberTokens)

        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new SMSActionHandler(
            @framework, textTokens, toNumberTokens, @plugin.sendSMSMessage
          )
        }

  plugin.SMSActionProvider = SMSActionProvider

  class SMSActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @textTokens, @toNumberTokens, @sendSMSMessage) ->
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

          if simulate
            return resolve(__("Would Post to Slack '#{text}' to channel '#{channel}'"))
          else
            return @sendSMSMessage(toNumber, text).then( (message) ->
              if (message.price is null)
                resolve __("SMS sent to #{message.to} for free!")
              else
                resolve __("SMS sent to #{message.to} and cost #{message.price} #{message.price_unit}")
            )
        )
      )

  plugin.SMSActionHandler = SMSActionHandler

  # and return it to the framework.
  return plugin

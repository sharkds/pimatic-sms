module.exports = {
  title: "SMS Plugin Config Options"
  type: "object"
  required: ["provider","fromNumber"]
  properties:
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
    provider:
      description: "Which SMS Provider to use"
      type: "string"
      default: "twilio"
      enum: ["twilio"]
    twilioAccountSid:
      description: "Account Sid for Twilio"
      type: "string"
      default: ""
    twilioAuthToken:
      description: "Account Auth Token for Twilio"
      type: "string"
      default: ""
    fromNumber:
      description: "Number to send SMS from"
      type: "string"
      default: ""
    toNumber:
      description: "Default number to send SMS messages to"
      type: "string"
      default: ""
    numberFormatCountry:
      description: "Country code to format numbers in. This helps us to format numbers correctly incase country code is not passed. You can still override it without a country code, but allows you to write numbers with a default country code for convenience."
      type: "string"
      default: "US"
}

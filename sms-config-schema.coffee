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
    twilioSid:
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
}

# pimatic-sms

SMS Integration with [Pimatic](https://pimatic.org). Additional providers can easily be supported, for now it just supports [Twilio](https://www.twilio.com/).


## Plugin Configuration

You can load the backend by editing your `config.json` to include:

```json
{
   "plugin": "sms",
   "provider": "twilio",
   "fromNumber": "+112345689"
}
```

Depending on which provider you pick (Currently only twilio is supported), you will need to provide some additional properties. You can see all available properties by looking at [sms-config-schema](sms-config-schema.coffee).

If using twilio you will need to supply these additional properties:

```json
{
   "twilioSid": "YOUR_TWILLIO_ACCOUNT_SID",
   "twilioAuthToken": "YOUR_TWILLIO_AUTH_TOKEN"
}
```

## Example

It can be used like any normal Pimatic rule

- if it is 08:00 send sms message "Good morning!" to number "+1888123456"
- if X then send sms message "X Happened" to number "+1888123456"

## TODO

- Add [Plivo](https://www.plivo.com) SMS Provider.
- Add [Sinch](https://www.sinch.com) SMS Provider.
- Add [Nexmo](https://www.nexmo.com) SMS Provider.

## Contributing

Feel free to submit any pull requests or add functionality, I'm usually pretty responsive.

If you like the module, please consider donating some bitcoin or litecoin.

**Bitcoin**

![LNzdZksXcCF6qXbuiQpHPQ7LUeHuWa8dDW](http://i.imgur.com/9rsCfv5.png?1)

**LiteCoin**

![LNzdZksXcCF6qXbuiQpHPQ7LUeHuWa8dDW](http://i.imgur.com/yF1RoHp.png?1)

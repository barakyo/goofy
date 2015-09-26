Goofy
=====

A better gif Slack bot.

Goofy will listen to messages and query a Redis server for getting/setting/searching keys and their values.

Goofy has the following abilities:

* Can set keys to images
* Can retrieve images based upon a key
* Wildcard key searching

### Setting Up ###

Using the `config/config.exs.sample` to create a `config.exs` file with the following values:
  * `token` - The bot token provided by Slack
  * `hook_url` - The hook URL generated by slack for the incoming hook API.
  * `username` - name of the bot
  * `redis_host` - The redis host
  * `redis_port` - The redis port

### Usage ###

You can get the bots attention by mentioning it.

Examples:
  * `@goofy set kobe http://i.imgur.com/DjGh9.gif`
  * `@goofy kobe`
  * `@goofy search kobe`

### Running ###

You can run the bot with `mix run --no-halt`

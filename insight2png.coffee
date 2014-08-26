webpage = require("webpage")
system = require("system")

if system.args.length < 2 or system.args.length > 3
  console.log "Usage: insight2png URL filename"
  phantom.exit 1
else
  page = webpage.create()
  url = system.args[1]
  filename = system.args[2]
  page.viewportSize =
    width: 800
    height: 500

  # below required for typekit
  page.settings.userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17"
  page.customHeaders = Referer: url

  page.includeJs "https://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"

  page.open url, (status) ->
    if status isnt "success"
      console.log "Unable to open URL."
      phantom.exit 1
    else
      window.setTimeout (->
        renderPage page, filename
        phantom.exit 0
        return
      ), 200
    return


renderPage = (page, filename) ->
  offset = page.evaluate ->
    $('.insight').offset()

  crop = page.evaluate ->
    insight = document.querySelector('.insight')
    offset =
      height: insight.offsetHeight
      width: insight.offsetWidth

  page.clipRect =
    top: offset.top
    left: offset.left
    width: crop.width
    height: crop.height

  console.log 'rendering page'
  page.render(filename)

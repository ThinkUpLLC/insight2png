#!/usr/bin/env slimerjs

webpage = require("webpage")
system = require("system")
fs = require("fs")

module.exports = class Insight2png
  constructor: (@url, @filename, @response, @callbacks) ->

  run: ->
    getImage = =>
      try
        imgData = @renderPage @page, @filename
      catch error
        @response.error = error
      finally
        if imgData?
          return @callbacks.success(imgData, @response) if @callbacks.success?
          phantom.exit 0
        else
          error = @response.error or "No insight on page"
          return @callbacks.error(error, @response) if @callbacks.error?

    start = new Date()
    @page = webpage.create()
    @page.settings.userAgent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17'
    @page.customHeaders =
      Referer: @url


    # below for debugging
    # @page.onAlert = (text) ->
    #   console.log("Alert: " +text);

    @page.viewportSize =
      width: 800
      height: 800

    # this callback is only triggered
    # for insights with visualizations
    @page.onCallback = =>
      clearTimeout chartTimeout
      @response.log += "Visualization loaded\n"
      if @url.match /weekly_graph/
        setTimeout ->
          getImage()
        , 600
      else if @url.match /insight_tester.+&preview=1/
        setTimeout ->
          getImage()
        , 100
      else
        getImage()

    chartTimeout = null

    @page.onResourceError = (resourceError) =>
      @page.reason = resourceError.errorString
      @page.reason_url = resourceError.url
    @page.open @url, (status) =>
      if status isnt "success"
        @response.log += "Unable to open URL: #{@page.reason_url}\n#{@page.reason}\n"
        return @callbacks.error("Unable to open URL", @response) if @callbacks.error?
        phantom.exit 1
      else
        vis = @page.evaluate ->
          google.visualization
        if vis? or @url.match /insight_tester.+&preview=1/
          chartTimeout = setTimeout getImage, 6e3
        else
          getImage()


  renderPage: ->
    return null unless @page.evaluate ->
      $('.insight').length
    @page.evaluate ->
      # this is for smoothing over on xvfb; don't use if don't have to
      $('.user-name, .user-text').css('font-size', '14.25px')
      $('.panel-body-inner p').css('font-size', '14.25px')
      $('.panel-title').css('font-weight', 'bold')
      $('.panel-subtitle').css('font-weight', 'lighter')
        .css('font-size', '14.5px')
      $('body').css('font', 'helvetica')
      # $('.panel-body-inner').css('font-size', '16px')
      $('.insight-metadata').css('font-size', '12.5px')
      $('.tweet-action.tweet-action-permalink').css('font-size', '12.5px')
      $('.userpic-featured').css('z-index', 10)

      # provide plenty of room for crop w/lots of gray space
      $('.insight').css('margin-top': 500, 'margin-bottom': 500)

      # add brand to insight
      brand = "https://thinkup.thinkup.com/assets/img/thinkup-logo-white.png"
      if window.location.href.match(/square=1/)
        brandHeightGrowth = 20
        moreText = '<div style="position: absolute; bottom: 9px; left: 10px; color: white; font-family: tablet-gothic-semi-condensed, sans-serif;">thinkup.com</div>'
      else
        brandHeightGrowth = 0
        moreText = ""
      if $('.insight').height() - $('.panel-title').height() < 50
        $('.panel-title').height($('.panel-title').height() + 50)
      height = $('.panel.insight').outerHeight() - 45
      brandContainer = """
        <div style="position:absolute; top: #{height - brandHeightGrowth}px; height: #{40 + brandHeightGrowth}px;background: rgba(0, 0, 0, 0.1);width: 100%;left: 0;right: 0;">  <img class="insight-brand" style="height: 22px; position: absolute; top: 11px; left: 10px;" src="#{brand}">#{moreText}</div>
      """
      $('.panel-heading').append($(brandContainer))


    offset = @page.evaluate ->
      $('.insight').offset()

    crop = @getImageDimensions '.insight'

    if @instagramShare()
      if crop.width > crop.height
        buffer = crop.width - crop.height
        crop.height += buffer
        offset.top -= Math.round(buffer/2)
        if offset.top < 0
          @page.evaluate ->
            $('.insight').css('margin-top': buffer, 'margin-bottom': buffer)
          offset.top = 0
      else if crop.width < crop.height
        buffer = crop.height - crop.width
        crop.width += buffer
        offset.left -= Math.round(buffer/2)

    @page.clipRect =
      top: offset.top
      left: offset.left
      width: crop.width
      height: crop.height

    @response.log += 'Rendering page: '
    @response.log += @filename
    @page.render("screenshots/#{@filename}")
    @page.renderBase64('png')

  readFile: ->
    start = new Date()
    @page = webpage.create()
    @page.viewportSize =
      width: 1000
      height: 1000
    @url = "#{fs.workingDirectory}/screenshots/#{@filename}"
    @page.open @url, (status) =>
      if status isnt "success"
        return @callbacks.error("Unable to open URL", @response) if @callbacks.error?
        phantom.exit 1
      else
        try
          dimensions = @page.title.match(/(\d+)\s.\s(\d+)\spixels/)
          if dimensions?[1]? and dimensions[2]?
            size =
              width: dimensions[1]
              height: dimensions[2]
          else
            size = @getImageDimensions 'img'
          return @callbacks.error("No image found on page", @response) if @callbacks.error? and !size?
          # below works for phantom, not slimer
          # @page.clipRect =
          #   top: 0
          #   left: 0
          #   width: size.width
          #   height: size.height

          @page.viewportSize =
            width: size.width
            height: size.height

          imgData = @page.renderBase64('png')
        catch error
          @response.error = error
        finally
          if imgData?
            return @callbacks.success(imgData, @response) if @callbacks.success?
            phantom.exit 0
          else
            error = @response.error or "No image on page"
            return @callbacks.error(error, @response) if @callbacks.error?

  getImageDimensions: (selector) ->
    size = @page.evaluate (selector) ->
      insight = document.querySelector(selector)
      unless insight?
        return null
      offset =
        height: insight.offsetHeight
        width: insight.offsetWidth
    , selector

  logTime: (start) ->
    end = new Date()
    console.log("#{(end-start)/1000} seconds\n")

  instagramShare: ->
    @url.match(/square=1/)?
unless system.args[0].match /server\.js/
  if system.args.length < 2 or system.args.length > 3
    console.log "Usage: insight2png URL filename"
    phantom.exit 1
  else
    url = system.args[1]
    filename = system.args[2]
    new Insight2png(url, filename).run()


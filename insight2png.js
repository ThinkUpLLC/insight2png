// Generated by CoffeeScript 1.7.1
(function() {
  var Insight2png, filename, fs, system, url, webpage;

  webpage = require("webpage");

  system = require("system");

  fs = require("fs");

  module.exports = Insight2png = (function() {
    function Insight2png(url, filename, response) {
      this.url = url;
      this.filename = filename;
      this.response = response;
    }

    Insight2png.prototype.run = function(callbacks) {
      var chartTimeout, getImage, start;
      if (callbacks == null) {
        callbacks = {};
      }
      getImage = (function(_this) {
        return function() {
          var error, imgData;
          try {
            imgData = _this.renderPage(_this.page, _this.filename);
            if (callbacks.success != null) {
              return callbacks.success(imgData, _this.response);
            }
            return slimer.exit(0);
          } catch (_error) {
            error = _error;
            if (callbacks.error != null) {
              return callbacks.error(error, _this.response);
            }
          }
        };
      })(this);
      start = new Date();
      this.page = webpage.create();
      this.page.viewportSize = {
        width: 800,
        height: 500
      };
      this.page.onCallback = function() {
        clearTimeout(chartTimeout);
        this.response.log += "Visualization loaded\n";
        if (this.url.match(/weekly_graph$/)) {
          return setTimeout(function() {
            return getImage();
          }, 1500);
        } else {
          return getImage();
        }
      };
      chartTimeout = null;
      return this.page.open(this.url, (function(_this) {
        return function(status) {
          var vis;
          if (status !== "success") {
            _this.response.log += "Unable to open URL.\n";
            if (callbacks.error != null) {
              return callbacks.error("Unable to open URL", _this.response);
            }
            return slimer.exit(1);
          } else {
            vis = _this.page.evaluate(function() {
              return google.visualization;
            });
            if (vis != null) {
              return chartTimeout = setTimeout(getImage, 6e3);
            } else {
              return getImage();
            }
          }
        };
      })(this));
    };

    Insight2png.prototype.renderPage = function() {
      var crop, offset;
      if (!this.page.evaluate(function() {
        return $('.insight').length;
      })) {
        throw "No insight on page";
      }
      this.page.evaluate(function() {
        $('.user-name, .user-text').css('font-size', '14.25px');
        $('.panel-body-inner p').css('font-size', '14.25px');
        $('.panel-title').css('font-weight', 'bold');
        $('.panel-subtitle').css('font-weight', 'lighter').css('font-size', '14.5px');
        $('body').css('font', 'helvetica');
        $('.insight-metadata').css('font-size', '12.5px');
        return $('.tweet-action.tweet-action-permalink').css('font-size', '12.5px');
      });
      offset = this.page.evaluate(function() {
        return $('.insight').offset();
      });
      crop = this.getImageDimensions('.insight');
      this.page.clipRect = {
        top: offset.top,
        left: offset.left,
        width: crop.width,
        height: crop.height
      };
      this.response.log += 'Rendering page: ';
      this.response.log += this.filename;
      this.page.render("screenshots/" + this.filename);
      return this.page.renderBase64('png');
    };

    Insight2png.prototype.readFile = function(callbacks) {
      var start;
      if (callbacks == null) {
        callbacks = {};
      }
      start = new Date();
      this.page = webpage.create();
      this.url = "" + fs.workingDirectory + "/screenshots/" + this.filename;
      return this.page.open(this.url, (function(_this) {
        return function(status) {
          var error, imgData, size;
          if (status !== "success") {
            if (callbacks.error != null) {
              return callbacks.error("Unable to open URL", _this.response);
            }
            return slimer.exit(1);
          } else {
            try {
              size = _this.getImageDimensions('.decoded');
              if ((callbacks.error != null) && (size == null)) {
                return callbacks.error("No image found on page", _this.response);
              }
              _this.page.viewportSize = {
                width: size.width,
                height: size.height
              };
              imgData = _this.page.renderBase64('png');
              if (callbacks.success != null) {
                return callbacks.success(imgData, _this.response);
              }
              slimer.exit(0);
            } catch (_error) {
              error = _error;
              if (callbacks.error != null) {
                return callbacks.error(error, _this.response);
              }
            }
          }
        };
      })(this));
    };

    Insight2png.prototype.getImageDimensions = function(selector) {
      var size;
      return size = this.page.evaluate(function(selector) {
        var insight, offset;
        insight = document.querySelector(selector);
        if (insight == null) {
          throw "Insight not found on page";
        }
        return offset = {
          height: insight.offsetHeight,
          width: insight.offsetWidth
        };
      }, selector);
    };

    Insight2png.prototype.logTime = function(start) {
      var end;
      end = new Date();
      return console.log("" + ((end - start) / 1000) + " seconds\n");
    };

    return Insight2png;

  })();

  if (!system.args[0].match(/server\.coffee/)) {
    if (system.args.length < 2 || system.args.length > 3) {
      console.log("Usage: insight2png URL filename");
      slimer.exit(1);
    } else {
      url = system.args[1];
      filename = system.args[2];
      new Insight2png(url, filename).run();
    }
  }

}).call(this);

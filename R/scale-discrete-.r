#' Position scales for discrete data
#'
#' You can use continuous positions even with a discrete position scale -
#' this allows you (e.g.) to place labels between bars in a bar chart.
#' Continuous positions are numeric values starting at one for the first
#' level, and increasing by one for each level (i.e. the labels are placed
#' at integer positions).  This is what allows jittering to work.
#'
#' @inheritDotParams discrete_scale
#' @inheritParams discrete_scale
#' @rdname scale_discrete
#' @family position scales
#' @export
#' @examples
#' ggplot(diamonds, aes(cut)) + geom_bar()
#'
#' \donttest{
#' # The discrete position scale is added automatically whenever you
#' # have a discrete position.
#'
#' (d <- ggplot(subset(diamonds, carat > 1), aes(cut, clarity)) +
#'       geom_jitter())
#'
#' d + scale_x_discrete("Cut")
#' d + scale_x_discrete("Cut", labels = c("Fair" = "F","Good" = "G",
#'   "Very Good" = "VG","Perfect" = "P","Ideal" = "I"))
#'
#' # Use limits to adjust the which levels (and in what order)
#' # are displayed
#' d + scale_x_discrete(limits = c("Fair","Ideal"))
#'
#' # you can also use the short hand functions xlim and ylim
#' d + xlim("Fair","Ideal", "Good")
#' d + ylim("I1", "IF")
#'
#' # See ?reorder to reorder based on the values of another variable
#' ggplot(mpg, aes(manufacturer, cty)) + geom_point()
#' ggplot(mpg, aes(reorder(manufacturer, cty), cty)) + geom_point()
#' ggplot(mpg, aes(reorder(manufacturer, displ), cty)) + geom_point()
#'
#' # Use abbreviate as a formatter to reduce long names
#' ggplot(mpg, aes(reorder(manufacturer, displ), cty)) +
#'   geom_point() +
#'   scale_x_discrete(labels = abbreviate)
#' }
scale_x_discrete <- function(..., expand = waiver(), position = "bottom") {
  sc <- discrete_scale(c("x", "xmin", "xmax", "xend"), "position_d", identity, ...,
    expand = expand, guide = "none", position = position, super = ScaleDiscretePosition)

  sc$range_c <- continuous_range()
  sc
}
#' @rdname scale_discrete
#' @export
scale_y_discrete <- function(..., expand = waiver(), position = "left") {
  sc <- discrete_scale(c("y", "ymin", "ymax", "yend"), "position_d", identity, ...,
    expand = expand, guide = "none", position = position, super = ScaleDiscretePosition)

  sc$range_c <- continuous_range()
  sc
}

# The discrete position scale maintains two separate ranges - one for
# continuous data and one for discrete data.  This complicates training and
# mapping, but makes it possible to place objects at non-integer positions,
# as is necessary for jittering etc.

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
ScaleDiscretePosition <- ggproto("ScaleDiscretePosition", ScaleDiscrete,
  train = function(self, x) {
    if (is.discrete(x)) {
      self$range$train(x, drop = self$drop, na.rm = !self$na.translate)
    } else {
      self$range_c$train(x)
    }
  },

  get_limits = function(self) {
    if (self$is_empty()) return(c(0, 1))

    self$limits %||% self$range$range %||% integer()
  },

  is_empty = function(self) {
    is.null(self$range$range) && is.null(self$limits) && is.null(self$range_c$range)
  },

  reset = function(self) {
    # Can't reset discrete position scale because no way to recover values
    self$range_c$reset()
  },

  map = function(self, x, limits = self$get_limits()) {
    if (is.discrete(x)) {
      seq_along(limits)[match(as.character(x), limits)]
    } else {
      x
    }
  },

  rescale = function(self, x, limits = self$get_limits(), range = self$dimension(limits = limits)) {
    rescale(self$map(x, limits = limits), from = range)
  },

  dimension = function(self, expand = c(0, 0, 0, 0), limits = self$get_limits()) {
    c_range <- self$range_c$range
    d_range <- limits

    if (self$is_empty()) {
      c(0, 1)
    } else if (is.null(self$range$range)) { # only continuous
      expand_range4(c_range, expand)
    } else if (is.null(c_range)) { # only discrete
      expand_range4(c(1, length(d_range)), expand)
    } else { # both
      range(
        c_range,
        expand_range4(c(1, length(d_range)), expand)
      )
    }
  },

  clone = function(self) {
    new <- ggproto(NULL, self)
    new$range <- discrete_range()
    new$range_c <- continuous_range()
    new
  }
)

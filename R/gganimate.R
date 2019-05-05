

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Tag a character string as being for an asciicast file
#'
#' @param filename asciicast filename. Should end in ".cast"
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
asciicast_file <- function(filename) {
  stopifnot(length(filename) == 1)
  if (!grepl('.cast$', filename)) warning('filename should be a .cast', call. = FALSE)
  class(filename) <- 'asciicast'
  filename
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' @rdname play_asciicast
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print.asciicast <- play_asciicast


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' A 'renderer' to use with \code{gganimate::animate()}
#'
#' Warning: this only currently works with a hacked, custom version of gganimate.
#'
#' @param filename output file for the asciicast animation
#' @param ... further arguments passed to \code{asciicast::create_asciicast_flipbook()}
#'
#' @return Returns a function which takes 2 arguments: \code{frames} and \code{fps}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
asciicast_renderer <- function(filename = tempfile(fileext = '.cast'), ...) {

  function(frames, fps) {

    if (!all(grepl('.txt$', frames))) {
      stop('asciicast_renderer() only supports .txt files', call. = FALSE)
    }

    filename <- asciicast::create_asciicast_flipbook(txt_files = frames,
                                                     filename  = filename,
                                                     fps       = fps,
                                                     ...)
    invisible(asciicast_file(filename))
  }

}
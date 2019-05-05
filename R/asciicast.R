
`%||%` <- function (x, y) { if (is_null(x)) y else x }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Create a header for v2 asciicast
#'
#' @param width,height dimensions of terminal
#' @param title title of asciicast
#' @param env terminal environment
#' @param ... other arguments ignored
#'
#' @importFrom jsonlite toJSON
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
create_v2_header <- function(width = NULL, height = NULL, title = NULL, env = NULL, ...) {
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # 'asciicast' v2 header
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  header <- list(
    version = 2,
    width = width %||% 80,
    height = height %||% 24,
    timestamp = as.integer(Sys.time()),
    title = title %||% 'asciicastr',
    env = env %||% list(
      TERM  = "xterm-256color",
      SHELL = "/bin/sh"
    )
  )

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Convert to JSON txt and auto-unbox so single elements are not arrays
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  header_txt <- jsonlite::toJSON(header, auto_unbox = TRUE)

  header_txt
}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Create an asciinema flipbook from a list of txt files
#'
#' This function simply joins together a list of text files into a single asciicast file.
#' Each of the input files becomes a frame in a very crude "flipbook" animation.
#'
#' @param txt_files character vector of txt filenames
#' @param filename output filename for asciicast animation
#' @param fps target frames-per-second of the animation. default: 20
#' @param width,height width and height of terminal. default: NULL determine
#'        size as the maximum width and height of all the text files
#' @param verbose default: FALSE
#' @param ... other arguments passed to \code{create_v2_header}
#'
#' @import purrr
#' @importFrom jsonlite toJSON
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
create_asciicast_flipbook <- function(txt_files, filename = "out.cast", fps = 20,
                                      width = NULL, height = NULL, verbose = FALSE, ...) {


  stopifnot(length(txt_files) > 0)
  for (txt_file in txt_files) {
    if (!file.exists(txt_file)) {
      stop("create_asciicast_flipbook: File does not exist: ", txt_file, call. = FALSE)
    }
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Read all the files
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  txt <- txt_files %>%
    map(readLines)


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Determine the maximum size
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  rows <- txt %>% map_int(length) %>% max()
  cols <- txt %>% map_int(~max(nchar(.x))) %>% max()

  if (verbose) {
    message("asciicast: Max size across ", length(txt_files), " files is ", cols, "x", rows)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Collapse all the lines in a file together
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  txt <- txt %>%
    map(~paste(.x, collapse = "\r\n"))



  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Add a "clear screen" command at the start of each frame
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  txt <- txt %>% purrr::map(~paste0("\u001b[H\u001b[J", .x))


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Work out a timestamp for each frame to match FPS
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  timestamps <- (seq_along(txt) - 1L) / fps


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Convert each file to JSON
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  all_out <- map2(timestamps, txt, ~list(.x, "o", .y)) %>%
    map(~jsonlite::toJSON(.x, auto_unbox = TRUE)) %>%
    flatten_chr()


  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Create the header txt - first line of asciicast file
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  header_txt <- create_v2_header(width = cols, height = rows, ...)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Write out
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  writeLines(c(header_txt, all_out), filename)

  invisible(asciicast_file(filename))
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#' Play an asciicast file
#'
#' This function creates an HTML document (which includes the javascript and
#' CSS for the player).   It then asks Rstudio to show this HTML in the viewer, or
#' if that is not available, to open it in a browser.
#'
#' See \url{https://github.com/asciinema/asciinema-player} for information on the player.
#'
#' @param x asciicast filename
#' @param autoplay default: FALSE
#' @param loop default: FALSE
#' @param theme terminal colour theme. default: black-on-white
#' @param verbose default: FALSE
#' @param ... further arguments passed to of from other methods.
#'
#' @importFrom glue glue
#' @importFrom utils browseURL
#'
#' @export
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
play_asciicast <- function(x,
                            autoplay = FALSE,
                            loop     = TRUE,
                            theme    = c('black-on-wite', 'asciinema', 'tango',
                                         'solarized-dark', 'solarized-light', 'monokai'),
                            verbose  = FALSE,
                            ...) {

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Custom theme 'black-on-white' is the default, but user can choose
  # one of the asciinema default themes if they'd like
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  theme = match.arg(theme)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Pick a place to put everything
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  tempDir <- tempfile()
  dir.create(tempDir, showWarnings = FALSE, recursive = TRUE)
  htmlFile <- file.path(tempDir, "index.html")

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Names of JS and CSS files which come with the package
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  jsfile  <- system.file("player/asciinema-player.js"     , package = 'asciicast')
  cssfile <- system.file("player/asciinema-player.css"    , package = 'asciicast')
  bwfile  <- system.file("player/black-on-white-theme.css", package = 'asciicast')

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Copy over all necessary files to the index.html directory i.e.
  #  - .cast file
  #  - JS and CSS file for player
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  file.copy(x      , tempDir)
  file.copy(jsfile , tempDir)
  file.copy(cssfile, tempDir)
  file.copy(bwfile , tempDir)

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # When 'autoplay' and 'loop' are set to *anything* in the player, then
  # they are considered ON
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  autoplay <- if (autoplay) "autoplay = 'true'" else ''
  loop     <- if (loop)     "loop     = 'true'" else ''

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # The template HTML file to play an asciicast file
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  sink(htmlFile)
  cat(glue::glue('<html>
      <head>
              <link rel="stylesheet" type="text/css" href="{basename(cssfile)}" />
              <link rel="stylesheet" type="text/css" href="{basename(bwfile )}" />
      </head>
      <body>
              <asciinema-player
              src      = "{basename(as.character(x))}"
              theme    = "{theme}"
              {autoplay}
              {loop} >
              </asciinema-player>
                  <script src="{basename(jsfile)}"></script>
      </body>
  </html>'))
  sink()

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Debugging
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  if (verbose) {
    message("print.asciicast: .cast file: ", as.character(x))
    message("print.asciicast: .html file: ", htmlFile)
  }

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  # Show in Rstudio viewer if possible, otherwise open a browser window
  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    viewer(htmlFile)
  } else {
    utils::browseURL(htmlFile)
  }
}


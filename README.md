
<!-- README.md is generated from README.Rmd. Please edit that file -->

# asciicast

<!-- badges: start -->

![](https://img.shields.io/badge/cool-useless-green.svg)
![](https://img.shields.io/badge/Status-alpha-orange.svg)
<!-- badges: end -->

`asciicast` contains some limited tools for dealing with the
[`asciicast` file
format](https://github.com/asciinema/asciinema/blob/master/doc/asciicast-v2.md)
as defined by [asciinema](https://asciinema.org).

Its only real capability is to combine multiple text documents into a
flipbook (one-file-per-frame), and play the resulting asciicast file in
Rstudio or a browser.

## What’s in the box

  - `create_asciicast_flipbook()` to create an asciicast file from a
    list of text files, with each text file being 1 frame of the
    animation.
  - `play_asciicast()` to play an asciicast file in Rstudio or the
    browser.

## Limitations

  - Currently asciicasts can’t be played in an Rmarkdown document or on
    github - but they play fine in the Rstudio viewer using
    `asciicast::play_asciicast()`
  - Only flipbook animation supported.

## Installation

You can install the from
[GitHub](https://github.com/coolbutuseless/asciicast) with:

``` r
# install.packages("remotes")
remotes::install_github("coolbutuseless/asciicast")
```

## Create some text files

``` r
tdir <- tempdir()

line_letters <- c(letters)

for (file_num in 1:26) {
  cline <- paste(line_letters, collapse = '')
  filename <- sprintf("%s/frame-%03i.txt", tdir, file_num)
  writeLines(rep(cline, 10), con = filename)
  line_letters <- c(line_letters[-1], line_letters[1])
}
```

Example file:

    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi
    #> jklmnopqrstuvwxyzabcdefghi

## Combine text files into an asciicast animation file

``` r
txt_files <- list.files(tdir, pattern = "frame.*txt", full.names = TRUE) 

cast <- asciicast::create_asciicast_flipbook(txt_files, filename = file.path(tdir, 'out.cast'), fps = 15)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# This currently won't play in Rmarkdown or in github, but it will 
# play in the viewer in Rstudio.  
# For this document, I have uploaded the ".cast" file to asciinema.com and 
# linked to there.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
asciicast::play_asciicast(cast)
```

<a href="https://asciinema.org/a/244438?autoplay=1&loop=1&theme=solarized-light">
<img src="https://asciinema.org/a/244438.png" width="836"/></a>

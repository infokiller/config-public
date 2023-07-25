#!/usr/bin/env bash

# NOTE(infokiller): upstream version was last reviewed on 2020-05-06.

set -o noclobber -o noglob -o nounset -o pipefail
IFS=$'\n'

# If the option `use_preview_script` is set to `true`,
# then this script will be called and its output will be displayed in ranger.
# ANSI color codes are supported.
# STDIN is disabled, so interactive scripts won't work properly

# This script is considered a configuration file and must be updated manually.
# It will be left untouched if you upgrade ranger.

# Because of some automated testing we do on the script #'s for comments need
# to be doubled up. Code that is commented out, because it's an alternative for
# example, gets only one #.

# Meanings of exit codes:
# code | meaning    | action of ranger
# -----+------------+-------------------------------------------
# 0    | success    | Display stdout as preview
# 1    | no preview | Display no preview at all
# 2    | plain text | Display the plain content of the file
# 3    | fix width  | Don't reload when width changes
# 4    | fix height | Don't reload when height changes
# 5    | fix both   | Don't ever reload
# 6    | image      | Display the image `$IMAGE_CACHE_PATH` points to as an image preview
# 7    | image      | Display the file directly as an image

# Script arguments
FILE_PATH="${1}" # Full path of the highlighted file
PV_WIDTH="${2}"  # Width of the preview pane (number of fitting characters)
# shellcheck disable=SC2034 # PV_HEIGHT is provided for convenience and unused
PV_HEIGHT="${3}"        # Height of the preview pane (number of fitting characters)
IMAGE_CACHE_PATH="${4}" # Full path that should be used to cache image preview
PV_IMAGE_ENABLED="${5}" # 'True' if image previews are enabled, 'False' otherwise.

FILE_EXTENSION="${FILE_PATH##*.}"
FILE_EXTENSION_LOWER="$(printf "%s" "${FILE_EXTENSION}" | tr '[:upper:]' '[:lower:]')"

# Settings
HIGHLIGHT_SIZE_MAX=$((2 * 1024 * 1024)) # 2MiB
# Maximum height for rendering non-image previews. The higher this number, the
# slower previews will take to render.
# By default, render up to 10 times the number of visible lines in the terminal
# in case the user wants to scroll the review pane. Terminals rarely have more
# than 100 visible lines, so this should be reasonable in terms of performance.
MAX_RENDERED_HEIGHT=${MAX_RENDERED_HEIGHT:-$((10 * PV_HEIGHT))}
HIGHLIGHT_OPTIONS="${HIGHLIGHT_OPTIONS:-}"
PYGMENTIZE_STYLE=${PYGMENTIZE_STYLE:-solarized-dark}
OPENSCAD_IMGSIZE=${RNGR_OPENSCAD_IMGSIZE:-1000,1000}
OPENSCAD_COLORSCHEME=${RNGR_OPENSCAD_COLORSCHEME:-Tomorrow Night}
FONT_PREVIEW_TEXT='  ABCDEFGHIJKLMNOPQRSTUVWXYZ
  abcdefghijklmnopqrstuvwxyz
  0123456789.:,;(*!?)"
  The quick brown fox jumps over the lazy dog.
'

# As of 2018-06-13 it seems truecolor previews are not supported in ranger.
# Therefore, we only enable it when scope is used outside ranger and the
# terminal seems to support truecolor. See:
# https://github.com/ranger/ranger/issues/989
_has_truecolor() {
  # Running ps is very slow in my tests, so I'm using an environment variable
  # instead.
  # [[ "$(ps -o comm --no-heading -p "${PPID}")" == ranger ]]
  [[ -n "${SCOPE_TRUECOLOR:-}" ]] && [[ ${COLORTERM:-} =~ (truecolor|24bit) ]]
}

# Runs a command and trims it's output to the first MAX_RENDERED_HEIGHT lines.
# head can't be used directly because some commands will return errors when
# their stdout is closed unexpectedly.
# Using this function can improve performance over passing the full output,
# because for some reason ranger can be very slow in trimming large output.
_trim_output() {
  "$@" | {
    head -"${MAX_RENDERED_HEIGHT}"
    cat > /dev/null
  }
}

_handle_text() {
  if [[ "$(stat --printf='%s' -- "${FILE_PATH}")" -gt "${HIGHLIGHT_SIZE_MAX}" ]]; then
    # The sed command reduces the excessive leading spaces from cat
    { cat -n -- "${FILE_PATH}" | sed -E 's/^ *//'; } && exit 5
  fi
  local highlight_format pygmentize_format
  if _has_truecolor; then
    highlight_format='truecolor'
  elif [[ "$(tput colors)" -ge 256 ]]; then
    pygmentize_format='terminal256'
    highlight_format='xterm256'
  else
    pygmentize_format='terminal'
    highlight_format='ansi'
  fi
  # NOTE: on success we return 3 from highlight so that terminal window resizing
  # will re-trigger the preview.
  env HIGHLIGHT_OPTIONS="${HIGHLIGHT_OPTIONS}" highlight \
    --out-format="${highlight_format}" \
    --line-range=1-"${MAX_RENDERED_HEIGHT}" \
    --force -- "${FILE_PATH}" && exit 3
  env COLORTERM=8bit bat --color=always --style="plain" \
    --line-range=:"${MAX_RENDERED_HEIGHT}" \
    -- "${FILE_PATH}" && exit 5
  pygmentize -f "${pygmentize_format}" -O "style=${PYGMENTIZE_STYLE}" \
    -- "${FILE_PATH}" && exit 5
}

handle_extension() {
  case "${FILE_EXTENSION_LOWER}" in
    # Archive
    a | ace | alz | arc | arj | bz | bz2 | cab | cpio | deb | gz | jar | lha | lz | lzh | lzma | lzo | \
      rpm | rz | t7z | tar | tbz | tbz2 | tgz | tlz | txz | tZ | tzo | war | xpi | xz | Z | zip)
      _trim_output atool --list -- "${FILE_PATH}" && exit 5
      _trim_output bsdtar --list --file "${FILE_PATH}" && exit 5
      exit 1
      ;;
    rar)
      # Avoid password prompt by providing empty password
      _trim_output unrar lt -p- -- "${FILE_PATH}" && exit 5
      exit 1
      ;;
    7z)
      # Avoid password prompt by providing empty password
      _trim_output 7z l -p -- "${FILE_PATH}" && exit 5
      exit 1
      ;;

      # PDF
    pdf)
      # Preview as text conversion
      pdftotext -l 10 -nopgbrk -q -- "${FILE_PATH}" - |
        fmt -w "${PV_WIDTH}" && exit 5
      mutool draw -F txt -i -- "${FILE_PATH}" 1-10 |
        fmt -w "${PV_WIDTH}" && exit 5
      exiftool "${FILE_PATH}" && exit 5
      exit 1
      ;;

      # BitTorrent
    torrent)
      transmission-show -- "${FILE_PATH}" && exit 5
      exit 1
      ;;

      # OpenDocument
    odt | ods | odp | sxw)
      # Preview as text conversion
      odt2txt "${FILE_PATH}" && exit 5
      # Preview as markdown conversion
      pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
      exit 1
      ;;

      # XLSX
    xlsx)
      # Preview as csv conversion
      # Uses: https://github.com/dilshod/xlsx2csv
      xlsx2csv -- "${FILE_PATH}" && exit 5
      exit 1
      ;;

      # HTML
    htm | html | xhtml)
      # Preview as text conversion
      w3m -dump "${FILE_PATH}" && exit 5
      lynx -dump -- "${FILE_PATH}" && exit 5
      elinks -dump "${FILE_PATH}" && exit 5
      pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
      ;;

      # JSON
    json)
      _handle_text
      jq --color-output . "${FILE_PATH}" && exit 5
      python -m json.tool -- "${FILE_PATH}" && exit 5
      ;;

      # Direct Stream Digital/Transfer (DSDIFF) and wavpack aren't detected
      # by file(1).
    dff | dsf | wv | wvc)
      mediainfo "${FILE_PATH}" && exit 5
      exiftool "${FILE_PATH}" && exit 5
      ;; # Continue with next handler on failure
  esac
}

handle_image() {
  # Size of the preview if there are multiple options or it has to be
  # rendered from vector graphics. If the conversion program allows
  # specifying only one dimension while keeping the aspect ratio, the width
  # will be used.
  local DEFAULT_SIZE="1920x1080"

  local mimetype="${1}"
  case "${mimetype}" in
    # SVG
    # image/svg+xml|image/svg)
    #     convert -- "${FILE_PATH}" "${IMAGE_CACHE_PATH}" && exit 6
    #     exit 1;;

    # DjVu
    # image/vnd.djvu)
    #     ddjvu -format=tiff -quality=90 -page=1 -size="${DEFAULT_SIZE}" \
    #           - "${IMAGE_CACHE_PATH}" < "${FILE_PATH}" \
    #           && exit 6 || exit 1;;

    # Image
    image/*)
      local orientation
      # If orientation data is present and the image actually
      # needs rotating ("1" means no rotation)...
      if orientation="$(identify -format '%[EXIF:Orientation]\n' -- "${FILE_PATH}" 2> /dev/null)" &&
        [[ -n "${orientation}" && "${orientation}" != 1 ]]; then
        # ...auto-rotate the image according to the EXIF data.
        convert -- "${FILE_PATH}" -auto-orient "${IMAGE_CACHE_PATH}" && exit 6
      fi

      # `w3mimgdisplay` will be called for all images (unless overridden
      # as above), but might fail for unsupported types.
      exit 7
      ;;

      # Video
    video/*)
      # Thumbnail
      ffmpegthumbnailer -i "${FILE_PATH}" -o "${IMAGE_CACHE_PATH}" -s 0 && exit 6
      exit 1
      ;;

      # PDF
    application/pdf)
      pdftoppm -f 1 -l 1 \
        -scale-to-x "${DEFAULT_SIZE%x*}" \
        -scale-to-y -1 \
        -singlefile \
        -jpeg -tiffcompression jpeg \
        -- "${FILE_PATH}" "${IMAGE_CACHE_PATH%.*}" &&
        exit 6 || exit 1
      ;;

      # ePub, MOBI, FB2 (using Calibre)
    application/epub+zip | application/x-mobipocket-ebook | \
      application/x-fictionbook+xml)
      # ePub (using https://github.com/marianosimone/epub-thumbnailer)
      epub-thumbnailer "${FILE_PATH}" "${IMAGE_CACHE_PATH}" \
        "${DEFAULT_SIZE%x*}" && exit 6
      ebook-meta --get-cover="${IMAGE_CACHE_PATH}" -- "${FILE_PATH}" \
        > /dev/null && exit 6
      exit 1
      ;;

    # Font
    application/font* | application/*opentype | font/sfnt)
      if convert -size 600x400 xc:'#ffffff' \
        -gravity center \
        -pointsize 20 \
        -font "${FILE_PATH}" \
        -fill '#000000' \
        -annotate +0+0 "${FONT_PREVIEW_TEXT}" \
        -flatten "${IMAGE_CACHE_PATH}"; then
        exit 6
      fi
      preview_png="/tmp/$(basename "${IMAGE_CACHE_PATH%.*}").png"
      if fontimage -o "${preview_png}" \
        --pixelsize "120" \
        --fontname \
        --pixelsize "80" \
        --text "  ABCDEFGHIJKLMNOPQRSTUVWXYZ  " \
        --text "  abcdefghijklmnopqrstuvwxyz  " \
        --text "  0123456789.:,;(*!?') ff fl fi ffi ffl  " \
        --text "  The quick brown fox jumps over the lazy dog.  " \
        "${FILE_PATH}"; then
        convert -- "${preview_png}" "${IMAGE_CACHE_PATH}" &&
          rm -- "${preview_png}" &&
          exit 6
      else
        exit 1
      fi
      ;;

      # Preview archives using the first image inside.
      # (Very useful for comic book collections for example.)
      # application/zip|application/x-rar|application/x-7z-compressed|\
      #     application/x-xz|application/x-bzip2|application/x-gzip|application/x-tar)
      #     local fn=""; local fe=""
      #     local zip=""; local rar=""; local tar=""; local bsd=""
      #     case "${mimetype}" in
      #         application/zip) zip=1 ;;
      #         application/x-rar) rar=1 ;;
      #         application/x-7z-compressed) ;;
      #         *) tar=1 ;;
      #     esac
      #     { [ "$tar" ] && fn=$(tar --list --file "${FILE_PATH}"); } || \
      #     { fn=$(bsdtar --list --file "${FILE_PATH}") && bsd=1 && tar=""; } || \
      #     { [ "$rar" ] && fn=$(unrar lb -p- -- "${FILE_PATH}"); } || \
      #     { [ "$zip" ] && fn=$(zipinfo -1 -- "${FILE_PATH}"); } || return
      #
      #     fn=$(echo "$fn" | python -c "import sys; import mimetypes as m; \
      #             [ print(l, end='') for l in sys.stdin if \
      #               (m.guess_type(l[:-1])[0] or '').startswith('image/') ]" |\
      #         sort -V | head -n 1)
      #     [ "$fn" = "" ] && return
      #     [ "$bsd" ] && fn=$(printf '%b' "$fn")
      #
      #     [ "$tar" ] && tar --extract --to-stdout \
      #         --file "${FILE_PATH}" -- "$fn" > "${IMAGE_CACHE_PATH}" && exit 6
      #     fe=$(echo -n "$fn" | sed 's/[][*?\]/\\\0/g')
      #     [ "$bsd" ] && bsdtar --extract --to-stdout \
      #         --file "${FILE_PATH}" -- "$fe" > "${IMAGE_CACHE_PATH}" && exit 6
      #     [ "$bsd" ] || [ "$tar" ] && rm -- "${IMAGE_CACHE_PATH}"
      #     [ "$rar" ] && unrar p -p- -inul -- "${FILE_PATH}" "$fn" > \
      #         "${IMAGE_CACHE_PATH}" && exit 6
      #     [ "$zip" ] && unzip -pP "" -- "${FILE_PATH}" "$fe" > \
      #         "${IMAGE_CACHE_PATH}" && exit 6
      #     [ "$rar" ] || [ "$zip" ] && rm -- "${IMAGE_CACHE_PATH}"
      #     ;;
  esac
  # esac

  openscad_image() {
    TMPPNG="$(mktemp -t XXXXXX.png)"
    openscad --colorscheme="${OPENSCAD_COLORSCHEME}" \
      --imgsize="${OPENSCAD_IMGSIZE/x/,}" \
      -o "${TMPPNG}" "${1}"
    mv "${TMPPNG}" "${IMAGE_CACHE_PATH}"
  }

  case "${FILE_EXTENSION_LOWER}" in
    ## 3D models
    ## OpenSCAD only supports png image output, and ${IMAGE_CACHE_PATH}
    ## is hardcoded as jpeg. So we make a tempfile.png and just
    ## move/rename it to jpg. This works because image libraries are
    ## smart enough to handle it.
    csg | scad)
      openscad_image "${FILE_PATH}" && exit 6
      ;;
    3mf | amf | dxf | off | stl)
      openscad_image <(echo "import(\"${FILE_PATH}\");") && exit 6
      ;;
  esac
}

handle_mime() {
  local mimetype="${1}"
  case "${mimetype}" in
    # RTF and DOC
    text/rtf | *msword)
      # Preview as text conversion
      # note: catdoc does not always work for .doc files
      # catdoc: http://www.wagner.pp.ru/~vitus/software/catdoc/
      catdoc -- "${FILE_PATH}" && exit 5
      exit 1
      ;;

    # DOCX, ePub, FB2 (using markdown)
    # You might want to remove "|epub" and/or "|fb2" below if you have
    # uncommented other methods to preview those formats
    *wordprocessingml.document | */epub+zip | */x-fictionbook+xml)
      # Preview as markdown conversion
      pandoc -s -t markdown -- "${FILE_PATH}" && exit 5
      exit 1
      ;;

    # XLS
    *ms-excel)
      # Preview as csv conversion
      # xls2csv comes with catdoc:
      #   http://www.wagner.pp.ru/~vitus/software/catdoc/
      xls2csv -- "${FILE_PATH}" && exit 5
      exit 1
      ;;

    # Text
    text/* | */xml)
      _handle_text
      exit 2
      ;;

      # Image
    image/*)
      # Preview as text conversion
      # img2txt --gamma=0.6 --width="${PV_WIDTH}" -- "${FILE_PATH}" && exit 4
      exiftool "${FILE_PATH}" && exit 5
      exit 1
      ;;

      # Video and audio
    video/* | audio/*)
      mediainfo "${FILE_PATH}" && exit 5
      exiftool "${FILE_PATH}" && exit 5
      exit 1
      ;;
  esac
}

handle_fallback() {
  printf '%s\n' '----- File Type Classification -----' && file --dereference --brief -- "${FILE_PATH}" && exit 5
  exit 1
}

get_mime_type() {
  # NOTE: As of 2018-06-13 I've encountered many SVG files which are
  # not detected correctly by xdg-mime (detected as xml instead of svg).
  # Example command:
  # xdg-mime query filetype /usr/share/icons/Adwaita/scalable/actions/contact-new-symbolic.svg
  # This is a workaround to always process files with an svg extension as an
  # image.
  if [[ ${FILE_EXTENSION_LOWER} == svg ]]; then
    'image/svg+xml'
  else
    file --dereference --brief --mime-type -- "${FILE_PATH}"
  fi
}

MIMETYPE="$(get_mime_type)"

# procfs needs to be displayed using cat.
if [[ $(realpath "${FILE_PATH}")/ =~ /proc/* ]]; then
  cat -v -- "${FILE_PATH}" && exit 0
fi
if [[ "${PV_IMAGE_ENABLED}" == 'True' ]]; then
  handle_image "${MIMETYPE}"
fi
handle_extension
handle_mime "${MIMETYPE}"
handle_fallback

# shellcheck disable=SC2317
exit 1

zpm-theme () {
    # Bundle spec arguments' default values.
    local url="$ZPM_DEFAULT_REPO_URL"
    local loc=/
    local branch=
    local no_local_clone=false
    local btype=plugin

    # Parse the given arguments. (Will overwrite the above values).
    eval "$(-zpm-parse-args \
            'url?, loc? ; branch:?, no-local-clone?, btype:?' \
            "$@")"

    # Add the theme extension to `loc`, if this is a theme.
    if [[ $loc != *.zsh-theme ]]; then
        loc="$loc.zsh-theme"
    fi

    zpm-load $url $loc --branch=$branch --btype=theme
}

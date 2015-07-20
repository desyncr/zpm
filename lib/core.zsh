# Load a package
-zpm-load-package () {
    -zpm-package-source "$@" | while read line; do
        if [[ -f "$line" ]]; then
            source "$line"
        elif [[ -d "$line" ]]; then
            fpath=($line $fpath)
        fi
    done
}

# Enables a package (PATH it)
-zpm-enable-package () {
    local url="$1"
    local loc="$2"
    local make_local_clone="$3"

    # The full location where the plugin is located.
    local location

    # Resolve the url.
    location="$(-zpm-get-clone-dir "$url")/"
    [[ $loc != "/" ]] && location="$location$loc"
    export PATH="$PATH:$location"
}

# Install a given package
-zpm-install-package () {
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

    [[ "$url" == "" ]] && return;

    # Check if url is just the plugin name. Super short syntax.
    if [[ "$url" != */* ]]; then
        loc="plugins/$url"
        url="$ZPM_DEFAULT_REPO_URL"
    fi

    # Resolve the url.
    url="$(-zpm-resolve-package-url "$url")"

    # Add the branch information to the url.
    if [[ ! -z $branch ]]; then
        url="$url#$branch"
    fi

    # The `make_local_clone` variable better represents whether there should be
    # a local clone made. For cloning to be avoided, firstly, the `$url` should
    # be an absolute local path and `$branch` should be empty. In addition to
    # these two conditions, either the `--no-local-clone` option should be
    # given, or `$url` should not a git repo.
    local make_local_clone=true
    if [[ $url == /* && -z $branch &&
            ( $no_local_clone == true || ! -d $url/.git ) ]]; then
        make_local_clone=false
    fi

    # Add the theme extension to `loc`, if this is a theme.
    if [[ $btype == theme && $loc != *.zsh-theme ]]; then
        loc="$loc.zsh-theme"
    fi

    # Ensure a clone exists for this repo, if needed.
    if $make_local_clone; then
        -zpm-clone-repo "$url" &> /dev/null
    fi
}

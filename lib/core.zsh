# Load a package
-zpm-load-package () {
    local url="$1"
    local loc="$2"
    local make_local_clone="$3"

    # The full location where the plugin is located.
    local location
    if $make_local_clone; then
        location="$(-zpm-get-clone-dir "$url")/"
    else
        location="$url/"
    fi

    [[ $loc != "/" ]] && location="$location$loc"

    if [[ -f "$location" ]]; then
        source "$location"

    elif [[ -d "$location" ]]; then

        # Source the plugin script.
        # FIXME: I don't know. Looks very very ugly. Needs a better
        # implementation once tests are ready.
        local script_loc="$(ls "$location" | grep '\.plugin\.zsh$' | head -n1)"

        if [[ -f $location/$script_loc ]]; then
            # If we have a `*.plugin.zsh`, source it.
            source "$location/$script_loc"

        elif ls "$location" | grep -l '\..*sh$' &> /dev/null; then
            # If there is no `*.plugin.zsh` file, source *all* the `*.zsh`
            # files.
            for script ($location/*.*sh(N)) { source "$script" }
        fi

        # Add to $fpath, for completion(s).
        fpath=($location $fpath)

    fi
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
        -zpm-clone-repo "$url"
    fi
}

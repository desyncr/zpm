export _ZPM_INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
export ZPM_DIR=${ZPM_DIR:-$_ZPM_INSTALL_DIR}

source "$_ZPM_INSTALL_DIR/lib/utils.zsh"
source "$_ZPM_INSTALL_DIR/lib/core.zsh"
source "$_ZPM_INSTALL_DIR/lib/ext.zsh"

# Used to defer compinit/compdef
typeset -a __deferred_compdefs
compdef () { __deferred_compdefs=($__deferred_compdefs "$*") }

# Load a given package and loads it (sources it)
# Syntaxes
#   zpm-load <url> [<loc>=/]
# Keyword only arguments:
#   branch - The branch of the repo to use for this bundle.
zpm-load () {
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

    # Install the package if necessary
    -zpm-install-package "$@"

    # Load the plugin.
    url="$(-zpm-resolve-package-url "$url")"

    # Add the branch information to the url.
    if [[ ! -z $branch ]]; then
        url="$url|$branch"
    fi

    -zpm-load-package "$url" "$loc" "$make_local_clone"
}

# Install a given package and make it available (PATH it)
# Syntaxes
#   zpm-install <url> [<loc>=/]
# Keyword only arguments:
#   branch - The branch of the repo to use for this bundle.
zpm-install () {
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

    # Install the package if necessary
    -zpm-install-package "$@"

    # make package bin available
    url="$(-zpm-resolve-package-url "$url")"

    # Add the branch information to the url.
    if [[ ! -z $branch ]]; then
        url="$url|$branch"
    fi

    -zpm-enable-package "$url" "$loc" "$make_local_clone"
}

# Intializes compinit and loads deferred compdefs
zpm-apply () {

    # Initialize completion.
    local cdef

    # Load the compinit module. This will readefine the `compdef` function to
    # the one that actually initializes completions.
    autoload -U compinit
    compinit -C

    # Apply all `compinit`s that have been deferred.
    eval "$(for cdef in $__deferred_compdefs; do
                echo compdef $cdef
            done)"

    unset __deferred_compdefs
}

# A syntax sugar to avoid the `-` when calling zpm commands. With this
# function, you can write `zpm-install` as `zpm install` and so on.
zpm () {
    local cmd="$1"
    if [[ -z "$cmd" ]]; then
        echo 'zpm: Please give a command to run.' >&2
        return 1
    fi
    shift

    if functions "zpm-$cmd" > /dev/null; then
        "zpm-$cmd" "$@"
    else
        echo "zpm: Unknown command: $cmd" >&2
    fi
}

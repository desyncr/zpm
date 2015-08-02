# Given an acceptable short/full form of a bundle's repo url, this function
# echoes the full form of the repo's clone url.
#
# Expand short github url syntax: `username/reponame`.
-zpm-resolve-package-url () {
    local url="$1"

    # Expand short github url syntax: `username/reponame`.
    if [[ $url != git://* &&
            $url != https://* &&
            $url != http://* &&
            $url != ssh://* &&
            $url != /* &&
            $url != git@github.com:*/*
            ]]; then
        url="https://github.com/${url%.git}.git"
    fi

    echo "$url"
}

# Takes a repo url and gives out the path that this url needs to be cloned
# to. Doesn't actually clone anything.
-zpm-get-clone-dir () {
    echo -n $ZPM_DIR/repos/

    echo "$1" | sed \
        -e 's./.-SLASH-.g' \
        -e 's.:.-COLON-.g' \
        -e 's.|.-PIPE-.g' \
        -e 's.#.-SHARP-.g'
}

# Takes a repo's clone dir and gives out the repo's original url that was
# used to create the given directory path.
-zpm-get-clone-url () {
    echo "$1" | sed \
        -e "s:^$ZPM_DIR/repos/::" \
        -e 's.-SLASH-./.g' \
        -e 's.-COLON-.:.g' \
        -e 's.-PIPE-.|.g' \
        -e 's.-SHARP-.#.g'
}

# Ensure that a clone exists for the given repo url and branch. If the first
# argument is `--update` and if a clone already exists for the given repo
# and branch, it is pull-ed, i.e., updated.
-zpm-clone-repo () {
    # Argument defaults.
    # The url. No sane default for this, so just empty.
    local url=
    # Check if we have to update.
    local update=false
    # Verbose output.
    local verbose=false

    eval "$(-zpm-parse-args 'url ; update?, verbose?' "$@")"
    shift $#

    # Get the clone's directory as per the given repo url and branch.
    local clone_dir="$(-zpm-get-clone-dir $url)"

    # A temporary function wrapping the `git` command with repeated arguments.
    --plugin-git () {
        (cd "$clone_dir" && git --no-pager "$@" &> /dev/null )
    }
    # Clone if it doesn't already exist.
    if [[ ! -d $clone_dir ]]; then
        git clone --recursive "${url%'#'*}" "$clone_dir"
    elif $update; then
        # Save current revision.
        local old_rev="$(--plugin-git rev-parse HEAD)"
        # Pull changes if update requested.
        --plugin-git pull
        # Update submodules.
        --plugin-git submodule update --recursive
        # Get the new revision.
        local new_rev="$(--plugin-git rev-parse HEAD)"
    fi

    # If its a specific branch that we want, checkout that branch.
    if [[ $url == *'#'* ]]; then
        local current_branch=${$(--plugin-git symbolic-ref HEAD)##refs/heads/}
        local requested_branch="${url#*'#'}"
        # Only do the checkout when we are not already on the branch.
        [[ $requested_branch != $current_branch ]] &&
            --plugin-git checkout $requested_branch
    fi

    if [[ -n $old_rev && $old_rev != $new_rev ]]; then
        echo Updated from ${old_rev:0:7} to ${new_rev:0:7}.
        if $verbose; then
            --plugin-git log --oneline --reverse --no-merges --stat '@{1}..'
        fi
    fi

    # Remove the temporary git wrapper function.
    unfunction -- --plugin-git
}

# Get a list of files to source to load the given plugin
-zpm-package-source () {
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
        echo "$location"

    elif [[ -f "$location.zsh" ]]; then
        echo "$location.zsh"

    elif [[ -d "$location" ]]; then

        # Source the plugin script.
        # FIXME: I don't know. Looks very very ugly. Needs a better
        # implementation once tests are ready.
        local script_loc="$(ls "$location" | grep '\.plugin\.zsh$' | head -n1)"

        if [[ -f $location/$script_loc ]]; then
            # If we have a `*.plugin.zsh`, source it.
            echo "$location/$script_loc"

        elif ls "$location" | grep -l '\..*sh$' &> /dev/null; then
            # If there is no `*.plugin.zsh` file, source *all* the `*.zsh`
            # files.
            for script ($location/*.*sh(N)) { echo "$script" }
        else
            echo "$location"
        fi
    fi
}

-zpm-parse-package-query () {
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

    echo "$url $loc $make_local_clone"
}

# An argument parsing functionality to parse arguments the *antigen* way :).
# Takes one first argument (called spec), which dictates how to parse and
# the rest of the arguments are parsed. Outputs a piece of valid shell code
# that can be passed to `eval` inside a function which creates the arguments
# and their values as local variables. Suggested use is to set the defaults
# to all arguments first and then eval the output of this function.

# Spec: Only long argument supported. No support for parsing short options.
# The spec must have two sections, separated by a `;`.
#       '<positional-arguments>;<keyword-only-arguments>'
# Positional arguments are passed as just values, like `command a b`.
# Keyword arguments are passed as a `--name=value` pair, like `command
# --arg1=a --arg2=b`.

# Each argument in the spec is separated by a `,`. Each keyword argument can
# end in a `:` to specifiy that this argument wants a value, otherwise it
# doesn't take a value. (The value in the output when the keyword argument
# doesn't have a `:` is `true`).

# Arguments in either section can end with a `?` (should come after `:`, if
# both are present), means optional. FIXME: Not yet implemented.

# See the test file, tests/arg-parser.t for (working) examples.
-zpm-parse-args () {
    local spec="$1"
    shift

    # Sanitize the spec
    spec="$(echo "$spec" | tr '\n' ' ' | sed 's/[[:space:]]//g')"

    local code=''

    --add-var () {
        test -z "$code" || code="$code\n"
        code="${code}local $1='$2'"
    }

    local positional_args="$(echo "$spec" | cut -d\; -f1)"
    local positional_args_count="$(echo $positional_args |
            awk -F, '{print NF}')"

    # Set spec values based on the positional arguments.
    local i=1
    while [[ -n $1 && $1 != --* ]]; do

        if (( $i > $positional_args_count )); then
            echo "Only $positional_args_count positional arguments allowed." >&2
            echo "Found at least one more: '$1'" >&2
            return
        fi

        local name_spec="$(echo "$positional_args" | cut -d, -f$i)"
        local name="${${name_spec%\?}%:}"
        local value="$1"

        if echo "$code" | grep -l "^local $name=" &> /dev/null; then
            echo "Argument '$name' repeated with the value '$value'". >&2
            return
        fi

        --add-var $name "$value"

        shift
        i=$(($i + 1))
    done

    local keyword_args="$(
            # Positional arguments can double up as keyword arguments too.
            echo "$positional_args" | tr , '\n' |
                while read line; do
                    if [[ $line == *\? ]]; then
                        echo "${line%?}:?"
                    else
                        echo "$line:"
                    fi
                done

            # Specified keyword arguments.
            echo "$spec" | cut -d\; -f2 | tr , '\n'
            )"
    local keyword_args_count="$(echo $keyword_args | awk -F, '{print NF}')"

    # Set spec values from keyword arguments, if any. The remaining arguments
    # are all assumed to be keyword arguments.
    while [[ $1 == --* ]]; do
        # Remove the `--` at the start.
        local arg="${1#--}"

        # Get the argument name and value.
        if [[ $arg != *=* ]]; then
            local name="$arg"
            local value=''
        else
            local name="${arg%\=*}"
            local value="${arg#*=}"
        fi

        if echo "$code" | grep -l "^local $name=" &> /dev/null; then
            echo "Argument '$name' repeated with the value '$value'". >&2
            return
        fi

        # The specification for this argument, used for validations.
        local arg_line="$(echo "$keyword_args" |
                            egrep "^$name:?\??" | head -n1)"

        # Validate argument and value.
        if [[ -z $arg_line ]]; then
            # This argument is not known to us.
            echo "Unknown argument '$name'." >&2
            return

        elif (echo "$arg_line" | grep -l ':' &> /dev/null) &&
                [[ -z $value ]]; then
            # This argument needs a value, but is not provided.
            echo "Required argument for '$name' not provided." >&2
            return

        elif (echo "$arg_line" | grep -vl ':' &> /dev/null) &&
                [[ -n $value ]]; then
            # This argument doesn't need a value, but is provided.
            echo "No argument required for '$name', but provided '$value'." >&2
            return

        fi

        if [[ -z $value ]]; then
            value=true
        fi

        --add-var "${name//-/_}" "$value"
        shift
    done

    echo "$code"

    unfunction -- --add-var

}

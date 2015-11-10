# Extension system
#
# Provides an extension load mechanism for loading custom code that extends zpm.
#
# This is different than plugins or themes in a way that it actually interacts with
# zpm as it can hook into different zpm commands and internal/private functions.
#
# It provides pre- and post- hooks for any function (currently even outside zpm). Effectively
# executing the pre-function, the function itself and a post-function.
#
# It doesn't short-circuit (meaning it will always call all hooks and the actual command/function).
#
# Usage:
#
#       zpm ext ext-name # loads (ie, sources) the given extension from $_ZPM_INSTALL_DIR/ext/
#
# These are only meant to be run inside extension definitions:
#
#       # overwrites 'any-zpm-function' (ex, zpm-bundle) with 'extension-hook-function'
#       # which could be any function already defined.
#       # it can hook into pre- or post- events. defaults to pre-.
#       -zpm-ext-hook "any-zpm-function" "extension-hook-function" ["pre"|"post"]
#
#       # defined a new autocompletion for the zpm command (ex, zpm logger)
#       -zpm-ext-compadd "extension-auto-completion"
#
# The hooks functions receives the same arguments the original function receives.
typeset -A callbacks
local -a hooks; hooks=()

# enable or disable logging
export _EXT_LOGGING_ENABLED=false

# logs a custom message (echo to >&2)
#
# usage:
#   -zpm-ext-log "message"          # LOG: message
#   -zpm-ext-log -e "error message" # ERROR: error message
#
# enable or disable logging with $_EXT_LOGGING_ENABLED env variable
function -zpm-ext-log () {
    local message
    if [[ $1 == "-e" ]]; then
        shift
        message="ERROR: $@"
    else
        message="LOG: $@"
    fi

    if ($_EXT_LOGGING_ENABLED) {
        echo "$message" >&2
    }
}

# function wrapper for -zpm-ext-log to display "ERROR: " labeled logs
#
# usage:
#   -zpm-ext-log-error "error"  # ERROR: error
function -zpm-ext-log-error () {
    -zpm-ext-log "-e" "$@"
}

# capture functions providing a pre and post callbacks
#
# usage:
#   -zpm-ext-capture "func-name"
#
# captures 'func-name' and registers it into $hooks list
function -zpm-ext-capture () {
    local funcname="$1"
    eval "function -captured-$(functions -- $funcname)"

    -zpm-ext-log capturing function $funcname
    hooks+=($funcname)

    $funcname () {
        callback="$0"
        call-hooks () {
            local hook_name="$1-$2"
            local names=${callbacks[$hook_name]}
            for hook in ${(s.:.)names}; do
                -zpm-ext-log calling hook function $hook for $hook_name with \'${@[3,-1]}\'
                eval "$hook" "${@[3,-1]}"
            done
        }

        # calling pre hooks
        call-hooks "$callback" "pre" "$@"

        # we call the captured function
        -zpm-ext-log calling captured function $0 with "$@"
        -captured-$0 $@

        # calling post hooks
        call-hooks "$callback" "post" "$@"
    }
}

# hooks a particular function
#
# usage:
#   -zpm-hook "zpm-bundle" "zpm-bundle-hook"    # hooks zpm-bundle (pre event)
#   -zpm-hook "zpm-bundle" "zpm-bundle-hook" "post" #hooks zpm-bundle (post event)
#
# if the function to be hooked wasn't captured it captures it with -zpm-ext-capture
function -zpm-ext-hook () {
    local function_hook="$1"
    local callback_function="$2"
    local event="$3"

    if [ ! "$event" ]; then
        event="pre"
    fi

    local hook_name="$function_hook-$event"

    callbacks[$hook_name]=${callbacks[$hook_name]}"$callback_function:"

    if [[ ! -n "${hooks[(r)$function_hook]}" ]]; then
        -zpm-ext-capture $function_hook
    else
        -zpm-ext-log already hooked function $function_hook
    fi

    -zpm-ext-log registering callback for function hook $hook_name as $callback_function
}

# adds an autocompletion to zpm command
#
# usage:
#   -zpm-ext-compadd "extension-command"
function -zpm-ext-compadd () {
    local compadd_function="compadd-ext-$1"
    eval "function $compadd_function () {
        local _zpm_ext_compadd=('$1:$2')
        _describe -t commands 'zpm command' _zpm_ext_compadd
    }"
    -zpm-ext-hook "_zpm" $compadd_function
}

# loads a given extension (ie, sources it)
#
# usage:
#   zpm ext "extname"
function zpm-ext () {
    if [[ "$1" == "" ]]; then
        local line=""
        grep '^[[:space:]]*[^[:space:]#]' | while read line; do
            eval zpm-ext $line
        done
    else
        local extension_name="$1"
        -zpm-ext-log loading extension "$extension_name"
        zpm-load "$@"
    fi
}

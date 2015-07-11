# logger extension
# logs bundled stuff
#
# TODO add load time per bundle and accumulated load time
local -a packages; packages=()

# register the loaded bundles
function -zpm-install-log () {
    packages+=($@)
}

# logger command that prints the logged bundles
function zpm-logger () {
    echo Packages currently loaded:
    echo
    for package in $packages; do
        echo $package
    done
    echo
}

# hooks into antigen-bundle to have access to all 'antigen bundle *' runs
-zpm-ext-hook "zpm-install" "-zpm-install-log"
-zpm-ext-hook "zpm-load" "-zpm-install-log"

# add a completion for the extension
-zpm-ext-compadd "logger"

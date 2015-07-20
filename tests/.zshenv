# zshrc file written for zpm's tests. Might not be a good one for daily use.

# See cram's documentation for some of the variables used below.

export ZPM_DIR="$PWD/dot-zpm"

test -f "$TESTDIR/.zcompdump" && rm "$TESTDIR/.zcompdump"

source "$TESTDIR/../zpm.zsh"

# A test plugin repository to test out antigen with.

export PLUGIN_DIR="$PWD/test-plugin"
mkdir "$PLUGIN_DIR"

# A wrapper function over `git` to work with the test plugin repo.
alias pg='git --git-dir "$PLUGIN_DIR/.git" --work-tree "$PLUGIN_DIR"'

echo 'alias hehe="echo hehe"' > "$PLUGIN_DIR"/aliases.zsh
echo 'export PS1="prompt>"' > "$PLUGIN_DIR"/silly.zsh-theme

{
    pg init
    pg add .
    pg commit -m 'Initial commit'
} > /dev/null

# Create a specific branch
echo 'alias hehetest="echo hehetest"' > "$PLUGIN_DIR"/aliases.zsh
echo 'export PS1="prompt-test>"' > "$PLUGIN_DIR"/silly.zsh-theme
{
	pg checkout -b dev
    pg add .
    pg commit -m 'Testing prompt'
    pg checkout master
} &> /dev/null

# Another test plugin.

export PLUGIN_DIR2="$PWD/test-plugin2"
mkdir "$PLUGIN_DIR2"

# A wrapper function over `git` to work with the test plugin repo.
alias pg2='git --git-dir "$PLUGIN_DIR2/.git" --work-tree "$PLUGIN_DIR2"'

echo 'alias hehe2="echo hehe2"' > "$PLUGIN_DIR2"/init.zsh
echo 'alias unsourced-alias="echo unsourced-alias"' > "$PLUGIN_DIR2"/aliases.zsh

{
    pg2 init
    pg2 add .
    pg2 commit -m 'Initial commit'
} > /dev/null

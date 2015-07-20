Install plugin from master.

  $ zpm-install $PLUGIN_DIR &> /dev/null
  $ echo $PATH
  .*test\-plugin.* (re)

Load the plugin again. Just to see nothing happens.

  $ zpm-install $PLUGIN_DIR
  $ which hehe
  hehe not found
  [1]

Confirm there is still only one repository.

  $ ls $ZPM_DIR/repos | wc -l
  1

Tests docblock syntax.

  $ zpm-install <<EOPLUGINS
  >    $PLUGIN_DIR
  >    $PLUGIN_DIR2
  > EOPLUGINS

  $ echo $PATH
  .*test\-plugin.* (re)

  $ echo $PATH
  .*test\-plugin2.* (re)

  $ which hehe
  hehe not found
  [1]

  $ which hehe2
  hehe2 not found
  [1]

Confirm there are now two repositories.

  $ ls $ZPM_DIR/repos | wc -l
  2

Install from a specific branch.
  $ zpm-install $PLUGIN_DIR --branch=dev &> /dev/null
  $ echo $PATH
  .*test\-plugin\-SHARP\-dev.* (re)

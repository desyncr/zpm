Load plugin from master.

  $ zpm-load $PLUGIN_DIR &> /dev/null
  $ hehe
  hehe

Load the plugin again. Just to see nothing happens.

  $ zpm-load $PLUGIN_DIR
  $ hehe
  hehe

Confirm there is still only one repository.

  $ ls $ZPM_DIR/repos | wc -l
  1

Tests docblock syntax.

  $ zpm-load <<EOPLUGINS
  >    $PLUGIN_DIR
  >    $PLUGIN_DIR2
  > EOPLUGINS

  $ hehe
  hehe

  $ hehe2
  hehe2

Confirm there are now two repositories.

  $ ls $ZPM_DIR/repos | wc -l
  2

Load from a specific branch.
  $ zpm-load $PLUGIN_DIR --branch=dev &> /dev/null
  $ hehetest
  hehetest

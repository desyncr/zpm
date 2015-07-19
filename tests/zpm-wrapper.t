Create a dummy zpm command.

  $ zpm-dummy () {
  >   echo me dummy
  > }

Check the normal way of calling it

  $ zpm-dummy
  me dummy

Call with the wrapper syntax.

  $ zpm dummy
  me dummy

Call with an alias

  $ alias a=zpm
  $ a dummy
  me dummy

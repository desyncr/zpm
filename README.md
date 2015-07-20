zpm - Zsh Plugin Manager [![Build Status](https://travis-ci.org/desyncr/zpm.svg)](https://travis-ci.org/desyncr/zpm)
===

zpm is a spin off Antigen which aims to provide a lightweight, fast and flexible plugin manager for ZSH.

It's core component is it's extension system which allows for anyone to extend how and what zpm can do.


Concept
===

There are three components in the whole zpm universe. Those are: plugins, binaries and extensions.

#### Plugins

Plugins is anything that interacts with the shell, such as syntax highlighters, aliases and so on so forth. Plugins are sourced once they are installed.

#### Binaries

Binaries are tools once installed are available for invokation (are present in $PATH).


#### Extensions

Extensions are meant to extend zpm functionallity and keep base code small and reliable.

Usage
===

#### zpm load

Loads a given plugin. Example:

    zpm load zsh-users/zsh-syntax-highlighting

#### zpm install

Install and makes available a given binary. Example:

    zpm install LuRsT/hr

#### zpm apply
  
  Makes available all plugin-defined auto-completions.

Extensions
===

Zpm can be extended to support any sort of costumization such as working with themes, caching plugins and more.

#### zpm ext

Loads a given extension.

    zpm ext desyncr/zpm-ext

See the extensions repositories to see how they work.


Feedback
===

If you'd like to contribute to the project or file a bug or feature request, please visit [the project page][1].

License
===

The project is licensed under the [GNU GPL v3][2] license.

  [1]: https://github.com/desyncr/zpm/
  [2]: http://www.gnu.org/licenses/gpl.html



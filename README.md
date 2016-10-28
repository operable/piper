# Piper

[![Build status](https://badge.buildkite.com/74522f9355301b7e15be69feb5f4f13472d5ccf63801e6c5c5.svg?branch=master)](https://buildkite.com/operable/piper)

Piper contains parsers for [Cog's](https://github.com/operable/cog) access control rule and ChatOps command languages. Piper has minimal
dependencies and can be used wherever parsing either of these languages would be useful.

## Getting piper

Add `piper` to the `deps` section of `mix.exs`:

`{:piper, github: "operable/piper"}`

## Using piper

Until we have proper docs `Piper.Permissions.Parser` (access control rules parser) and `Piper.Command.Parser` (ChatOps command parser) are good
places to start.

## Filing issues

Piper issues are tracked centrally in [Cog's](https://github.com/operable/cog/issues) issue tracker.

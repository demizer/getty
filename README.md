<br/>

<p align="center">
  <img alt="Getty" src="https://github.com/getty-zig/logo/blob/main/getty-solid.svg" width="410px">
  <br/>
  <br/>
  <a href="https://github.com/getty-zig/getty/releases/latest"><img alt="Version" src="https://img.shields.io/github/v/release/getty-zig/getty?include_prereleases&label=version&style=flat-square"></a>
  <a href="https://github.com/getty-zig/getty/actions/workflows/ci.yml"><img alt="Build status" src="https://img.shields.io/github/workflow/status/getty-zig/getty/ci?style=flat-square" /></a>
  <a href="https://ziglang.org/download"><img alt="Zig" src="https://img.shields.io/badge/zig-master-fd9930.svg?style=flat-square"></a>
  <a href="https://github.com/getty-zig/getty/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/badge/license-MIT-blue?style=flat-square"></a>
</p>

## Overview

Getty is a serialization and deserialization framework for the [Zig programming
language](https://ziglang.org).

The main contribution of Getty is its data model, a set of types that
establishes a generic baseline from which serializers and deserializers can
operate. Using the data model, serializers and deserializers:

- Automatically support a number of Zig data types (including many within the standard library).
- Can serialize or deserialize into any data type mapped to Getty's data model.
- Can perform custom serialization and deserialization.
- Become much simpler than equivalent, handwritten alternatives.

## Installation

### Manual

1. Clone Getty:

    ```
    git clone https://github.com/getty-zig/getty deps/getty
    ```

2. Add the following to `build.zig`:

    ```diff
    const std = @import("std");

    pub fn build(b: *std.build.Builder) void {
        ...

        const exe = b.addExecutable("my-project", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
    +   exe.addPackagePath("getty", "deps/getty/src/lib.zig");
        exe.install();

        ...
    }
    ```

### Gyro

1. Make Getty a project dependency:

    ```
    gyro add -s github getty-zig/getty
    gyro fetch
    ```

2. Add the following to `build.zig`:

    ```diff
    const std = @import("std");
    +const pkgs = @import("deps.zig").pkgs;

    pub fn build(b: *std.build.Builder) void {
        ...

        const exe = b.addExecutable("my-project", "src/main.zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
    +   pkgs.addAllTo(exe);
        exe.install();

        ...
    }
    ```

### Zigmod

1. [Read this tutorial](https://nektro.github.io/zigmod/tutorial.html) on how to setup a new zigmod project.

    Note: getty is not hosted on aquila.red ([see this comment for details](https://github.com/nektro/zigmod/issues/63#issuecomment-1063205053)).

1. Add getty to zigmod.yml

    ```
    root_dependencies:
      - src: git https://github.com/getty-zig/getty
    ```

1. Fetch the new dependency:

    ```
    zigmod fetch
    ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

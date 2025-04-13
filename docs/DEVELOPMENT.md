# Development

## Local development

To build a Dogebox release image while developing locally, copy the `dev.example.json` to a `dev.json` and fill it out with absolute paths to all your projects.

Nix flakes require files to be committed before they can be accessed during a build, so to avoid that, we can trick git:

```bash
git add -f --intent-to-add dev.json
git update-index --assume-unchanged dev.json
```

Typically nix will not let you read "outside" of its deterministic environment, so we have to pass a couple of flags to say "this is temporarily OK".

If you wanted to build an aarch64 iso, your command would previous look like:

```bash
nix build .#iso-aarch64
```

Now, it should look like:

```bash
dev=1 nix build .#iso-aarch64 --impure
```

The `--impure` flag tells nix to allow reading environment variables, and the `dev=1` env var actually tells our build process to use the `dev.json` file as input overrides for all our services.

A couple of our projects that use Golang may need to be explicitly "vendored" to support this workflow. If this is the case, cd to the project directory and run `go mod vendor`. The created `vendor` folder should **not** be committed, and should be added to the `.gitignore` file of the project if it doesn't already exist.

If you get an error opening dev.json, consider clearing your cache with:
```bash
nix-collect-garbage -d
```
After this, re-run the `git add` and `git update-index` commands above to re-add the dev.json to the git repository before running any further builds.
# ripper

A file watcher that sends desktop notifications.

## Nix

### Run on startup

Add this repoisitory as an input: `ripper.url = "github:filipforsstrom/ripper";`

Add it as a module: `inputs.ripper.nixosModules.default`

Add a nix file for options:

```
{...}: {
  services.ripper = {
    enable = true;
    command = "whipper cd rip";
    user = "your_user";
  };
}
```

### Building

Run `nix build`

### Development

Run `nix flake`

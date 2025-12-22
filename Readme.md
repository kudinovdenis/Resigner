# Resigner

This tool designed to resign iOS application and verify matching bundle ids of all executables with provided provisioning profiles.

To use it you only need to fix Info.plist for main target and all executables inside (Exensions, Plugins, Watch directories inside .app)

## UI application
- Build Resigner app
- Open Resigner app
- Resigner will automatically parse display all Mach-O binaries inside app
- Select executable binaries and provide provisioning profiles and entitlements for each. Note: frameworks does not require pp / entitlements.
- Resigner will check if provisioning profile match connected executable.
- Click Resign button. After that you will have resigned application with new pp / entitlements
- To see logs, open console in top right corner of Resigner
- UI application has it's own persistent storage to store pairs bundle id -> provisioning profile and entitlements list, so you can re-run Resigner without losing selected pp / entitlements.

## Command-line interface
- Build `resigner-cli` target
- Run resulting binary

How to use resigner-cli:
```sh
OPTIONS:
  --binary-path <binary-path>
                          Path to binary to resign
  -h, --help              Show help information.
```
Note: resigner-cli shares same persistent cache with Resigner UI application

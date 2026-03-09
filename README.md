# MultiroleServerBuild

Automatically publish pre-build artifact of [DyXel/Multirole](https://github.com/DyXel/Multirole) for Linux x64 (OS Ubuntu 22.04 or compatible).

The artifact contains:
- `multirole` — main server binary
- `hornet` — core wrapper process
- `area-zero.sh` — utility script
- `config.json` — server configuration
- `libboost_*.so.*` — bundled Boost runtime libraries (built from source)

## Update script

Run manually 'update-multirole.sh' on the server to update to the latest artifact.

## systemd Service

Create `/etc/systemd/system/multirole.service`:
Example from 'multirole.service'

Then enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now multirole
```

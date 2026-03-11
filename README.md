# MultiroleServerBuild

Automated builds of [DyXel/Multirole](https://github.com/DyXel/Multirole) for Linux x64 (Ubuntu 22.04 or compatible).

Each release artifact contains:
- `multirole` — main server binary
- `hornet` — core wrapper process
- `area-zero.sh` — utility script
- `libboost_*.so.*` — bundled Boost 1.90 runtime libraries

## Configuration

Create `config.json` in your install directory. See the [Multirole repo](https://github.com/DyXel/Multirole) for the format and available options.

## Updating

Re-run the update script to pull the latest release:
```bash
./update-multirole.sh
```

## systemd Service

An example service file is provided in `multirole.service`.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now multirole

sudo systemctl restart multirole
systemctl status multirole
```

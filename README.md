# VSCode Portable Updater

[![GitHub Repo](https://img.shields.io/badge/GitHub-VSCode%20Portable%20Updater-3399FF?logo=github&logoColor=white)](https://github.com/FrancescoGd/vscode-portable-updater)
[![License: MIT](https://img.shields.io/badge/License-MIT-99cc00.svg)](https://spdx.org/licenses/MIT.html)
[![Latest Release](https://img.shields.io/github/v/release/FrancescoGd/vscode-portable-updater?color=%238a2be2&label=Release&logo=starship&logoColor=white)](https://github.com/FrancescoGd/vscode-portable-updater/releases)

Simple _PowerShell_ script to update **VSCode Portable** installations while preserving user data.

This is an **highly opinionated** but simple script that I've built for myself to automate _my own routine_ each time I have to update the portable version of VSCode which currently doesn't support automatic updates.

## Features

- Detects latest version from VSCode ZIP files (using semantic versioning) if you have more than one in the same directory
- Automatic backup of previous installation
- Preserves `data` folder (extensions, settings, history)
- Cleans up source ZIP after successful extraction

## Usage

```powershell
.\vscode-portable-updater.ps1
```

## Inline Help

```powershell
Get-Help .\vscode-portable-updater.ps1 [-Full]
```

## Requirements

- PowerShell 5.1+

## Current Limitations

These are actual limitations... as said earlier this script is higly tied to my own routine so I may or may not change and expand it.

- It only works in the current directory, everything must reside in the same folder
- To check for a successful unzipping it only verifies if `Code.exe` exists in the new folder
- Backup will always have the same name `VSCode-bak` so future updates will clash if you don't get rid of/rename it later (the script will output a warning and stop execution)

## License

This script is released under **MIT license** see the [LICENSE](LICENSE) file or read it [on its website](https://spdx.org/licenses/MIT.html).

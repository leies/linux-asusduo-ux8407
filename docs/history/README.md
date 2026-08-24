# History (do not run)

`readme.html` is the original step-by-step writeup of how Phase 1 was found.

`scripts/` are the one-off apply attempts from that session. Several of them **failed** and were superseded:

- Audio blacklist / forced topology: SOF waited forever or still duplicated the RT722 jack
- Late `add_file` ACPI: table upgrade already ran
- `ukify` `ACPI=` and PE `.acpi` via `objcopy`: ignored or shifted the UKI `.text` section

The working audio path is the early-initramfs SSDT (`files/acpi/` + `acpi_override`). Use `../../install.sh`, not these scripts.

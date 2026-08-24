# Per-host DMS settings

`settings.json` in the parent directory is SHARED by every host and is written
by DMS itself at runtime — change the bar layout on one machine and the other
gets it on the next pull. That is the behaviour we want for almost all of the
381 keys in there.

A handful are not shareable. `<hostname>.json` in this directory holds exactly
those, and is merged over `settings.json` immediately before DMS starts
(`ExecStartPre` on dms-shell.service) and on every home-manager activation.
Filenames must match `networking.hostName`.

The union of keys across every file here is also the set that
`.gitattributes` strips from `settings.json` on the way into git — so those
lines never appear in a diff and the two machines cannot fight over them.
There is one source of truth per key and it is the file you are reading about.

To make a key host-specific: add it to EVERY `<hostname>.json` here (a key
present in only one host's file is deleted from the shared file for all hosts
but restored on only one, so the others silently fall back to the DMS default).

To make one shared again: remove it from all of them, then set it once on
either machine and commit.

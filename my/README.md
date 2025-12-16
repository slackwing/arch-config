# tmux-\*

Symlink from ~/.local/bin/ to run manually.

# userChrome.css

In Firefox go to about:support then open the Profile Directory, create or open a directory "chrome/", and symlink to this file.

# Web Development Reorientation

- ws_prod and ws_stag sync the feathers/.../html/ directory to the server's /var/www/html/{,.staging}/ respectively.
- If on a new machine, a new SSH key is easy to generate; generate a pair, and copy the PUBLIC file contents to the server's ~/.ssh/authorized_keys. Of course, access is necessary from an older machine. Otherwise, try transferring id_ed25519_gcp_202512 (PRIVATE) to the new machine and ssh-add'ing it.
- ws_ssh is the alias to ssh into the server.
- ws_prod and ws_stag's rsync parameters have been updated to DELETE files they do not find, i.e. perform an exact mirror.
- Exceptions (as of this writing) are:
  - .staging/ - So that ws_prod does not delete .staging/.
  - shared/assets/ - To prevent constant adding and removing of large assets (see staging workflow for why this would happen) and also to guarantee asset existence at the (acceptable) price of forever-storage.
  - \*\*/wordpress/ - We already accidentally deleted the entire WordPress installation the first time we enabled DELETE. Luckily, Abi's site code was fully encapsulated in the repo-tracked index.html. But WordPress will have to be re-installed to restore the site. This example serves to show the next point:
- The server should always be viewed as a mirror of the git repo, EXCEPTING ONLY THE PATHS DEFINED IN rsync FILTERS. Be mindful of this and if ever needing anything else to persist indefinitely, update the rsync filter.
- ws_prod is guarded so that it can only run on the master branch. The idea is to keep production identical to what's merge to master, while development only occurs in branches. ws_stag then clobbers .staging/ when run from different branches. This is intentional. If working simultaneously on multiple branches, we would ws_stag from each branch anyway. The cost of rewrites is acceptable.
- IMPORTANT: Be disciplined about DELETING branches merged to master so that the list of branches reflect unmerged changes!

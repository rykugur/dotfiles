# this command creates a keys.txt file to be used for sops(-nix)
# it assumes that the SSH key you want to use exists already in 1password and that you're logged in
# if a file already exists at the destination, the script will abort
def write_stops_age_keysdottxt [out_path: string = "~/.config/sops/age/keys.txt"] {
  let selected_key_id = (op item list --categories "SSH Key" --vault "Private" | lines | skip 1 | to text | fzf | split column -r '\s{2,}' ID TITLE VAULT EDITED | get ID | to text)
  nix-shell -p ssh-to-age --run $'op item get ($selected_key_id) --fields "label=private key" --reveal | ssh-to-age -private-key > $(out_path)'
}

def "steam id-lookup" [...name: string] {
  let term = $name | str join " "
  http get $"https://store.steampowered.com/api/storesearch/?term=($term | url encode)&l=english&cc=US"
  | get items
  | select id name
}

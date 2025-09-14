$env.abbreviations = $env.abbreviations | merge {
  dc: "docker compose"
  dcb: "docker compose build"
  dcl: "docker compose logs"
  dclf: "docker compose logs -f"
  dcr: "docker compose restart"
  dcu: "docker compose up"
  dcud: "docker compose up -d"
  dcd: "docker compose down"
  drit: "docker run -it"
  docker.clean: "docker rmi (docker images -f dangling=true -q)"
  lzd: "lazydocker"
}

$env.abbreviations = $env.abbreviations | merge {
  jjd: "jj diff"
  jjds: "jj diff --summary"
  jjl: "jj log"
}

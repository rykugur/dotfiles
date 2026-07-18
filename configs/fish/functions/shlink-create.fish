function shlink-create --description "Create a Shlink URL with a custom slug"
    argparse -n shlink-create 'slug=' 'url=' -- $argv
    or return

    if not set -q _flag_slug; or not set -q _flag_url
        echo "usage: shlink-create --slug SLUG --url URL" >&2
        return 2
    end

    command kubectl --namespace shlink exec -it deployments/shlink -- bin/cli short-url:create --custom-slug "$_flag_slug" "$_flag_url"
end

# install lakos - see https://pub.dev/packages/lakos/install
# dart pub global activate lakos
# export PATH="$PATH":"$HOME/.pub-cache/bin"
echo "Generate Graph dependencies"

rm graph.dot
rm graph.svg

lakos ./lib/. --no-tree -o graph.dot
npx --yes github:jpdup/glad graph.dot -o graph.svg --exclude "**/test/*" --lines elbow

rm graph.dot
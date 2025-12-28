#!/bin/bash

if which node >/dev/null; then    
  npx --yes git@github.com:jpdup/glad.git --view layers --lines elbow --align left -o layers.svg  
else
  echo "Node.js is not installed."
  echo "To install use brew"
  echo "brew install node"
fi



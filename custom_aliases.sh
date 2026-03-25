# Open a solution file in Rider (defaults to the only solution if one match is found)
function rider() {
  local results=$(find . -maxdepth 1 -type f -iname "*.sln")
 
  if [ -z "$results" ]; then
    echo -e "No solution file found"
  else
    local count=$(echo "$results" | wc -l)
 
    if [ "$count" -eq 1 ]; then
      rider64.exe "$results"
    else
      echo -e "\nMultiple solution files found\n"
      echo "$results" | sed 's/^/- /'
    fi
  fi
}
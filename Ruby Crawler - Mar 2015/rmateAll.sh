i=0;
find . -type f | while read x; do
  rmate $x;
  
  i=$(($i+1));
  
  if [$i -gt 50]
  then
    break;
  fi
done
#!/bin/bash
source $1

attempts=3
timeout=5
online=false

echo "Checking status of $url."

for (( i=1; i<=$attempts; i++ ))
do
  code=`curl -sL --connect-timeout 20 --max-time 30 -w "%{http_code}\\n" "$url" -o ${pkg}.content.html`

  echo "Found code $code for $url."

  if [ "$code" = "200" ]; then
    echo "Website $url is online."
    online=true
    break
  else
    echo "Website $url seems to be offline. Waiting $timeout seconds."
    sleep $timeout
  fi
done

echo "  <testcase classname=\"${pkg}.${report}\" name=\"WebsiteOnline\">\n"  >> uptime.xml
if $online; then
  echo "Monitor finished, website is online."
else
  echo "Monitor failed, website seems to be down."
  echo "    <failure type=\"WebsiteOffline\">The website ${url%%\?*} is down</failure>\n" >> uptime.xml
fi
echo "  </testcase>\n" >> uptime.xml

echo "  <testcase classname=\"${pkg}.${report}\" name=\"WebsiteContent\">\n"  >> uptime.xml
if grep -q "${expectedContent}" "${pkg}.content.html"; then
  echo "Website contains expected content"
else
  echo "Website does not contain expected content: '${expectedContent}'."
  echo "    <failure type=\"WebsiteContent\">The ${url%%\?*} website content did not contain '${expectedContent}'</failure>\n" >> uptime.xml
fi
echo "  </testcase>\n" >> uptime.xml


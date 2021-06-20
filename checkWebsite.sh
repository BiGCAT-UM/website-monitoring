#!/bin/bash
source $1

attempts=3
timeout=5
online=false
useragent="BiGCaT Website Monitor"

echo "Checking status of $url."

for (( i=1; i<=$attempts; i++ ))
do
  httpcode=`curl -A "${useragent}" -sL --connect-timeout 20 --max-time 30 -w "%{http_code}\\n" "$url" -o ${pkg}.${report}.content.html; echo "Exit code: $? " | tee ${pkg}.${report}.exitcode | grep -v "Exit"`
  exitcode=`cat ${pkg}.${report}.exitcode | cut -d':' -f2 | sed -e 's/[ \t]//g'`

  echo "Found HTTP code $httpcode for $url."
  echo "Found exit code $exitcode for $url."

  if [ "$httpcode" = "200" ]; then
    echo "Website $url is online."
    online=true
    break
  elif [ "$httpcode" = "000" ]; then
    echo "Website $url is online but has an curl exit code $exitcode."
    if [ "$exitcode" = "60" -o "$exitcode" = "51" ]; then
      httpcode=`curl -k -A "${useragent}" -sL --connect-timeout 20 --max-time 30 -w "%{http_code}\\n" "$url" -o ${pkg}.${report}.content.html; echo "Exit code: $? " | tee ${pkg}.${report}.exitcode | grep -v "Exit"`
      online=true
    elif [ "$exitcode" = "56" ]; then
      httpcode=`curl -k -A "${useragent}" -sL --connect-timeout 20 --max-time 30 -w "%{http_code}\\n" "$url" -o ${pkg}.${report}.content.html; echo "Exit code: $? " | tee ${pkg}.${report}.exitcode | grep -v "Exit"`
      online=true
    else
      online=false
    fi
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
  echo "    <system-out>HTTP ${httpcode}</system-out>\n" >> uptime.xml
fi
echo "  </testcase>\n" >> uptime.xml

doCheckWebsite=false
if [ "$httpcode" = "000" ]; then
  if [ "$exitcode" = "60" -o "$exitcode" = "51" ]; then
    # SSL certificat, but we can still check
    doCheckWebsite=true
  elif [ "$exitcode" = "56" ]; then
    # connection terminated but seems a false positive
    doCheckWebsite=true
  fi
else
  doCheckWebsite=true
fi

echo "  <testcase classname=\"${pkg}.${report}\" name=\"WebsiteContent\">\n"  >> uptime.xml
if $doCheckWebsite; then
  if grep -q "${expectedContent}" "${pkg}.${report}.content.html"; then
    echo "Website contains expected content"
  else
    echo "Website does not contain expected content: '${expectedContent}'."
    echo "    <failure type=\"WebsiteContent\">The ${url%%\?*} website content did not contain '${expectedContent}'</failure>\n" >> uptime.xml
  fi
else
  echo "Not checking the content (because http code '${httpcode}' and exit code '${exitcode}')"
  echo "    <failure type=\"WebsiteContent\">The ${url%%\?*} website content was not checked. cURL exit code '${exitcode}'</failure>\n" >> uptime.xml
fi
echo "  </testcase>\n" >> uptime.xml

echo "  <testcase classname=\"${pkg}.${report}\" name=\"SecurityCertificates\">\n"  >> uptime.xml
if [ "$exitcode" = "60" -o "$exitcode" = "51" ]; then
  echo "The remote server's SSL certificate or SSH md5 fingerprint was deemed not OK."
  echo "    <failure type=\"SecurityCertificates\">The ${url%%\?*} website's SSL certificate or SSH md5 fingerprint was deemed not OK: cURL exit code '${exitcode}'</failure>\n" >> uptime.xml
else
  echo "No certificate problems detected"
fi
echo "  </testcase>\n" >> uptime.xml


# a short break before continuing to the next website
sleep 0.5

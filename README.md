# BiGCaT Website Monitoring

This repository has a website checking script and configurations for the websites we wish to have regularly checked.
The script currently checks if the website is online (HTTP 200) and the content of the website.

The configuration file contains four lines that describe the what and how. For example:

```properties
url='http://bridgedb.org/'
pkg="org.bridgedb"
report='MainBridgeDbWebsite'
expectedContent='BridgeDb is a framework'
```

The second and third line are used for reporting in the Jenkins job and must be descriptive and
unique. The first line is the URL of the website to test (note that HTTP and HTTPS are different URLs)
and the fourth line gives a string that is expected to be part of the HTML, JSON, etc that is
returned for the URL (after a HTTP GET call).

# Caveats

The system is really just a poor man's set up and has its limitations. Take into account the following
aspects:

1. the passed url is used for a cURL call to get HTML, but the HTML is not interpreted
2. the output is reported in an XML file, which sometimes gives problems with characters in URLs that need escaping (encoding)

The first point means that the test cannot test for JavaScript-generated content on the page.

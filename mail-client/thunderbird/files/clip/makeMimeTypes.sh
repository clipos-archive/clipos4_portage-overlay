#!/bin/bash
# Copyright 2016 ANSSI
# Distributed under the terms of the GNU General Public License v2

set -u
set -e

# make the mimeTypes.rdf file

declare -A FILETYPES
FILETYPES["application/pdf"]="pdf|/usr/local/bin/xdg-open|PDF Document"
FILETYPES["application/postscript"]="ps|/usr/local/bin/xdg-open|Postscript Document"
FILETYPES["image/png"]="png|/usr/local/bin/xdg-open|PNG image"
FILETYPES["image/jpeg"]="jpg|/usr/local/bin/xdg-open|JPEG image"
FILETYPES["image/gif"]="gif|/usr/local/bin/xdg-open|GIF image"
FILETYPES["image/bmp"]="gif|/usr/local/bin/xdg-open|BMP image"

MIMETYPES_ROOT=""
DESC_APPLICATION=""
DESC_HANDLER=""
EXT_APP=""

for type in "${!FILETYPES[@]}"; do
	MIMETYPES_ROOT="$MIMETYPES_ROOT <RDF:li RDF:resource=\"urn:mimetype:${type}\"/>"

	DESC_APPLICATION="$DESC_APPLICATION
		<RDF:Description RDF:about=\"urn:mimetype:${type}\"
		NC:fileExtensions=\"$(echo ${FILETYPES[${type}]}|cut -d "|" -f 1)\"
		NC:description=\"$(echo ${FILETYPES[${type}]}| cut -d "|" -f 3)\"
		NC:value=\"${type}\"
		NC:editable=\"false\">
		<NC:handlerProp RDF:resource=\"urn:mimetype:handler:${type}\" />
	  "

	DESC_HANDLER="$DESC_HANDLER
		<RDF:Description RDF:about=\"urn:mimetype:handler:${type}\"
		NC:alwaysAsk=\"false\"
		NC:saveToDisk=\"false\"
		NC:useSystemDefault=\"false\"
		NC:handleInternal=\"false\">
		<NC:externalApplication RDF:resource=\"urn:mimetype:externalApplication:${type}\" />
		</RDF:Description>
	"
	EXT_APP="$EXT_APP
		<RDF:Description RDF:about=\"urn:mimetype:externalApplication:${type}\"
		NC:path=\"$(echo ${FILETYPES[${type}]}| cut -d "|" -f 2)\"
		NC:prettyName=\"$(basename $(echo ${FILETYPES[${type}]}| cut -d "|" -f 2))\" />
	"
done


cat << EOF
<?xml version="1.0"?>
<RDF:RDF xmlns:NC="http://home.netscape.com/NC-rdf#"
         xmlns:RDF="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
  <RDF:Description RDF:about="urn:scheme:externalApplication:https"
                   NC:prettyName="xdg-open"
                   NC:path="/usr/local/bin/xdg-open" />
  <RDF:Description RDF:about="urn:scheme:handler:https"
                   NC:alwaysAsk="false">
    <NC:externalApplication RDF:resource="urn:scheme:externalApplication:https"/>
  </RDF:Description>
  <RDF:Description RDF:about="urn:root"
                   NC:fr_defaultHandlersVersion="-1" />
  <RDF:Description RDF:about="urn:scheme:https"
                   NC:value="https">
    <NC:handlerProp RDF:resource="urn:scheme:handler:https"/>
  </RDF:Description>
  <RDF:Description RDF:about="urn:scheme:handler:http"
                   NC:alwaysAsk="false">
    <NC:externalApplication RDF:resource="urn:scheme:externalApplication:http"/>
  </RDF:Description>
  <RDF:Description RDF:about="urn:mimetypes">
    <NC:MIME-types RDF:resource="urn:mimetypes:root"/>
  </RDF:Description>
  <RDF:Description RDF:about="urn:scheme:http"
                   NC:value="http">
    <NC:handlerProp RDF:resource="urn:scheme:handler:http"/>
  </RDF:Description>
  <RDF:Description RDF:about="urn:scheme:handler:ftp"
                   NC:alwaysAsk="false">
    <NC:externalApplication RDF:resource="urn:scheme:externalApplication:ftp"/>
  </RDF:Description>
  <RDF:Description RDF:about="urn:scheme:externalApplication:ftp"
                   NC:prettyName="xdg-open"
                   NC:path="/usr/local/bin/xdg-open" />
  <RDF:Description RDF:about="urn:scheme:ftp"
                   NC:value="ftp">
    <NC:handlerProp RDF:resource="urn:scheme:handler:ftp"/>
  </RDF:Description>
  <RDF:Seq RDF:about="urn:schemes:root">
    <RDF:li RDF:resource="urn:scheme:http"/>
    <RDF:li RDF:resource="urn:scheme:ftp"/>
    <RDF:li RDF:resource="urn:scheme:https"/>
  </RDF:Seq>
  <RDF:Seq RDF:about="urn:mimetypes:root">
    ${MIMETYPES_ROOT}
  </RDF:Seq>

$DESC_APPLICATION

$DESC_HANDLER

$EXT_APP


  <RDF:Description RDF:about="urn:scheme:externalApplication:http"
                   NC:prettyName="xdg-open"
                   NC:path="/usr/local/bin/xdg-open" />
  <RDF:Description RDF:about="urn:schemes">
    <NC:Protocol-Schemes RDF:resource="urn:schemes:root"/>
  </RDF:Description>
</RDF:RDF>
EOF

xquery version "3.0";
(:
  Edirom Online
  Copyright (C) 2011 The Edirom Project
  http://www.edirom.de

  Edirom Online is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Edirom Online is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Edirom Online.  If not, see <http://www.gnu.org/licenses/>.

  ID: $Id: util.xqm 1334 2012-06-14 12:40:33Z daniel $
:)

(:~
: This module provides library utility functions
:
: @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
: @author <a href="mailto:roewenstrunk@edirom.de">Nikolaos Beer</a>
: @author <a href="mailto:bohl@edirom.de">Benjamin W. Bohl</a>
:)

module namespace eutil = "http://www.edirom.de/xquery/util";

import module namespace work="http://www.edirom.de/xquery/work" at "work.xqm";
import module namespace source="http://www.edirom.de/xquery/source" at "source.xqm";
import module namespace teitext="http://www.edirom.de/xquery/teitext" at "teitext.xqm";
import module namespace edition="http://www.edirom.de/xquery/edition" at "../xqm/edition.xqm";
import module namespace functx = "http://www.functx.com" at "../xqm/functx-1.0-nodoc-2007-01.xq";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace edirom="http://www.edirom.de/ns/1.3";

(:~
: Returns a localized string
:
: @param $node The node to be processed
: @return The string
:)

declare function eutil:getLocalizedName($node, $lang) as xs:string {

    if ($node/mei:title)
    then (
        if ($lang = $node/mei:title/@xml:lang)
        then $node/mei:title[@xml:lang = $lang]/text()
        else $node/mei:title[1]/text()
    )
    else if ($node/mei:name)
    then (
        if ($lang = $node/mei:name/@xml:lang)
        then $node/mei:name[@xml:lang = $lang]/text()
        else $node/mei:name[1]/text()
    )
    else if ($node/edirom:names)
        then (
            if ($lang = $node/edirom:names/edirom:name/@xml:lang)
            then $node/edirom:names/edirom:name[@xml:lang = $lang]/node()
            else $node/edirom:names/edirom:name[1]/node()
    )
    else (normalize-space($node))
};

(:~
: Returns a document
:
: @param $uri The URIs of the documents to process
: @return The document
:)
declare function eutil:getDoc($uri) {

    if(starts-with($uri, 'textgrid:'))
    then(
        let $session := request:get-cookie-value('edirom_online_textgrid_sessionId')
        return
            doc('http://textgridlab.org/1.0/tgcrud/rest/' || $uri || '/data?sessionId=' || $session)
    )
    else(
        doc($uri)
    )
};

(:~
: Returns a comma separated list of document labels
:
: @param $docs The URIs of the documents to process
: @return The labels
:)
declare function eutil:getDocumentsLabels($docs as xs:string*, $edition as xs:string) as xs:string {

    string-join(
        eutil:getDocumentsLabelsAsArray($docs, $edition)
    , ', ')
};

(:~
: Returns an array of document labels
:
: @param $docs The URIs of the documents to process
: @return The labels
:)
declare function eutil:getDocumentsLabelsAsArray($docs as xs:string*, $edition as xs:string) as xs:string* {

    for $doc in $docs
    return
        eutil:getDocumentLabel($doc, $edition)
};

(:~
: Returns a document's label
:
: @param $doc The URIs of the document to process
: @return The label
:)
declare function eutil:getDocumentLabel($doc as xs:string, $edition as xs:string) as xs:string {
    
    if(work:isWork($doc))
    then(work:getLabel($doc, $edition))
    
    else if(source:isSource($doc))
    then(source:getLabel($doc, $edition))
    
    else if(teitext:isText($doc))
    then(teitext:getLabel($doc, $edition))

    else('')
};

(:~
: Returns a language specific string
:
: @param $key The key to search for
: @param $values The values to include into the string
: @return The string
:)
declare function eutil:getLanguageString($key as xs:string, $values as xs:string*) as xs:string {

    eutil:getLanguageString($key, $values, eutil:getLanguage(''))
};

(:~
: Returns a language specific string from the locale/edirom-lang files
:
: @param $key The key to search for
: @param $values The values to include into the string
: @param $lang The language 
: @return The string
:)
declare function eutil:getLanguageString($key as xs:string, $values as xs:string*, $lang as xs:string) as xs:string {

    let $base := system:get-module-load-path()
    let $file := doc(concat($base, '/../locale/edirom-lang-', $lang, '.xml'))
    
    let $string := $file//entry[@key = $key]/string(@value)
    let $string := functx:replace-multi($string, for $i in (0 to (count($values) - 1)) return concat('\{',$i,'\}'), $values)
                        
    return
        $string
};

(:~
: Return a value of preference to key 
:
: @param $key The key to search for
: @return The string
:)
declare function eutil:getPreference($key as xs:string, $edition as xs:string?) as xs:string {

     let $file := doc('../prefs/edirom-prefs.xml')
     let $projectFile := doc(edition:getPreferencesURI($edition))
     
     return    
        if($projectFile != 'null' and $projectFile//entry[@key = $key]) then ($projectFile//entry[@key = $key]/string(@value))
        else ($file//entry[@key = $key]/string(@value))
};

(:~
: Return the application and content language 
:
: @param $edition The edition's path
: @return The language key
:)
declare function eutil:getLanguage($edition as xs:string?) as xs:string {

     if(request:get-cookie-names() = 'edirom-language')
     then(
        request:get-cookie-value('edirom-language')
     )
     else(
         eutil:getPreference('application_language', $edition)
     )
};

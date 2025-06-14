xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides library utility functions
 :
 : @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
 : @author <a href="mailto:roewenstrunk@edirom.de">Nikolaos Beer</a>
 : @author <a href="mailto:bohl@edirom.de">Benjamin W. Bohl</a>
 :)

module namespace eutil = "http://www.edirom.de/xquery/eutil";

(: IMPORTS ================================================================= :)

import module namespace functx = "http://www.functx.com";

import module namespace annotation="http://www.edirom.de/xquery/annotation" at "annotation.xqm";
import module namespace edition="http://www.edirom.de/xquery/edition" at "edition.xqm";
import module namespace source="http://www.edirom.de/xquery/source" at "source.xqm";
import module namespace teitext="http://www.edirom.de/xquery/teitext" at "teitext.xqm";
import module namespace work="http://www.edirom.de/xquery/work" at "work.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace edirom="http://www.edirom.de/ns/1.3";
declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace system="http://exist-db.org/xquery/system";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace util="http://exist-db.org/xquery/util";

(: VARIABLE DECLARATIONS =================================================== :)

declare variable $eutil:lang := eutil:getLanguage(());
declare variable $eutil:langDoc := eutil:getDoc(concat('../locale/edirom-lang-', $eutil:lang, '.xml'));
 
(: FUNCTION DECLARATIONS =================================================== :)

(:~
 : Returns the namespace (standardized prefix)
 :
 : @param $node The node to be processed
 : @return The namespace (prefix)
 :)
declare function eutil:getNamespace($node as node()) as xs:string {

  switch (namespace-uri($node))
    case 'http://www.music-encoding.org/ns/mei'
        return 'mei'
    case 'http://www.tei-c.org/ns/1.0'
        return 'tei'
    case 'http://www.edirom.de/ns/1.3'
        return 'edirom'
    default
        return 'unknown'

};

(:~
 : Returns a localized string
 :
 : @param $node The node to be processed
 : @return The string
 :)
declare function eutil:getLocalizedName($node, $lang) {

    let $name :=
        if ($node/mei:title) then (
            if ($lang = $node/mei:title/@xml:lang) then
                $node/mei:title[@xml:lang = $lang]/text()
            else
                $node/mei:title[1]/text()
        
        ) else if ($node/mei:name) then (
            if ($lang = $node/mei:name/@xml:lang) then
                $node/mei:name[@xml:lang = $lang]/text()
            else
                $node/mei:name[1]/text()
        
        ) else if ($node/edirom:names) then (
            if ($lang = $node/edirom:names/edirom:name/@xml:lang) then
                $node/edirom:names/edirom:name[@xml:lang = $lang]/node()
            else
                $node/edirom:names/edirom:name[1]/node()
        
        ) else if (local-name($node) = 'annot' and $node/@type = 'editorialComment') then
            (annotation:generateTitle($node))
        
        else
        (normalize-space($node))
    
    return
        if($node/edirom:names) then
            ($name)
        else
            (eutil:joinAndNormalize($name))

};


(:~
 : Returns a localized string
 :
 : @param $node The node to be processed
 : @param $lang Optional parameter for lang selection
 : @return The string (normalized space)
 :)
declare function eutil:getLocalizedTitle($node as node(), $lang as xs:string?) as xs:string {

    eutil:getLocalizedTitle($node, $lang, eutil:getLanguageString('no_title', ()))

};

(:~
 : Returns a localized string
 :
 : @param $node The node to be processed
 : @param $lang Optional parameter for lang selection
 : @return The string (normalized space)
 :)
declare function eutil:getLocalizedTitle($node as node(), $lang as xs:string?, $default as xs:string) as xs:string {

    let $namespace := eutil:getNamespace($node)
  
    let $titleMEI :=
        if ($lang != '' and $lang = $node/mei:title[mei:titlePart]/@xml:lang) then
            (eutil:joinAndNormalize($node/mei:title[@xml:lang = $lang]/mei:titlePart, '. '))
        else if ($lang != '' and $lang = $node/mei:title[not(mei:titlePart)]/@xml:lang) then
            (eutil:joinAndNormalize($node/mei:title[@xml:lang = $lang]))
        else
            (eutil:joinAndNormalize(($node//mei:title)[1]))
    
    let $titleTEI :=
        if ($lang != '' and $lang = $node/tei:title/@xml:lang) then
            eutil:joinAndNormalize($node/tei:title[@xml:lang = $lang])
        else
            eutil:joinAndNormalize($node/tei:title[1])
    
    return
        if ($namespace = 'mei' and $titleMEI != '') then
            ($titleMEI)
        else if ($namespace = 'tei' and $titleTEI != '') then
            ($titleTEI)
        else 
            $default

};

(:~
 : Returns a document
 :
 : @param $uri The URIs of the documents to process
 : @return The document
 :)
declare function eutil:getDoc($uri as xs:string?) as document-node()? {
    if(empty($uri) or ($uri eq ""))
    then util:log("warn", "No document URI provided")
    else if(doc-available($uri))
    then doc($uri)
    else util:log("warn", "Unable to load document at " || $uri)
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

    if(work:isWork($doc)) then
        (work:getLabel($doc, $edition))
    
    else if(source:isSource($doc)) then
        (source:getLabel($doc, $edition))
    
    else if(teitext:isText($doc)) then
        (teitext:getLabel($doc, $edition))

    else
        ('')

};

(:~
 : Returns a part's label (translated if available)
 :
 : @author Dennis Ried
 : @param $partID The xml:id of the Part's node() to process
 : @return The label (translated if available)
 :)
declare function eutil:getPartLabel($measureOrPerfRes as node(), $type as xs:string) as xs:string {

    let $lang := $eutil:lang

    let $part := $measureOrPerfRes/ancestor::mei:part
    let $voiceRef := $part//mei:staffDef/@decls
    let $voiceID := substring-after($voiceRef, '#')

    let $perfResLabel :=
        if($type eq 'measure') then
            ($measureOrPerfRes/ancestor::mei:mei/id($voiceID)/@label)
        else
            ($measureOrPerfRes/@label)

    let $dictKey := 'perfMedium.perfRes.' || functx:substring-before-if-contains($perfResLabel,'.')

    let $label :=
        if(eutil:getLanguageString($dictKey, (), $lang)) then
            (eutil:getLanguageString($dictKey, (), $lang))
        else
            ($perfResLabel)

    let $numbering :=
        for $i in subsequence(tokenize($perfResLabel,'\.'),2)
        where matches($i, '([0-9])|([ivxIVX])')
        return
            upper-case($i)

    return
        eutil:joinAndNormalize(($label, $numbering))

};

(:~
 : Returns a language specific string
 :
 : @param $key The key to search for
 : @param $values The values to replace the placeholders with (from the language string)
 : @return The looked up language string from a language file
 :)
declare function eutil:getLanguageString($key as xs:string, $values as xs:string*) as xs:string? {

    eutil:getLanguageString($key, $values, $eutil:lang)

};

(:~
 : Returns a language specific string from the locale/edirom-lang files
 : NB, the project specific language dictionaries are not being queried here.
 : Please use the four-arity version for this!
 :
 : @param $key The key to search for
 : @param $values The values to replace the placeholders with (from the language string)
 : @param $lang The language code (e.g. "de" or "en")
 : @return The looked up language string from a language file
 :)
declare function eutil:getLanguageString($key as xs:string, $values as xs:string*, $lang as xs:string) as xs:string? {

    let $langString := $eutil:langDoc//entry[@key = $key]/string(@value)

    return
        if($langString) 
        (: replace placeholders in the language string with values provided to the function as parameter :)
        then functx:replace-multi($langString, for $i in (0 to (count($values) - 1)) return concat('\{',$i,'\}'), $values)
        else util:log('error', concat('Failed to find the key `', $key, '` in the Edirom default language file'))

};

(:~
 : Returns a language specific string from the locale/edirom-lang files or project specific language files.
 : The latter takes precedence.
 :
 : @param $edition The URI of the Edition's document to process
 : @param $key The key to search for
 : @param $values The values to replace the placeholders with (from the language string) 
 : @param $lang The language code (e.g. "de" or "en")
 : @return The looked up language string from a language file
 :)
declare function eutil:getLanguageString($edition as xs:string, $key as xs:string, $values as xs:string*, $lang as xs:string) as xs:string? {

    (: Try to load a custom language file :)
    let $langFileCustom := 
        try { doc(edition:getLanguageFileURI($edition, $lang)) }
        catch * { util:log-system-out('Failed to load the custom language file for edition "' || $edition || '"') }
    
    let $langString :=
        (: If there is a value for the key in the custom language file :)
        if($langFileCustom//entry/@key = $key) then
            $langFileCustom//entry[@key = $key]/@value => string()
        (: If not, take the value for the key in the default language file :)
        else
            $eutil:langDoc//entry[@key = $key]/@value => string()
    return
        if($langString) 
        (: replace placeholders in the language string with values provided to the function as parameter :)
        then functx:replace-multi($langString, for $i in (0 to (count($values) - 1)) return concat('\{',$i,'\}'), $values)
        else util:log('error', concat('Failed to find the key `', $key, '` in any language file'))
};

(:~
 : Returns a value from the preferences for a given key
 :
 : @param $key The key to look up
 : @param $edition The current edition URI
 : @return The preference value
 :)
declare function eutil:getPreference($key as xs:string, $edition as xs:string?) as xs:string? {

    (: Try to load a custom preferences file :)
    let $prefFileCustom := 
        try { doc(edition:getPreferencesURI($edition)) }
        catch * { util:log-system-out('Failed to load the custom preferences file') }
    
    return
        (: If there is a value for the key in the custom preferences file :)
        if($prefFileCustom//entry/@key = $key) then
            $prefFileCustom//entry[@key = $key]/@value => string()
        (: If not, take the value for the key in the default preferences file :)
        else
            try { doc($edition:default-prefs-location)//entry[@key = $key]/@value => string() }
            (: If the key is not in the default file, then there should be an error :)
            catch * { util:log-system-out(concat('Failed to find the key `', $key, '` in default preferences file')) }
};

(:~
 : Return the application and content language
 :
 : @param $edition The edition's path
 : @return The language key
 :)
declare function eutil:getLanguage($edition as xs:string?) as xs:string {
    
    if (request:get-parameter("lang", "") != "") then
        request:get-parameter("lang", "")
    else if(eutil:getPreference('application_language', edition:getEditionURI($edition))) then
        eutil:getPreference('application_language', edition:getEditionURI($edition))
    else    
        'de'
};

(:~
 : Returns the application base URL as seen from the client
 :
 : NB, this is a relative path on the server, missing the scheme,
 : as well as the server address and port.
 : This function simply concats the current context path with the
 : eXist variables `$exist:prefix` and `$exist:controller`
 : (see https://exist-db.org/exist/apps/doc/urlrewrite)
 :
 : @return a relative path on the server
 :)
declare function eutil:get-app-base-url() as xs:string? {

    if(request:exists()) then
        request:get-context-path() || request:get-attribute("exist:prefix") || request:get-attribute('exist:controller')
    else
        util:log-system-out('request object does not exist; failing to compute base url')
};

(:~
 : Sorts a sequence of numeric-alpha values or nodes (e.g. 1, 1a, 1b, 2) 
 : This is an adaption of functx:sort-as-numeric()
 :
 : @author  Dennis Ried
 : @see     http://www.xqueryfunctions.com/xq/functx_sort-as-numeric.html 
 : @param   $seq the sequence to sort 
 :)
declare function eutil:sort-as-numeric-alpha($seq as item()* )  as item()* {

   for $item in $seq
   let $itemPart1 := (functx:get-matches($item, '\d+'))[1]
   let $itemPart2 := substring-after($item, $itemPart1)
   order by number($itemPart1), $itemPart2
   return $item

} ;

(:~
 : Extracts an ISO 639 language code from a given ISO 3166-1 language code
 :
 : @author Benjamin W. Bohl
 : @param  $iso3166-1 xs:string the given ISO 3166-1 language code, e.g., en-US
 : @return xs:string ISO 639 language code, e.g., en
 :)
declare function eutil:iso3166-1-to-iso639($iso3166-1 as xs:string) as xs:string {

    tokenize($iso3166-1, "-")[1]

};

(:~
 : Returns the ISO 639 language code with the highest 'quality' (none considered as 1) from
 : the HTTP-request Accept-Language header
 :
 : @author Benjamin W. Bohl
 : @return xs:string ISO 639 language code
 :)
declare function eutil:request-lang-preferred-iso639() as xs:string {

    let $request.accept-language := request:get-header("Accept-Language")
    return
        if($request.accept-language) then
            let $tokens := tokenize($request.accept-language, ";")
            
            let $tokens.qless.ordered := (
                for $token in $tokens
                let $q := substring-after(string-join((analyze-string($token, "(q=\d(\.\d)?)")//fn:match)[1], ""), "q=")
                let $q.decimal := if($q = "") then xs:decimal(1) else xs:decimal($q)
                let $token.qless := replace($token,",?q=\d(\.\d)?,?", "")
                order by $q.decimal descending
                return
                    $token.qless
            )
            
            let $tokens.qmax := $tokens.qless.ordered[1]
            let $tokens.qmax.first := tokenize($tokens.qmax, ",")[1]
            return 
                eutil:iso3166-1-to-iso639($tokens.qmax.first)
        
        else
            "en"

};

(:~
 : Returns one joined and normalized string
 :
 : @param $strings The string(s) to be processed
 : @return The string (joined with whitespace and normalized space)
 :)
declare function eutil:joinAndNormalize($strings as xs:string*) as xs:string {
    $strings => string-join(' ') => normalize-space()
};

(:~
 : Returns one joined and normalized string
 :
 : @param $strings The string(s) to be processed
 : @param $separator One ore more characters as separators for joining the string
 : @return The string (joined and normalized space)
 :)
declare function eutil:joinAndNormalize($strings as xs:string*, $separator as xs:string) as xs:string {
    $strings => string-join($separator) => normalize-space()
};
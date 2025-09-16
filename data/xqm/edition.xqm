xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(:~
 : This module provides library functions for Editions
 :
 : @author <a href="mailto:roewenstrunk@edirom.de">Daniel Röwenstrunk</a>
 :)
module namespace edition = "http://www.edirom.de/xquery/edition";

(: IMPORTS ================================================================= :)

import module namespace functx="http://www.functx.com";

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace edirom = "http://www.edirom.de/ns/1.3";
declare namespace util = "http://exist-db.org/xquery/util";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(: FUNCTION DECLARATIONS =================================================== :)


(:~
 : Returns a map object with details about an Edition
 :
 : @param $uri The URI of the Edition's document to process
 : @return a map object with the keys "id", "doc", and "name" 
 :)
declare function edition:details($uri as xs:string) as map(*) {
    
    let $edition := doc($uri)/edirom:edition
    return
        map {
            "id": $edition/string(@xml:id),
            "doc": $uri,
            "name": $edition/edirom:editionName => fn:normalize-space(),
            "additional_css_path": edition:getPreference('additional_css_path', $uri),
            "languages": edition:getLanguageCodesSorted($uri)
        }
};

(:~
 : Returns a list of objects with details about all Editions 
 :
 :)
 declare
    %rest:GET
    %rest:path("/editions")
    %rest:produces("application/json") 
    %output:media-type("application/json")
    %output:method("json")
 function edition:findEditions() {
    
    let $editionURIs := edition:findEditionUris()
    for $edition in $editionURIs
    return
        edition:details($edition)
};
 

(:~
 : Returns a list of URIs pointing to Editions
 :
 : @return The list of URIs
 :)
declare function edition:findEditionUris() as xs:string* {
    
    for $edition in collection('/db/apps')/edirom:edition
    let $document-uri := document-uri($edition/root())
    (: exclude editions found within the testing collection :)
    where not(contains($document-uri, 'testing/XQSuite/data'))
    return
        'xmldb:exist://' || $document-uri
};

(:~
 : Returns a list of URIs pointing to referenced Works
 :
 : @param $uri The URI of the Edition's document to process
 : @return The list of URIs
 :)
declare function edition:getWorkUris($uri as xs:string) as xs:string* {
    
    doc($uri)//edirom:work/@xlink:href ! string(.)
};

(:~
 : Returns the URI for a specific language file
 :
 : @param $uri The URI of the Edition's document to process
 : @param $lang The language
 : @return The URI
 :)
declare function edition:getLanguageFileURI($uri as xs:string, $lang as xs:string) as xs:string {

    let $doc := edition:getEditionURI($uri) => eutil:getDoc()
    return
        if ($doc//edirom:language[@xml:lang eq $lang]/@xlink:href => string() != "") then
            $doc//edirom:language[@xml:lang eq $lang]/@xlink:href => string()
        else
            ""
};

(:~
 : Returns the URI for a specific language file
 :
 : @param $uri The URI of the Edition's document to process
 : @return the edition's languages as defined in the edition file sorted as
 : complete languages in document-order followed by incomplete langauges in document-order
 :)
declare function edition:getLanguageCodesSorted($uri as xs:string) as xs:string* {
    
    let $languages := doc($uri)//edirom:language

    return
        (
            $languages[@complete eq 'true']/@xml:lang ,
            $languages[@complete eq 'false']/@xml:lang ,
            $languages[exists(@complete) and not(@complete eq 'true' or @complete eq 'false')]/@xml:lang ,
            $languages[not(@complete)]/@xml:lang
        )[. ne ""]
};

(:~
 : Return the application and content language
 :
 : @param $edition The edition's path
 : @return The language key
 :)
declare function edition:getLanguage($edition as xs:string?) as xs:string {
    
    if (request:get-parameter("lang", "") != "") then
        request:get-parameter("lang", "")
    else if(edition:getPreference('application_language', edition:getEditionURI($edition))) then
        edition:getPreference('application_language', edition:getEditionURI($edition))
    else    
        'de'
};

(:~
 : Returns the URI of the preferences file for a given edition
 :
 : @param $uri The URI of the Edition's document to process
 : @return The URI of the edition's preference file or the default edirom preferences as fallback
 :)
declare function edition:getPreferencesURI($uri as xs:string?) as xs:string {
    if(doc-available($uri) and doc($uri)//edirom:preferences/@xlink:href => string()) 
    then(doc($uri)//edirom:preferences/@xlink:href => string()) 
    else $eutil:default-prefs-location
};

(:~
 : Returns a value from the preferences for a given key
 :
 : @param $key The key to look up
 : @param $edition The current edition URI
 : @return The preference value
 :)
declare function edition:getPreference($key as xs:string, $edition as xs:string?) as xs:string? {

    eutil:getPreference($key, edition:getPreferencesURI($edition))
};

(:~
 : Returns the URI of the edition specified by the submitted $editionIDorPath parameter.
 :
 : @param $editionIDorPath The '@xml:id' of or the database path to the edirom:edition document to process
 : @return The URI of the Edition file
 :)
declare function edition:getEditionURI($editionIDorPath as xs:string?) as xs:string? {
    (: $editionID is the empty sequence or the empty string :)
    if(not($editionIDorPath))
    then ()

    (: $editionID is a resolvable file path with an edirom:edition root element :)
    else if(doc-available($editionIDorPath))
    then doc($editionIDorPath)/edirom:edition ! concat('xmldb:exist://', document-uri(./root()))

    (: $editionID is a resolvable xml:id that points at an edirom:edition :)
    (: since there are potentially multiple documents with the same xml:id we fall back to returning only the first one :)
    else if (collection('/db/apps')/id($editionIDorPath)/self::edirom:edition)
    then (collection('/db/apps')/id($editionIDorPath)/self::edirom:edition)[1] ! concat('xmldb:exist://', document-uri(./root()))

    (: for everything else the empty sequence will be returned :)
    else ()
};

(:~
 : Returns the name of the edition specified by $uri
 : This is a shortcut function for `edition:details($uri)?name`
 : and might get deprecated in the future.
 :
 : @param $uri The URI of the Edition's document to process
 : @return the text contents of edirom:edition/edirom:editionName
 :)
declare function edition:getName($uri as xs:string) as xs:string {
    edition:details($uri)?name
};

(:~
 : Returns the frontend URI of the edition, e.g. if the edirom:edition file
 : submitted via $editionUri is xmldb:exist///db/apps/editionFolder/edition.xml
 : and the $contextPath is /exist the string returned would be /exist/apps/editionFolder
 :
 : @param $editionUri The URI of the Edition's document to process
 : @param $contextPath The request:get-context-path() of the frontend
 : @return The frontend URI of the edition
 :)
declare function edition:getFrontendUri($editionUri as xs:string, $contextPath as xs:string) as xs:string {

    let $editionContext := functx:substring-before-last(substring-after($editionUri, 'xmldb:exist:///db/'), '/')

    return
        string-join(($contextPath, $editionContext), '/')
};

(:~
 : Returns the documents contained in the collection specified by the
 : `edition_path` parameter in the edition's preference file.
 : If `$editionUri` is the empty sequence or no information is found
 : for `edition_path`, the empty sequence is returned.
 :
 : @param $edition The URI of the Edition's document to process
 : @return The document nodes contained in or under the given collection
 :)
declare function edition:collection($editionUri as xs:string?) as document-node()* {
    if($editionUri and edition:getPreference('edition_path', $editionUri))
    then collection(edition:getPreference('edition_path', $editionUri))
    else util:log('warn', 'No edition provided')
};

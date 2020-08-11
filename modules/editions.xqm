xquery version "3.1";

module namespace editions="https://backend.edirom.de/editions";

declare namespace edirom="http://www.edirom.de/ns/1.3";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";
declare namespace xlink="http://www.w3.org/1999/xlink";

import module namespace config="https://backend.edirom.de/config" at "config.xqm";
import module namespace commons="https://backend.edirom.de/commons" at "commons.xqm";
import module namespace utils="https://backend.edirom.de/utils" at "utils.xqm";

declare
    %rest:GET
    %rest:path("/editions")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
    function editions:editions-json() {
        let $editions := for $edition in collection('/db/apps')//edirom:edition
                            return editions:editionToJson($edition)
        let $edition-json := array { $editions }
        return (
            $commons:response-headers,
            $edition-json
        )
};

declare
    %rest:GET
    %rest:path("/editions/{$editionID}")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
    function editions:editionsID-json($editionID as xs:string) {
        let $edition := collection('/db/apps')//edirom:edition[@xml:id eq $editionID]
        let $edition-json := editions:editionToJson($edition)
        return (
            $commons:response-headers,
            $edition-json
        )
};

declare
    %rest:GET
    %rest:path("/getDefaultEdition")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
    function editions:getDefaultEdition-json() {
        let $uri := config:get-conf-entry("EDITION_URI")
        let $edition := if(doc($uri)) 
                        then(
                            doc($uri)/edirom:edition
                        )else (
                            editions:findEdition()
                        )
        let $edition-json := editions:editionToJson($edition)
              
        return (
            $commons:response-headers,
            $edition-json
        )   
};

declare %private function editions:editionToJson($edition as element(edirom:edition)) as map() {
    map {
        'editionID': editions:title($edition),
        'title': $edition/data(@xml:id),
        'uri': utils:uri($edition),
        'preferencesURI': editions:preferencesURI($edition),
        'languages': editions:languages($edition)
    }
};

declare %private function editions:title($edition as element(edirom:edition)) as xs:string {
    $edition/edirom:editionName[1] => normalize-space() 
};

declare %private function editions:preferencesURI($edition as element(edirom:edition)) as xs:string {
    if($edition/edirom:preferences and $edition/edirom:preferences/@xlink:href)
    then($edition/edirom:preferences/string(@xlink:href))
    else('')
};

declare %private function editions:languages($edition as element(edirom:edition)) {
     array {
        for $language in $edition/edirom:languages/edirom:language
        return editions:language($language)
     }
};

declare %private function editions:language($language as element(edirom:language)) as map() {
     map {
        'langCode': $language/string(@xml:lang),
        'complete': if($language/@complete eq 'true')then(true())else(false()),
        'uri': if($language/@xlink:href)then($language/string(@xlink:href))else('')
    }
};


(:~
: Returns the URI of the first found Edition
:
: @return The URI
:)
declare %private function editions:findEdition() as xs:string {
    let $edition := (collection('/db/apps')//edirom:edition)[1]
    return utils:uri($edition)
};



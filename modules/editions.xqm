xquery version "3.1";

module namespace editions="https://backend.edirom.de/editions";

declare namespace edirom="http://www.edirom.de/ns/1.3";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest="http://exquery.org/ns/restxq";
declare namespace map="http://www.w3.org/2005/xpath-functions/map";

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
        let $editions := '[{"editionID": "edition-45346", "title": "Freischütz Digital", "uri": "xmldb:exist:///db/apps/freidi/edition/freidi-edition.xml"}]'
        return (
            commons:set-response-header($commons:response-headers),
            $editions
        )
};

declare
    %rest:GET
    %rest:path("/editions/{$editionID}")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
    function editions:editionsID-json($editionID as xs:string) {
        let $edition := '{"editionID": "edition-45346", "title": "Freischütz Digital", "uri": "xmldb:exist:///db/apps/freidi/edition/freidi-edition.xml"}'
        return (
            $commons:response-headers,
            $edition
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
        let $edition := editions:editionToJson(doc($uri)/edirom:edition)
        return (
            $commons:response-headers,
            $edition
        )
};

declare %private function editions:editionToJson($edition as element(edirom:edition)) as map() {
    map {
        'editionID': editions:title($edition),
        'title': $edition/data(@xml:id),
        'uri': utils:uri($edition)
    }
};

declare %private function editions:title($edition as element(edirom:edition)) as xs:string {
    $edition/edirom:editionName[1] => normalize-space() 
};





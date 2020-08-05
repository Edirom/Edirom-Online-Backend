xquery version "3.1";

module namespace commons="https://backend.edirom.de/commons";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace http="http://expath.org/ns/http-client";
declare namespace rest="http://exquery.org/ns/restxq";

import module namespace config="https://backend.edirom.de/config" at "config.xqm";

declare variable $commons:response-headers := 
    <rest:response>
        <http:response>
            <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
    </rest:response>;

declare function commons:set-status($response-headers as element(rest:response), $status as xs:integer) as element(rest:response) {
    element {$response-headers/name()} {
        $response-headers/@*,
        element {$response-headers/http:response/name()} {
            $response-headers/http:response/@* except $response-headers/http:response/@status,
            attribute status {
                $status
            },
            $response-headers/http:response/*
        }
    }
};

(:~
 : index.html file
 :)
declare
    %rest:GET
    %rest:path("/index.html")
    %rest:produces("text/html")
    %output:media-type("text/html")
    %output:method("html")
    function commons:index-html() {
        $commons:response-headers,
        doc($config:app-root || '/index.html')
};

(:~
 : swagger.json file
 :)
declare
    %rest:GET
    %rest:path("/swagger.json")
    %rest:produces("application/json")
    %output:media-type("application/json")
    %output:method("json")
    function commons:swagger-config() {
        $commons:response-headers,
        json-doc($config:app-root || '/swagger.json')
};


xquery version "3.1";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config="https://backend.edirom.de/config";

declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace util="http://exist-db.org/xquery/util";
import module namespace json="http://www.json.org";
import module namespace functx="http://www.functx.com";
import module namespace xmldb="http://exist-db.org/xquery/xmldb";

(: 
    Determine the application root collection from the current module load path.
:)
declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
;

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

declare variable $config:swagger-config-path := $config:app-root || "/swagger.json";

declare variable $config:config-path := $config:app-root || "/conf.json";

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
    $config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
    $config:expath-descriptor
};

(:~
 : Returns the default user for new data 
 :)
declare function config:app-default-user($repo-descriptor as element(repo:meta)?) as xs:string {
    if ($repo-descriptor/repo:permissions[@user]) then $repo-descriptor/repo:permissions/data(@user)
    else 'guest'
};

(:~
 : Returns the default group for new data 
 :)
declare function config:app-default-group($repo-descriptor as element(repo:meta)?) as xs:string {
    if ($repo-descriptor/repo:permissions[@group]) then $repo-descriptor/repo:permissions/data(@group)
    else 'guest'
};

declare function config:app-title($node as node(), $model as map(*)) as text() {
    $config:expath-descriptor/expath:title/text()
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
    <meta xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$author/text()}"/>
};

declare function config:get-max-limit() as xs:positiveInteger {
    try { json-doc($config:swagger-config-path)?parameters?limitParam?maximum cast as xs:positiveInteger }
    catch * { util:log-system-out('error reading maximum limit, defaulting to 200'), 200 }
};

declare function config:get-conf-entry($key as xs:string) as xs:string {
    try { json-doc($config:config-path)?data($key) cast as xs:string }
    catch * { util:log-system-out('error reading conf entry: ' + $key), "" }
};

(:~
 : set option from environment variable
 : NB: You have to be logged in as admin to be able to update preferences!
 :
 : @param $key a sequence of keys navigating to the object; 
 :  e.g. the sequence ('foo', 'bar') will select the object 'bar' within the object 'foo'. 
 :  Non existing keys will be added, existing keys will be updated
 : @param $value the value of the new or updated key. 
 :  String values will be parsed as JSON, so you can pass objects or arrays via
 :  environment variables. NB: JSON strings need to be wrapped in double quotes!  
 : @return the new value if successful, the empty sequence otherwise
 :)
declare function config:set-option($key as xs:string*, $value as item()?) as item()? {
    let $optionsFile := fn:json-doc($config:config-path)
    let $valueJSON := 
        typeswitch($value)
        case xs:string return
            try { parse-json($value) }
            catch * { $value } (: parse-json() fails for simple string values  :)
        case node() return parse-json(json:xml-to-json($value)) (: the output of json:xml-to-json() seems to be a string, not a map object :)
        case array(*) return $value
        case map(*) return $value
        default return error('config:set-option(): failed to convert value of ' || string-join($key, '.') || ' to a JSON object.')
    let $update := config:map-put-recursive($optionsFile, $key, $valueJSON)
    let $serialize-json := function($json as item()) as xs:string {
        serialize($json, <output:serialization-parameters><output:method>json</output:method></output:serialization-parameters>)
    }
    let $update2string := $serialize-json($update)
    let $fileName := functx:substring-after-last($config:config-path, '/')
    let $collection := functx:substring-before-last($config:config-path, '/')
    let $update := 
        try { 
            xmldb:store($collection, $fileName, $update2string, 'application/json'),
            util:log-system-out('set option "' || string-join($key, '.') || '" to "' || $serialize-json($valueJSON) || '"')
        }
        catch * { error('config:set-option(): failed to set option "' || string-join($key, '.') || '" to "' || $serialize-json($valueJSON) || '" -- Error was ' || string-join(($err:code, $err:description), ' ;; ')) }
    return
        if($update) then $valueJSON
        else ()
};

(:~
 : set/update object in swagger.json description.
 : NB: You have to be logged in as admin to be able to update preferences!
 :
 : @param $key a sequence of keys navigating to the object; 
 :  e.g. the sequence ('foo', 'bar') will select the object 'bar' within the object 'foo'. 
 :  Non existing keys will be added, existing keys will be updated
 : @param $value the value of the new or updated key. 
 :  String values will be parsed as JSON, so you can pass objects or arrays via
 :  environment variables. NB: JSON strings need to be wrapped in double quotes!  
 : @return the new value if successful, the empty sequence otherwise
 :)
declare function config:set-swagger-option($key as xs:string*, $value as item()?) as item()? {
    let $swagger.json := fn:json-doc($config:swagger-config-path)
    let $valueJSON := 
        typeswitch($value)
        case xs:string return
            try { parse-json($value) }
            catch * { $value } (: parse-json() fails for simple string values  :)
        case node() return parse-json(json:xml-to-json($value)) (: the output of json:xml-to-json() seems to be a string, not a map object :)
        case array(*) return $value
        case map(*) return $value
        default return error('config:set-swagger-option(): failed to convert value of ' || string-join($key, '.') || ' to a JSON object.')
    let $update := config:map-put-recursive($swagger.json, $key, $valueJSON)
    let $serialize-json := function($json as item()) as xs:string {
        serialize($json, <output:serialization-parameters><output:method>json</output:method></output:serialization-parameters>)
    }
    let $update2string := $serialize-json($update)
    let $fileName := functx:substring-after-last($config:swagger-config-path, '/')
    let $collection := functx:substring-before-last($config:swagger-config-path, '/')
    let $update := 
        try { 
            xmldb:store($collection, $fileName, $update2string, 'application/json'),
            util:log-system-out('set swagger option "' || string-join($key, '.') || '" to "' || $serialize-json($valueJSON) || '"')
        }
        catch * { error('config:set-swagger-option(): failed to set swagger option "' || string-join($key, '.') || '" to "' || $serialize-json($valueJSON) || '" -- Error was ' || string-join(($err:code, $err:description), ' ;; ')) }
    return
        if($update) then $valueJSON
        else ()
};

(:~
 : Recursively walk through a map object and update map objects therein.
 : Helper function for config:set-swagger-option()
 :)
declare %private function config:map-put-recursive($map as map(*), $key as xs:string+, $value as item()*) as map(*) {
    if(count($key) eq 1) 
    then map:put($map, $key, $value)
    else if(map:contains($map, $key[1]) and $map($key[1]) instance of map())
    then
        map:put(
            $map,
            $key[1],
            config:map-put-recursive($map($key[1]), subsequence($key, 2), $value)
        )
    else 
        map:put(
            $map,
            $key[1],
            config:map-put-recursive(map {}, subsequence($key, 2), $value)
        )
};


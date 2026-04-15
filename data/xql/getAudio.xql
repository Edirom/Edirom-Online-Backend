xquery version "3.1";
(:
 : For LICENSE-Details please refer to the LICENSE file in the root directory of this repository.
 :)

(: IMPORTS ================================================================= :)

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "../xqm/eutil.xqm";

(: NAMESPACE DECLARATIONS ================================================== :)

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace request = "http://exist-db.org/xquery/request";


(: OPTION DECLARATIONS ===================================================== :)

declare option output:method "json";
declare option output:media-type "application/json";


(: QUERY BODY ============================================================== :)

(: Query parameter :)
let $uri := request:get-parameter('uri', '')

(: Load MEI document :)
let $docUri :=
    if (contains($uri, '#')) then
        (substring-before($uri, '#'))
    else
        ($uri)
let $doc := eutil:getDoc($docUri)

(: Extract relevant information :)
let $artist := $doc//mei:titleStmt/mei:respStmt/mei:persName[@role = 'artist']
let $album := $doc//mei:meiHead/mei:fileDesc/mei:sourceDesc/mei:source[1]/mei:titleStmt/mei:title[1]/text()
let $albumCover := $doc//mei:graphic[@type = 'cover']/string(@target)

(: Build records objects :)
let $records :=
    for $rec in $doc//mei:recording
        let $recSource := $doc//mei:source[@xml:id = substring-after($rec/@decls, '#')]
        let $recTitle := $recSource/mei:titleStmt/string-join(mei:title, '; ')
        let $avFile := $rec/mei:avFile[1]/string(@target)
        let $avType := $rec/mei:avFile[1]/string(@mimetype)
        return
            map {
                'title': replace($recTitle, '"', '\\"'),
                'composer': replace($artist, '"', '\\"'),
                "work": replace($album, '"', '\\"'),
                "src": $avFile,
                (: "cover": $albumCover, :)
                "type": $avType
            }

(: Build and return result object :)
let $result :=
   map {
       'audios': array {$records},
       'success': true(),
       'total': count($records)
   }

return
    $result

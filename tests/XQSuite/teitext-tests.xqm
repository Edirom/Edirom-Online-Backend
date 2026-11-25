xquery version "3.1";

(:~
 : XQSuite tests for the text helper functions in data/xqm/teitext.xqm.
 :)
module namespace ttt = "http://www.edirom.de/xquery/xqsuite/teitext-tests";

import module namespace teitext = "http://www.edirom.de/xquery/teitext" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/teitext.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

(: teitext:getChapterName ================================================== :)

declare
    (: Chapter number and heading whitespace are included and normalized. :)
    %test:arg("containerXml", "<div xmlns='http://www.tei-c.org/ns/1.0' type='chapter' n='2'><head>  First   chapter </head></div>")
    %test:arg("target", "chapter")
    %test:assertEquals("2: First chapter")
    (: Fallback text nodes are joined and normalized. :)
    %test:arg("containerXml", "<div xmlns='http://www.tei-c.org/ns/1.0' type='chapter'> First <hi>ignored</hi> chapter </div>")
    %test:arg("target", "chapter")
    %test:assertEquals("First chapter")
    (: Numbered milestones use the No. prefix. :)
    %test:arg("containerXml", "<milestone xmlns='http://www.tei-c.org/ns/1.0' unit='number' n='12'/>")
    %test:arg("target", "milestone")
    %test:assertEquals("No. 12")
    (: Scene names include the Roman numeral of their containing act. :)
    %test:arg("containerXml", "<div xmlns='http://www.tei-c.org/ns/1.0' type='act' n='2'><div type='scene'><head>Opening</head></div></div>")
    %test:arg("target", "scene")
    %test:assertEquals("II - Opening")
    function ttt:test-getChapterName($containerXml as xs:string, $target as xs:string) as xs:string {
        let $container := parse-xml($containerXml)/*
        let $elem :=
            if ($target eq 'scene') then
                $container//tei:div[@type = 'scene']
            else
                $container
        return teitext:getChapterName($elem)
};

(: teitext:getChapterPageId =============================================== :)

declare
    (: Page mode extracts the fragment from the nearest preceding page break. :)
    %test:arg("teiXml", "<TEI xmlns='http://www.tei-c.org/ns/1.0'><text><body><pb facs='#page-1'/><div type='chapter'/></body></text></TEI>")
    %test:arg("mode", "pageMode")
    %test:assertEquals("page-1")
    (: Other modes return the sentinel page identifier. :)
    %test:arg("teiXml", "<TEI xmlns='http://www.tei-c.org/ns/1.0'><text><body><pb facs='#page-1'/><div type='chapter'/></body></text></TEI>")
    %test:arg("mode", "chapterMode")
    %test:assertEquals("-1")
    function ttt:test-getChapterPageId($teiXml as xs:string, $mode as xs:string) as xs:string {
        let $tei := parse-xml($teiXml)/*
        return teitext:getChapterPageId($tei//tei:div[@type = 'chapter'], $mode)
};

xquery version "3.1";

module namespace lt = "http://www.edirom.de/xquery/xqsuite/linktarget-tests";

import module namespace linktarget = "http://www.edirom.de/xquery/linktarget" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/linktarget.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";

declare variable $lt:document-uri := "xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/tei-document.xml";

declare
    (: the enabled preference keeps the metadata tab available :)
    %test:args("xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/edition-metadata-enabled.xml")
    %test:assertTrue
    (: an edition override of false hides the metadata tab :)
    %test:args("xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/edition-metadata-disabled.xml")
    %test:assertFalse
    function lt:test-metadata-view-preference($editionUri as xs:string) as xs:boolean {
        let $views := linktarget:getViews('text', $lt:document-uri, doc($lt:document-uri), 'en', $editionUri)
        return exists($views[?type eq 'headerView'])
    };

declare
    %test:assertFalse
    function lt:test-html-document-has-no-header-view() as xs:boolean {
        let $htmlDoc := document { <html><head/><body/></html> }
        let $views := linktarget:getViews(
            'html',
            'plain.html',
            $htmlDoc,
            'en',
            'xmldb:exist:///db/apps/Edirom-Online-Backend/tests/XQSuite/data/edition-metadata-enabled.xml'
        )
        return exists($views[?type eq 'headerView'])
    };

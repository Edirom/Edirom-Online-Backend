xquery version "3.1";

module namespace eut = "http://www.edirom.de/xquery/xqsuite/eutil-tests";

import module namespace eutil = "http://www.edirom.de/xquery/eutil" at "xmldb:exist:///db/apps/Edirom-Online-Backend/data/xqm/eutil.xqm";

declare namespace mei="http://www.music-encoding.org/ns/mei";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace edirom="http://www.edirom.de/ns/1.3";


declare 
    %test:args("<title xmlns='http://www.tei-c.org/ns/1.0' 
        type='main'>Some Title</title>")            %test:assertEquals("tei")
    %test:args("<render xmlns='http://www.music-encoding.org/ns/mei' 
        xmlns:mei='http://www.music-encoding.org/ns/mei'><mei:render>
        nested</mei:render> render</render>")       %test:assertEquals("mei")
    %test:args("<xhtml:span xmlns:xhtml='http://www.w3.org/1999/xhtml' 
        class='author'>Johann Evangelist Engl</xhtml:span>")     %test:assertEquals("unknown")
    function eut:test-getNamespace($node as element()) as xs:string {
        eutil:getNamespace($node)
};

declare 
    %test:args("<titleStmt xmlns='http://www.tei-c.org/ns/1.0'><?prüfen?><title type='abbreviated'>
        <identifier>P1-PA<rend rend='sup'>1</rend></identifier> – Autographe Partitur</title>
        <title type='main'>Autographe Partitur</title>
        <title type='sub'>Manifestation</title></titleStmt>", 
        "de")       %test:assertEquals("P1-PA1 – Autographe Partitur")
    %test:args("<titleStmt xmlns='http://www.tei-c.org/ns/1.0'>
        <title type='main'>Autographe Partitur</title>
        <title type='sub'>Manifestation</title></titleStmt>", 
        "de")       %test:assertEquals("Autographe Partitur")
    %test:args("<titleStmt xmlns='http://www.tei-c.org/ns/1.0'>
        <title type='main'>Autographe Partitur</title></titleStmt>", 
        "de")       %test:assertEquals("Autographe Partitur")
    function eut:test-getLocalizedTitle($node as element(), $lang as xs:string?) as xs:string {
        eutil:getLocalizedTitle($node, $lang)
};

declare
    %test:arg("uri")                %test:assertEmpty
    %test:arg("uri", "")            %test:assertEmpty
    %test:args("foo")               %test:assertEmpty
    %test:args("https://edirom.de") %test:assertXPath("/html")
    %test:args("xmldb:exist://db/apps/Edirom-Online-Backend/data/locale/edirom-lang-de.xml")    %test:assertXPath("/langFile")
    %test:args("/db/apps/Edirom-Online-Backend/data/locale/edirom-lang-de.xml")                 %test:assertXPath("/langFile")
    function eut:test-getDoc($uri as xs:string?) as document-node()? {
        eutil:getDoc($uri)
};

declare 
    (: Test empty replacements with non-existing key :)
    %test:arg("key", "foo1g4#")
    %test:arg("values") 
    %test:arg("lang", "de") %test:assertEmpty
    (: Test empty replacements with existing key :)
    %test:arg("key", "view.desktop.Desktop_Maximize")
    %test:arg("values") 
    %test:arg("lang", "de") %test:assertEquals("Maximieren")
    (: Test empty replacements with existing key in another language :)
    %test:arg("key", "view.desktop.Desktop_Maximize")
    %test:arg("values") 
    %test:arg("lang", "en") %test:assertEquals("Maximize")
    (: Test replacements with existing key :)
    %test:args("view.desktop.TaskBar_Desktop", "5", "de") %test:assertEquals("Desktop 5")
    (: Test replacements with existing key in another language :)
    %test:args("view.desktop.TaskBar_Desktop", "foo", "en") %test:assertEquals("Desktop foo")
    (: Test replacements with existing key without placeholders :)
    %test:args("view.desktop.Desktop_Maximize", "foo", "de") %test:assertEquals("Maximieren")
    (: Test replacements with existing key and non-existing language :)
    %test:args("view.desktop.Desktop_Maximize", "foo", "foo1g4#lang") %test:assertEmpty
    (: Test empty replacements with non-existing key and non-existing language :)
    %test:arg("key", "foo1g4#")
    %test:arg("values") 
    %test:arg("lang", "foo1g4#lang") %test:assertEmpty
    function eut:test-getLanguageString-3-arity($key as xs:string, $values as xs:string*, $lang as xs:string) as xs:string? {
        eutil:getLanguageString($key, $values, $lang)
};

declare 
    (: Test empty replacements with non-existing key :)
    %test:arg("langFileURI", "xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-de.xml")
    %test:arg("key", "foo1g4#")
    %test:arg("values") 
    %test:arg("lang", "de") %test:assertEmpty
    (: Test empty replacements with existing key :)
    %test:arg("langFileURI", "xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-de.xml")
    %test:arg("key", "global_cancel")
    %test:arg("values") 
    %test:arg("lang", "de") %test:assertEquals("Test-Abbrechen")
    (: Test empty replacements with existing key in another language :)
    %test:arg("langFileURI", "xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-it.xml")
    %test:arg("key", "global_cancel")
    %test:arg("values") 
    %test:arg("lang", "it") %test:assertEquals("Test-it-Abbrechen")
    (: Test replacements with existing key :)
    %test:args("xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-de.xml", "view.desktop.TaskBar_Desktop", "5", "de") %test:assertEquals("Test-Desktop 5")
    (: Test replacements with existing key in another language :)
    %test:args("xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-it.xml", "view.desktop.TaskBar_Desktop", "foo", "it") %test:assertEquals("Test-it-Desktop foo")
    (: Test replacements with existing key without placeholders :)
    %test:args("xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-de.xml", "global_cancel", "foo", "de") %test:assertEquals("Test-Abbrechen")
    (: Test replacements with existing key and non-existing language :)
    %test:args("", "global_cancel", "foo", "foo1g4#lang") %test:assertEmpty
    (: Test empty replacements with non-existing key and non-existing language :)
    %test:arg("langFileURI", "")
    %test:arg("key", "foo1g4#")
    %test:arg("values") 
    %test:arg("lang", "foo1g4#lang") %test:assertEmpty
    (: Test empty replacements with existing key from default language file :)
    %test:arg("langFileURI", "xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-de.xml")
    %test:arg("key", "view.desktop.Desktop_Maximize")
    %test:arg("values") 
    %test:arg("lang", "de") %test:assertEquals("Maximieren")
    (: Test empty replacements with non-existing language file – with existing key from default language file :)
    %test:arg("langFileURI", "xmldb:exist:///db/apps/Edirom-Online-Backend/testing/XQSuite/data/language-fr.xml")
    %test:arg("key", "view.desktop.Desktop_Maximize")
    %test:arg("values") 
    %test:arg("lang", "de") %test:assertEquals("Maximieren")
    function eut:test-getLanguageString-4-arity($langFileURI as xs:string, $key as xs:string, $values as xs:string*, $lang as xs:string) as xs:string? {
        eutil:getLanguageString($langFileURI, $key, $values, $lang)
};

(:

    let $case := (  'child::mei:label'[$node/mei:label], 
                   'self::mei:annot'[$node[self::mei:annot]] )[1]

:)

declare 
    (: setting default language to 'en' - it is derived in code by a global setting :)
    (: Test output with one title child element and existing language :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='en'>English title</title></titleStmt>") %test:assertEquals("English title")
    (: Test output with one title child element and non-existing language :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='de'>Deutscher Titel</title></titleStmt>") %test:assertEquals("Deutscher Titel")
    (: Test output with two title child elements and existing language :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='de'>Deutscher Titel</title><title xml:lang='en'>English title</title></titleStmt>") %test:assertEquals("English title")
    (: Test output with one label child element and existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='en'>articulation</label></category>") %test:assertEquals("articulation")
    (: Test output with one label child element and non-existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label></category>") %test:assertEquals("Artikulation")
    (: Test output with two label child elements and existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label><label xml:lang='en'>articulation</label></category>") %test:assertEquals("articulation")
    (: Test output with two label child elements and non-existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label><label xml:lang='es'>articulacion</label></category>") %test:assertEquals("Artikulation")
    (: Test output with two name elements and existing language :)
    %test:arg("node", "<navigatorItem xmlns='http://www.edirom.de/ns/1.3'><names><name xml:lang='de'>Einführung</name><name xml:lang='en'>Introduction</name></names></navigatorItem>") %test:assertEquals("Introduction")
    (: Test output with two name elements and non-existing language, fallback to first element's text content :)
    %test:arg("node", "<navigatorItem xmlns='http://www.edirom.de/ns/1.3'><names><name xml:lang='de'>Einführung</name><name xml:lang='es'>Introduccion</name></names></navigatorItem>") %test:assertEquals("Einführung")
    (: Test output with random element w/o children :)
    %test:arg("node", "<p xmlns='http://www.w3.org/1999/xhtml'>string</p>") %test:assertEquals("string")   
    (: Test output with random element w/ children :)
    %test:arg("node", "<div xmlns='http://www.w3.org/1999/xhtml'><p><span>string</span></p></div>") %test:assertEquals("string")
    function eut:test-getLocalizedName-1-arity-en($node as element()) as xs:string? {
        eutil:getLocalizedName($node, "en")
};

declare     
    (: setting default language to 'de' - it is derived in code by a global setting :)
    (: Test output with one title child element and existing language :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='de'>Deutscher Titel</title></titleStmt>") %test:assertEquals("Deutscher Titel")
    (: Test output with one title child element and non-existing language :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='en'>English title</title></titleStmt>") %test:assertEquals("English title")
    (: Test output with two title child elements and existing language :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='de'>Deutscher Titel</title><title xml:lang='en'>English title</title></titleStmt>") %test:assertEquals("Deutscher Titel")
    (: Test output with one label child element and existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label></category>") %test:assertEquals("Artikulation")
    (: Test output with one label child element and non-existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='en'>articulation</label></category>") %test:assertEquals("articulation")
    (: Test output with two label child elements and existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label><label xml:lang='en'>articulation</label></category>") %test:assertEquals("Artikulation")
    (: Test output with two label child elements and non-existing language :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='en'>articulation</label><label xml:lang='es'>articulacion</label></category>") %test:assertEquals("articulation")
    (: Test output with two name elements and existing language :)
    %test:arg("node", "<navigatorItem xmlns='http://www.edirom.de/ns/1.3'><names><name xml:lang='de'>Einführung</name><name xml:lang='en'>Introduction</name></names></navigatorItem>") %test:assertEquals("Einführung")
    (: Test output with two name elements and non-existing language, fallback to first element's text content :)
    %test:arg("node", "<navigatorItem xmlns='http://www.edirom.de/ns/1.3'><names><name xml:lang='en'>Introduction</name><name xml:lang='es'>Introduccion</name></names></navigatorItem>") %test:assertEquals("Introduction")
    (: Test output with random element w/o children :)
    %test:arg("node", "<p xmlns='http://www.w3.org/1999/xhtml'>string</p>") %test:assertEquals("string")   
    (: Test output with random element w/ children :)
    %test:arg("node", "<div xmlns='http://www.w3.org/1999/xhtml'><p><span>string</span></p></div>") %test:assertEquals("string")
    function eut:test-getLocalizedName-1-arity-de($node as element()) as xs:string? {
        eutil:getLocalizedName($node, "de")
};

declare     
    (: Test output with title elements and language de :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='de'>Deutscher Titel</title><title xml:lang='en'>English title</title></titleStmt>")
    %test:arg("lang", "de") %test:assertEquals("Deutscher Titel")
    (: Test output with title elements and language en :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='de'>Deutscher Titel</title><title xml:lang='en'>English title</title></titleStmt>")
    %test:arg("lang", "en") %test:assertEquals("English title")
    (: Test output with non-existing language, fallback to first element's text content :)
    %test:arg("node", "<titleStmt xmlns='http://www.music-encoding.org/ns/mei'><title xml:lang='de'>Deutscher Titel</title><title xml:lang='en'>English title</title></titleStmt>")
    %test:arg("lang", "foo1g4#lang") %test:assertEquals("Deutscher Titel")
    (: Test output with one label child element and language de :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label></category>") 
    %test:arg("lang", "de") %test:assertEquals("Artikulation")
    (: Test output with one label child element and non-existing language en :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label></category>") 
    %test:arg("lang", "en") %test:assertEquals("Artikulation")
    (: Test output with two label child elements and existing language en :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='de'>Artikulation</label><label xml:lang='en'>articulation</label></category>") 
    %test:arg("lang", "en") %test:assertEquals("articulation")
    (: Test output with two label child elements and non-existing language de, fallback to first element's text content :)
    %test:arg("node", "<category xmlns='http://www.music-encoding.org/ns/mei'><label xml:lang='en'>articulation</label><label xml:lang='es'>articulacion</label></category>") 
    %test:arg("lang", "de") %test:assertEquals("articulation")
    (: Test output with two name elements and existing language de :)
    %test:arg("node", "<navigatorItem xmlns='http://www.edirom.de/ns/1.3'><names><name xml:lang='de'>Einführung</name><name xml:lang='en'>Introduction</name></names></navigatorItem>")
    %test:arg("lang", "de") %test:assertEquals("Einführung")
    (: Test output with two name elements and existing language en :)
    %test:arg("node", "<navigatorItem xmlns='http://www.edirom.de/ns/1.3'><names><name xml:lang='de'>Einführung</name><name xml:lang='en'>Introduction</name></names></navigatorItem>")
    %test:arg("lang", "en") %test:assertEquals("Introduction")
    (: Test output with two name elements and non-existing language, fallback to first element's text content :)
    %test:arg("node", "<navigatorItem xmlns='http://www.edirom.de/ns/1.3'><names><name xml:lang='en'>Introduction</name><name xml:lang='es'>Introduccion</name></names></navigatorItem>")
    %test:arg("lang", "de") %test:assertEquals("Introduction")
    (: Test output with random element w/o children and language en :)
    %test:arg("node", "<p xmlns='http://www.w3.org/1999/xhtml'>string</p>") 
    %test:arg("lang", "de") %test:assertEquals("string")
    (: Test output with random element w/o children and language de :)
    %test:arg("node", "<p xmlns='http://www.w3.org/1999/xhtml'>string</p>") 
    %test:arg("lang", "de") %test:assertEquals("string")
    (: Test output with random element w/o children and non-existing language :)
    %test:arg("node", "<p xmlns='http://www.w3.org/1999/xhtml'>string</p>") 
    %test:arg("lang", "foo1g4#lang") %test:assertEquals("string")
    (: Test output with random element w/ children and language en :)
    %test:arg("node", "<div xmlns='http://www.w3.org/1999/xhtml'><p><span>string</span></p></div>") 
    %test:arg("lang", "de") %test:assertEquals("string")
    (: Test output with random element w/ children and language de :)
    %test:arg("node", "<div xmlns='http://www.w3.org/1999/xhtml'><p><span>string</span></p></div>")
    %test:arg("lang", "de") %test:assertEquals("string")
    (: Test output with random element w/ children and non-existing language :)
    %test:arg("node", "<div xmlns='http://www.w3.org/1999/xhtml'><p><span>string</span></p></div>")
    %test:arg("lang", "foo1g4#lang") %test:assertEquals("string")    
    function eut:test-getLocalizedName-2-arity($node as element(), $lang as xs:string) as xs:string? {
        eutil:getLocalizedName($node, $lang)
};

declare
    %test:args("1", "2")     %test:assertFalse
    %test:args("2", "1")     %test:assertTrue
    %test:args("2", "2")     %test:assertFalse
    %test:args("1a", "2b")     %test:assertFalse
    %test:args("10a", "2b")     %test:assertTrue
    %test:args("10a", "2ba")     %test:assertTrue
    %test:args("10a1", "10ba")     %test:assertFalse
    %test:args("2b", "1a")     %test:assertTrue
    %test:args("", "2")     %test:assertFalse
    %test:args("2", "")     %test:assertTrue
    function eut:test-compute-measure-sort-key($key1 as xs:string, $key2 as xs:string) as xs:boolean {
        eutil:compute-measure-sort-key($key1) > eutil:compute-measure-sort-key($key2)
};

declare
    %test:arg("seq", 2, 1, 3)     %test:assertEquals(1, 2, 3)
    %test:arg("seq", 1, 2, 3)     %test:assertEquals(1, 2, 3)
    %test:arg("seq", "1", "2", "3")     %test:assertEquals("1", "2", "3")
    %test:arg("seq", "1a", "1", "10", "2", "10b", "3s")     %test:assertEquals("1", "1a", "2", "3s", "10", "10b")
    %test:arg("seq", "10aa", "10aaa", "10x", "2c", "10_b")     %test:assertEquals("2c", "10_b", "10aa", "10aaa", "10x")
    %test:arg("seq", "<a/>", "<c/>", "<b/>")     %test:assertEquals("<a/>", "<c/>", "<b/>")
    %test:arg("seq", "<a>1</a>", "<c>3</c>", "<b>2</b>")     %test:assertEquals("<a>1</a>", "<b>2</b>", "<c>3</c>")
    function eut:sort-as-numeric-alpha($seq as item()*) as item()* {
        eutil:sort-as-numeric-alpha($seq)
};

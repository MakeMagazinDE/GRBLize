#GRBLize

###CNC-Steuerung für GRBL-JOG Projekt

Erstellt mit Delphi 2005 PE. Bitte beachten Sie unbedingt den Artikel in **[c't Hacks 4/2014](http://shop.heise.de/katalog/ct-hacks-4-2014)**. 

Ausführbare Datei (.EXE, Win32) im Verzeichnis **[/bin](https://github.com/heise/GRBLize/tree/master/bin)**, benötigt "default.job", ggf. die Beispiel-Plot-Dateien und 
gegebenenfalls ftd2xx.dll, letzteres aber nur, falls nicht ohnehin schon im System vom FTDI-Treiber-Download 
installiert.

Auf der rechten Spalte der Github-Seite finden Sie den Button "Download ZIP". Dies lädt das komplette Projekt herunter einschl. Sourcen. Nach Entpacken findet sich das Windows-Executable (32 Bit) im Unterverzeichnis /bin.

Das Projekt befindet sich noch in Entwicklung, bitte auf evt. Updates prüfen. 
Die passende GRBL-Steuerplatine finden Sie in unserem Github-Repo **[GRBL-JOG](https://github.com/heise/GRBL-JOG)**.

###Version History

- 0.96b: Latest build, bugfix on FTDI class, new Z Feed Scaling parameter for use with woodmill (otherwise Z feed will be too slow)
- 0.95b: First public beta
- 0.94a: Internal alpha, some serious bugs

###CNC Control Software for GRBL Jogger Project

Executable for Windows XP/7/8 in folder **[/bin](https://github.com/heise/GRBLize/tree/master/bin)**. No Installation required, but configuration file "default.job" and example plot files 
must be placed in same folder. Please see article in **[c't Hacks 4/2014](http://shop.heise.de/katalog/ct-hacks-4-2014)** for usage.

Made with Delphi 2005 PE. Sources to be compiled with Borland Delphi 2005 Personal Edition (and up) for those interested in improving it. GRBLize 
uses ftdiclass component from Michael "Zipplet" Nixon, Clipper library by Angus Johnson and GLscene OpenGL component.

Borland Delphi 2005 Personal Edition was downloadable for free some time ago, also included on some computer magazine CDs/DVDs as on c't 13/2005. It should be still available for free on http://delphi.developpez.com/delphi2005/

Delphi 2005 still works fine on Windows 7 if you add the new string value "$(BDS)\Bin\delphicoreide90.bpl" = "Delphi Core IDE" 
to the "HKEY_CURRENT_USER\Software\Borland\BDS\3.0\Known IDE Packages" registry key. Otherwise you'll get an access 
violation error on rtl90.bpl on exit of IDE. 

On Windows 7 latest update, the DZ Line Editor Fix (http://sourceforge.net/projects/dzeditorlineendsfix/) must be installed.

For Delphi 2005 PE, if you want to compile and install the design-time support for GLScene in folder Delphi2005, you 
will need to:

- rename FAKE_xmlrtl.dcp to xmlrtl.dcp
- copy/move it to your BDS\3.0\lib directory

This will take care of the warning (doesn't add xmlrtl functionality however, the dcp is empty). Source:
http://andy.jgknet.de/oss/kylix/wiki/index.php/Delphi_2005_Personal_Edition_xmlrtl.dcp_fake

Do not hesitate to port the project to [Lazarus](http://www.lazarus.freepascal.org), a free Delphi clone available for Linux and Windows.

(c) by Carsten Meyer, Redaktion c't Hacks/Make Deutschland, cm@ct.de, 12/2014.

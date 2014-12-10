#GRBLize

###CNC-Steuerung für GRBL-JOG Projekt

Erstellt mit Delphi 2005 PE. Bitte beachten Sie unbedingt den Artikel in **[c't Hacks 4/2014](http://shop.heise.de/katalog/ct-hacks-4-2014)**. Ausführbare Datei (.EXE, Win32) im Verzeichnis /bin, benötigt 
"default.job" und ggf. die Beispiele.

Das Projekt befindet sich noch in Entwicklung, bitte auf evt. Updates prüfen. Die passende GRBL-Steuerplatine finden Sie in unserem Github-Repo GRBL-JOG.

###CNC Control Software for GRBL Jogger Project

Made with Delphi 2005 PE. Please note article in **[c't Hacks 4/2014](http://shop.heise.de/katalog/ct-hacks-4-2014)** 
magazine. Executable in directory /bin, needs file "default.job" also.

Sources to be compiled with Borland Delphi 2005 Personal Edition (and up) for those interested in improving it. GRBLize 
uses ftdiclass component from Michael "Zipplet" Nixon and GLscene OpenGL component.

Borland Delphi 2005 Personal Edition was downloadable for free some time ago, also included on some computer magazine 
CDs/DVDs as on c't 13/2005. It is still available for free on **http://delphi.developpez.com/delphi2005/**

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

(c) by Carsten Meyer, Redaktion c't Hacks/Make Deutschland, cm@ct.de, 12/2014.

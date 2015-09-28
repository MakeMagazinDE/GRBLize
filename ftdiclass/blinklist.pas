{ Copyright (C) 2005 Bas Steendijk and Peter Green

  This software is provided 'as-is', without any express or implied warranty.
  In no event will the authors be held liable for any damages arising from the
  use of this software.
  
  Permission is granted to anyone to use this software for any purpose, including
  commercial applications, and to alter it and redistribute it freely, subject to
  the following restrictions:

      1. The origin of this software must not be misrepresented; you must not
         claim that you wrote the original software. If you use this software in a
         product, an acknowledgment in the product documentation would be
         appreciated but is not required.
  
      2. Altered source versions must be plainly marked as such, and must not be
         misrepresented as being the original software.
  
      3. This notice may not be removed or altered from any source distribution.
  ----------------------------------------------------------------------------- }

unit blinklist;
{$ifdef fpc}
  {$mode delphi}
{$endif}


interface

type
  tlinklist=class(tobject)
    next:tlinklist;
    prev:tlinklist;
    constructor create;
    destructor destroy; override;
  end;

  {linklist with 2 links}
  tlinklist2=class(tlinklist)
    next2:tlinklist2;
    prev2:tlinklist2;
  end;

  {linklist with one pointer}
  tplinklist=class(tlinklist)
    p:pointer
  end;

  tstringlinklist=class(tlinklist)
    s:string;
  end;

  tthing=class(tlinklist)
    name:string;      {name/nick}
    hashname:integer; {hash of name}
  end;

{
adding new block to list (baseptr)
}
procedure linklistadd(var baseptr:tlinklist;newptr:tlinklist);
procedure linklistdel(var baseptr:tlinklist;item:tlinklist);


procedure linklist2add(var baseptr,newptr:tlinklist2);
procedure linklist2del(var baseptr:tlinklist2;item:tlinklist2);

var
  linklistdebug:integer;

implementation

procedure linklistadd(var baseptr:tlinklist;newptr:tlinklist);
var
  p:tlinklist;
begin
  p := baseptr;
  baseptr := newptr;
  baseptr.prev := nil;
  baseptr.next := p;
  if p <> nil then p.prev := baseptr;
end;

procedure linklistdel(var baseptr:tlinklist;item:tlinklist);
begin
  if item = baseptr then baseptr := item.next;
  if item.prev <> nil then item.prev.next := item.next;
  if item.next <> nil then item.next.prev := item.prev;
end;

procedure linklist2add(var baseptr,newptr:tlinklist2);
var
  p:tlinklist2;
begin
  p := baseptr;
  baseptr := newptr;
  baseptr.prev2 := nil;
  baseptr.next2 := p;
  if p <> nil then p.prev2 := baseptr;
end;

procedure linklist2del(var baseptr:tlinklist2;item:tlinklist2);
begin
  if item = baseptr then baseptr := item.next2;
  if item.prev2 <> nil then item.prev2.next2 := item.next2;
  if item.next2 <> nil then item.next2.prev2 := item.prev2;
end;

constructor tlinklist.create;
begin
  inherited create;
  inc(linklistdebug);
end;

destructor tlinklist.destroy;
begin
  dec(linklistdebug);
  inherited destroy;
end;

end.

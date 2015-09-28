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
  
{actually a hashtable. it was a tree in earlier versions}

unit bsearchtree;

interface

uses blinklist;

const
  hashtable_size=$4000;

type
  thashitem=class(tlinklist)
    hash:integer;
    s:string;
    p:pointer;
  end;
  thashtable=array[0..hashtable_size-1] of thashitem;
  phashtable=^thashtable;

{adds "item" to the tree for name "s". the name must not exist (no checking done)}
procedure addtree(t:phashtable;s:string;item:pointer);

{removes name "s" from the tree. the name must exist (no checking done)}
procedure deltree(t:phashtable;s:string);

{returns the item pointer for s, or nil if not found}
function findtree(t:phashtable;s:string):pointer;

implementation

function makehash(s:string):integer;
const
  shifter=6;
var
  a,b:integer;
begin
  result := 0;
  b := length(s);
  for a := 1 to b do begin
    result := (result shl shifter) xor byte(s[a]);
  end;
  result := (result xor result shr 16) and (hashtable_size-1);
end;

procedure addtree(t:phashtable;s:string;item:pointer);
var
  hash:integer;
  p:thashitem;
begin
  hash := makehash(s);
  p := thashitem.create;
  p.hash := hash;
  p.s := s;
  p.p := item;
  linklistadd(tlinklist(t[hash]),tlinklist(p));
end;

procedure deltree(t:phashtable;s:string);
var
  p,p2:thashitem;
  hash:integer;
begin
  hash := makehash(s);
  p := t[hash];
  p2 := nil;
  while p <> nil do begin
    if p.s = s then begin
      p2 := p;
      break;
    end;
    p := thashitem(p.next);
  end;
  linklistdel(tlinklist(t[hash]),tlinklist(p2));
  p2.destroy;
end;


function findtree(t:phashtable;s:string):pointer;
var
  p:thashitem;
  hash:integer;
begin
  result := nil;
  hash := makehash(s);
  p := t[hash];
  while p <> nil do begin
    if p.s = s then begin
      result := p.p;
      exit;
    end;
    p := thashitem(p.next);
  end;
end;

end.

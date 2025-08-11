#!/bin/murgaLua

--this murgaLua script has been tested with version 0750 https://github.com/igame3dbill/MurgaLua_0.7.5
-- joining  two star database files to build one unified database with all useful-for-plotting-informations
-- goals = 
--> subset/downsize of BSC V5 with only useful fields
--> allowing [astrolua.lua] plotting constellations asterisms with HR id (=BSC id for stars), so having to retrieve these HR ids
-- file "catalog" & "readme" from 
-----> https://cdsarc.u-strasbg.fr/viz-bin/Cat?V/50#/browse & https://cdsarc.u-strasbg.fr/ftp/V/50/catalog.gz & https://cdsarc.u-strasbg.fr/ftp/V/50/ReadMe
-- file "stars_names_with_HRnb.txt" from
-----> https://www.glyphweb.com/esky/stars/bsc.html

-- Historical information
--1st versions of astroLua used following file for plotting stars & constellations, which is a subset of Yale BSC catalog (9010 elements, only 8 cols). Problem : it lacks stars' HR (=^BSC) numbers, so no asterism plotting was possible.
--"yalebsc.dat" (structure info "yalebsc.pat") from https://ian.macky.net/pat/yalebsc/index.html & https://ian.macky.net/pat/yalebsc/yalebsc.tar.bz2. 


find = string.find
sub = string.sub
gsub=string.gsub
upper=string.upper
lower=string.lower
random = math.random
floor = math.floor
ceil = math.ceil
abs=math.abs
format = string.format
sin=math.sin
cos=math.cos
pi=math.pi
sqrt=math.sqrt
pow=math.pow

osName="OS=" .. murgaLua.getHostOsName()
size_eol = 0 -- varie selon Unix (+MacOs) ou Windows

--constellations names and abrev
constellation_abrev={}

--database / tables : tables for this subset of Yale bright star catalog (BSC)
filename_starsnames_HR="stars_names_with_HRnb.txt"
hr_star={}
hr_name={}

--database / tables : tables for this complete Yale bright star catalog V5 (BSC)
filename_cbsc="catalog.txt"
c_hr_star={}
c_bfc_star={}
cra_h={}
cra_m={}
cra_s={}
cdeclsign={}
cdecldeg={}
cdeclmn={}
cdeclsec={}
cmagn={}
cconst={}
cname={}

--location for database files (ONE path for all files)
pathname=""

--csv separator
csv_separator=";"


function define_textfile_origin(data)
  local i,st
  --finding if -CURRENTLY OPENED- text file
  -- is Unix or Windows -generated
  --searching for CR/LF (windows)
  st = string.char(13) .. string.char(10)
  i = find(data, st)
  if i then
--print("Ce fichier a ete genere par Windows => size_eol=2")
     size_eol=1 -- for windows remove CR+LF at end of line
     return("windows")
  else
--print("Ce fichier a ete genere par un Unix-like => size_eol=1")
     size_eol=1 -- for unixes remove only LF(?)
     return("unix")
  end
end --end function

function round(typdata, data1, data2, data3)
 if typdata == "RA" then
    --rounding "seconds" field of a RA
    --RA for Sirius Cma (HR 2491) in complete BSC 064508.9 should be rounded to 064509 in BSC subset
    --data sign is ALWAYS positive
    if (data1-floor(data1))>0.5 then
       return (floor(data1)+1), nil
    else
       return floor(data1), nil
    end
 end
 if typdata == "DECL" then
    if data1 and data2 and data3 then
       --rounding "mn" field of a DECL, using "seconds" field
       --DECL for same star in complete BSC -164258 should be rounded to -1643 in BSC subset
       if data2 == 59 then
          return (data1+1),0
       else
          if data3>50 then
             return data1, (data2+1)
          else
             return data1, data2
          end
       end
    end
 end
end

function extract_from_starsnames_line(line) 
 -- extract from file "stars_names_with_HRnb.txt" from https://www.glyphweb.com/esky/stars/bsc.html
 local st,i,j,k
 if line == nil then
    return
 end
 if sub(line,1,3) == "HR " then
    --correct prefix checked
    --[[ some lines (samples)
HR 1 in Andromeda
HR 337 Mirach
HR 612 Nu Fornacis
HR 2878 Sigma Puppis
HR 2145 66 Orionis
HR 2491 Sirius
    ]]
    i = find(line, " ", 4, true) --find 
    if i then
       j = sub(line, 4,(i-1))
       if j then
          k = tonumber(j)
          table.insert(hr_star, k)
          st=sub(line, (i+1)) --CR/LF is removed from line string
          table.insert(hr_name, st)
       end
    end
 else 
    return
 end
end --end function

function extract_from_cbsc_line(line)
 -- extract from file "catalog", dl url=
 -- file is the complete Yale BSC, but .. "cultural names" of stars are lacking
  local st,i
  local hr_id, bayer_flamesteed, Durchmusterung_Identification
  local right_asc_hh,right_asc_mm,right_asc_ss
  local declsign,declination_d,declination_m,declination_s
  local msign,magnitude
  local constellation
  
 if line == nil then
    return
 end
 hr_id =tonumber( sub(line,1,4) )
 bayer_flamesteed = sub(line,5,14)
 Durchmusterung_Identification = sub(line,15,25) 
 if Durchmusterung_Identification == "           " then
    --not a star : object may be a cluster, a nova or something else like messier or NGC object
    return
 end 
 right_asc_hh=tonumber( sub(line,76,77) )
 right_asc_mm=tonumber( sub(line,78,79) )
 right_asc_ss=tonumber( sub(line,80,83) )
 right_asc_ss=round("RA",right_asc_ss)
 --i=right_asc_ss
 --right_asc_ss = tonumber(format('%2d',i) ) --"rounding"
 --declination
 if sub(line,84,84) == "-" then
    declsign=-1
 elseif sub(line,84,84) == "+" then
    declsign=1
 end
 declination_d=tonumber( sub(line,85,86))
 declination_m=tonumber( sub(line,87,88))
 declination_s=tonumber( sub(line,89,90))
 --magnitude
 if sub(line,103,103) == "-" then
    msign=-1
    magnitude=msign*tonumber( sub(line,104,107) )
 else
    msign=1
    magnitude=msign*tonumber( sub(line,104,107) )
 end
--print("=====> magnitude " ..magnitude )
 --string data...
 constellation = upper(sub(line,12,14))

if bayer_flamesteed =="  9Alp CMa" then
   --nothing as for now
elseif bayer_flamesteed =="" then
   --nothing
else
   --nothing
end
 
 --set values
 table.insert(c_hr_star, hr_id)
 table.insert(c_bfc_star, bayer_flamesteed)
 table.insert(cra_h, right_asc_hh)
 table.insert(cra_m, right_asc_mm)
 table.insert(cra_s, right_asc_ss)
 table.insert(cdeclsign, declsign)
 table.insert(cdecldeg, declination_d)
 table.insert(cdeclmn, declination_m)
 table.insert(cdeclsec, declination_s)
 table.insert(cmagn, magnitude)
 table.insert(cconst, constellation)
--debug
--print("HR ".. hr_id .. " RA=".. right_asc_hh .."h"..right_asc_mm.."mn"..right_asc_ss.."sec,  ---  DECL=("..sign..") "..declination_d.."deg"..declination_m.."mn"..declination_s.."sec , MAG="..magnitude..", CONST="..constellation)
end --end function

function extract_from_const_line(line)
  local pos1,pos2,pos3,name,abrev
 if line == nil then
    return
 end
 --1st line sample
 --Andromeda ;Andromedae ;And ; 
 
  pos1=find(line, separator_const, 1)
  if pos1 then
     --name = upper(sub(line,1, pos1-2))
     name = sub(line,1, pos1-2)
     pos2=find(line, separator_const, (pos1+1))
     if pos2 then
        pos3=find(line, separator_const, (pos2+1))
        if pos3 then
           --abrev = upper(sub(line,pos2+1, pos3-1))
           abrev = sub(line,pos2+1, pos3-1)
           if sub(abrev,-1,-1) == " " then
              abrev = sub(abrev,1,-2)
           end
        end
     end
  end
  if name then
     table.insert(constellation_name, name)
  end
  if abrev then
     table.insert(constellation_abrev, abrev)
  end
end --end function

function search_path()
 local f
 local fn="astro_lua_path.txt"
 f = io.open(fn,"rb")
 if f then
print("File " .. fn .. " found & opened for reading !")
    pathname = f:read("*all")
    io.close(f)
    return(1)
 else
print("File " .. fn .. " not found : have to ask you for databases pathname & save it...")
    return nil
 end
end --end function

function save_path()
 local f
 local fn="astro_lua_path.txt"
 f = io.open(fn,"wb")
 if f then
    f:write(pathname)
    io.close(f)
print("File " .. fn .. " created !")
 else
print("Problem saving File " .. fn .. " ! Please check/delete it and retry :")
 end
end --end function

function path_finder()
  -- ask user to select path where database files are located
  -- then save it to a file
  -- then directly load the file
  pathname = fltk.fl_dir_chooser("PATH SELECTION for database files (CSV, DAT)", "CSV Files (*.{csv,CSV,dat,DAT})", SINGLE, nil)
  print("pathname = " .. pathname)
end --end function

function dl_starsnames()
 local buffer="" 
 local nblines=0
 local pos,j
--csv file for celestial objects data loading
--Bright Star Catalogue / dezipped file yalebsc.tar.bz2
--source=https://ian.macky.net/pat/yalebsc/yalebsc.tar.bz2
 if find(osName, "linux",1,true) then
    filename_starsnames_HR=pathname .. "/" .. filename_starsnames_HR
else
    --windows, i presume
    filename_starsnames_HR=pathname .. "\\" .. filename_starsnames_HR
end

print(filename_starsnames_HR)
nblines=0
 if filename_starsnames_HR then
     f = io.open(filename_starsnames_HR,"rb")
     if f then
print("File " .. filename_starsnames_HR .. " opened for reading !")
       buffer = f:read("*all")
       io.close(f)
       pos=1
       while 1 do
             j = find(buffer,"\n",pos)
             if j then
	            line = sub(buffer, pos, j-1)
                extract_from_starsnames_line(line)
                pos = j+1
                nblines=nblines+1
             else
                line = sub(buffer, pos)
                if line then
                   if #line>6 then
                      extract_from_starsnames_line(line)
                      nblines=nblines+1
                   end
                end
                break
             end
       end
    end
 end
print(nblines .. " lines have been extracted from file ".. filename_starsnames_HR .."\nFollowing two tables were built :\nhr_star (size="..#hr_star.." elements) and hr_name (size="..#hr_name.." elements)")
end --end function

function dl_cbsc()
 --dowload cpomplete BSC catalog from :
 --https://cdsarc.u-strasbg.fr/ftp/V/50/catalog.gz 
 --https://cdsarc.u-strasbg.fr/ftp/V/50/ReadMe (structure info for this catalog)
 local buffer="" 
 local nblines=0
 local pos,j
--complete Bright Star Catalog
--source=https://ian.macky.net/pat/yalebsc/yalebsc.tar.bz2
 if find(osName, "linux",1,true) then
    filename_cbsc=pathname .. "/" .. filename_cbsc
else
    --windows, i presume
    filename_cbsc=pathname .. "\\" .. filename_cbsc
end

print(filename_cbsc)
nblines=0
 if filename_cbsc then
     f = io.open(filename_cbsc,"rb")
     if f then
print("File " .. filename_cbsc .. " opened for reading !")
       buffer = f:read("*all")
       io.close(f)
       pos=1
       while 1 do
             j = find(buffer,"\n",pos)
             if j then
	            line = sub(buffer, pos, j)
                extract_from_cbsc_line(line)
                pos = j+1
                nblines=nblines+1
             else
                  break
             end
       end
    end
 end
 print(nblines .. " lines have been extracted from file ".. filename_cbsc .."\nTables were built, with main index :\nc_hr_star (size="..#c_hr_star.." elements)")
end --end function

function save_newbsc()
 local i, f
 local fn="newbfc.csv"
 local buffer=""

 for i=1,#c_hr_star do
      --csv line building
      buffer=buffer.. c_hr_star[i]
      if c_bfc_star[i] then
         buffer = buffer .. csv_separator .. c_bfc_star[i]
      else
         buffer = buffer .. csv_separator .. ""
      end
      buffer=buffer.. csv_separator .. format('%02d',cra_h[i]).. csv_separator.. format('%02d',cra_m[i])..csv_separator.. format('%02d',cra_s[i])
      if cdeclsign[i] == -1 then
         buffer=buffer.. csv_separator.. "-"
      else
         buffer=buffer.. csv_separator.. "+"
      end
      buffer=buffer.. csv_separator.. format('%02d',cdecldeg[i])..csv_separator.. format('%02d',cdeclmn[i])..csv_separator.. format('%02d',cdeclsec[i])
      if cmagn[ i ] then
         buffer=buffer.. csv_separator.. format('%+1.2f',cmagn[i])
      else
         buffer=buffer.. csv_separator.. ""
      end
      if cconst[ i ] then
         buffer=buffer.. csv_separator.. cconst[i]
      else
         buffer=buffer.. csv_separator.. ""
      end
      if cname[ i ] then
         buffer=buffer.. csv_separator.. cname[i]
      else
         buffer=buffer.. csv_separator.. ""
      end
      buffer=buffer.."\n"
 end

 f = io.open(fn,"wb")
 if f then
    f:write(buffer)
    io.close(f)
print("File " .. fn .. " created with size=" .. #buffer .. " !")
 else
print("Problem saving File " .. fn .. " ! Please check/delete it and retry :")
 end
end --end function

 t00=0
 t00 = os.time() --top chrono
 --osName="OS=" .. murgaLua.getHostOsName()
  --version FLTK
 print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. "." .. fltk.FL_PATCH_VERSION)
 print("RAM used BEFORE opData by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))

 if search_path() == nil then
    --first launch => ask for path => save path
    path_finder()
    save_path()
 end
 
 dl_starsnames()
 dl_cbsc()
 
 if #hr_star == 0 or #cra_h == 0 then
    st="At least a database is missing, please check your path for following 2 files :\nyalebsc.dat (subset of Yale BSC)\ncatalog.txt (complete Yale BSC V5 catalog)"
    fltk:fl_alert(st)
    exit(0)
 end
 processed_stars=0
 
 for i=1,#hr_star do
      for j=1,#cra_h do
           if hr_star[ i ] == c_hr_star[ j ] then
              cname[ j ] = hr_name[ i ]
              processed_stars=processed_stars+1
              break
           end
      end --for j
 end --for i

print("\nprocessed_stars=".. processed_stars .. " =====> #hr_star="..#hr_star.. " // #c_hr_star="..#c_hr_star)

save_newbsc()

print("Processing in " .. os.difftime(os.time(), t00) .. " seconds, ie  " .. format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, ie " .. format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " hours")
print("RAM used AFTER opData by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))

Fl:check()
Fl:run()


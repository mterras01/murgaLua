#!/bin/murgaLua

--this murgaLua script has been tested with version 0750 https://github.com/igame3dbill/MurgaLua_0.7.5
--goals=it gives a sky card, adjusting some parameters :
-- -- max visible magnitudes for celestial objects (user defined)
--planet's locations ???
-- either computed with some help here 
-- => https://cs108.epfl.ch/archive/20/p/05_sun-planets-model.html
-- or here => https://ssd.jpl.nasa.gov/planets/approx_pos.html
-- or here = https://stjarnhimlen.se/comp/tutorial.html

-- or retrieved from the internet
-- exemple here => http://pgj.astro.free.fr/position-planetes.htm (duration in time ???)
-- other exemples (location Bourg-en-Bresse)
-- => Mars  = https://www.planetscalc.org/#/46.2053,5.2256,13/2025.04.27/12:16/2/3
-- => Jupiter = https://www.planetscalc.org/#/46.2053,5.2256,13/2025.04.27/12:16/3/3
-- => Saturn = https://www.planetscalc.org/#/46.2053,5.2256,13/2025.04.30/10:20/4/3
-- => Venus = https://www.planetscalc.org/#/46.2053,5.2256,13/2025.04.30/10:20/1/3
-- => Mercury = https://www.planetscalc.org/#/46.2053,5.2256,13/2025.04.30/10:20/0/3
-- other website = https://ssd.jpl.nasa.gov/horizons/
-- help on api here https://ssd-api.jpl.nasa.gov/doc/horizons.html
-- --sun and moon locations at current date/time or given date/time


--this script has a (local) database 
-- url=https://www.datastro.eu/api/explore/v2.1/catalog/datasets/catalogue-de-messier/exports/csv?lang=fr&timezone=Europe%2FBerlin&use_labels=true&delimiter=%3B

find = string.find
sub = string.sub
gsub=string.gsub
upper=string.upper
random = math.random
floor = math.floor
ceil = math.ceil
format = string.format

osName="OS=" .. murgaLua.getHostOsName()
size_eol = 0 -- varie selon Unix (+MacOs) ou Windows

--database / tables : tables for bright star catalog data
ra_h={}
ra_m={}
ra_s={}
decl={}
magn={}
sym={}
spect={}
let={}
const={}
star={}
comment_bsc={}

--database / tables : tables for messier catalog data
mess_cat={}
mess_ngc_cat={}
mess_type={}
mess_cons={}
ra_h_m={}
ra_m_m={}
decl_m={}
magn_m={}
size_m={}
dist_m={}
season_m={}
diff_m={}
comment_m={}

--GUI
window=object
width_twindow = 1500
height_twindow = 768
u_quit,v_button=object,object
magn_slider=object

-- sky objects plotting:grid pataméters
grid_hor_width=60
grid_vert_height=40
grid_decx=37
grid_decy=80

function extract_from_bsc_line(line) 
 local st
 if line == nil then
    return
 end
    right_asc_hh=tonumber( sub(line,1,2) )
    right_asc_mm=tonumber( sub(line,3,4) )
    right_asc_ss=tonumber( sub(line,5,6) )
--print("=====> RA " ..right_asc_hh .. "h " .. right_asc_mm .. "mn " .. right_asc_ss .."s ")
    --declination
    if sub(line,7,7) == "-" then
       sign=-1
    elseif sub(line,7,7) == "+" then
       sign=1
    else 
print("Erreur de format, line = " .. line)
exit(0)
    end
    declination=sign*tonumber( sub(line,8,11) )/100
--print("=====> DECL " ..declination  .. "deg ")
    --magnitude
    if sub(line,12,12) == "-" then
       sign=-1
       magnitude=sign*tonumber( sub(line,13,14) )/10
    else
       sign=1
       magnitude=sign*tonumber( sub(line,12,14) )/100
    end
--print("=====> magnitude " ..magnitude )
    --graphic symbol
    symbol = sub(line,15,16)
    if symbol == "SS" or symbol == "SD" or symbol == "SV" then
--print("=====> graphical symbol " .. symbol)
    else
print("Erreur de format, line = " .. line)
exit(0)
    end
    --string data...
    spectral_type = sub(line,17,18)
    letter = sub(line,19,20)
    constellation = sub(line,21,23)
    starname = sub(line,24,-2)
    
    --set values
    table.insert(ra_h, right_asc_hh)
    table.insert(ra_m, right_asc_mm)
    table.insert(ra_s, right_asc_ss)
    table.insert(decl, declination)
    table.insert(magn, magnitude)
    table.insert(sym, symbol)
    table.insert(spect, spectral_type)
    table.insert(let, letter)
    table.insert(const, constellation)
    table.insert(star, starname)
    st="RA="..ra_h[#ra_h] .."h ".. ra_m[#ra_m] .."mn " .. ra_s[#ra_s].. "s\nDecl=" .. decl[#decl] .."deg\nMagn=".. magn[#magn] .."\nGrphSym=" ..sym[#sym] .."\nSpec Type=" .. spect[#spect] .."\nLetter=" .. let[#let] .."\n" .. "Const=" .. const[#const] .. "\nStar)" ..star[#star]
    table.insert(comment_bsc, st)

--print("=====> spectral type " ..spectral_type)
--print("=====> letter " ..letter)
--print("=====> constellation " ..constellation)
--print("=====> starname " ..starname)
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
     name = upper(sub(line,1, pos1-2))
     pos2=find(line, separator_const, (pos1+1))
     if pos2 then
        pos3=find(line, separator_const, (pos2+1))
        if pos3 then
           abrev = upper(sub(line,pos2+1, pos3-1))
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

function grid()
local i,j,k,b,c,st,st2
--local grid_hor_width,grid_vert_height=40,40
--local grid_decx,grid_decy=37,80

  fltk.fl_color(256) --black is 256
  --for i=23,-1,-1 do
  for i=24,0,-1 do
       k=0
       for j=80,-80,-10 do
            --fltk:fl_line(37+((23-i)*40), 80,37+((23-i)*40), 80+(16*40)) --vertical grid
            --fltk:fl_line(grid_decx+((23-i)*grid_hor_width), grid_decy,grid_decx+((23-i)*grid_hor_width), grid_decy+(16*grid_vert_height)) --vertical grid
            fltk:fl_line(grid_decx+((24-i)*grid_hor_width), grid_decy,grid_decx+((24-i)*grid_hor_width), grid_decy+(16*grid_vert_height)) --vertical grid
            --fltk:fl_line(37, 80+(k*40),37+(24*40), 80+(k*40)) --horizontal grid
            fltk:fl_line(grid_decx, grid_decy+(k*grid_vert_height),grid_decx+(24*grid_hor_width), grid_decy+(k*grid_vert_height)) --horizontal grid
            k=k+1
       end
  end
end --end function

function plot_stars()
  local i
  local posx,oldrposx,rposx,posy,f,decx
  local c,d
  --a star at 24h 80deg should be at coordinates x=0,y=0
  --a star at 24h 0deg should be at coordinates x=0,y=halh of height
  --a star at 12h 0deg should be at coordinates x=half of width (?),y=halh of height
  --a star at 0h -80deg should be at coordinates x=whole width,y=whole height
  
  print("New plotting")
  for i=1,#star do
       if star[i] then
--          if star[i] ~= "" and star[i] ~= " " then
--if magn[i] <4 then 
if magn[i] < magn_slider:value() then
             posx= floor(((24-(ra_h[i]+(ra_m[i]/60)+(ra_s[i]/3600)))*grid_hor_width)+grid_decx)
             
--             if star[i] == "Betelgeuse" or star[i] == "Bellatrix" or star[i] == "Rigel" then
--print(star[i] .. "'s posx is " .. ra_h[i]+(ra_m[i]/60)+(ra_s[i]/3600))
--             end
             
             if decl[i]>0 then
                --posy=floor((80-decl[i])*40)
                posy=floor((80-decl[i])*4)+grid_decy
             else
                --posy=floor(-1*decl[i]*40)+320
                posy=floor(-1*decl[i]*4)+320+grid_decy
             end
--print("Star " .. star[i] .. " plotting with x= " .. posx .. ", y=" .. posy )
             fltk.fl_color(1)
             fltk.fl_rectf(posx, posy, 4, 4)
             
             --[-[--
                if star[i] ~= "" then
                   c=fltk:Fl_Button(posx, posy, 60, 20)
                   c:align(fltk.FL_ALIGN_TOP)
                   c:labelsize(8)
                   c:labelcolor(256)
                   c:color(2)
                   c:label(star[i])
                   c:tooltip(star[i])
                   
                end
             --]]--
             --fltk.fl_point((posx+37), (posy+40))
end
--          end
       end
  end
end

function extract_from_mess_line(line) 
 if line == nil then
    return
 end
-- line sample
-- M1	NGC 1952 Crab Nebula	Supernova Remnant	Taurus	5h 34.5m	22°1	8.4	6.0x4.0	6,3	Winter	Moderate
 local s={}
 local i,j,k,l,pos,st,nb,st2,nb2,dec1,dec2
 --find data positions from CSV separator
 pos=1
 for i=1,#line do
      --j=find(line, separator_mess, pos, true)
      st = sub(line, i, i)
      if st == separator_mess then
         table.insert(s, i)
         --pos=j+1 --next data
      end
 end
--print("Localisation separator in current line = "..table.concat(s,"/"))
 if s[1] then
    st=sub(line, 1, s[1]-1)
    table.insert(mess_cat, st)
--print(st)
    if s[2] then
       st=sub(line, s[1]+1, s[2]-1)
       table.insert(mess_ngc_cat, st)
--print(st)
       if s[3] then
          st=sub(line, s[2]+1, s[3]-1)
          table.insert(mess_type, st)
--print(st)
          if s[4] then
             st=sub(line, s[3]+1, s[4]-1)
             table.insert(mess_cons, st)
--print(st)
             if s[5] then --right ascension
                st=sub(line, s[4]+1, s[5]-1)
                k = find(st,"h",1,true)
                l = find(st,"m",1,true)
                nb=tonumber( sub(st,1, k-1) ) --right ascension hour
                nb2=tonumber( sub(st,k+2, l-1) ) --right ascension minutes
                table.insert(ra_h_m, nb)
                table.insert(ra_m_m, nb2)
--print(st)
--print(ra_h_m[#ra_h_m] .. "h" .. ra_m_m[#ra_h_m].."m")

                if s[6] then --declination
                   st=sub(line, s[5]+1, s[6]-1)
--print(st)
--for i=1,#st do
--     print(string.sub(st,i,i) .. " <=> ".. string.byte( st,i,i) )
--end
                   --k = find(st,"°",1)
                   k = find(st, string.char(176), 1)
                   l = sub(st,1,1) --sign or nb ?
                   if l =="-" then
                      dec1 = -1*tonumber( sub(st,2, k-1) ) --declination degree
                   else
                      dec1 = tonumber( sub(st,1, k-1) ) --declination degree
                   end
                   dec2=tonumber( sub(st,k+1) ) --declination minutes
--print(dec1 .. "deg " .. dec2 .. "mn")
                   table.insert(decl_m, (dec1+(dec2/60) ) )
--print(decl_m[#decl_m] .. "deg ")
                     if s[7] then --magnitude
                         st=sub(line, s[6]+1, s[7]-1)
                         nb=tonumber(st)
                         table.insert(magn_m, nb)
--print("Magn=" .. magn_m[#magn_m])
                         if s[8] then --size
                            st=sub(line, s[7]+1, s[8]-1)
                            table.insert(size_m, st)
--print("Size=" .. size_m[#size_m])
                            if s[9] then --distance (light year)
                               st=sub(line, s[8]+1, s[9]-1)
                               --sometimes, normating is mad = distance are written here with a coma, and not with a point
                               --so have to replace "," with "." if exists any
                               i=find(st,",",1,true)
                               if i then
                                  st2 = sub(st,1,i-1) .. "." .. sub(st,i+1,-1)
                               else
                                  st2=st
                               end
                               nb=tonumber(st2)
                               table.insert(dist_m, nb)
--print("Dist=" .. dist_m[#dist_m])
                               if s[10] then --viewing season
                                  st=sub(line, s[9]+1, s[10]-1)
                                  table.insert(season_m, st)
--print("Viewing season=" .. season_m[#season_m])
                                  st=sub(line, s[10]+1,-1)
                                  table.insert(diff_m, st)
--print("Viewing diff=" .. diff_m[#diff_m])
                                  st = "Messier=" .. mess_cat[#mess_cat] .."\nNGC/Name=" ..mess_ngc_cat[#mess_ngc_cat] .."\nMessier Type=" ..mess_type[#mess_type] .."\nConstellation=" .. mess_cons[#mess_cons] .."\nRight Ascension=" .. ra_h_m[#ra_h_m] .. "h".. ra_m_m[#ra_m_m] .. "m\nDeclination=" .. dec1.."deg " .. dec2.. "s ".. "(" .. decl_m[#decl_m]..")\nMagnitude="..magn_m[#magn_m] .."\nSize="..size_m[#size_m] .."\nDistance="..dist_m[#dist_m].." light year(s)\nViewing season=" ..season_m[#season_m] .. "\nViewing difficulty="..diff_m[#diff_m]
                                  table.insert(comment_m, st)
                               end
                            end
                         end
                     end
                end
             end
          end
       end
     end
  end

end --end function

function show_stars() 
  --window:show()
  --window:make_current()
 window:make_current()
    grid()
    plot_stars()
    window:show()
end

function main_display()
 local i,j,k,l,st,b,c,st2
 --window = fltk:Fl_Double_Window(width_twindow, height_twindow, "Global skymap")   
 window = fltk:Fl_Window(width_twindow, height_twindow, "Global skymap")   
 for i=24,0,-1 do
       k=0
       for j=80,-80,-10 do
            --if i==23 then
            if i==24 then
               --vertical declination labels tracing
               st2=j.."deg"
               c=fltk:Fl_Box(35, 65+(k*grid_vert_height),30, 30)
               c:label(st2)
               c:align(fltk.FL_ALIGN_LEFT)
               c:labelsize(8)
               --text box with no box
            end
            if j==80 then
               --horizontal "right ascension" labels tracing
               b=fltk:Fl_Box(grid_decx+((24-i)*grid_hor_width), grid_decy,40, 40)
               --b:box(fltk.FL_BORDER_BOX)
               st=i.."h"
               b:label(st)
               b:align(fltk.FL_ALIGN_TOP+fltk.FL_ALIGN_LEFT)
               b:labelsize(10)
            end
            k=k+1
       end
  end

 height_button=25
 width_button=50 
  u_quit = fltk:Fl_Button(5, 5, width_button, height_button, "Quit")
  u_quit:color(fltk.FL_RED)
  u_quit:tooltip("Quit this application")
  u_quit:callback(function (quit_u)
     window:hide()
     window:clear()
     window = nil
     os.exit()
  end)
  v_button = fltk:Fl_Button(10+width_button, 5, width_button, height_button, "stars")
  --v_button:color(fltk.FL_RED)
  v_button:tooltip("Display the Stars")
  v_button:callback(show_stars)
  
  magn_slider=fltk:Fl_Value_Slider(10+2*width_button, 5, (4*width_button), height_button, "Upper Magnitude")
  magn_slider:type(fltk.FL_HOR_NICE_SLIDER)
  magn_slider:textsize(8)
  magn_slider:value(4)
  magn_slider:maximum(30)
  magn_slider:minimum(-30)
  magn_slider:tooltip("Defines with this slider value an upper limit for objects' Magnitude")
   
  window:show()
  window:make_current()
end --end function

 t00=0
 t00 = os.time() --top chrono
 osName="OS=" .. murgaLua.getHostOsName()
  --version FLTK
 print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. "." .. fltk.FL_PATCH_VERSION)
                                                 
 
 print("RAM used BEFORE opData by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))

 
 
--csv file for celestial objects data loading
--Bright Star Catalogue / dezipped file yalebsc.tar.bz2
--url=https://ian.macky.net/pat/yalebsc/yalebsc.tar.bz2
--Fields description
--
--	field name	p  w  storage   type     units    format    flags
--       ---------------------------------------------------------------------
--field	ra		0  6  double	ra       hour     hhmmss    longitude
--field	declination	0  5  double	decl     dd       sddmm     latitude
--field	magnitude	0  3  double	vismag   none     mag3      0
--field	type		0  2  string	string   none     string    0
--field	spectral_type	0  2  ub2	spectral none     spectral  null-ok
--field	letter		0  2  string	string   none     string    null-ok
--field	constellation	0  3  string	string   none     string    null-ok
--field	name		0  0  string	string   none     string    null-ok
-- -----------------------------------
-- 0D details
-- points		9010
-- fields		8
-- color		spectral spectral_type, magnitude
-- scale		((6 - magnitude) / 2)
--symbol		(type = "SS"), solid circle, (type = "SD"), circle, \ (type = "SV"), box
filename_bsc="/home/terras/Téléchargements/AstroLua_docs/data/space/yalebsc.dat"
print(filename_bsc)
separator=";"
buffer_bsc=""
tab_bsc={}
nblines=0
 if filename_bsc then
     f = io.open(filename_bsc,"rb")
     if f then
print("File " .. filename_bsc .. " opened for reading !")
       buffer_bsc = f:read("*all")
       io.close(f)
       pos=1
       while 1 do
             j = find(buffer_bsc,"\n",pos)
             if j then
	            line = sub(buffer_bsc, pos, j)
                extract_from_bsc_line(line)
                pos = j+1
                nblines=nblines+1
             else
                  break
             end
       end
    end
 end
 
 filename_const="/home/terras/Téléchargements/AstroLua_docs/data/space/constellation_abrev.csv"
print(filename_const)
separator_const=";"
buffer=""
constellation_name={}
constellation_abrev={}
nblines=0
 if filename_const then
     f = io.open(filename_const,"rb")
     if f then
print("File " .. filename_const .. " opened for reading !")
       buffer = f:read("*all")
       io.close(f)
       pos=1
       while 1 do
             j = find(buffer,"\n",pos)
             if j then
	            line = sub(buffer, pos, j)
	            if find(line,"Tags;;;",1,true) then
print("Found \"Tags;;;\" field ")
	               --following lines are like "text legend"
	               break
	            end
                extract_from_const_line(line)
                pos = j+1
                nblines=nblines+1
             else
                  break
             end
       end
    end
 end 
 print(table.concat(constellation_name,"/"))
 print(table.concat(constellation_abrev,"/"))
 
 --Now, download Messier catalog (110 objects)
 filename_mess="/home/terras/Téléchargements/AstroLua_docs/data/space/Messier_Catalog_110_List3.csv"
print(filename_mess)
separator_mess=";"
buffer=""
nblines=0
 if filename_mess then
     f = io.open(filename_mess,"rb")
     if f then
print("File " .. filename_mess .. " opened for reading !")
       buffer = f:read("*all")
       io.close(f)
       pos=1
       while 1 do
             j = find(buffer,"\n",pos)
             if j then
	            line = sub(buffer, pos, j)
	            if nblines == 0 then
	               --text legend line
	            else
                   extract_from_mess_line(line)
                end
                pos = j+1
                nblines=nblines+1
             else
                  break
             end
       end
    else
print("Problem loading File " .. filename_mess .. " for reading !")
    end
 end 
 
 main_display()
 show_stars()

 print("RAM used AFTER pre_report() -and freeing some huge tables- by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))
 
 print("Processing in " .. os.difftime(os.time(), t00) .. " seconds, ie  " .. format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, ie " .. format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " hours")

  --print("Free RAM by collectgarbage(\"count\") = " .. collectgarbage("count"))
  print("RAM used AFTER opData by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))

Fl:check()
Fl:run()

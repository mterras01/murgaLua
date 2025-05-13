#!/bin/murgaLua

--this murgaLua script has been tested with version 0750 https://github.com/igame3dbill/MurgaLua_0.7.5
--goals=it gives a sky card, adjusting some parameters :
-- -- max visible magnitudes for celestial objects (user defined)
--planet's locations
-- https://celestialprogramming.com/planets_with_keplers_equation.html (code written entirely in js)
-- /* by Greg Miller gmiller@gregmiller.net 2021
-- http://www.celestialprogramming.com/
-- Released as public domain */

find = string.find
sub = string.sub
gsub=string.gsub
upper=string.upper
random = math.random
floor = math.floor
ceil = math.ceil
format = string.format
sin=math.sin
cos=math.cos
pi=math.pi
sqrt=math.sqrt
pow=math.pow

osName="OS=" .. murgaLua.getHostOsName()
size_eol = 0 -- varie selon Unix (+MacOs) ou Windows

require "planetpositions" --module located in your (linux) home dir: guess what it does?

--constellations names and abrev
filename_const="constellation_abrev.csv"
separator_const=";"
constellation_name={}
constellation_abrev={}
selconst=0 --index of selected constellation

--database / tables : tables for bright star catalog data
filename_bsc="yalebsc.dat"
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
filename_mess="Messier_Catalog_110_List3.csv"
separator_mess=";"
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

--database / tables : tables for planets & Sun info data
ra_h_p={0,0,0,0,0,0,0,0,0,0}
ra_m_p={0,0,0,0,0,0,0,0,0,0}
ra_s_p={0,0,0,0,0,0,0,0,0,0}
decl_p={0,0,0,0,0,0,0,0,0,0}
comment_p={"","","","","","","","","",""}

--GUI
cwindow=object --command window 
width_cwindow, height_cwindow = 900, 75
window=object
width_twindow, height_twindow= 1500, 768
u_quit,v_button=object,object
magn_slider_s=object
magn_slider_m=object
height_button=25
width_button=80
co={} --constellation buttons
gridtextdecb={} --grid legend text for declination (skymap)
gridtextrab={} --grid legend text for right ascension (skymap)
gridb={} --grid (skymap)
starsb={} --stars'buttons (skymap)
messiersb={} --Messiers objects' buttons (skymap)
planetsb={} --planets & suns' buttons (skymap)

--night vision parameters, default mode=day
windowbg=fltk.FL_BACKGROUND_COLOR --skymap background
labelcol=fltk.FL_BLACK --labelcolors for stars, messier, planets and grid
gridcol=4 --grid color

-- sky objects plotting:grid parameters
grid_hor_width=60
grid_vert_height=40
grid_decx=37
grid_decy=80

--time vars
jd=0 --julian date
timestep=0 --unit of time between two plotting (julian date format, nb of millisec)
timebeg=0 --beginning in time of the current animation (julian date format, nb of millisec)

--location for database files (ONE path for all files)
pathname=""

function get_date_time()
  --local dd,mm,yyyy
  --local hh,mn,ss
  local t
  t=os.time() --sec from epoch => *1000 to get approx millisec from epoch
  dd=os.date("%d")
  mm=os.date("%m")
  yyyy=os.date("%Y")
  hh=os.date("%H")
  mn=os.date("%M")
  ss=os.date("%S")
  return dd,mm,yyyy,hh,mn,ss,t
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

function extract_from_bsc_line(line) 
 local st,i,constp
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
    --find complete constellation name from its abrev
    constp=""
    for i=1,#constellation_abrev do
         if const[#const] == constellation_abrev[i] then
            constp = constellation_name[i]
            break
         end
    end
    if constp == "" then
       constp=const[#const]
    end
    st="RA="..ra_h[#ra_h] .."h ".. ra_m[#ra_m] .."mn " .. ra_s[#ra_s].. "s\nDecl=" .. decl[#decl] .."deg\nMagn=".. magn[#magn] .."\nGrphSym=" ..sym[#sym] .."\nSpec Type=" .. spect[#spect] .."\nLetter=" .. let[#let] .."\n" .. "Const=" .. constp .. "\nStar=" ..star[#star]
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
                                  st = "Messier=" .. mess_cat[#mess_cat] .."\nNGC/Name=" ..mess_ngc_cat[#mess_ngc_cat] .."\nMessier Type=" ..mess_type[#mess_type] .."\nConstellation=" .. mess_cons[#mess_cons] .."\nRight Ascension=" .. ra_h_m[#ra_h_m] .. "h".. ra_m_m[#ra_m_m] .. "m\nDeclination=" .. dec1.."deg " .. dec2.. "s \nMagnitude="..magn_m[#magn_m] .."\nSize="..size_m[#size_m] .." arc mn\nDistance="..dist_m[#dist_m].." light year(s)\nViewing season=" ..season_m[#season_m] .. "\nViewing difficulty="..diff_m[#diff_m]
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

function extract_from_planets()
  local i,st,sign,j
  local ra_planet,decl_planet
  local rahh,ramn,rass
  local decdeg,decmn,decss
  
  --init global table, in case of update
  ra_h_p={0,0,0,0,0,0,0,0,0,0}
  ra_m_p={0,0,0,0,0,0,0,0,0,0}
  ra_s_p={0,0,0,0,0,0,0,0,0,0}
  decl_p={0,0,0,0,0,0,0,0,0,0}
  comment_p={"","","","","","","","","",""}
  
  numplanet=1
  for i=1,#planetpositions.results do
       --Pay Attention! 9 results for 10 objects, Earth/Moon Barycenter is part of Planets'names table but not part of positions' results table
       if planetpositions.results[i][2] == "Long" then --best accuracy
print(table.concat(planetpositions.results[i],"\t") ) --text legends
          ra_planet = planetpositions.results[i][3]
          --RA exemple      +01h 42mn 32s (sign always "+")
          rahh=tonumber(sub(ra_planet, 2, 3))
          ramn=tonumber(sub(ra_planet, 6, 7))
          rass=tonumber(sub(ra_planet, 11, 12))
          ra_h_p[numplanet] = rahh
          ra_m_p[numplanet] = ramn
          ra_s_p[numplanet] = rass
          decl_planet = planetpositions.results[i][4]
          if sub(decl_planet,1,1) == "+" then
             sign=1
          elseif sub(decl_planet,1,1) == "-" then
             sign=-1
          else
print("Sign problem in planets' table (declination) --> Fix Needed, aborting!")
exit(0)
          end
          
          --DECL exemple  -00deg 48' 08"  (sign + or -)
          decdeg=tonumber(sub(decl_planet, 2, 3))
          decmn=tonumber(sub(decl_planet, 8, 9))
          decss=tonumber(sub(decl_planet, 12,13))
          j = sign*(decdeg+(decmn/60)+(decss/3600))
          decl_p[numplanet] = j
          --global comments table
          st = "Celestial Object= " .. planetpositions.results[i][1] .."\nRA=".. planetpositions.results[i][3] .."\nDECL="..planetpositions.results[i][4] .."\nDIST="..planetpositions.results[i][5]
          comment_p[numplanet] = st
          numplanet=numplanet+1
          if numplanet == 3 then
             numplanet = 4 --Earth/Moon Barycenter is part of Planets'names table but not part of positions' results table 
          end
       end
  end
end --end function

function planet_animation()  
 --planets & Sun animation with time-compression
 --which button called ?
 --forward_b, fforward_b
 local dd,mm,yyyy,hh,mn,ss,t
 
 --dd,mm,yyyy,hh,mn,ss,t = get_date_time()
 jd=tonumber(jd_button:label()) --displayed jd
 t = planetpositions.UnixTimeFromJulianDate(jd)
 
 if Fl.event_inside(forward_b) == 1 then
    --step of one week
    --jd=planetpositions.JulianDateFromUnixTime(t*1000)
    timebeg=t
    timestep=7*24*60*60
 elseif Fl.event_inside(fforward_b) == 1 then
    --step of one month, 30 days
    timebeg=t
    timestep=30*24*60*60
 elseif Fl.event_inside(stop_b) == 1 then
    --stop animation
    timestep=0
    time=0
 else
    --stop animation
    timestep=0
    time=0
 end

 planetpositions.clearResultsTable()
 
 t=timebeg+timestep
 jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
 cwindow:make_current()
 jd_button:label(jd)
 jd_button:redraw()
 
 --updating gregorian date in cmd window
 yyyy, mm, dd = planetpositions.julianDateToGregorian(jd)
 day_b:value(dd)
 month_b:value(mm)
 year_b:value(yyyy)
 
 --update planets positions' table AFTER clearing previous positions
 planetpositions.clearResultsTable()
 planetpositions.computeAll(jd)
 --os.execute("sleep ".. 0.5) --adapted for Linux/Unix OS
 show_objects(t)
end --end function

function plot_messier()  
  local i
  local posx,oldrposx,rposx,posy,f,decx
  local c,d
  
  for i=1,#mess_cat do
       if m_button:value() == 0 then
          messiersb[i]:hide()
       else
          posx= floor(((24-(ra_h_m[i]+(ra_m_m[i]/60)))*grid_hor_width)+grid_decx)
          if decl_m[i]>0 then
              posy=floor((80-decl_m[i])*4)+grid_decy
          else
              posy=floor(-1*decl_m[i]*4)+320+grid_decy
          end
          if magn_m[i] < magn_slider_m:value() then                
             messiersb[i]:position(posx, posy)
             messiersb[i]:labelsize(8)
             --messiersb[i]:labelcolor(256)
             messiersb[i]:labelcolor(labelcol)
             messiersb[i]:redraw_label()
             messiersb[i]:redraw()
             messiersb[i]:show()
          else
             messiersb[i]:hide()
          end
       end
  end
end --end function

function plot_stars()
  local i
  local posx,oldrposx,rposx,posy,f,decx
  local c,d
  
  for i=1,#star do
       if s_button:value() == 1 then
          if magn[i] < magn_slider_s:value() then --magnitude limit condition
             posx= floor(((24-(ra_h[i]+(ra_m[i]/60)+(ra_s[i]/3600)))*grid_hor_width)+grid_decx)
             if decl[i]>0 then
                posy=floor((80-decl[i])*4)+grid_decy
             else
                posy=floor(-1*decl[i]*4)+320+grid_decy
             end
             starsb[i]:position(posx, posy)
             starsb[i]:labelsize(8)
             starsb[i]:labelcolor(labelcol)
             starsb[i]:redraw_label()
             starsb[i]:redraw()
             starsb[i]:show()
          else 
             starsb[i]:hide() --stars with these magnitudes are not selected to be visible
          end --end magnitude condition
          --special colors for selected constellation
          if selconst then 
             if selconst>0 and selconst<=#co then
                if const[i] == constellation_abrev[selconst] then
                   starsb[i]:color(2) --special display
                else
                   starsb[i]:color(1) --usual display
                end
             else
                 starsb[i]:color(1) --usual display --no constellation was selected
             end
          end
       else
          starsb[i]:hide()
       end
 end
end --end function

function plot_planets()
  --module planetpositions.lua required
  --best accuracy, ie LongTerm table
  local i
  local posx,oldrposx,rposx,posy,f,decx
  local c,d
  --[[
  if time  then
     --animation context
     cwindow:make_current()
     jd=planetpositions.JulianDateFromUnixTime(time*1000) --module planetpositions is required
     jd_button:label(jd)
     jd_button:redraw()
     --lacks update of gregorian date
     planetpositions.computeAll(jd)
  end
  window:make_current()
  ]]--
  for i=1,#planetsb do
       --for earth/moon barycenter "EM", no change of pos: keep out of view (Attention: EM pos is needed for other planets computations
       posx= floor(((24-(ra_h_p[i]+(ra_m_p[i]/60)+(ra_s_p[i]/3600)))*grid_hor_width)+grid_decx)      
       if decl_p[i]>0 then
           posy=floor((80-decl_p[i])*4)+grid_decy
       else
           posy=floor(-1*decl_p[i]*4)+320+grid_decy
       end
       if p_button:value() == 1 then
          if i ~= 3 then
             --all planets except barycenter earth/moon
             planetsb[i]:position(posx, posy)
             planetsb[i]:labelsize(12)
             --planetsb[i]:labelcolor(256)
             planetsb[i]:labelcolor(labelcol)
             planetsb[i]:redraw_label()
             planetsb[i]:redraw()
             planetsb[i]:show()
          end
       else
          planetsb[i]:hide()
       end
  end
end --end function

function ask_night()
 --scan this command button
  if night_button:labelcolor() == fltk.FL_YELLOW then
     --day vision
     windowbg=fltk.FL_BACKGROUND_COLOR
     labelcol=fltk.FL_BLACK
     gridcol=4
  else
     --night vision
     windowbg=fltk.FL_BLACK
     labelcol=fltk.FL_WHITE
     gridcol=48
  end
end --end function

function update_time()
 local dd,mm,yyyy,hh,mn,ss,t
 --get current time & update date/time fileds in GUI
 dd,mm,yyyy,hh,mn,ss,t = get_date_time()
 day_b:value(dd)
 month_b:value(mm)
 year_b:value(yyyy)
 hh_b:value(hh)
 mn_b:value(mn)
 ss_b:value(ss)
 jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
 jd_button:label(jd)
 cwindow:redraw()
end --end function

function show_objects(time)  
 if timestep == 0 then 
    update_time() --set date/time to current = NOT in animation context
 end
 window:make_current()
 ask_night() --look for parameter night or day vision? windowbg / gridcol / labelcol
 plot_stars()
 plot_messier()
 plot_planets()
 window:redraw()
 window:show()
end --end function

function select_const()
 local previous_selconst,i
 selconst=0
 --find prev selconst (if any)
 for i=1,#co do
      if co[i]:color() == fltk.FL_RED then
         previous_selconst=i
         break
      end
 end
 --select a unique constellation for separate display
 for i=1,#co do
       if Fl.event_inside(co[i]) == 1 then
--print(constellation_name[i] .. " has been selected !")
          co[i]:color(fltk.FL_RED)
          if previous_selconst then
             co[previous_selconst]:color(fltk.FL_BACKGROUND_COLOR)
          end
          if previous_selconst == i then
             selconst=0
          else
             selconst=i
          end
          break
       end
 end
 cwindow:redraw()
 show_objects(nil)
end --end function

function night_vision()
  local i,j
  local night
  
  --cmd window + color variables update
  if night_button:labelcolor() == fltk.FL_YELLOW then
     --toggle in night mode
     night=1 --night!
     night_button:labelcolor(fltk.FL_BLACK)
     night_button:redraw()
     windowbg=fltk.FL_BLACK
     labelcol=fltk.FL_WHITE
     gridcol=48
  else
     night=0 --day!
     night_button:labelcolor(fltk.FL_YELLOW)
     night_button:redraw()
     windowbg=fltk.FL_BACKGROUND_COLOR
     labelcol=fltk.FL_BLACK
     gridcol=4
  end
  
  --toggle mode
  window:color(windowbg)
  --grid 
  for i=1,#gridb do
       gridb[i]:color(gridcol)
  end
  for i=1,#gridtextdecb do
       gridtextdecb[i]:labelcolor(labelcol)
  end
  for i=1,#gridtextrab do
       gridtextrab[i]:labelcolor(labelcol)
  end
  for i=1,#starsb do
       starsb[i]:labelcolor(labelcol)
  end
  for i=1,#messiersb do
       messiersb[i]:labelcolor(labelcol)
  end
  for i=1,#planetsb do
       planetsb[i]:labelcolor(labelcol)
  end
  window:redraw()
end --end function

function reset_mag_mess()
  magn_slider_m:value(6)
  cwindow:redraw()
  --magn_slider_m:redraw()
  show_objects(nil)
end --end function

function reset_mag_star()
  magn_slider_s:value(4)
  cwindow:redraw()
  --magn_slider_s:redraw()
  show_objects(nil)
end --end function

function reset_planets_anim()
  show_objects(nil)
end --end function

function cmd_display()
 local i,j,k,l,st,b,c,st2
 local time_cell_width=20
 cwindow = fltk:Fl_Window(0,0, width_cwindow, height_cwindow, "Skymap Commander")   
 u_quit = fltk:Fl_Button(0, 0, width_button, height_button, "Quit")
 u_quit:color(fltk.FL_RED)
 u_quit:tooltip("Quit this application")
 u_quit:callback(function (quit_u)
   cwindow:hide()
   cwindow:clear()
   cwindow = nil
  os.exit()
 end)
 --date + time
 dd,mm,yyyy,hh,mn,ss,t = get_date_time()
 day_b = fltk:Fl_Int_Input(0, height_button, time_cell_width, height_button)
 day_b:insert(dd)
 day_b:textsize(10)
 day_b:tooltip("Day 1-31")
--[[
 day_b:callback(  function(inputday)
   alta = alti:value()
   day_b:redraw()
  end)
]]--
 month_b = fltk:Fl_Int_Input(time_cell_width+1, height_button, time_cell_width, height_button)
 month_b:tooltip("Month 1-12")
 month_b:insert(mm)
 month_b:textsize(10)
 year_b= fltk:Fl_Int_Input((2*time_cell_width)+2, height_button, 2*time_cell_width, height_button)
 year_b:tooltip("Year")
 year_b:insert(yyyy)
 year_b:textsize(10)
 --time
 hh_b = fltk:Fl_Int_Input((4*time_cell_width)+16, height_button, time_cell_width, height_button)
 hh_b:insert(hh)
 hh_b:textsize(10)
 hh_b:tooltip("Hours 0-23")
 mn_b = fltk:Fl_Int_Input((5*time_cell_width)+17, height_button, time_cell_width, height_button)
 mn_b:tooltip("Minutes 0-59")
 mn_b:insert(mn)
 mn_b:textsize(10)
 ss_b= fltk:Fl_Int_Input((6*time_cell_width)+18, height_button, time_cell_width, height_button)
 ss_b:tooltip("Seconds 0-59")
 ss_b:insert(ss)
 ss_b:textsize(10)
 
 --Julian date jd converted from previous date time buttons' contents
 --jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
 jd_button = fltk:Fl_Button(0, 2*height_button, (2*width_button), height_button)
 jd_button:label(jd)
 jd_button:tooltip("Julian Date from the given date/time")
 --planetpositions.computeAll(jd)
 --extract_from_planets() --for first displaying of skymap
 
 v_button = fltk:Fl_Button(width_button, 0, width_button, height_button, "Update")
 --v_button:color(fltk.FL_RED)
 v_button:tooltip("Update Skymap with current parameters")
 v_button:callback(show_objects)
 
 night_button = fltk:Fl_Button(2*width_button, 0, height_button, height_button, "@circle")
 --night_button:label("@circle")
 night_button:labelcolor(fltk.FL_YELLOW) --default=day=yellow, night=BLACK
 night_button:tooltip("Toggles between day and night vision")
 night_button:callback(night_vision)
 s1_button = fltk:Fl_Button((2*width_button)+height_button, 0, height_button, height_button, "S1")
 s2_button = fltk:Fl_Button((2*width_button), height_button, height_button, height_button, "S2")
 s3_button = fltk:Fl_Button((2*width_button)+height_button, height_button, height_button, height_button, "S3")
 s4_button = fltk:Fl_Button((2*width_button), (2*height_button), height_button, height_button, "S4")
 s5_button = fltk:Fl_Button((2*width_button)+height_button, (2*height_button), height_button, height_button, "S5")
 k=(2*width_button)+(2*height_button)
 s_button = fltk:Fl_Light_Button(k, 0, width_button, height_button, "Stars")
 s_button:tooltip("Display or not stars from Bright Stars catalog")
 s_button:selection_color(2) --green as default "ON"
 s_button:value(1) --default button as "ON"

 m_button = fltk:Fl_Light_Button(k, height_button, width_button, height_button, "Messier")
 m_button:tooltip("Display or not Messier Objects")
 m_button:selection_color(2) --green as default "ON"
 m_button:value(1) --default button as "ON"
 
 p_button = fltk:Fl_Light_Button(k, 2*height_button, width_button, height_button, "Planets")
 p_button:tooltip("Display or not Planets & Sun")
 p_button:selection_color(2) --green as default "ON"
 p_button:value(1) --default button as "ON"
 --planets animation buttons
 i=(2*width_button)+(2*height_button)+width_button
 fbackward_b = fltk:Fl_Button(i, 2*height_button, height_button, height_button, "@<<")
 backward_b = fltk:Fl_Button(i+height_button, 2*height_button, height_button, height_button, "@<")
 pause_b = fltk:Fl_Button(i+(2*height_button), 2*height_button, height_button, height_button, "@||")
 stop_b = fltk:Fl_Button(i+(3*height_button), 2*height_button, height_button, height_button, "@square")
 stop_b:tooltip("STOP Planets & Sun animation")
 stop_b:callback(planet_animation)
 forward_b = fltk:Fl_Button(i+(4*height_button), 2*height_button, height_button, height_button, "@>")
 forward_b:tooltip("Planets & Sun slow animation from current date : one week between two plotting")
 forward_b:callback(planet_animation)
 fforward_b = fltk:Fl_Button(i+(5*height_button), 2*height_button, height_button, height_button, "@>>")
 fforward_b:callback(planet_animation)
 
 reinit_b = fltk:Fl_Button(i+(6*height_button), 2*height_button, height_button, height_button, "@reload")
 reinit_b:tooltip("Reset Date/Time to current and end animation")
 reinit_b:callback(reset_planets_anim)
 
 magn_slider_s=fltk:Fl_Value_Slider(i, 0, (6*height_button), height_button, nil)
 magn_slider_s:type(fltk.FL_HOR_NICE_SLIDER)
 magn_slider_s:labelsize(8)
 magn_slider_s:textsize(8)
 magn_slider_s:value(4)
 magn_slider_s:maximum(30)
 magn_slider_s:minimum(-30)
 magn_slider_s:tooltip("All Stars below this Magnitude will be displayed")
 reinit_s = fltk:Fl_Button(i+(6*height_button), 0, height_button, height_button, "@reload")
 reinit_s:tooltip("Reset upper limit Magnitude to 4 for Stars")
 reinit_s:callback(reset_mag_star)
 
 magn_slider_m=fltk:Fl_Value_Slider(i, height_button, (6*height_button), height_button, nil)
 magn_slider_m:type(fltk.FL_HOR_NICE_SLIDER)
 magn_slider_m:labelsize(8)
 magn_slider_m:textsize(8)
 magn_slider_m:value(6)
 magn_slider_m:maximum(30)
 magn_slider_m:minimum(-30)
 magn_slider_m:tooltip("All Messier Objects below this Magnitude will be displayed")
 reinit_m = fltk:Fl_Button(i+(6*height_button), height_button, height_button, height_button, "@reload")
 reinit_m:tooltip("Reset upper limit Magnitude to 6 for Messier")
 reinit_m:callback(reset_mag_mess)
 --display constellations buttons
 local width_b_const=21 --19 before
 local height_b_const=15 --11, then 12, before 
 j=(2*width_button)+(2*height_button)+width_button+(7*height_button)
 x=j
 y=0
 for i=1,#constellation_abrev do
      table.insert(co, fltk:Fl_Button(x, y, width_b_const, height_b_const, constellation_abrev[i]) )
      co[#co]:tooltip(constellation_name[i])
      co[#co]:labelsize(8)
      co[#co]:callback( select_const )
      x=x+width_b_const
      if x>=(j+(20*width_b_const)) then
         x=j
         y=y+height_b_const
      end
 end
 y=y+height_b_const
 
 cwindow:show()
end --end function

function info_p()
 --display info about mouse-pointed planet (or sun, moon to come) 
 for i=1,#planetsb do
       if Fl.event_inside(planetsb[i]) == 1 then
fltk:fl_alert(comment_p[i])
       end
 end
end --end function

function info_m()
 --display info about mouse-pointed Messier's object
 for i=1,#messiersb do
       if Fl.event_inside(messiersb[i]) == 1 then
fltk:fl_alert(comment_m[i])
       end
 end
end --end function

function info_s()
 --display info about mouse-pointed star
 for i=1,#starsb do
       if Fl.event_inside(starsb[i]) == 1 then
fltk:fl_alert(comment_bsc[i])
       end
 end
end --end function

function main_display()
 local i,j,k,l,st,b,c,st2,x,y
 local planetcolors={51,54,221,93,84,215,247,247,215,3} --ordered from Mercury to Pluto (last old planet, now small body), and last=Sun (not planet)
 window = fltk:Fl_Window(0,130, width_twindow, height_twindow, "Global skymap")
 --text for grid
 for i=24,0,-1 do
       k=0
       for j=80,-80,-10 do
            --if i==23 then
            if i==24 then
               --vertical declination labels tracing
               st2=j.."deg"
               table.insert(gridtextdecb, fltk:Fl_Box(35, 65+(k*grid_vert_height),30, 30))
               gridtextdecb[#gridtextdecb]:label(st2)
               gridtextdecb[#gridtextdecb]:align(fltk.FL_ALIGN_LEFT)
               gridtextdecb[#gridtextdecb]:labelsize(8)
               --text box with no box
            end
            if j==80 then
               --horizontal "right ascension" labels tracing
               st=i.."h"
               table.insert(gridtextrab, fltk:Fl_Box(grid_decx+((24-i)*grid_hor_width), grid_decy,40, 40))
               gridtextrab[#gridtextrab]:label(st)
               gridtextrab[#gridtextrab]:align(fltk.FL_ALIGN_TOP+fltk.FL_ALIGN_LEFT)
               gridtextrab[#gridtextrab]:labelsize(10)
            end
            k=k+1
       end
  end
  --marks for grid
  for i=24,0,-1 do
       x=grid_decx+((24-i)*grid_hor_width)
       table.insert(gridb, fltk:Fl_Box(x, grid_decy, 1, (16*grid_vert_height) ) )
       gridb[#gridb]:box(fltk.FL_FLAT_BOX)
       gridb[#gridb]:color(4)
       k=0
       for j=80,-80,-10 do
            y=grid_decy+(k*grid_vert_height)
            table.insert(gridb, fltk:Fl_Box(grid_decx, y, 24*grid_hor_width, 1) )
            gridb[#gridb]:box(fltk.FL_FLAT_BOX)
            gridb[#gridb]:color(4)
            k=k+1
       end
  end
  --buttons for stars, messiers, and planets, created with a "standard" location (not in visible area)
  for i=1,#star do
      st=star[i] ..""
      table.insert(starsb, fltk:Fl_Button(-30, -30, 4, 4,st) )
      starsb[#starsb]:box(fltk.FL_FLAT_BOX)
      starsb[#starsb]:color(1)
      starsb[#starsb]:align(fltk.FL_ALIGN_TOP+fltk.FL_ALIGN_CENTER)
      starsb[#starsb]:callback(info_s)
  end
  for i=1,#mess_cat do
       table.insert(messiersb, fltk:Fl_Button(-30, -30, 4, 4,mess_cat[i]) )
       messiersb[#messiersb]:box(fltk.FL_FLAT_BOX)
       messiersb[#messiersb]:color(3)
       --messiersb[#messiersb]:align(fltk.FL_ALIGN_TOP+fltk.FL_ALIGN_CENTER)
       messiersb[#messiersb]:align(fltk.FL_ALIGN_BOTTOM+fltk.FL_ALIGN_CENTER)
       messiersb[#messiersb]:callback(info_m)
  end
   for i=1,#planetpositions.planetNames do
       --Pay Attention!! #3 is Earth/Moon's barycenter, used for computing other positions, BUT NOT TO PLOT !!!
       table.insert(planetsb, fltk:Fl_Button(-30, -30, 8, 8,planetpositions.planetNames[i]) )
       planetsb[#planetsb]:box(fltk.FL_FLAT_BOX)
       planetsb[#planetsb]:color(planetcolors[i])
       planetsb[#planetsb]:align(fltk.FL_ALIGN_BOTTOM+fltk.FL_ALIGN_CENTER)
       planetsb[#planetsb]:tooltip(comment_p[i])
       if #planetsb == 3 then
          --earth/moon barycenter : no display, no callback
       else
          planetsb[#planetsb]:callback(info_p)
       end
  end
  
  window:show()
  window:make_current()
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

function dl_constellations()
 local buffer=""
 local nblines=0
 local pos,j
 --download abrevations & complete names for constellations
 --source=https://www.aavso.org/constellation-names-and-abbreviations
 if find(osName, "linux",1,true) then
     filename_const=pathname .. "/" .. filename_const
 else
     --windows, i presume
     --filename_const=pathname .. "\\constellation_abrev.csv"
     filename_const=pathname .. "\\" .. filename_const
 end
 
print(filename_const)
nblines=0
 if filename_const then
     f = io.open(filename_const,"rb")
     if f then
print("File " .. filename_const .. " opened for reading !")
       buffer = f:read("*all")
       buffer=upper(buffer)
       io.close(f)
       pos=1
       while 1 do
             j = find(buffer,"\n",pos)
             if j then
	            line = sub(buffer, pos, j)
	            if find(line,"TAGS;;;",1,true) then
print("Found \"TAGS;;;\" field ")
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
 --print(table.concat(constellation_name,"/"))
 --print(table.concat(constellation_abrev,"/"))
end --end function

function dl_bsc()
 local buffer="" 
 local nblines=0
 local pos,j
--csv file for celestial objects data loading
--Bright Star Catalogue / dezipped file yalebsc.tar.bz2
--source=https://ian.macky.net/pat/yalebsc/yalebsc.tar.bz2
 if find(osName, "linux",1,true) then
    filename_bsc=pathname .. "/" .. filename_bsc
else
    --windows, i presume
    filename_bsc=pathname .. "\\" .. filename_bsc
end

print(filename_bsc)
nblines=0
 if filename_bsc then
     f = io.open(filename_bsc,"rb")
     if f then
print("File " .. filename_bsc .. " opened for reading !")
       buffer = f:read("*all")
       io.close(f)
       pos=1
       while 1 do
             j = find(buffer,"\n",pos)
             if j then
	            line = sub(buffer, pos, j)
                extract_from_bsc_line(line)
                pos = j+1
                nblines=nblines+1
             else
                  break
             end
       end
    end
 end
end --end function

function dl_messcat() 
 local buffer="" 
 local nblines=0
 local pos,j
--download Messier catalog (110 objects)
 --source page=https://starlust.org/messier-catalog/Messier_Catalog_StarLust.html
 --file at https://docs.google.com/spreadsheets/d/11keXJH6XIeJh6N90yRQ-9X_Pdg9vpq34vWZY8RA9I5c/edit?usp=sharing
 if find(osName, "linux",1,true) then
    filename_mess=pathname .. "/" .. filename_mess
 else
    --windows, i presume
    filename_mess=pathname .. "\\" .. filename_mess
 end
print(filename_mess)

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
end --end function

 t00=0
 t00 = os.time() --top chrono
 --osName="OS=" .. murgaLua.getHostOsName()
  --version FLTK
 print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. "." .. fltk.FL_PATCH_VERSION)
 print("RAM used BEFORE opData by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))

 t=os.time()*1000
 print("Unix time " .. t .. ", JulianDateFromUnixTime = ".. planetpositions.JulianDateFromUnixTime(t))
 
 print("W = " .. Fl:w() .. "\nH = " .. Fl:h())
 if Fl:w() >= 1500 and Fl:h() >= 768 then
    --continue
 else
    st="Sorry, a minimal resolution (Width x Height) = 1500 x 768 is required for this app displaying up to 9200+ celestial objects.\nChange your screen resolution or change host computer !"
    fltk:fl_alert(st)
    exit(0)
 end
 
 if search_path() == nil then
    --first launch => ask for path => save path
    path_finder()
    save_path()
 end
 
 dl_constellations()
 dl_bsc()
 dl_messcat()

 
 if #comment_bsc == 0 or #comment_m == 0 or #constellation_name == 0 then
    st="At least a database is missing, please check your path for following 3 files :\nMessier_Catalog_110_List3.csv\nyalebsc.dat\nconstellation_abrev.csv"
    fltk:fl_alert(comment_m[i])
    exit(0)
 end
 cmd_display()
 
  jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
 planetpositions.computeAll(jd)
 extract_from_planets()  --for 1st display
 
 main_display()
 show_objects(nil)

 print("RAM used AFTER pre_report() -and freeing some huge tables- by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))
 
 print("Processing in " .. os.difftime(os.time(), t00) .. " seconds, ie  " .. format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, ie " .. format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " hours")

  --print("Free RAM by collectgarbage(\"count\") = " .. collectgarbage("count"))
  print("RAM used AFTER opData by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))

Fl:check()
Fl:run()


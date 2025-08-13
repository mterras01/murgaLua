#!/bin/murgaLua

--this murgaLua script has been tested with version 0750 https://github.com/igame3dbill/MurgaLua_0.7.5
--goals=plotting a sky card, adjusting some parameters :
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

--database / tables : tables from a subset of bright star catalog, built with script "astrobuildbsc.lua"
filename_bsc="newbfc.csv"
separator_bsc=";"
hr_star={}
bayer_flamesteed={}
ra_h={}
ra_m={}
ra_s={}
decl={}
magn={}
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

--database / tables : tables for planets & Sun & Moon info data
ra_h_p={0,0,0,0,0,0,0,0,0,0,0} ----11th celestial object is moon for all these tables
ra_m_p={0,0,0,0,0,0,0,0,0,0,0}
ra_s_p={0,0,0,0,0,0,0,0,0,0,0}
decl_p={0,0,0,0,0,0,0,0,0,0,0}
comment_p={"","","","","","","","","","",""} --11th celestial object is moon

--database url = https://github.com/MarcvdSluys/ConstellationLines/blob/master/ConstellationLines.dat
-- ConstellationLines.dat: lists of BSC stars to connect in order to draw the constellations.
-- Licence: Creative commons Attribution-ShareAlike 4.0 International (CC BY-SA 4.0 - https://creativecommons.org/licenses/by-sa/4.0/)
-- Source and documentation: https://github.com/MarcvdSluys/ConstellationLines
-- Copyright (c) 2005-2023, Marc van der Sluys - https://hemel.waarnemen.com
-- adapted to Lua by MT 110825
asterisms={
"And  20 8961 8976 8965 8762 8965   68  165   15  165  163  215  163  165  337  603  337  464  337  269  226"
,"Ant   4 4273 4104 3871 3765"
,"Aps   4 5470 6020 6102 6163"
,"Aql  12 7602 7557 7525 7377 7235 7377 7570 7710 7570 7377 7236 7193"
,"Aqr  15 8812 8841 8834 8597 8518 8698 8709 8698 8518 8499 8418 8499 8518 8414 8232"
,"Ara  11 6743 6510 6461 6462 6500 6462 6285 6229 6285 6295 6510"
,"Ari   6  951  888  838  617  553  546"
,"Aur   9 1708 2088 2095 1791 1577 1612 1641 1605 1708"
,"Boo  11 5435 5429 5340 5506 5681 5602 5435 5351 5404 5329 5351"
,"CMa  15 2596 2574 2657 2596 2491 2294 2429 2580 2618 2646 2693 2827 2693 2653 2491"
,"CMi   2 2943 2845"
,"CVn   2 4915 4785"
,"Cae   3 1443 1502 1503"
,"Cam   7 1040 1035 1155 1148 1542 1603 1568"
,"Cap  11 7754 7776 7936 7980 8204 8278 8322 8278 8167 8075 7776"
,"Car  11 2326 2554 3117 3307 3699 4050 4140 4199 4037 3685 3890"
,"Cas   5  542  403  264  168   21"
,"Cen  23 4467 4522 4390 4638 4621 4743 4802 4819 5132 5267 5132 5459 5132 5231 5193 5190 5028 5190 5288 5190 5248 5440 5576"
,"Cep   6 8974 8238 8162 8465 8694 8974"
,"Cet  15  804  718  813  896  911  804  779  681  539  402  334  188  433  585  539"
,"Cha   6 3318 3340 4231 4674 4174 3318"
,"Cir   3 5670 5463 5704"
,"Cnc   6 3572 3461 3249 3461 3449 3475"
,"Col   8 2296 2256 2106 2040 2120 2040 1956 1743"
,"Com   3 4968 4983 4737"
,"CrA   6 7152 7226 7254 7259 7242 7188"
,"CrB   7 5971 5947 5889 5849 5793 5747 5778"
,"Crt  10 4567 4514 4405 4343 4287 4382 4405 4382 4402 4468"
,"Cru   2 4730 4763"
,"Cru   2 4853 4656"
,"Crv   6 4623 4630 4662 4757 4786 4630"
,"Cyg  11 7417 7615 7796 7949 8115 7949 7796 7924 7796 7528 7420"
,"Del   6 7852 7882 7906 7948 7928 7882"
,"Dor   7 1338 1465 1674 1922 2015 1922 2102"
,"Dra  17 6688 6705 6536 6554 6688 7310 7582 6927 6636 6396 6132 5986 5744 5291 4787 4434 3751"
,"Equ   4 8131 8178 8123 8097"
,"Eri  31 1666 1560 1520 1463 1298 1231 1136 1084  874  811  818  919 1003 1088 1173 1213 1240 1464 1393 1347 1195 1190 1106 1008  898  794  789  721  674  566  472"
,"For   3  963  841  612"
,"Gem  26 2134 2216 2286 2473 2343 2473 2697 2852 2890 2852 2697 2540 2697 2821 2905 2990 2905 2985 2905 2777 2650 2421 2650 2777 2763 2484"
,"Gru  11 8353 8411 8556 8636 8425 8636 8675 8747 8675 8820 8787"
,"Her  19 6324 6418 6695 6588 6695 6418 6220 6168 6092 6168 6220 6212 6148 6212 6324 6410 6623 6703 6779"
,"Hor   8  909  934  802  778  810  868 1326 1302"
,"Hya  18 3492 3482 3410 3418 3454 3492 3547 3665 3845 3748 3903 3994 4094 4232 4450 4552 5020 5287"
,"Hyi   5  591  806 1208   98  591"
,"Ind   8 7869 8140 8368 8387 8368 8140 8055 7986"
,"LMi   3 4247 4100 3974"
,"Lac  12 8498 8485 8579 8632 8579 8523 8579 8572 8541 8538 8585 8572"
,"Leo  16 3873 3905 4031 4058 3975 3982 3852 3982 4359 4399 4386 4399 4359 4534 4357 4058"
,"Lep   7 1654 1829 1865 1702 1865 1998 2085"
,"Lib   9 5908 5787 5685 5531 5603 5685 5603 5794 5812"
,"Lup  13 5987 5948 5776 5708 5646 5649 5469 5571 5695 5776 5695 5705 5883"
,"Lyn   8 3705 3690 3612 3579 3275 2818 2560 2238"
,"Lyr   6 7001 7056 7106 7178 7139 7056"
,"Men   4 2261 1953 1629 1677"
,"Mic   4 8151 8135 8039 7965"
,"Mon  10 2385 2298 2506 2714 2356 2227 2356 2714 2970 3188"
,"Mus   8 4844 4798 4923 4798 4773 4798 4671 4520"
,"Nor   3 6115 6072 5962"
,"Oct   4 8630 5339 8254 8630"
,"Oph   9 6556 6299 6149 6056 6075 6175 6378 6603 6556"
,"Ori  30 1948 2004 1713 1852 1790 1879 2061 2124 2199 2159 2047 2135 2199 2124 2061 1948 1903 1852 1790 1543 1552 1567 1601 1567 1552 1543 1544 1580 1638 1676"
,"Pav  12 7790 7913 8181 7913 7590 6982 6582 6745 6855 7074 7665 7913"
,"Peg  13 8454 8650 8775   15 8775 8781   39   15   39 8781 8634 8450 8308"
,"Per   9  936  941 1017  915 1017 1122 1220 1228 1203"
,"Phe  10   99  322  429  440  429  322  338  191   25   99"
,"Pic   3 2550 2042 2020"
,"PsA  11 8728 8628 8478 8386 8326 8305 8431 8576 8695 8720 8728"
,"Psc  19  360  383  352  360  437  510  596  489  294  224 9072 8969 8916 8878 8852 8911 8984 9004 8969"
,"Pup  10 3185 3045 2948 2922 2773 2451 2553 2878 3165 3185"
,"Pyx   3 3438 3468 3518"
,"Ret   6 1336 1355 1247 1264 1175 1336"
,"Scl   4  280 9016 8863 8937"
,"Sco  17 5985 6084 5953 6084 5944 6084 6134 6165 6241 6247 6271 6380 6553 6615 6580 6527 6508"
,"Sct   5 7063 6973 6930 6973 6884"
,"Ser   5 6446 6561 6581 6869 7142"
,"Ser   9 5867 5879 5933 5867 5788 5854 5892 5881 6446"
,"Sex   3 4119 3981 3909"
,"Sge   5 7635 7536 7479 7536 7488"
,"Sgr  31 7348 7581 7337 7581 7623 7650 7604 7440 7234 7121 7217 7264 7340 7342 7340 7264 7217 7150 7217 7121 7039 7194 7234 7194 7039 6913 6859 6746 6859 6879 6832"
,"Tau  10 1910 1457 1346 1239 1030 1239 1346 1373 1409 1791"
,"Tel   3 6783 6897 6905"
,"TrA   5 6217 5671 5771 5897 6217"
,"Tri   4  622  664  544  622"
,"Tuc   7 8540 8502 8848 9076   77  126 8848"
,"UMa  29 5191 5054 4905 4660 4554 4518 4377 4375 4377 4518 4335 4069 4033 4069 4335 4518 4554 4295 4301 4660 4301 3757 3323 3888 4295 3888 3775 3594 3569"
,"UMi   8  424 6789 6322 5903 5563 5735 6116 5903"
,"Vel  12 3206 3485 3734 3940 4216 4167 4023 3786 3634 3477 3426 3206"
,"Vir   6 5056 4963 4826 4910 5107 5056"
,"Vol   7 3615 3347 3223 2803 2736 3024 3223"
,"Vul   3 7306 7405 7592"
}

--GUI
window=object
width_window, height_window= 1500, 768
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
grid_mid_vert=0
pixelsperdeg=1

--time vars
jd=0 --julian date
sign_timestep=1 --default=direction's time for planets' animation is future (past is -1)
timestep=0 --unit of time between two plotting (julian date format, nb of millisec)
timebeg=0 --beginning in time of the current animation (julian date format, nb of millisec)
timelapsefactor=10000 --time scale = increasing => lower animation speed, decreasing => higher animation speed
tron=0

--location for database files (ONE path for all files)
pathname=""

--timers needed for planets animation
 timer = murgaLua.createFltkTimer()
function start_timer()
    timer:doWait(4)
end --end function
function stop_timer()
    if (timer:isActive() == 1) then
       timer:doWait(0)
    else
	   timer:doWait(0)
     end
end --end function
function renew_timer()
       Fl:check()
       timer:doWait(1)
end --end function
timer:callback(renew_timer)

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

function extract_from_bsc2_line(line) 
 local st,i,j,nb,constp,occurs,pos,loc
 local cdecl,decl_sign, decl_d, decl_m, decl_s, mag_sign
 
 if line == nil then
    return
 end
 _, occurs = line:gsub(separator_bsc, "") --check for 11 separator occurences
 if occurs ~= 11 then
    return
 end
 pos=1
 loc=find(line,separator_bsc,pos,true) --1st separator
 if loc then
    st=sub(line,pos,loc-1)
    nb=tonumber(st)
    table.insert(hr_star, nb)
 end
 pos=loc+1
 loc=find(line,separator_bsc,pos,true) --2nd separator
 if loc then
    st=sub(line,pos,loc-1)
    table.insert(bayer_flamesteed, st)
 end
 pos=loc+1 --afer 2nd separator = formatted area (with separator) = Right Ascension hh;mm;ss;sign of decl;dd;mm;ss;magnitude 5 digits; etc.
 --sample : 1st line
 --1;          ;00;05;10;+;45;13;45;+6.70;   ;in Andromeda
 if loc then
    st=sub(line,pos,pos+1)
    nb=tonumber(st)
    table.insert(ra_h, nb)
    st=sub(line,pos+3,pos+4)
    nb=tonumber(st)
    table.insert(ra_m, nb)
    st=sub(line,pos+6,pos+7)
    nb=tonumber(st)
    table.insert(ra_s, nb)
    if sub(line,pos+9,pos+9) == "+" then
       decl_sign=1
    else
      decl_sign=-1
    end
    st=sub(line,pos+11,pos+12)
    decl_d=tonumber(st)
    st=sub(line,pos+14,pos+15)
    decl_m=tonumber(st)
    st=sub(line,pos+17,pos+18)
    decl_s=tonumber(st)
    cdecl = decl_sign*tonumber(format('%2.3f', (decl_d+(decl_m/60)+(decl_s/3600) ) ) )
    table.insert(decl, cdecl)
    if sub(line,pos+20,pos+20) == "+" then
       mag_sign=1
    else
       mag_sign=-1
    end
    st=sub(line,pos+21,pos+24)
    nb=tonumber(st)
    magnitude=mag_sign*nb
    table.insert(magn, magnitude)
    --last two fields are strings
    constellation = upper(sub(line,pos+26,pos+28))
    if constellation == "   " then
       constellation = "" --empty string
    end
    table.insert(const, constellation)
    j=find(line,"\n",1,true)
    if j then
       starname = sub(line,pos+30,j-1)
    else
       starname = sub(line,pos+30)
    end
    if starname == nil then
       starname =""
    end
    table.insert(star, starname)
 end

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
    st="HR Number " .. hr_star[#hr_star] .. "\nBayer Flamesteed name=" ..bayer_flamesteed[#bayer_flamesteed].. "\nRA="..ra_h[#ra_h] .."h ".. ra_m[#ra_m] .."mn " .. ra_s[#ra_s].. "s\nDecl= "..(decl_sign*decl_d) .."deg"..decl_m.."mn"..decl_s.."secs (original) (decimal computed=" .. decl[#decl] .."deg)\nMagn=".. magn[#magn] .."\n" .. "Const=" .. constp .. "\nStar=" ..star[#star]
    table.insert(comment_bsc, st)
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

function print_planetpositions()
 local i
 if planetspositions.results then
print(table.concat(planetpositions.results[1],"\t") ) --text legends
    for i=1,#planetpositions.results do
       if planetpositions.results[i][2] == "Long" then --best accuracy
print(table.concat(planetpositions.results[i],"\t") )
       end
    end
 end
end --end function

function extract_from_planets()
  local i,st,sign,j
  local ra_planet,decl_planet
  local rahh,ramn,rass
  local decdeg,decmn,decss
  local dd,mm,yyyy,hh,mn,ss
  --init global table, in case of update
  ra_h_p={0,0,0,0,0,0,0,0,0,0,0} ----11th celestial object is moon for all these tables
  ra_m_p={0,0,0,0,0,0,0,0,0,0,0}
  ra_s_p={0,0,0,0,0,0,0,0,0,0,0}
  decl_p={0,0,0,0,0,0,0,0,0,0,0}
  comment_p={"","","","","","","","","","",""} --11th celestial object is moon
  
  numplanet=1
  for i=1,#planetpositions.results do
       --Pay Attention! 9 results for 10 objects, Earth/Moon Barycenter is part of Planets'names table but not part of positions' results table
       if planetpositions.results[i][2] == "Long" then --best accuracy
--print(table.concat(planetpositions.results[i],"\t") ) --text legends
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
  numplanet=11 --Moon, not a planet
  if jd>0 then
     --continue
  else
     dd,mm,yyyy,hh,mn,ss,t=get_date_time()
     jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
  end
  ra,dec,d=planetpositions.getGeocentricMoonPos(jd)
  ra_h_p[numplanet] = floor(ra)
  ra_m_p[numplanet] = floor((ra-floor(ra))*60)
  ra_s_p[numplanet] = 0 --no use, low accuracy flor plotting is expected
  decl_p[numplanet] = dec
  st = "Celestial Object= " .. planetpositions.planetNames[numplanet] .."\nRA=".. ra_h_p[numplanet].."H ".. ra_m_p[numplanet].."mn " ..ra_s_p[numplanet] .."sec " .."\nDECL="..decl_p[numplanet] .."\nDIST="..d.. "AU"
  comment_p[numplanet] = st
end --end function

function draw_planet_animation()
  planet_animation()
  Fl:check()
  timer:doWait(0.2)
end

function timer_planet_animation()  
 if timestep == 0 then
    st="Before launching Planets' animation, set timestep first, to 1, 7 or 30 days !"
    fltk:fl_alert(st)
print(st)
 else
    timer:callback(draw_planet_animation)
    timer:do_callback()
 end
end --end function

function get_timestep_sign()
 --set direction of time animation : +=future, -=past
 --ATTENTION! function JulianDateFromUnixTime() in module planetpositions.lua is Not valid for dates before Oct 15, 1582
 if sign_b:label() == "@-4->" then
    sign_timestep = -1
    sign_b:label("@-4<-")
 else
    sign_timestep = 1
    sign_b:label("@-4->")
 end
end --end function

function get_timestep()
 --this function is called once BEFORE animation
 if Fl.event_inside(forward_b) == 1 then
    --step of one day
    timestep=24*60*60
    forward_b:labelcolor(1)
    fforward_b:labelcolor(256)
    vfforward_b:labelcolor(256)
    forward_b:redraw()
    fforward_b:redraw()
    vfforward_b:redraw()
print("Timestep is set to one day")
 elseif Fl.event_inside(fforward_b) == 1 then
    --step of one week, 7 days
    timestep=7*24*60*60
    forward_b:labelcolor(256)
    fforward_b:labelcolor(1)
    vfforward_b:labelcolor(256)
    forward_b:redraw()
    fforward_b:redraw()
    vfforward_b:redraw()
print("Timestep is set to seven days")
 elseif Fl.event_inside(vfforward_b) == 1 then
    --step of one month, 30 days
    timestep=30*24*60*60
    forward_b:labelcolor(256)
    fforward_b:labelcolor(256)
    vfforward_b:labelcolor(1)
    forward_b:redraw()
    fforward_b:redraw()
    vfforward_b:redraw()
print("Timestep is set to thirty days")
 else
    --nothing
 end
end --end function

function planet_animation()  
 --planets & Sun animation with time-compression
 local dd,mm,yyyy,hh,mn,ss,t
 
 jd=tonumber(jd_button:label()) --displayed jd
 t = planetpositions.UnixTimeFromJulianDate(jd)/1000
 timebeg=t
 t=timebeg+(timestep*sign_timestep)
 planetpositions.clearResultsTable()
 jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
 window:make_current()
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
 extract_from_planets()
 
 --show_objects()
 --window:make_current()
 ask_night() --look for parameter night or day vision? windowbg / gridcol / labelcol
 plot_planets()
 Fl:check()
 if tron==1 then
    --no redraw() => trajectory is visible and 
 else
    window:redraw()
 end
 --window:show()
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
              --posy=floor((80-decl_m[i])*4)+grid_decy
              posy=floor((80-decl_m[i])*pixelsperdeg)+grid_decy
          else
              --posy=floor(-1*decl_m[i]*4)+320+grid_decy
              posy=floor(-1*decl_m[i]*pixelsperdeg)+grid_mid_vert
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
                --posy=floor((80-decl[i])*4)+grid_decy
                posy=floor((80-decl[i])*pixelsperdeg)+grid_decy
             else
                --posy=floor(-1*decl[i]*4)+320+grid_decy
                posy=floor(-1*decl[i]*pixelsperdeg)+grid_mid_vert
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
  
  for i=1,#planetsb do
       --for earth/moon barycenter "EM", no change of pos: keep out of view (Attention: EM pos is needed for other planets computations
       posx= floor(((24-(ra_h_p[i]+(ra_m_p[i]/60)+(ra_s_p[i]/3600)))*grid_hor_width)+grid_decx)      
       if decl_p[i]>0 then
           --posy=floor((80-decl_p[i])*4)+grid_decy -- "*4" was for "40 pixels per 10 degrees"
           posy=floor((80-decl_p[i])*pixelsperdeg)+grid_decy
       else
           --posy=floor(-1*decl_p[i]*4)+320+grid_decy -- "*4" was for "40 pixels per 10 degrees" and 320 for midscreen's mark
           posy=floor(-1*decl_p[i]*pixelsperdeg)+grid_mid_vert --+grid_decy
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
  --plotting moon
  i=11
  posx= floor(((24-(ra_h_p[i]+(ra_m_p[i]/60)+(ra_s_p[i]/3600)))*grid_hor_width)+grid_decx)      
  if decl_p[i]>0 then
     posy=floor((80-decl_p[i])*pixelsperdeg)+grid_decy
  else
     posy=floor(-1*decl_p[i]*pixelsperdeg)+grid_mid_vert --+grid_decy
  end
  if p_button:value() == 1 then
        --all planets except barycenter earth/moon
        planetsb[i]:position(posx, posy)
        planetsb[i]:labelsize(12)
        --planetsb[i]:labelcolor(256)
       planetsb[i]:labelcolor(labelcol)
       planetsb[i]:redraw_label()
       planetsb[i]:redraw()
       planetsb[i]:show()
  else
     planetsb[i]:hide()
  end
  
end --end function

function plotter_asterism(constast, nodes_ast, hr_ast_array)
 local i, j, x1, y1, x2, y2
 
 fltk.fl_color(4)
 for i=1,#hr_ast_array-1 do
      j=hr_ast_array[ i ] --star index
      x1= floor(((24-(ra_h[j]+(ra_m[j]/60)+(ra_s[j]/3600)))*grid_hor_width)+grid_decx)
      if decl[j]>0 then
         y1=floor((80-decl[j])*pixelsperdeg)+grid_decy
      else
         y1=floor(-1*decl[j]*pixelsperdeg)+grid_mid_vert
      end
      j=hr_ast_array[ i+1 ] --next star index
      x2= floor(((24-(ra_h[j]+(ra_m[j]/60)+(ra_s[j]/3600)))*grid_hor_width)+grid_decx)
      if decl[j]>0 then
         y2=floor((80-decl[j])*pixelsperdeg)+grid_decy
      else
         y2=floor(-1*decl[j]*pixelsperdeg)+grid_mid_vert
      end
      fltk.fl_line(x1, y1, x2,y2)
 end
end --end function

function get_info_asterism2( cname )
 --get constellation's info from its (3 cars-text) name
 local i,j,st,idx
 local constast,nodes_ast
 local hr_nb_array={}
 
 for j=1,#asterisms do
     if cname  == upper( sub(asterisms[j], 1,3) ) then
        idx=j
        break
     end
 end
 --asterism samples
 --"Sco  17 5985 6084 5953 6084 5944 6084 6134 6165 6241 6247 6271 6380 6553 6615 6580 6527 6508"
 --"Aps   4 5470 6020 6102 6163"
 --"Cas   5  542  403  264  168   21"
 constast = upper( sub(asterisms[idx], 1,3) )
 st=sub(asterisms[idx], 6,7)
 nodes_ast = tonumber(st)
 for i=9,#asterisms[idx],5 do
      st=sub(asterisms[idx], i,(i+3))
      j=tonumber(st)
      table.insert(hr_nb_array, j)
 end
 --[[
 if #hr_nb_array == nodes_ast then
print("Number of Nodes in array for constellation ".. constast .. " (".. nodes_ast ..") is equal to computed nodes tables (" ..#hr_nb_array.. ")")
print("Detailed node array with HR_numbers = " .. table.concat(hr_nb_array,"//") )
 end
 --]]--
 return constast,nodes_ast,hr_nb_array
end --end function

function get_info_asterism( idx )
 local i,j,st
 local constast,nodes_ast
 local hr_nb_array={}
 --asterism samples
 --"Sco  17 5985 6084 5953 6084 5944 6084 6134 6165 6241 6247 6271 6380 6553 6615 6580 6527 6508"
 --"Aps   4 5470 6020 6102 6163"
 --"Cas   5  542  403  264  168   21"
 constast = upper( sub(asterisms[idx], 1,3) )
 st=sub(asterisms[idx], 6,7)
 nodes_ast = tonumber(st)
 for i=9,#asterisms[idx],5 do
      st=sub(asterisms[idx], i,(i+3))
      j=tonumber(st)
      table.insert(hr_nb_array, j)
 end
 if #hr_nb_array == nodes_ast then
print("Number of Nodes in array for constellation ".. constast .. " (".. nodes_ast ..") is equal to computed nodes tables (" ..#hr_nb_array.. ")")
print("Detailed node array with HR_numbers = " .. table.concat(hr_nb_array,"//") )
 end
 return constast,nodes_ast,hr_nb_array
end --end function

function plot_asterisms(cname)
 local i, j, const_name, st
 local hr_ast_array={}
 
--window:make_current()
 if cname then
    --plot this asterism described by constellation's name
    for j=1,#asterisms do
         constasterisms = upper( sub(asterisms[j], 1,3) )
         if cname  == constasterisms then
            constast, nodes_ast, hr_ast_array = get_info_asterism( j )
            plotter_asterism(constast, nodes_ast, hr_ast_array)
         end
    end
 else
    --plot ALL asterism
    for i=1,#constellation_abrev do
         for j=1,#asterisms do
              constasterisms = upper( sub(asterisms[j], 1,3) )
              if cname then
              else
                 if constasterisms == constellation_abrev[i] then
                    constast, nodes_ast, hr_ast_array = get_info_asterism( j )
                    plotter_asterism(constast, nodes_ast, hr_ast_array)
                 end
              end
         end
    end
 end
 Fl:check()
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
 window:redraw()
end --end function

function show_objects()  
--print("Appel show_objects() avec timestep = " .. timestep)
 if timestep == 0 then 
    update_time() --set date/time to current = NOT in animation context
    dd,mm,yyyy,hh,mn,ss,t = get_date_time()
    planetpositions.clearResultsTable()
    jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
    planetpositions.computeAll(jd)
    extract_from_planets()
    ra,dec,d=planetpositions.getGeocentricMoonPos(jd)
--print("Moon Pos at JD=" .. jd .."\nRA="..ra.."\nDecl=".. dec.."\nDist="..d .. "AU, ie " .. (d*149597870.7).. " km")
 else
--print("jd=" .. jd)
 end
 window:make_current()
 ask_night() --look for parameter night or day vision? windowbg / gridcol / labelcol
 plot_stars()
 plot_messier()
 plot_planets()
 --window:make_current()
 --plot_asterisms("ORI")
 --plot_asterisms("UMA")
 --plot_asterisms("CAS")
 
 window:redraw()
 window:show()
end --end function

function get_hr_array_idx( hr_ast_array_idx )
 local i
 for i=1,#hr_star do
      if hr_star[ i ] == hr_ast_array_idx then
         return i
      end
 end
end --end function

function select_const2()
 --Version 2 for plotting selected constellation asterism 
 local i,x1,y1,x2,y2,cname,cidx
 local constast, nodes_ast
 local hr_ast_array={}
 local previous_selconst=0
 for i=1,#co do
      if Fl.event_inside(co[ i ]) == 1 then
         cname = co[ i ]:label() --less smart than self:label(), but self solution does not work for some reason
         cidx = i
         break
      end
 end
 if cname == nil then 
    return
 end 
 --search previous GUI selection BUTTON for constellation, if any
 for i=1,#co do
      if co[i]:color() == fltk.FL_RED then
         previous_selconst=i
      end
      co[i]:color(fltk.FL_BACKGROUND_COLOR)
      co[i]:redraw()
 end
 for i=1,#co do
       if i == cidx then
--print(constellation_name[i] .. " has been selected !")
          co[i]:color(fltk.FL_RED)
          if previous_selconst>0 then
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
 constast, nodes_ast, hr_ast_array = get_info_asterism2( cname )
--DEBUG INFO 
print(constast.. "-- " .. nodes_ast .. " -- (#hr_ast_array=)".. #hr_ast_array ..")" .. table.concat(hr_ast_array,"//") )
for i=1,#hr_ast_array do
    --j=hr_ast_array[ i ]
    j = get_hr_array_idx( hr_ast_array[ i ] )
    print( "HR" .. hr_star[ j ] .. ". RA=" ..ra_h[ j ].."h".. ra_m[ j ].."mn".. ra_s[ j ].. "sec, DECL=".. decl[ j ] )
end
 
 window:make_current() -- needed for all drawing functions
 fltk.fl_color(4)
 fltk.fl_line_style(fltk.FL_SOLID, 2, nil) --must be set only AFTER drawing color
 -- Linux will segfault unless we set the font before using fl_draw (=text drawing) with, for example, fltk.fl_font(fltk.FL_HELVETICA_BOLD,20)
  for i=1,#hr_ast_array-1 do
      --j=hr_ast_array[ i ] --star index
      j = get_hr_array_idx( hr_ast_array[ i ] )  --star index
      x1= floor(((24-(ra_h[j]+(ra_m[j]/60)+(ra_s[j]/3600)))*grid_hor_width)+grid_decx)
      if decl[j]>0 then
         y1=floor((80-decl[j])*pixelsperdeg)+grid_decy
      else
         y1=floor(-1*decl[j]*pixelsperdeg)+grid_mid_vert
      end
      --j=hr_ast_array[ i+1 ] --next star index
      j = get_hr_array_idx( hr_ast_array[ i+1 ] )  --next star index
      x2= floor(((24-(ra_h[j]+(ra_m[j]/60)+(ra_s[j]/3600)))*grid_hor_width)+grid_decx)
      if decl[j]>0 then
         y2=floor((80-decl[j])*pixelsperdeg)+grid_decy
      else
         y2=floor(-1*decl[j]*pixelsperdeg)+grid_mid_vert
      end
      fltk.fl_line(x1, y1, x2,y2)
 end
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
  window:redraw()
  show_objects()
end --end function

function reset_mag_star()
  magn_slider_s:value(4)
  window:redraw()
  show_objects()
end --end function

function reset_planets_anim()
 stop_timer() --stop anim
 timestep=0
 --dd,mm,yyyy,hh,mn,ss,t=get_date_time()
 show_objects()
end --end function

function info_p()
 --display info about mouse-pointed planet (or sun, moon to come)  
 local st
 for i=1,#planetsb do
       if Fl.event_inside(planetsb[i]) == 1 then
          st = comment_p[i] .. "\nJulianDate=" .. jd_button:label()
          st = st .. "\nGregorianDate=" .. day_b:value() .. "/" .. month_b:value() .. "/" .. year_b:value().. " at ".. hh_b:value() .. ":" .. mn_b:value() .. ":" .. ss_b:value()
fltk:fl_alert(st)
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

function traceon()
 --toggles between trace ON and trace OFF for planets animation : partial redrawing enables visualization of celestial body's trajectory
 if s1_button:label() == "ON" then
    s1_button:label("OFF")
    s1_button:redraw()
    tron=0
 else
    s1_button:label("ON")
    s1_button:redraw()
    tron=1
 end
end --end function

function main_display()
 local i,j,k,l,st,b,c,st2,x,y
 local time_cell_width=20
 local width_button,height_button=80,15
 local labelsize=10
 
 local planetcolors={51,54,221,93,84,215,247,247,215,3,27} --ordered from Mercury to Pluto (last old planet, now small body), and forlast=Sun (not planet) and very last=Moon
 --window = fltk:Fl_Window(0,0, width_window, height_window, "Global skymap")
 Fl:visual(FL_RGB)
 window = fltk:Fl_Double_Window(0,0, width_window, height_window, "Global skymap")
--GUI commands & parameters
 u_quit = fltk:Fl_Button(0, 0, width_button, height_button, "Quit")
 u_quit:color(fltk.FL_RED)
 u_quit:labelsize(labelsize)
 u_quit:tooltip("Quit this application")
 u_quit:callback(function (quit_u)
  stop_timer() --ends animation
  os.exit()
 end)
 --
 dd,mm,yyyy,hh,mn,ss,t = get_date_time()
 day_b = fltk:Fl_Int_Input(0, height_button, time_cell_width, height_button)
 day_b:insert(dd)
 day_b:textsize(10)
 day_b:tooltip("Day 1-31")
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
 --
 --Julian date jd converted from previous date time buttons' contents
 jd_button = fltk:Fl_Button(0, 2*height_button, (2*width_button), height_button)
 jd_button:label(jd)
 jd_button:tooltip("Julian Date from the given date/time")
 jd_button:labelsize(labelsize)
 
 v_button = fltk:Fl_Button(width_button, 0, width_button, height_button, "Update")
 v_button:tooltip("Update Skymap with current parameters")
 v_button:labelsize(labelsize)
 v_button:callback(show_objects)
 --
 night_button = fltk:Fl_Button(2*width_button, 0, height_button, height_button, "@-2circle")
 --night_button:label("@circle")
 night_button:labelcolor(fltk.FL_YELLOW) --default=day=yellow, night=BLACK
 night_button:tooltip("Toggles between day and night vision")
 night_button:labelsize(labelsize)
 night_button:callback(night_vision)
 s1_button = fltk:Fl_Button((2*width_button)+height_button, 0, height_button, height_button, "ON")
 s1_button:tooltip("Planet's trajectory is visible (trace ON)/invisible (trace OFF)")
 s1_button:callback(traceon)
 s1_button:labelsize(labelsize-2)
 s2_button = fltk:Fl_Button((2*width_button), height_button, height_button, height_button, "S2")
 s2_button:labelsize(labelsize)
 s3_button = fltk:Fl_Button((2*width_button)+height_button, height_button, height_button, height_button, "S3")
 s3_button:labelsize(labelsize)
 s4_button = fltk:Fl_Button((2*width_button), (2*height_button), height_button, height_button, "S4")
 s4_button:labelsize(labelsize)
 s5_button = fltk:Fl_Button((2*width_button)+height_button, (2*height_button), height_button, height_button, "S5")
 s5_button:labelsize(labelsize)
 k=(2*width_button)+(2*height_button)
 s_button = fltk:Fl_Light_Button(k, 0, width_button, height_button, "Stars")
 s_button:tooltip("Display or not stars from Bright Stars catalog")
 s_button:selection_color(2) --green as default "ON"
 s_button:value(1) --default button as "ON"
 s_button:labelsize(labelsize)

 m_button = fltk:Fl_Light_Button(k, height_button, width_button, height_button, "Messier")
 m_button:tooltip("Display or not Messier Objects")
 m_button:selection_color(2) --green as default "ON"
 m_button:value(1) --default button as "ON"
 m_button:labelsize(labelsize)
 
 p_button = fltk:Fl_Light_Button(k, 2*height_button, width_button, height_button, "Planets")
 p_button:tooltip("Display or not Planets & Sun")
 p_button:selection_color(2) --green as default "ON"
 p_button:value(1) --default button as "ON"
 p_button:labelsize(labelsize)
 --
 --planets animation buttons
 i=(2*width_button)+(2*height_button)+width_button
 sign_b = fltk:Fl_Button(i, 2*height_button, height_button, height_button, "@-4->")
 sign_b:callback(get_timestep_sign)
 sign_b:tooltip("Set direction in time toggling between <= (past) and => (future)")
 stop_b = fltk:Fl_Button(i+(1*height_button), 2*height_button, height_button, height_button, "@-4square")
 stop_b:tooltip("STOP Planets & Sun animation")
 stop_b:callback(stop_timer)
 forward_b = fltk:Fl_Button(i+(2*height_button), 2*height_button, height_button, height_button, "1")
 forward_b:labelsize(labelsize)
 forward_b:tooltip("Planets & Sun slow animation from current date : one day between updates")
 forward_b:callback(get_timestep)
 fforward_b = fltk:Fl_Button(i+(3*height_button), 2*height_button, height_button, height_button, "7")
 fforward_b:labelsize(labelsize)
 fforward_b:tooltip("Planets & Sun faster animation from current date : one week between updates")
 fforward_b:callback(get_timestep)
 vfforward_b = fltk:Fl_Button(i+(4*height_button), 2*height_button, height_button, height_button, "30")
 vfforward_b:labelsize(labelsize)
 vfforward_b:tooltip("Planets & Sun fastest animation from current date : one month between updates")
 vfforward_b:callback(get_timestep)
 play_b = fltk:Fl_Button(i+(5*height_button), 2*height_button, height_button, height_button, "@-4>")
 play_b:labelsize(labelsize)
 play_b:tooltip("Play Planets & Sun animation with current timestep")
 play_b:callback(timer_planet_animation)
 reinit_b = fltk:Fl_Button(i+(6*height_button), 2*height_button, height_button, height_button, "@-4undo")
 reinit_b:tooltip("Reset Date/Time to current and end animation")
 reinit_b:callback(reset_planets_anim)
 --
 magn_slider_s=fltk:Fl_Value_Slider(i, 0, (6*height_button), height_button, nil)
 magn_slider_s:type(fltk.FL_HOR_NICE_SLIDER)
 magn_slider_s:labelsize(8)
 magn_slider_s:textsize(8)
 magn_slider_s:value(4)
 magn_slider_s:maximum(30)
 magn_slider_s:minimum(-30)
 magn_slider_s:tooltip("All Stars below this Magnitude will be displayed")
 magn_slider_s:precision(0)
 reinit_s = fltk:Fl_Button(i+(6*height_button), 0, height_button, height_button, "@-4reload")
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
 magn_slider_m:precision(0)
 reinit_m = fltk:Fl_Button(i+(6*height_button), height_button, height_button, height_button, "@-4reload")
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
      --co[#co]:callback( select_const )
      co[#co]:callback( select_const2 )
      x=x+width_b_const
      if x>=(j+(30*width_b_const)) then
         x=j
         y=y+height_b_const
      end
 end
 y=y+height_b_const
 --
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
      --limit -with greatest magnitude- nb of stars with a button label for global visibility
      if magn[i]<=2.6 then
         st=star[i] ..""
      else 
         st=nil --no display label for stars with greater magnitude (=less bright)
      end
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
  fltk:Fl_End(window)
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
 
--new version of BSC database 110825
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
                extract_from_bsc2_line(line)
                pos = j+1
                nblines=nblines+1
             else
                  break
             end
       end
    else
print("File " .. filename_bsc .. " is not present in dir " .. pathname)
os.exit(0)
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
 if Fl:w() >= 1200 and Fl:h() >= 768 then
    --optimize main window's size
    width_window = Fl:w()-100
    if Fl:h()>768 then
       height_window = Fl:h()-100
    else
       height_window = Fl:h()
    end
    --adjust grid's graphic parameters
    --[-[
    grid_hor_width=math.floor(width_window/25) --previous fixed value 60
    grid_vert_height=math.floor((height_window-80)/17) --previous fixed value 40
    grid_decx=37
    grid_decy=80
    grid_mid_vert=grid_decy+(8*grid_vert_height) 
    pixelsperdeg = floor(grid_vert_height/10)
print("pixelsperdeg = " .. pixelsperdeg )
    --]]--
 else
    st="Sorry, a minimal resolution (Width x Height) = 1200 x 768 is required for this app displaying up to 9200+ celestial objects.\nChange your screen resolution or change host computer !"
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
 --cmd_display()
 dd,mm,yyyy,hh,mn,ss,t = get_date_time()
 planetpositions.clearResultsTable()
 jd=planetpositions.JulianDateFromUnixTime(t*1000) --module planetpositions is required
 planetpositions.computeAll(jd)
 extract_from_planets()  --for 1st display
 
 main_display()
 show_objects()

 print("RAM used AFTER pre_report() -and freeing some huge tables- by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))
 
 print("Processing in " .. os.difftime(os.time(), t00) .. " seconds, ie  " .. format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, ie " .. format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " hours")

  --print("Free RAM by collectgarbage(\"count\") = " .. collectgarbage("count"))
  print("RAM used AFTER opData by  gcinfo() = " .. gcinfo() .. ", reported by collectgarbage()=" .. collectgarbage("count"))

Fl:check()
Fl:run()


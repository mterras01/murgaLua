module(..., package.seeall)

--[[
From original Great
Greg Miller gmiller@gregmiller.net 2021
http://www.celestialprogramming.com/
https://celestialprogramming.com/planets_with_keplers_equation.html
Released as public domain in javascript
--
some calendar conversion functions are adapted to Lua from 
Fliegel and van Flandern (1968) and 
FORTRAN code at https://aa.usno.navy.mil/faq/JD_formula
--
adapted by Dr M.TERRAS May, 2025
to a Lua Module
]]--

--sub = string.sub --NO : sub() is a local function in this module
floor=math.floor
pi=math.pi
abs=math.abs
sqrt=math.sqrt
cos=math.cos
sin=math.sin
acos=math.acos
asin=math.asin
tan=math.tan
atan=math.atan
atan2=math.atan2
format=string.format

results={} --table of results for each planets, with right ascension, declination, distance for each series short and long 5colsx19 lines with legends
table.insert(results,{"Planet","Series","RA (J2000)","DEC (J2000)","Distance AU"})


--orbital mecanics ---------------------------------------------------------
-- converted from original js code by Greg Miller gmiller@gregmiller.net 2021
-- http://www.celestialprogramming.com/
-- Released as public domain
data1800to2050 = { 
--          a                           e                       I                       L                               w                           O
--Mercury
        {{ 0.38709927,      0.20563593,      7.00497902,      252.25032350,     77.45779628,     48.33076593},
         { 0.00000037,      0.00001906,     -0.00594749,   149472.67411175,      0.16047689,     -0.12534081}},
--Venus,
        {{ 0.72333566,      0.00677672,      3.39467605,      181.97909950,    131.60246718,     76.67984255},
         { 0.00000390,     -0.00004107,     -0.00078890,    58517.81538729,      0.00268329,     -0.27769418}},
--EM Bary,
        {{ 1.00000261,      0.01671123,     -0.00001531,      100.46457166,    102.93768193,      0.0},
         { 0.00000562,     -0.00004392,     -0.01294668,    35999.37244981,      0.32327364,      0.0}},
--Mars,
        {{ 1.52371034,      0.09339410,      1.84969142,       -4.55343205,    -23.94362959,     49.55953891},
         { 0.00001847,      0.00007882,     -0.00813131,    19140.30268499,      0.44441088,     -0.29257343}},
--Jupiter,
        {{ 5.20288700,      0.04838624,      1.30439695,       34.39644051,     14.72847983,    100.47390909},
         {-0.00011607,     -0.00013253,     -0.00183714,     3034.74612775,      0.21252668,      0.20469106}},
--Saturn,
        {{ 9.53667594,      0.05386179,      2.48599187,       49.95424423,     92.59887831,    113.66242448},
         {-0.00125060,     -0.00050991,      0.00193609,     1222.49362201,     -0.41897216,     -0.28867794}},
--Uranus,
        {{19.18916464,      0.04725744,      0.77263783,      313.23810451,    170.95427630,     74.01692503},
         {-0.00196176,     -0.00004397,     -0.00242939,      428.48202785,      0.40805281,      0.04240589}},
--Neptune,
        {{30.06992276,      0.00859048,      1.77004347,      -55.12002969,     44.96476227,    131.78422574},
         { 0.00026291,      0.00005105,      0.00035372,      218.45945325,     -0.32241464,     -0.00508664}},
--Pluto,
        {{39.48211675,      0.24882730,     17.14001206,      238.92903833,    224.06891629,    110.30393684},
         {-0.00031596,      0.00005170,      0.00004818,      145.20780515,     -0.04062942,     -0.01183482}}
}
data3000BCto3000AD = { --https://ssd.jpl.nasa.gov/txt/p_elem_t2.txt
--          a                           e                       I                       L                               w                           O
--Mercury  
        {{ 0.38709843,      0.20563661,      7.00559432,      252.25166724,     77.45771895,     48.33961819},
         { 0.00000000,      0.00002123,     -0.00590158,   149472.67486623,      0.15940013,     -0.12214182}},
--Venus    
        {{ 0.72332102,      0.00676399,      3.39777545,      181.97970850,    131.76755713,     76.67261496},
         {-0.00000026,     -0.00005107,      0.00043494,    58517.81560260,      0.05679648,     -0.27274174}},
--EM Bary  
        {{ 1.00000018,      0.01673163,     -0.00054346,      100.46691572,    102.93005885,     -5.11260389},
         {-0.00000003,     -0.00003661,     -0.01337178,    35999.37306329,      0.31795260,     -0.24123856}},
--Mars     
        {{ 1.52371243,      0.09336511,      1.85181869,       -4.56813164,    -23.91744784,     49.71320984},
         { 0.00000097,      0.00009149,     -0.00724757,    19140.29934243,      0.45223625,     -0.26852431}},
--Jupiter  
        {{ 5.20248019,      0.04853590,      1.29861416,       34.33479152,     14.27495244,    100.29282654},
         {-0.00002864,      0.00018026,     -0.00322699,     3034.90371757,      0.18199196,      0.13024619}},
--Saturn   
        {{ 9.54149883,      0.05550825,      2.49424102,       50.07571329,     92.86136063,    113.63998702},
         {-0.00003065,     -0.00032044,      0.00451969,     1222.11494724,      0.54179478,     -0.25015002}},
--Uranus   
        {{19.18797948,      0.04685740,      0.77298127,      314.20276625,    172.43404441,     73.96250215},
         {-0.00020455,     -0.00001550,     -0.00180155,      428.49512595,      0.09266985,      0.05739699}},
--Neptune  
        {{30.06952752,      0.00895439,      1.77005520,      304.22289287,     46.68158724,    131.78635853},
         { 0.00006447,      0.00000818,      0.00022400,      218.46515314,      0.01009938,     -0.00606302}},
--Pluto    
        {{39.48686035,      0.24885238,     17.14104260,      238.96535011,    224.09702598,    110.30167986},
         { 0.00449751,      0.00006016,      0.00000501,      145.18042903,     -0.00968827,     -0.00809981}},
}
--            b                 c                    s                      f 
extraTerms = {
   {-0.00012452,    0.06064060,   -0.35635438,   38.35125000}, --Jupiter
   { 0.00025899,   -0.13434469,    0.87320147,   38.35125000}, --Saturn
   { 0.00058331,   -0.97731848,    0.17689245,    7.67025000}, --Uranus
   {-0.00041348,    0.68346318,   -0.10162547,    7.67025000}, --Neptune
   {-0.01262724,    0,             0,             0,}          --Pluto
}
planetNames={"Mercury","Venus","Earth","Mars","Jupiter","Saturn","Uranus","Neptune","Pluto","Sun","Moon"}

function computePlanetPosition(jd,elements,rates,extraTerms)
    local temp={}
    toRad=pi/180
    --Algorithm from Explanatory Supplement to the Astronomical Almanac ch8 P340
    --Step 1:
    T=(jd-2451545.0)/36525
    a=elements[1]+rates[1]*T
    e=elements[2]+rates[2]*T
    I=elements[3]+rates[3]*T
    L=elements[4]+rates[4]*T
    w=elements[5]+rates[5]*T
    O=elements[6]+rates[6]*T

    --Step 2:
    ww=w-O
    M=L - w
    if extraTerms then
       if #extraTerms > 0 then
           b=extraTerms[1]
           c=extraTerms[2]
           s=extraTerms[3]
           f=extraTerms[4]
           M=L - w + (b*T*T) + (c*cos(f*T*toRad)) + (s*sin(f*T*toRad))
       end
    end

    while(M>180) do M=M-360 end

    E=M+(57.29578*e*sin(M*toRad))
    dE=1
    n=0
    --while(abs(dE)>1e-7 and n<10) do
    while(abs(dE)>0.0000001 and n<10) do
        dE=SolveKepler(M,e,E)
        E= E+dE
        n=n+1
    end

    --Step 4:
    xp=a*(cos(E*toRad)-e)
    yp=a*sqrt(1-(e*e))*sin(E*toRad)
    zp=0

    --Step 5:
    a=a*toRad
    e=e*toRad
    I=I*toRad
    L=L*toRad 
    ww=ww*toRad
    O=O*toRad
    xecl=(((cos(ww)*cos(O))-(sin(ww)*sin(O)*cos(I)))*xp) + (((-sin(ww)*cos(O))-(cos(ww)*sin(O)*cos(I)))*yp)
    yecl=(((cos(ww)*sin(O))+(sin(ww)*cos(O)*cos(I)))*xp) + (((-sin(ww)*sin(O))+(cos(ww)*cos(O)*cos(I)))*yp)
    zecl=(sin(ww)*sin(I)*xp) + (cos(ww)*sin(I)*yp)

    --Step 6:
    eps=23.43928*toRad

    x=xecl
    y=(cos(eps)*yecl) - (sin(eps)*zecl)
    z=(sin(eps)*yecl) + (cos(eps)*zecl)
    
    temp={x,y,z}
    return temp
end --end function

function SolveKepler(M,e,E)
    toRad=pi/180

    dM=M - (E-(e/toRad*sin(E*toRad)))
    dE=dM/(1-(e*cos(E*toRad)))
    return dE
end --end function

function clearResultsTable()
local count = #results
 for i=1, count do 
      results[i]=nil 
 end
 table.insert(results,{"Planet","Series","RA (J2000)","DEC (J2000)","Distance AU"}) --text legend
end --end function

function computeAll(jd)
    planetS={}
    planetL={}

    for i=1,#data1800to2050 do
        table.insert(planetS, computePlanetShort(i,jd))
        table.insert(planetL, computePlanetLong(i,jd))
    end
    
    clearResultsTable()
    
    for i=1, #data1800to2050 do
        if i ~=3 then --EM bary is barycentre |earth,moon], not a planet
            planetS[i]=sub(planetS[i],planetS[3])
            addPlanet(planetS[i],i,false)
            planetL[i]=sub(planetL[i],planetL[3])
            addPlanet(planetL[i],i,true)
        end
    end

    sunS={}
    sunS[1]=-planetS[3][1]
    sunS[2]=-planetS[3][2]
    sunS[3]=-planetS[3][3]
    addPlanet(sunS,10,false)

    sunL={}
    sunL[1]=-planetL[3][1]
    sunL[2]=-planetL[3][2]
    sunL[3]=-planetL[3][3]
    addPlanet(sunL,10,true)
end --end function

function sub(a,b)
    temp={}
    for i=1, #a do
        table.insert(temp, a[i]-b[i])
    end
    return temp
end -- end function

function addPlanet(a,planet,longTerm)
   local str
   local temp={}
   b=xyzToRaDec(a)
   b[1]=b[1]*180/pi
   b[2]=b[2]*180/pi
   
   table.insert(temp,planetNames[planet])
   if longTerm == true then --series
      table.insert(temp,"Long")
   else
      table.insert(temp,"Short")
   end
   table.insert(temp, degreesToHMS(b[1])) --RA
   table.insert(temp, degreesToDMS(b[2])) --DECL
   str=b[3].." AU"
   table.insert(temp, str) --DIST
   table.insert(results,temp)
   --[[
   --debug only --------------------------------------------------------------------------------
   if planet == 1 and longTerm== false then
--text legend for cols
print(table.concat(results[1],"\t") ) --text legends
   end
print(table.concat(temp,"\t") ) --data
   --debug only --------------------------------------------------------------------------------
   ]]--
end -- end function

function degreesToDMS(d)
    -- declination
    local st,sign
    
    sign="+"
    if d<0 then 
       sign="-" 
    end
    d=abs(d)
    deg=floor(d)
    d=d-deg
    d=d*60
    min=floor(d)
    d=d-min
    d=d*60
    --sec=d.toFixed(2)
    sec=floor(d)

    st = sign .. string.format("%02d",deg) .. "deg ".. string.format("%02d",min) .."' ".. string.format("%02d",sec) .. "\""
    return(st)
end -- end function

function degreesToHMS(d)
    -- right ascension
    local st,sign
    d=d/15
    sign="+"
    if d<0 then 
       sign="-"
    end
    d=abs(d)
    deg=floor(d)
    d = d-deg
    d = d*60
    min=floor(d)
    d = d-min
    d = d*60
    --sec=d.toFixed(2)
    sec=floor(d)

    st = sign..string.format("%02d",deg).."h "..string.format("%02d",min).."mn "..string.format("%02d",sec).."s"
    return(st)
end --end function

function HdecToHMS(d) --M.TERRAS code
 --concerned = right ascension in decimal hours
 --output = right ascension in hours, mn, sec
 local i
 if d == nil then
    return nil
 end
 local hh=floor(d)
 local mn,sec=0,0
 mn = (d-hh)*60
 i = floor( ((d-hh)*100) )
 sec= (((d-hh)*100)-i)*60
 st=format('%02d',hh).."h"..format('%02d',mn).."mn"..format('%02d',sec).."s"
 return st
end --end function

function computePlanetShort(planet,jd)
   return computePlanetPosition(jd,data1800to2050[planet][1],data1800to2050[planet][2])
end

function computePlanetLong(planet,jd)
   local extra={}
   if planet>4 then  --giant planets Jupiter and following
      extra=extraTerms[planet-4]
   end
   return computePlanetPosition(jd,data3000BCto3000AD[planet][1],data3000BCto3000AD[planet][2],extra)
end --end function

function xyzToRaDec(target)
    x=target[1]
    y=target[2]
    z=target[3]

    --Convert from Cartesian to polar coordinates 
    r=sqrt((x*x)+(y*y)+(z*z))
    l=atan2(y,x)
    t=acos(z/r)

    --Make sure RA is positive, and Dec is in range +/-90
    if l<0 then 
       l = l+(2*pi)
    end
    t=.5*pi-t

    return {l,t,r}
end --end function

function JulianDateFromUnixTime(t)
   --Not valid for dates before Oct 15, 1582
   return ((t / 86400000) + 2440587.5)
end --end function

function UnixTimeFromJulianDate(jd)
   --Not valid for dates before Oct 15, 1582
   return ((jd-2440587.5)*86400000)
end --end function
 
--Lua code adapted from Javascript
--https://ix23.com/2016/05/29/converting-between-julian-dates-and-gregorian-calendar-dates-in-fortran-and-javascript/
function julianDateToGregorian(jd)
 local year, month, day, l, n, i, j, k
 l = jd + 68569
 n = floor(floor(4 * l) / 146097)
 l = l - floor((146097 * n + 3) / 4)
 i = floor(4000 * (l + 1) / 1461001)
 l = l - floor(1461 * i / 4) + 31
 j = floor(80 * l / 2447)
 k = floor(l - floor(2447 * j / 80))
 l = floor(j / 11)
 j = j + 2 - 12 * l
 i = 100 * (n - 49) + i + l
 year = i
 month = j
 day = k
 return year, month, day
end  --end function

function GregorianTojulianDate(year, month,day,h) --by MT with some help from Qwant
 --h is decimal hour
 local y,m,d=year,month,day
 local fraction_time
 local jd_day,jd
 local a,b
 
 if year and month and day and h then
--print("year, month,day,h = " .. year, month,day,h)
    y,m,d=tonumber(year),tonumber(month),tonumber(day),tonumber(h)
    if y and m and d and h then
       if y >1582 and m>=1 and m<=31 and d>=1 and d<=31 and h>=0 and h<24 then
          --continue
       else 
          return nil
       end
    else 
       return nil
    end
 else 
    return nil
 end
 fraction_time=h/24
 -- Ajustement de l'année et du mois
 if m <= 2 then
    y = y - 1
    m = m + 12
 end
 --Calcul du nombre de jours julien (JDN) à midi (12h)
 a = floor(y / 100)
 b = 2 - a + floor(a / 4)
 --Calcul du jour julien entier (pour la date sans l'heure) : 
 jd_day = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5 
 jd=jd_day+fraction_time
 print("jd="..jd)
 return jd
end  --end function

torad=pi/180.0

function sind(r)
	return sin(r*torad)
end --end function

function cosd(r)
	return cos(r*torad)
end --end function

--Low precision geocentric moon position (RA,DEC) from Astronomical Almanac page D22 (2017 ed), best in [1900-2100]
--other source=https://sohcahtoa.org.uk/kepler/jsmoon.html
function getGeocentricMoonPos(jd)
	T = (jd-2451545)/36525
	L = 218.32 + 481267.881*T + 6.29*sind(135.0 + 477198.87*T) - 1.27*sind(259.3 - 413335.36*T) + 0.66*sind(235.7 + 890534.22*T) + 0.21*sind(269.9 + 954397.74*T) - 0.19*sind(357.5 + 35999.05*T) - 0.11*sind(186.5 + 966404.03*T)
	B = 5.13*sind( 93.3 + 483202.02*T) + 0.28*sind(228.2 + 960400.89*T) - 0.28*sind(318.3 + 6003.15*T) - 0.17*sind(217.6 - 407332.21*T)
	P = 0.9508 + 0.0518*cosd(135.0 + 477198.87*T) + 0.0095*cosd(259.3 - 413335.36*T) + 0.0078*cosd(235.7 + 890534.22*T) + 0.0028*cosd(269.9 + 954397.74*T)

	SD=0.2724*P
	r=1/sind(P) --distance in earth radii unit, ie 6371km. To convert to AU
	r=r*6371 --distance in km
	--1AU = 149597870700 m
	--1AU = 149597870.7 km
	--1km = 1/149597870.7 AU
	r = r/149597870.7 --distance in AU

	l = cosd(B) * cosd(L)
	m = 0.9175*cosd(B)*sind(L) - 0.3978*sind(B)
	n = 0.3978*cosd(B)*sind(L) + 0.9175*sind(B)

	ra=atan2(m,l)
	if ra<0 then
	   ra=ra+(2*pi)
	end
	dec=asin(n)
	return (ra/torad/15),(dec/torad),r
end --end function	

--computing set & rise of sun
--Original javascript code by By Greg Miller gmiller@gregmiller.net celestialprogramming.com
--Released as public domain
--at https://celestialprogramming.com/risesetalgorithm.html
--default location is set @ St Denis Lès Bourg
dec_longitude=-5,1899 --degree ATTENTION! all west longitude have to be negative (and eastern positive) IN THIS PARTICULAR COMPUTATION
dec_latitude=46,2026 --° N 
--sun position at rise time (cf below) will give the EAST cardinal point on mercator skycard for your lat & lon location
toRad=pi/180.0
toDeg=180.0/pi
function constrain(v)
 if v<0 then
    return v+1
 end
 if v>1 then
    return v-1
 end
 return v
end --end function

--Greenwhich mean sidereal time from Meeus page 87
--Input is julian date, does not have to be 0h
--Output is angle in degrees
function GMST(jd)
 local t=(jd-2451545.0)/36525.0
 local st=280.46061837+360.98564736629*(jd-2451545.0)+0.000387933*t*t - t*t*t/38710000.0
 st=st%360
 if st<0 then
    st = st+360
 end
 return st
end --end function

function get_timezone()
--linux bash cmd=> date +"%z" => +0200
--windows equivalent powershell => Get-Date -format "zz" => +02
--macos equivalent=>  date +%z
local osName, linecmd, res, f, sign, buf,st,tz
 osName=murgaLua.getHostOsName()
 if osName == "linux" then
    linecmd = "date +\"%z\" > temp.txt"
 elseif osName == "macos" then
    linecmd = "date +%z  > temp.txt"
 elseif osName == "windows" then
    linecmd = "Get-Date -format \"zz\"> temp.txt"
 else
    --nothing
 end
 res = os.execute(linecmd)
--print("linecmd = " .. linecmd .. ", res is " .. res)
 if res == 0 then
    f = io.open("temp.txt", "rb")
    if f then
       buf = f:read("*all")
       io.close(f)
       if buf then 
          if string.sub(buf,1,1) == "+" then
             sign=1
          elseif string.sub(buf,1,1) == "-" then
             sign=-1
          else
          end
          st = string.sub(buf,2)
          if osName == "linux" or osName == "macos"then
             tz = sign*tonumber(st)/100
          elseif osName == "windows" then
             tz = sign*tonumber(st)
          else
          end
          if tz then
--print("Current TimeZone is : " .. tz)
             return tz
          end
      end
    end
 else
--print("res of cmd : " .. linecmd .. " is " .. res)
 end
 return nil
end --end function

function getRiseSet(jd,lat,lon,ra,dec)
 local h0=-0.8333 --For Sun
-- local h0=-0.5667 --For stars and planets, local h0=0.125   --For Moon
 local cosH=(sin(h0*pi/180.0)-(sin(lat*pi/180.0)*sin(dec*pi/180.0))) / (cos(lat*pi/180.0)*cos(dec*pi/180.0))
 local h1=acos(cosH)*180.0/pi
 local gmst=GMST(floor(jd)+.5)
--print("temp values\ncosH="..cosH.."\nh1="..h1.."\ngmst="..gmst)
 
 local suntransit=(ra+lon-gmst)/360.0
 local sunrise=suntransit-(h1/360.0)
 local sunset=suntransit+(h1/360.0)
--print("temp suntransit="..suntransit..", sunrise=".. sunrise .. ", sunset="..sunset) 
 local finaltransit=constrain(suntransit)*24.0
 local finalrise=constrain(sunrise)*24.0
 local finalset=constrain(sunset)*24.0
--print("final suntransit="..finaltransit..", sunrise=".. finalrise .. ", sunset="..finalset) 
 
return finaltransit, finalrise, finalset
end --end function

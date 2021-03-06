#!/bin/murgaLua

--[[ 
problems to resolve
1/ text with less than 300 distinct words
2/ minimum space dispersion ... allowing real time display
3/ improve residual superpositions of boxes
4/ 
]]

i=0
f=0
st=""
proportion_factor=0
max_font_size=80 -- word with highest occurence will be displaid with this font size 
-- GUI variables ----------------------------------------------------------
width_pwindow = 500 --dim main window for wordcloud
height_pwindow = 500
width_button = 160
height_button = 40
dec_button = 0
cwindow=nil -- window for charts/stats
pie=nil --var for charts
width_cwindow = 500 --dim window for charts/stats
height_cwindow = 500
decx_chart   = 20 --dim & position charts in this widow
decy_chart   = 0
width_chart  = 450
height_chart = 450
visibility_word_box=0 --0 for button without any visible borders/ 2 for button aspect
centerw=(width_pwindow/2)
centerh=((height_pwindow-height_button)/2)
ran,rad=0,0
fontfactor=1.7 --defines the proportion between nb of cars and width of container-box, empirical value=1.7
-- SLIDERS variables ------------------------------------------------------
debocc=30
finocc=300 --select 30 to 300 words  with max occurrences in panel
debdisp=50
findisp=200 --dispersion 5 to 200 pixels between words
-- main data tables -------------------------------------------------------
words={}
occur_words={}
words_ordering={}
word_box={}

table_convert={}
convert={ascii_car={}, 
         ascii_char={}
        }
convert.ascii_car[1]="é"
convert.ascii_char[1]="e"
convert.ascii_car[2]="É"
convert.ascii_char[2]="E"
convert.ascii_car[3]="à"
convert.ascii_char[3]="a"
convert.ascii_car[4]="À"
convert.ascii_char[4]="A"
convert.ascii_car[5]="è"
convert.ascii_char[5]="e"
convert.ascii_car[6]="È"
convert.ascii_char[6]="E"
convert.ascii_car[7]="ô"
convert.ascii_char[7]="o"
convert.ascii_car[8]="Ô"
convert.ascii_char[8]="O"
convert.ascii_car[9]="ê"
convert.ascii_char[9]="e"
convert.ascii_car[10]="Ê"
convert.ascii_char[10]="E"
convert.ascii_car[11]="î"
convert.ascii_char[11]="i"
convert.ascii_car[12]="Î"
convert.ascii_char[12]="I"
convert.ascii_car[13]="ù"
convert.ascii_char[13]="u"
convert.ascii_car[14]="Ù"
convert.ascii_char[14]="U"
convert.ascii_car[15]="ç"
convert.ascii_char[15]="c"
convert.ascii_car[16]="Ç"
convert.ascii_char[16]="C"
convert.ascii_car[17]="â"
convert.ascii_char[17]="a"
convert.ascii_car[18]="Â"
convert.ascii_char[18]="A"
convert.ascii_car[19]="û"
convert.ascii_char[19]="u"
convert.ascii_car[20]="Û"
convert.ascii_char[20]="U"
convert.ascii_car[21]="ë"
convert.ascii_char[21]="e"
convert.ascii_car[22]="Ë"
convert.ascii_char[22]="E"
convert.ascii_car[23]="ï"
convert.ascii_char[23]="i"
convert.ascii_car[24]="Ï"
convert.ascii_char[24]="I"
convert.ascii_car[25]="ö"
convert.ascii_char[25]="o"
convert.ascii_car[26]="Ö"
convert.ascii_char[26]="O"
convert.ascii_car[27]="ü"
convert.ascii_char[27]="U"
convert.ascii_car[28]="Ü"
convert.ascii_char[28]="U"
convert.ascii_car[29]="…" --"suspension points", not portable at all!
convert.ascii_char[29]= "."


-- control of ASCII table --
--[[
for i=1,#convert.ascii_car do
    print("initial ASCII char = " .. convert.ascii_car[i] .. " / converted char = " .. convert.ascii_char[i])
end
]]--

separator = ";"
co,li = 0,0

read_data = "" --tampon de lecture (et d'ecriture) des données sauvegardées au format CSV
size_eol = 0 -- varie selon Unix (MacOs) ou Windows

-- si luajit est utilisé, commenter cette ligne 
osName="OS=" .. murgaLua.getHostOsName()
--si luajit, remplacer la ligne ci-dessus par
--osName="OS=linux"

t00=0
t11=0

--Fl:scheme("plastic")
Fl:scheme("gtk+")

find = string.find
sub = string.sub
cos = math.cos
sin = math.sin
pi = math.pi
rand = math.random


function define_textfile_origin(data)
  local i,st

  --finding if -CURRENTLY OPENED- text file
  -- is Unix or Windows -generated
  --searching for CR/LF (windows)
  st = string.char(13) .. string.char(10)
  i = find(data, st)
  if i then
--print("file generated by MS Windows => size_eol=2")
     size_eol=2 -- for windows remove CR+LF at end of line
     return("windows")
  else
--print("file generated by an Unix-like OS => size_eol=1")
     size_eol=1 -- for unixes remove only LF(?)
     return("unix")
  end
end --end function

function erasepunct()
  local i, s, c, st, count
  local remp=" "
  
  count=0
  --1rst pass group replace accentuated french caracters with non-accentuated ones ----------------
  count=0
  for i=1,#convert.ascii_car do
      --print("initial ASCII char = " .. convert.ascii_car[i] .. " / converted char = " .. convert.ascii_char[i])
      st = convert.ascii_car[i]
      remp = convert.ascii_char[i]
      s,c = string.gsub(read_data, st, remp)
      if c then 
         read_data = s
	 count = count+c
      end
  end
  print("Replacements (accentuated cars) = " .. count)
  
  read_data = string.lower(read_data)
  
  --2nd pass group replace special caracter with spaces ----------------
  --st = "%A%c*" --pattern : all NON characters and escape sequences, zero or more occurences
  --st = "%A" --pattern : all NON characters and escape sequences, zero or more occurences
  st = "%p"
  remp=" "
  s,c = string.gsub(read_data, st, remp)
  if c then 
     read_data = s
     print("Replacements (non car) = " .. c)
  end
  
  --3rd pass convert multiple contiguous or unique spaces into ONE "\n" character ----------------
  remp="\n"
  --punct = nil
  --punct = {}
  count=0
  for i = 159,0,-1 do
      s,c = string.gsub(read_data, string.rep(" ", (i+1) ), remp)
      if c then 
         read_data = s
	 count = count+c
      end
  end
print("Replacements (espaces) = " .. count)

  --Fourth pass erasing small words whose size <=2 ((or 3 cars)) ----------------
  local p, p0
  local replace="\n"
  local excluded_short_strings="LES CES POUR AUCUN AVEC SANS FAIT PLUS MOINS AVANT APRES UNE BIS NON OUI MME DES HORS PUISQU RIEN BILAN BLDM PAR SUR DANS PAS ANNUEL PDF MEDICAL PEC VUE INITIE MEDECINS ANNEE DOCS MON VERS MOIS"
  local buffer=""
  excluded_short_strings = string.lower(excluded_short_strings)
  
  p0 = 1
  while 1 do
      p = find(read_data, replace, p0)
      if p then
	 tempword = sub(read_data, p0, p-1)
	 if #tempword >= 3 then
	    if find(excluded_short_strings, tempword) then 
	       --excluded short -french- strings
	    else
	       if find(buffer, tempword) then 
		  --string is already recorded
	       else
	          table.insert(words, tempword)
	          buffer = buffer .. " " .. words[ #words ]
	       end
	    end
	 end
	 p0 = p+1 --may require a modification according to EOL size UNIX-MAC or WINDOWS
      else
	 break
      end
  end
  --ordering list by alphanumeric car
  table.sort(words)
--[[
  for i=1,#words do
      print(i .. ". " .. words[i])
  end
]]--

print("function erasepunct() over")
--print(read_data)
end --end function

function occurs()
  local i, p, p0
  local st,s,c

  p0 = 1
      --st =  words[i]
  for i =1,#words do
      occur_words[ i ] = 0
      p0 = 1
      while 1 do
         p = find(read_data, words[i], p0, true)
	 --p = find(read_data, words[i], p0)
         if p then
	    occur_words[ i ] = occur_words[ i ] +1
	    p0 = p+1
         else
	    break
         end
      end
--print(i .. ". " .. words[i] .. " (size=" .. #words[i] .. ") occurs " .. occur_words[i] .. " times")
  end
print("before removing weak occurences, #words = " .. #words)


  --2nd pass: removing words whith occurs <=3 
  for i =#words,1,-1 do
      if occur_words[ i ] <= 3 then
	table.remove(occur_words, i)
	table.remove(words, i)
      else
--print(i .. ". " .. words[i] .. " (size=" .. #words[i] .. ") occurs " .. occur_words[i] .. " times")
      end
  end
print("After removing weak occurences, #words = " .. #words)


  --3rd pass: ordering occurs by descending order 
  local max_value = 0
  local max_order=1  
  local processed = {}
  for i =1,#words do
      table.insert(processed, 0)
  end
  
  --reset table words_ordering, if already used/filled
  if words_ordering then
     if #words_ordering then
        for i=#words_ordering,1,-1 do
	    table.remove(words_ordering)
	end
     end
  end
  
  
  while 1 do
    max_value = 0
    max_order=0
    for i =#words,1,-1 do
        if processed[ i ] == 0 then
	  if occur_words[ i ] > max_value then
              max_value = occur_words[ i ]
              max_order = i
           end
	end
    end
    if max_order == 0 then
       break
    end
    table.insert(words_ordering, max_order)
    processed[ max_order ] = 1
  end
  
  local j
  --display results
  for i =#words_ordering,1,-1 do
      j = words_ordering[ i ]
print(i .. ". word " .. words[j] .. " occurs " .. occur_words[j] .. " times")
    end
  
print("function occurs() over")
print("#words = " .. #words .. ", #read_data = " .. #read_data)
end --end function

function round(nb)
  if nb then
     if nb >= 0 then
	    return math.floor(nb)
	 else
	    return math.ceil(nb)
	 end
  else
     return 0
  end
end --end function

function check_xy_superposition(x,y,h,w,i)
  local xx,yy
  local px,py,pw,ph
  local ix,iy -- center of actual box
  local j,k
  local testsinside=0
  local d2

  if i == 1 then
     xx,yy = round(x),round(y)    
  else
     d2 = sliderdisp:value()
     --testsinside=0
     --update ix & iy = center of actaul box
     ix = x+(w/2) --center of actual box
     iy = y+(h/2)
     testtoto=0
     while 1 do
        testsinside=0
	--xcenter = x+(w/2)
	--ycenter = y+(h/2)
	hy = y+h
	wx = x+w
        for k=1,i-1 do
            --j = words_ordering[ k ]
	    px=word_box[ k ]:x()
	    py=word_box[ k ]:y()
	    pw=word_box[ k ]:w()
	    ph=word_box[ k ]:h()
	    pph = py+ph
	    ppw = px+pw
	    --test of actual box(x,y,w,h) inside previous boxes(px,py,pw,ph)
	    --if ix>=px and ix <=(px+pw) and iy>=py and iy <=(px+ph) then
	       --middle of actual box INSIDE previous box
	    --if x>=px and x <=(px+pw) and (x+w)>=px and (x+w) <=(px+pw) and y>=py and y <=(py+ph) and (y+h)>=py and (y+h) <=(py+ph) then
	       --opposite points of actual box are both INSIDE previous box
	    --if x>=px and x <=(px+pw) and (x+w)>=px and (x+w) <=(px+pw) and y>=py and y <=(py+ph) and (y+h)>=py and (y+h) <=(py+ph) and xcenter>=px and xcenter<=(px+pw) and ycenter>=py and ycenter<=(py+ph) then
	       --opposite points & center of actual box are ALL INSIDE previous box
--[[
	    if x>=px and x<=ppw and wx>=px and wx<=ppw and y>=py and y<=pph and hy>=py and hy<=pph then
	       --ALL four points of actual box are ALL INSIDE previous box : BAD (random) CHOICE => new position required 
	       testsinside=testsinside+1
	       break --end of for..next loop
	    end
]]
	    -- adding condition center of acual box INSID previous box creates new superpositions !
	    -- ie, this condition  and ix>=px and ix<=ppw and iy>=py and iy<=pph 
	    if x>=px and x<=ppw and y>=py and y<=pph then
	       --ONE point of actual box INSIDE previous box : BAD
	       testsinside=1
	       break --end of for..next loop
	    end
	    if wx>=px and wx<=ppw and y>=py and y<=pph then
	       --ONE point of actual box INSIDE previous box : BAD
	       testsinside=1
	       break --end of for..next loop
	    end
	    if x>=px and x<=ppw and hy>=py and hy<=pph then
	       --ONE point of actual box INSIDE previous box : BAD
	       testsinside=1
	       break --end of for..next loop
	    end
            if wx>=px and wx<=ppw and hy>=py and hy<=pph then
	       --ONE point of actual box INSIDE previous box : BAD
	       testsinside=1
	       break --end of for..next loop
	    end
--[[    
            if x<0 and x>(width_pwindow-w) then
	       --box is OUTSIDE display window : BAD (random) CHOICE => new position required 
	       testsinside=1
	       break --end of for..next loop
	    end
]]
    
        end --for..next loop
        if testsinside == 0 then
           --keep current position for box
--print("box " .. i .. " is positionned!")
           break --end of while.. end loop
        else
           --compute new random position
           if shapedisp:label() == "@square" then
              x=centerw-(w/2)+rand(-1*d2,d2)
              y=centerh-(h/2)+rand(-1*d2,d2)
           else
              ran=rand(0,359) --random angle in degrees
              rad = (ran*pi/180)--in radians for cos() and sin() functions
              x=centerw-(w/2)+(rand(0,d2) * cos(rad))
              y=centerh-(h/2)+(rand(0,d2) * sin(rad))
           end
	   --update ix & iy = center of actual box
           ix = x+(w/2) --center of actual box
           iy = y+(h/2)
	end
     end --while.. end loop
     yy=round(y)
     xx=round(x)
  end
  return xx,yy
end --end function

function display_charts()
  local i, j, st
  
  cwindow = fltk:Fl_Window(width_cwindow, height_cwindow, "Charts Window")
  pie = fltk:Fl_Chart(0, 0, 5, 5, nil)

  --fltk:fl_alert("cwindow & pie built! ")

  pie:position(decx_chart, decy_chart)
  pie:size(width_chart, height_chart)
  pie:label("Group words by occurences")
  pie:type( 1 )
  pie:box(3)
  pie:labelcolor(1)
  for i=1,30 do
      j = words_ordering[ i ]
      st = words[j] .. " : " .. occur_words[j]
      pie:add(occur_words[j], st, i) -- ORDRE = value, label and colour
  end
  cwindow:show()
end --end function

function display_cloud()
  local diml,dimh --dimension chaine lxh
  local posx,posy,sizefactor
  local i,j,a,b,x,y,w,h,st,xx,yy
  
  ran,rad=0,0
  proportion_factor=0

  proportion_factor = occur_words[ words_ordering[ 1 ] ]/max_font_size
  --question to process : if less than 300 words ????
  for i=1,300 do
      j = words_ordering[ i ]
      --sizefactor means "size of font" proportional to nb of word's occurences : max should equal to variable "max_font_size"
      if occur_words[j] and proportion_factor then
         sizefactor = occur_words[j]/proportion_factor
      else
         if occur_words[j] == nil then
            print("occur_words[j] == nil")
         end
         if proportion_factor == nil then
            print("proportion_factor == nil")
         end
         os.exit(0)
      end
      dimh = sizefactor

      --w = #words[j] * dimh /1.7
      w = #words[j] * dimh /fontfactor
      h = dimh
      word_box[ i ]:labelsize(dimh)
      word_box[ i ]:labelfont(fltk.fl_screen)
      word_box[ i ]:label( words[j] )
      word_box[ i ]:position(10,10)
      word_box[ i ]:box(visibility_word_box)
      word_box[ i ]:labelcolor(i)
  
      --now changing position of button for alignment
      if shapedisp:label() == "@square" then
         while 1 do
            x=centerw-(w/2)+rand(-200,200)
            if x>=0 and x <= (width_pwindow-w) then
               --keep x value
               break
            end
         end
         y=centerh-(h/2)+rand(-200,200)
      else
         ran=rand(0,359) --random angle in degrees
         rad = (ran*pi/180)--in radians for cos() and sin() functions
         while 1 do
            x=centerw-(w/2)+(rand(0,200) * cos(rad))
            if x>=0 and x <= (width_pwindow-w) then
               --keep x value
               break
            end
         end
         y=centerh-(h/2)+(rand(0,200) * sin(rad))		 
      end
      --check if words is inside the window
      xx,yy = check_xy_superposition(x,y,h,w,i)  
      word_box[ i ]:position(xx,yy)
      word_box[ i ]:size(w,h)
      --number of occurences in tooltip
      --st = occur_words[j] .. " occurences\nfor Word \"" .. words[j] .. "\"\nx=" .. xx .. "/y=" .. yy .. "\nw=" .. round(w)  .. "/h=" .. round(h)
      st = occur_words[j] .. " occurences\nfor Word \"" .. words[j]
      word_box[ i ]:tooltip(st)
      word_box[ i ]:show()
    end
end --end function

function update_cloud()
  local d,d2
  local i,j,x,y,h,w,xx,yy
  --local centerw=(width_pwindow/2)
  --local centerh=((height_pwindow-40)/2)
  local st
  local diml,dimh --dimension chaine lxh
  local posx,posy,sizefactor
  proportion_factor=0

  proportion_factor = occur_words[ words_ordering[ 1 ] ]/max_font_size
  
  --first update: make words visible/hidden according to slider1stwords
  d = slider1stwords:value()
--print("slider1stwords:value() = " .. d .. " ( in fct update_cloud)")
  for i=1,300 do
      word_box[ i ]:show() --all words are visible at this stage
  end
  for i=1,300 do
      if i < d+10 then 
         word_box[ i ]:show() --some words are visible at this stage
      else
         word_box[ i ]:hide() --other words are hidden according to d (nb of occurences) threshold
      end
  end
  --2nd update: make words more or less "dispersed". ALL words are processed, even those hidden 
  d2 = sliderdisp:value()
  for i=1,300 do
      j = words_ordering[ i ]
      --sizefactor = occur_words[j]/proportion_factor
      --w = #words[j] * sizefactor /1.7
      --w = #words[j] * sizefactor /fontfactor
      --h = sizefactor
  
      --this function updates ONLY position of boxes BUT NOT boxes' dimensions (defined by function display_cloud)
      --height and width of the widget = word_box
      h = word_box[ i ]:h()
      w = word_box[ i ]:w()
      --now changing position of ALL buttons (even hidden) for alignment according to d2 dispersion parameter
      if shapedisp:label() == "@square" then
         while 1 do
            x=centerw-(w/2)+rand(-1*d2,d2)
            if x>=0 and x <= (width_pwindow-w) then
               --keep x value
               break
            end
         end
         y=centerh-(h/2)+rand(-1*d2,d2)
      else
         ran=rand(0,359)
         rad = (ran*pi/180)--in radians for cos() and sin() functions
         while 1 do
            x=centerw-(w/2)+(rand(0,d2) * cos(rad))
            if x>=0 and x <= (width_pwindow-w) then
               --keep x value
               break
            end
         end
         y=centerh-(h/2)+(rand(0,d2) * sin(rad))
      end
      --chek if words is inside the window
      xx,yy = check_xy_superposition(x,y,h,w,i)
      word_box[ i ]:position(xx,yy)
      --number of occurences in tooltip, update x-y-w-h position & size
      --st = occur_words[j] .. " occurences\nfor Word \"" .. words[j] .. "\"\nx=" .. xx .. "/y=" .. yy .. "\nw=" .. round(w)  .. "/h=" .. round(h)
      st = occur_words[j] .. " occurences\nfor Word \"" .. words[j]
      word_box[ i ]:tooltip(st)
  end
  pwindow:redraw()
end --end function

function load_data()
  local st, sysfile = "", ""
  local nbl,nbc = 0, 0  
  
  i=0
  f=0
  st=""
  
  --for testing purpose only
 --[[ 
  if osName == "OS=linux" then
     linecmd = "hostname > temp.txt";
     res = os.execute(linecmd)
     if res == 0 then
        f = io.open("temp.txt", "rb")
        if f then
           buffer = f:read("*all")
print("Hostname ? " .. buffer)
	   if find(buffer, "terras-Aspire-5733Z",1,true) then
	      filename = "/home/terras/dim/TODO_2021_250721.txt" -- ACER
	   elseif find(buffer, "HP6200",1,true) then
	      filename = "/home/terras/Téléchargements/Documentation-DIM/2020_LISTE_A_FAIRE/TODO_2021_250721.txt"
	   else
	      filename=nil
	   end
           io.close(f)
	end
     end
  else
     --osName == "OS=windows" then
     filename = "G:\\Dim\\dsl-not\\scripts-murgaLua\\TODO_2021_250721.txt"
  end
  ]]
  --- FILE CHOOSER
  filename = fltk.fl_file_chooser("file selector", "CSV Files (*.{csv,CSV,txt,TXT})", SINGLE, nil) --place de SINGLE ?
  
  local f = 0
  local i = 0
  local j = 0
  local k = 0
  local pos=1
  local posc=1
  read_data = ""
  local str
  
  
  if filename then
     --init previous tables, if any
      
     f = io.open(filename,"rb")
     if f then
        read_data = f:read("*all")
        read_data = string.lower(read_data)
        print("Reading successfully file " .. filename .. ", taille=" .. #read_data .. " bytes")
        io.close(f)
        sysfile = define_textfile_origin(read_data)
        print("filesystem Origin (according to CR/LF) = " .. sysfile )
        erasepunct()
	occurs()
	return 1
     else
        print("Inexistent of file " .. filename)
        return nil, nil
     end
  else
    return nil, nil
  end
end --end function

function load_disp_data()  
  local i, st
  
  if words and occur_words then
     if #words and #occur_words then
        for i=#words,1,-1 do
	    table.remove(words)
	    table.remove(occur_words)
	end
     end
  end
  if words_ordering then
     if #words_ordering then
        for i=#words_ordering,1,-1 do
            table.remove(words_ordering)
	end
     end
  end
   if load_data() == 1 then
      --reinit display parameters before displaying new data
      slider1stwords:value( finocc )
      sliderdisp:value( findisp )
      display_cloud()
      pwindow:redraw()
--[[      
      --next code fixes a presentation issue
      st = finocc .. " first words"
      s1wbutton:label( st )
      update_cloud()
      ]]
   else
     print("load_data() != 1 !!!")
   end
end --end function

function quit_callback_app()
  if pwindow then
     pwindow:hide()
     pwindow:clear()
     print("Quiting")
     os.exit(0)
  end
end --end function

  t00 = os.time() --top chrono

  --version FLTK
  print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. fltk.FL_PATCH_VERSION)
  --premiere partie : chargement des données  
  if load_data() then
     print(#read_data .. " octets")
  else
     os.exit(0)
  end
  print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. (os.difftime(os.time(), t00)/60) .. " mn, soit en " .. (os.difftime(os.time(), t00)/3600).. " heures")
    
  --os.setlocale'fr_FR'
  --os.setlocale'fr_FR.ISO-8859-1'
  --os.setlocale'C'
  --st="Ceci est une pause" 
  --fltk:fl_alert(st)
  
  --GUI --------------------------------------------------------------------
  width_pwindow = 500
  height_pwindow = 500
  width_button = 160
  dec_button = 0
  
  pwindow = fltk:Fl_Window(width_pwindow, height_pwindow, "WordCloud")
  
  --centrage du bouton en bas de la fenetre pwindow
  width_button = 40
  height_button = 40
  quit = fltk:Fl_Button(dec_button+5, height_pwindow-height_button, width_button, height_button, "Quit")
  quit:tooltip("Quitter cette appli!")
  quit:callback(quit_callback_app)
  
  --selection of first x most written words
  dec_button = dec_button+width_button+10
  slider1stwords = fltk:Fl_Slider(dec_button, height_pwindow-20, 180, 15, "")
  s1wbutton=fltk:Fl_Button(dec_button, height_pwindow-35, 180, 15, "")
  s1wbutton:box(0)
  slider1stwords:type(1)
  debocc=30
  finocc=300 --select 30 to 300 words  with max occurrences in panel
  slider1stwords:range(debocc, finocc)
  slider1stwords:step(10)
  slider1stwords:value( finocc )
  st = finocc .. " first words"
  s1wbutton:label( st )
  s1wbutton:box(0)
  
  -- dispersion of words parameter
  dec_button = dec_button+180+5
  sliderdisp = fltk:Fl_Slider(dec_button, height_pwindow-20, 180, 15, "")
  sdispbutton=fltk:Fl_Button(dec_button, height_pwindow-35, 180, 15, "")
  sdispbutton:box(0)
  sliderdisp:type(1)
  debdisp=50
  findisp=200 --select 50 to 200 pixels "from-center-of-window-words'dispersion"
  sliderdisp:range(debdisp, findisp)
  sliderdisp:step(10)
  sliderdisp:value( findisp )
  st = findisp .. " pix dispersion"
  sdispbutton:label( st )
  sdispbutton:box(0)
  
  slider1stwords:callback(
	function(swordsupd)
	      local d,d2,st
	      d = slider1stwords:value()
	      st = d .. " first words"
              s1wbutton:label( st )
	      d2 = sliderdisp:value()
	      st = d2 .. " pix dispersion"
              sdispbutton:label( st )
	      update_cloud()
	end)
  sliderdisp:callback(
	function(sdispupd)
	      local d,d2,st
	      d = slider1stwords:value()
	      st = d .. " first words"
              s1wbutton:label( st )
	      d2 = sliderdisp:value()
	      st = d2 .. " pix dispersion"
              sdispbutton:label( st )
	      update_cloud()
	end)

  -- shape of dispersion = square or circle
  dec_button = dec_button+180
  width_button = 30
  height_button = 40
  shapedisp = fltk:Fl_Button(dec_button+5, height_pwindow-height_button, width_button, height_button, "@square")
  shapedisp:labelcolor(19)
  shapedisp:tooltip("click for toggle square/circle shape for words dispersion")
  shapedisp:callback(
        function(shapeupd)
	      if shapedisp:label() == "@square" then
		 shapedisp:label("@circle")
	      else
		 shapedisp:label("@square")
	      end
	      update_cloud()
        end)

  -- UPDATE button
  dec_button = dec_button+35
  fileopenbutton=fltk:Fl_Button(dec_button, height_pwindow-height_button, 40, height_button, "@fileopen")
  fileopenbutton:tooltip("Open another file")
  fileopenbutton:callback(load_disp_data)
  
  --display 300 empty "words-buttons"
  for i=1,300 do
      --table.insert(word_box, fltk:Fl_Button(0,0,20,20, ""))
	  table.insert(word_box, fltk:Fl_Box(0,0,20, 20, ""))
	  word_box[ #word_box]:box(visibility_word_box)
  end  
  --fltk:fl_alert("Check Point 1 post 300 boxes definition")
  display_cloud()
  
  --now display charts
  display_charts()
  
  
--[[
  --st="Ceci est un test de message d'alerte"
  st=""
  for i=1,#type_chart do
    st = st .. "type[" .. i .. "] = " .. type_chart[i] .. ", "
  end
  fltk:fl_alert(st)
  ]]    

  --Fl:check()
  pwindow:show()
  
Fl:check()
Fl:run()

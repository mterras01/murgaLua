#!/bin/murgaLua
i=0
f=0

words={}
occur_words={}
words_ordering={}
word_buffer=""
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


function define_textfile_origin(data)
  local i,st

  --finding if -CURRENTLY OPENED- text file
  -- is Unix or Windows -generated
  --searching for CR/LF (windows)
  st = string.char(13) .. string.char(10)
  i = find(data, st)
  if i then
--print("Ce fichier a ete genere par Windows => size_eol=2")
     size_eol=2 -- for windows remove CR+LF at end of line
     return("windows")
  else
--print("Ce fichier a ete genere par un Unix-like => size_eol=1")
     size_eol=1 -- for unixes remove only LF(?)
     return("unix")
  end
end --end function

function erasepunct()
  local i, s, c, st, count
  local remp=" "
  local valid_residual_words={}
  
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
  print("Remplacements (accentuated cars) = " .. c)
  read_data = string.upper(read_data)
  
  --2nd pass group replace special caracter with spaces ----------------
  --st = "%A%c*" --pattern : all NON characters and escape sequences, zero or more occurences
  st = "%A" --pattern : all NON characters and escape sequences, zero or more occurences
  remp=" "
  s,c = string.gsub(read_data, st, remp)
  if c then 
     read_data = s
     print("Remplacements (non car) = " .. c)
  end
  
  --3rd pass convert multiple contiguous or unique spaces into ONE "\n" character ----------------
  remp="\n"
  --punct = nil
  --punct = {}
  count=0
  for i = 159,0,-1 do
      --table.insert(punct, string.rep(" ", (i+1) ) )
      s,c = string.gsub(read_data, string.rep(" ", (i+1) ), remp)
      if c then 
         read_data = s
	 count = count+c
      end
  end
print("Remplacements (espaces) = " .. count)

  --Fourth pass erasing small words whose size <=2 ((or 3 cars)) ----------------
  local p, p0
  local replace="\n"
  local excluded_short_strings="POUR AUCUN AVEC SANS FAIT PLUS MOINS AVANT APRES UNE BIS NON OUI MME DES HORS PUISQU RIEN BILAN BLDM PAR SUR DANS PAS ANNUEL PDF MEDICAL PEC VUE INITIE MEDECINS ANNEE DOCS MON VERS MOIS"
  local buffer=""
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

  
  --[-[
  --restoring read_data buffer by replacing \n by space
  s,c = string.gsub(read_data, "\n", " ")
  if c then 
     read_data = s
     print("Restoring read_data buffer ")
--print(read_data)
  end
  --]]--
  
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

--[[
  --2nd pass: removing words whith occurs <=3 
  for i =#words,1,-1 do
      if occur_words[ i ] <= 3 then
	table.remove(occur_words, i)
	table.remove(words, i)
      else
print(i .. ". " .. words[i] .. " (size=" .. #words[i] .. ") occurs " .. occur_words[i] .. " times")
      end
  end
print("After removing weak occurences, #words = " .. #words)
]]--

  --2nd pass: ordering occurs by descending order 
  local max_value = 0
  local max_order=1  
  local processed = {}
  for i =1,#words do
      table.insert(processed, 0)
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

function display_cloud()
  local diml,dimh --dimension chaine lxh
  local posx,posy,sizefactor
  local i,j
  --width_pwindow, height_pwindow
  
    --for i =#words_ordering,1,-1 do
  for i =#words_ordering,(#words_ordering-30) do
      j = words_ordering[ i ]
      sizefactor = occur_words[j]/30
      dimh = sizefactor
      diml = sizefactor*#words[j]
      x=math.random(0, (width_pwindow-diml) )
      y=math.random(0, (height_pwindow-30-dimh) )
      w=diml
      h=dimh
      st=words[j]
      b = fltk:Fl_Button(x,y,w,h, st, st)
      b:box(0)
      b:labelcolor(i)
      b:labelsize(diml)
      
    end
end --end function

function load_data()
  local st, sysfile = "", ""
  local nbl,nbc = 0, 0  
  
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
  
  --- FILE CHOOSER
  --filename = fltk.fl_file_chooser("selecteur de fichier", "CSV Files (*.{csv,CSV,txt,TXT})", SINGLE, nil) --place de SINGLE ?
  
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
        read_data = string.upper(read_data)
        print("Lecture reussie pour le fichier " .. filename .. ", taille=" .. #read_data .. " octets")
        io.close(f)
        sysfile = define_textfile_origin(read_data)
        print("Origine systeme du fichier = " .. sysfile )
        erasepunct()
	occurs()
	return 1
     else
        print("Inexistence du fichier " .. filename)
        return nil, nil
     end
  else
    return nil, nil
  end
end --end function

function quit_callback_app()
  if pwindow then
     pwindow:hide()
     pwindow:clear()
     if twindow then
        twindow:hide()
        twindow:clear()
     end
     if pie then
        pie:hide()
        pie:clear()
     end
     print("Quiting?")
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
  
  decx_chart   = 20
  decy_chart   = 0
  width_chart  = 450
  height_chart = 450
  width_pwindow = 500
  height_pwindow = 500
  width_button = 160
  dec_button = 0
  type_graphics = 1
  
  demo_table = {10,30,-20,5,-30,15,20,40,7, 14}

  --GUI --------------------------------------------------------------------
  pwindow = fltk:Fl_Window(width_pwindow, height_pwindow, "WordCloud")
  
  --centrage du bouton en bas de la fenetre pwindow
  --i = (width_pwindow/2)-(width_button/2)
  width_button = 60
  quit = fltk:Fl_Button(dec_button+5, height_pwindow-30, width_button, 25, "Quitter")
  quit:tooltip("Quitter cette appli!")
  quit:callback(quit_callback_app)
  
  dec_button = dec_button+width_button+15
  slider1stwords = fltk:Fl_Slider(dec_button, height_pwindow-20, 180, 15, "")
  s1wbutton=fltk:Fl_Button(dec_button, height_pwindow-35, 180, 15, "")
  s1wbutton:box(0)
  slider1stwords:type(1)
  debocc=30
  finocc=1000 --select 30 to 1000 words  with max occurrences in panel
  slider1stwords:range(debocc, finocc)
  slider1stwords:step(10)
  
  st = debocc .. " first words"
  s1wbutton:label( st )
  s1wbutton:box(0)
  
  slider1stwords:callback(
	function(slider1stwords)
	      local d,st
	      d = slider1stwords:value()
	      st = d .. " first words"
              s1wbutton:label( st )
	end)
	
  -- dispersion of words parameter
  dec_button = dec_button+180+15
  sliderdisp = fltk:Fl_Slider(dec_button, height_pwindow-20, 180, 15, "")
  sdispbutton=fltk:Fl_Button(dec_button, height_pwindow-35, 180, 15, "")
  sdispbutton:box(0)
  sliderdisp:type(1)
  debdisp=30
  findisp=1000 --select 30 to 1000 words  with max occurrences in panel
  sliderdisp:range(debdisp, findisp)
  sliderdisp:step(10)
  
  st = debdisp .. " pix dispersion"
  sdispbutton:label( st )
  sdispbutton:box(0)
  
  sliderdisp:callback(
	function(sliderdisp)
	      local d,st
	      d = sliderdisp:value()
	      st = d .. " pix dispersion"
              sdispbutton:label( st )
	end)
  
  local diml,dimh --dimension chaine lxh
  local posx,posy,sizefactor
  local i,j,a,b,x,y,w,h
  local centerw=(width_pwindow/2)
  local centerh=((height_pwindow-30)/2)
  --width_pwindow, height_pwindow
  
    --for i =#words_ordering,1,-1 do
  for i=1,30 do
      j = words_ordering[ i ]
      sizefactor = occur_words[j]/20
      dimh = sizefactor
      diml = sizefactor*#words[j]
      x=math.random(centerw-(width_pwindow/4), centerw+(width_pwindow/4))
      y=math.random(centerh-((height_pwindow-30)/4), centerh+((height_pwindow-30)/4))
      w=diml
      h=dimh
      st=words[j]
      b = fltk:Fl_Button(x,y,w,h, st)
      b:box(0)
      b:labelcolor(i)
      b:labelsize(diml)
      
    end
  
  
  --[[
  dec_button = dec_button+35
  testbutton5 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@fileopen")
  testbutton5:tooltip("Ouvrir un autre fichier")
  testbutton5:callback(load_data)
  ]]--
  
  
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
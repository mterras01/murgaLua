#!/bin/murgaLua

--[[ 
------- Questions to answer :
-where are all your data?
-where are the X "fullest" directories?
------- Problems to resolve
1/ fine-tune windows / linux command lines for getting directories' size
2/ process text files with dirs'size
3/ define vizualisation's charts 
4/ zooming on charts ?
------- things to do :
1/ create special charts (and no native-fltk charts, too limited/restricted in terms of visualization)
-bar chart: ok
-pie-chart: to do
2/ integration of fltk dir chooser function to select a specific directory
-integration in murgaLua code : ok
-integration into command line (called from script) for linux (ok), windows (ok) (macos ?)
3/ create clickable charts, ie generate stats & charts for a new parent-directory et its subdirectories (ok)
]]

i=0
f=0
st,st2="",""
-- vars for host ----------------------------------------------------------
hostname=""
-- BUFFER and vars for file -----------------------------------------------
separator = ";"
read_data = "" --read buffer
size_eol = 0 -- EOL size Unix / MacOs / Windows
dirname = "" --parent directory as string, default is home
nb_subdirs_in_dir=0 --no comment
total_dir_size = 0

-- GUI variables ----------------------------------------------------------
width_pwindow = 500 --dim main window for wordcloud
height_pwindow = 500
width_button = 160
height_button = 40
dec_button = 0
centerw=(width_pwindow/2)
centerh=((height_pwindow-height_button)/2)
ran,rad=0,0
_LOG_SCALING=0
TYPE_CHARTS="HORIZONTAL BARS" --other choice="PIE"

dirs_labels={}
dirs_labels_ASCII={}
dirs_size={}
dirs_size_label={} --size "string formatted" 4,4G ou 163M ou 144k
dirs_button={}

-- encoding cars -------------------------------------------------------
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
st = ""
for i=1,#convert.ascii_car do
    --print("initial ASCII char = " .. convert.ascii_car[i] .. " / converted char = " .. convert.ascii_char[i])
    st = st .. "//initial ASCII char = " .. convert.ascii_car[i] .. " / converted char = " .. convert.ascii_char[i]
end
fltk:fl_alert(st)
]]


-- if using luajit, comment next line
osName="OS=" .. murgaLua.getHostOsName()
-- if using luajit, uncomment next line
--osName="OS=linux"

--Check pre-requisite for Windows OS
if osName == "OS=windows" then
   --REQUIRED 2K/XP RESSOURCE KIT with diruse in PATH
   cmdl="diruse /*  > testcmd.txt"
   res = os.execute(cmdl)
   if res == 0 then
      --success
   else
      --Fail => message & exit
      st = "Sorry Windows User !\nThis app REQUIRE the 2K/XP RESSOURCE KIT with diruse.exe in PATH"
      fltk:fl_alert(st)
   end
end

t00=0
t11=0

--Fl:scheme("plastic")
Fl:scheme("gtk+")

find = string.find
sub = string.sub
pi = math.pi
rand = math.random

function deaccentuate(str)
  local i,j,str2,s,c
  
  str2=str
  --finding accentuated chars and deaccentuate them
  for i=1,#str do
      for j=1,#convert.ascii_car do
          s,c = string.gsub(str2, convert.ascii_car[j], convert.ascii_char[j])
          if s then
	     str2 = s
	  end
      end
  end
  --finding double slashes and remove one of them (linux)
  s,c = string.gsub(str2, "//", "/")
  if s then
     str2 = s
  end
  return(str2)
end --end function

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

function display_charts()
  local i, h, p, w, st, st2
  local pwidth=0
  
  --adjusting  buttons size, propertie, color according to tables dirs_size, dirs_size_label, dirs_labels
  p = dirs_size[i] -- size as number
  --first button has the biggest size 
  
  for i=1,30 do
      st = i .. ". " .. dirs_labels_ASCII[i] .. "\nsize = " .. dirs_size_label[i] --size as tring
      dirs_button[i]:tooltip(st)
      dec_button = dec_button + height_button
      --ajusting width current scaling rules (log scaling or not)
      if _LOG_SCALING == 1 then
         pwidth = (math.log(dirs_size[i])/math.log(dirs_size[1]))*disp_width_for_button_bars
      else
	 pwidth = (dirs_size[i]/dirs_size[1])*disp_width_for_button_bars -- without "log viz"
      end
      if pwidth < 20 then
	 pwidth=20
      end
      pwidth = round(pwidth)
      h = dirs_button[i]:h()
      dirs_button[i]:size( pwidth, h )
      if dirs_size[i] == 0 then
	 dirs_button[i]:hide()
      else
	 dirs_button[i]:show()
      end
      dirs_button[i]:color( i )
  end  
  --updating dirname in charts window's tooltip
  st2=deaccentuate(dirname)
  if st2 then
     if nb_subdirs_in_dir <30 then
        st="Parent Directory presented here is\n".. st2 .. "\n" .. nb_subdirs_in_dir .. " subdirs"
     else
        st="Parent Directory presented here is\n".. st2 .. "\n30 biggest subdirs"
     end
  else
     if nb_subdirs_in_dir <30 then
        st="Parent Directory presented here is\n".. dirname .. "\n" .. nb_subdirs_in_dir .. " subdirs"
     else
        st="Parent Directory presented here is\n".. dirname .. "\n30 biggest subdirs"
     end
  end
  if total_dir_size > 0 then
     st = st .. "\n Total size of this dir is " .. total_dir_size .. " bytes"
  end
  charts_border:tooltip(st)
end --end function

function populate_tables()
  local i,p,p0,q,w1,w2
  local multi=1
  local size,st,st2,s,c
  
  --here, give values to tables
  --dirs_labels
  --dirs_size
  --dirs_ordering
  nb_subdirs_in_dir=0 --global var
  
  if #dirs_labels > 1 then
     for p=1,#dirs_labels do
         table.remove(dirs_labels)
	 table.remove(dirs_size)
	 table.remove(dirs_size_label)
	 table.remove(dirs_size_label)
	 table.remove(dirs_labels_ASCII)
     end
  end
  if osName == "OS=linux" then
     --structure of linux results in file
--[[
11G	cbr/
2,3G	Bureau/
1,6G	Téléchargements/
964M	Documents/
]]
     p0=1
     while 1 do
        p = find(read_data, "\n", p0, true)
        if p then
           line = sub(read_data, p0, p-1)
	   q = find(line,"\t",1,true)
	   w1 = string.upper(sub(line, 1, q-1))
	   if find(w1,"P",1,true) then
	      multi=1024^5
	      --multi=2^5
	   elseif find(w1,"T",1,true) then
	      multi=1024^4
	      --multi=2^4
	   elseif find(w1,"G",1,true) then
	      multi=1024^3
	      --multi=2^3
	   elseif find(w1,"M",1,true) then
	      multi=1024^2
	      --multi=2^2
	   elseif find(w1,"K",1,true) then
	      multi=1024
	      --multi=2
	   else
	      multi=1
	   end
	   st = sub(w1, 1, -2)
	   s,c = string.gsub(st, ",", ".")
	   if s then 
	      st = s
	   end
--print("conversion string of size to number = " .. st .. ", size of string = " .. #st)
	   size = multi * tonumber( st )
--print("conversion string of size to number = " .. size)
	   w2 = sub(line, q+1)
--print( (#dirs_labels+1) .. ". size=" .. w1 .. " // label=" .. w2)
           if w2 ~= nil and size ~= nil then
              table.insert(dirs_labels, w2)
	      nb_subdirs_in_dir = nb_subdirs_in_dir+1
	      table.insert(dirs_size, size) --size as a number defining width of button
	      table.insert(dirs_size_label,w1) -- size "string formatted" like 4,3G or 144k
	      st2 = deaccentuate( dirs_labels[ #dirs_labels ] )
	      if st2 then
	         table.insert(dirs_labels_ASCII, st2)
	      else
		 table.insert(dirs_labels_ASCII, "pb technique")
	      end
	   end
           p0 = p+1
        else
           break
        end
    end
  elseif osName == "OS=windows" then
     --structure of Windows "diruse" results (including a sorting in cmdline)
--[[
    Size  (b)  Files  Directory
    406274261    619  TOTAL
    384702882    374  SUB-TOTAL: C:/DOCUMENTS AND SETTINGS/TERRAS/\Local Settings
     20451687     95  SUB-TOTAL: C:/DOCUMENTS AND SETTINGS/TERRAS/\Mes documents
      1007447     55  SUB-TOTAL: C:/DOCUMENTS AND SETTINGS/TERRAS/\Application Data
...    
]]
     --1st line means cols' labels
     p = find(read_data, "\n", p0, true)
     p0 = p+1
     --2nd line means total size for this parent directory (=dirname)
     p = find(read_data, "\n", p0, true)
     if p then
        line = sub(read_data, p0, p-size_eol)
        w1 = sub(line, 1, 13)
	if w1 then
           total_dir_size = tonumber(w1)
	   if total_dir_size == nil then
	      total_dir_size = 0
	   end
	else
	   total_dir_size = 0
	end
	p0 = p+1
     end
     while 1 do
        p = find(read_data, "\n", p0, true)
        if p then
           line = sub(read_data, p0, p-size_eol)
	   w1 = sub(line, 1, 13)
	   if w1 then
	      size = tonumber( w1 )
	   else
	     size = 0
	   end
	   w2 = sub(line, 34)
           if w2 ~= nil and size ~= nil then
print( (#dirs_labels+1) .. ". size=" .. w1 .. " // label=" .. w2)
	      if dirs_labels [#dirs_labels] == "" and dirs_size_label[#dirs_size_label] == ""  then
	         break
	      else
                 table.insert(dirs_labels, w2)
	         nb_subdirs_in_dir = nb_subdirs_in_dir+1
	         table.insert(dirs_size, size) --size as a number defining width of button
	         table.insert(dirs_size_label,w1) -- size "string formatted" like 4,3G or 144k
	         st2 = deaccentuate( dirs_labels[ #dirs_labels ] )
	         if st2 then
	            table.insert(dirs_labels_ASCII, st2)
	         else
		    table.insert(dirs_labels_ASCII, "pb technique")
	         end
	      end
	   end
           p0 = p+1
        else
           break
        end
	if #dirs_labels > 30 then
	   break
	end
     end --end while
  elseif osName == "OS=macos" then
     --not sure about this dev
  else
     --????
  end
  -- filling tables, if less than 30 directories
  if #dirs_labels < 30 then
     for i=(#dirs_labels+1),30 do
         table.insert(dirs_labels, "")
	 table.insert(dirs_size, 0)
	 table.insert(dirs_size_label,"")
	 table.insert(dirs_labels_ASCII, "")
     end
  end
end --end function

function cmdline(dirname)
  local res
  local cmdl=""
  
  if dirname == nil then
     os.exit(0)
  end
  if osName == "OS=linux" then
     --30 "most full" directories
     --cmdl="du -k */ | sort -nr | cut -f2 | xargs -d '\n' du -sh | head -n 30 > /home/terras/testcmd.txt"
     cmdl="du -k \"" .. dirname .. "\"/*/ | sort -nr | cut -f2 | xargs -d '\n' du -sh | head -n 30 > /home/terras/testcmd.txt"
--print(cmdl)
     res = os.execute(cmdl)
     if res == 0 then
        --success
print("du command was successfull!")
        return 1
     else
        --epic fail
print("du command was an epic fail!")
        os.exit(0)
	--return 0
     end
  elseif osName == "OS=windows" then
     --REQUIRED 2K/XP RESSOURCE KIT with diruse in PATH
     --cmdl="dir \"" .. dirname .. "\" /S /-C | FIND /V \"/\" > testcmd.txt"
     --cmdl="diruse /* \"" .. dirname .. "\" > testcmd.txt"
     cmdl="diruse /* \"" .. dirname .. "\" | SORT /r /o testcmd.txt"
     res = os.execute(cmdl)
     if res == 0 then
        --success
        return 1
     else
        --epic fail
       print("Resultat de " .. cmdl .. " = " .. res)
        return 0
     end
  elseif osName == "OS=macos" then
     return 0
  else
     print("Unknown OS !")
     os.exit(0)
  end
end

function load_data(dirname)
  local st, sysfile = "", ""
  local nbl,nbc = 0, 0  
  
  i=0
  f=0
  st=""
  
  if cmdline(dirname) ~= 1 then
     return nil
  end
  
  if osName == "OS=linux" then
     linecmd = "hostname > temp.txt";
     res = os.execute(linecmd)
     if res == 0 then
        f = io.open("temp.txt", "rb")
        if f then
           buffer = f:read("*all")
print("Hostname is " .. buffer)
	   if find(buffer, "terras-Aspire-5733Z",1,true) then
	      hostname = "terras-Aspire-5733Z"
	      filename = "/home/terras/testcmd.txt" -- ACER
	   elseif find(buffer, "HP6200",1,true) then
	      hostname = "HP6200"
	      filename = "/home/terras/testcmd.txt"
	   else
	      filename=nil
	   end
           io.close(f)
	end
     end
  elseif osName == "OS=windows" then
     linecmd = "hostname > temp.txt";
     res = os.execute(linecmd)
     if res == 0 then
        f = io.open("temp.txt", "rb")
        if f then
           buffer = f:read("*all")
print("Hostname is " .. buffer)
	   if find(buffer, "optiplex320",1,true) then
	      hostname = "optiplex320"
	      filename = "testcmd.txt" --OPTIPLEX (current dir)
	   else
	      filename = "G:\\Dim\\dsl-not\\scripts-murgaLua\\testcmd.txt"
	      --filename=nil
	   end
           io.close(f)
	end
     end
     
  elseif osName == "OS=macos" then
     --nothing for macos
	 return nil
  else
     return nil
  end
  
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
        --read_data = string.lower(read_data)
	read_data = read_data
print("Reading successfully file " .. filename .. ", taille=" .. #read_data .. " bytes")
        io.close(f)
        sysfile = define_textfile_origin(read_data)
print("filesystem Origin (according to CR/LF) = " .. sysfile )
        populate_tables()
        return 1
     else
        print("Inexistent file " .. filename)
        return nil, nil
     end
  else
    return nil, nil
  end
end --end function

function load_dir()
  dirname = fltk.fl_dir_chooser("Directory selector", "", SINGLE, nil)
  if load_data(dirname) then
     return 1
  else
     return 0
  end
end --end function

function clicksubdir()
  --computing x and y mouse coordinates when clicked and retrieving button's range = subdir
  local i,st
  
  --One subdir button was clicked : which one?
  for i=1,30 do 
      if Fl:event_inside( dirs_button[ i ] ) == 1 then 
	 dirname = dirs_labels[i]
print("clicked button was number " .. i)
print("dirname is now " .. dirname)
         break
      end
  end
  --as for unices systems, 
  --dirname needs to be scanned for "double slashes" (//), 
  --these couple of cars have to be converted into "one slash" (/)
  --and final / has to be removed
  if osName == "OS=linux" then
     st = string.gsub(dirname, "//", "/")
     dirname = sub(st,1,-2)
     print("dirname is now " .. dirname)
  end
  --click on a subdir will select this one as new parent-dir
  --have to launch cmdline with this dir
  if load_data(dirname) then
print("calling to load_data() was succefull")
     display_charts()
     pwindow:redraw()
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

  --FLTK Version
  print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. fltk.FL_PATCH_VERSION)
  
  --if load_data() then
  if load_dir() then
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
  disp_width_for_button_bars = (width_pwindow-20) --disponible width for buttons-bars (charts)
  
  pwindow = fltk:Fl_Window(width_pwindow, height_pwindow, "YOUR 30 biggest Directories")

  --centrage du bouton en bas de la fenetre pwindow
  width_button = 40
  height_button = 25
  quit = fltk:Fl_Button(dec_button+5, height_pwindow-height_button, width_button, height_button, "Quit")
  quit:tooltip("Quit this app!")
  quit:callback(quit_callback_app)
  --frame bordering charts part
  charts_border = fltk:Fl_Box(5, 5, width_pwindow-10, height_pwindow-height_button-10)
  charts_border:box(2)
  --charts_border:color(fltk.FL_DARK_GREEN)
  charts_border:color(25)
  st2=deaccentuate(dirname)
  if st2 then
     st="Parent Directory presented here is\n".. st2
  else
     st="Parent Directory presented here is\n".. dirname
  end
  charts_border:tooltip(st)

  --LOG button for "sweeter" data scaling
  dec_button = dec_button+width_button+10
  _LOG_SCALING=0
  logbutton = fltk:Fl_Button(dec_button, height_pwindow-height_button, width_button, height_button, "Log")
  logbutton:tooltip("Logarithmic scaling OFF")
  logbutton:color(1)
  logbutton:callback(
        function(Logarithmic_scaling)
	      _LOG_SCALING = 1-_LOG_SCALING
	      local sc={}
	      sc[0] = "OFF"
	      sc[1] = "ON"
	      local st="Logarithmic scaling "
	      st = st .. sc[_LOG_SCALING]
	      logbutton:tooltip(st)
	      logbutton:color((_LOG_SCALING+1))
	      display_charts()
	      pwindow:redraw()
        end)
	
  --change parent directory
  dec_button = dec_button+width_button+10
  filebutton = fltk:Fl_Button(dec_button, height_pwindow-height_button, width_button, height_button, "@fileopen")
  filebutton:tooltip("Open another directory")
  filebutton:callback(
        function(reload_dir)
	      dirname = fltk.fl_dir_chooser("Directory selector", "", SINGLE, nil)
              if load_data(dirname) then
                 display_charts()
		 pwindow:redraw()
              end
        end)
	
  -- shape of charts = square (bars) or circle (pie)
  dec_button = dec_button+width_button+5
  width_button = 30
  height_button = 25
  shapedisp = fltk:Fl_Button(dec_button, height_pwindow-height_button, width_button, height_button, "@square")
  shapedisp:labelcolor(19)
  shapedisp:tooltip("click for toggle Bar/pie charts")
  shapedisp:callback(
        function(shapeupd)
	      if shapedisp:label() == "@square" then
		 shapedisp:label("@circle")
	      else
		 shapedisp:label("@square")
	      end
	      display_charts()
        end)  
	
  --display 30 empty "directory buttons"
  dec_button = 10
  height_button = 15
  
  for i=1,30 do
      table.insert(dirs_button, fltk:Fl_Button(10,dec_button,300,height_button, ""))
      dec_button = dec_button + height_button
      dirs_button[ i ]:callback( clicksubdir )
  end  
  
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

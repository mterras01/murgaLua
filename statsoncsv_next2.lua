#!/bin/murgaLua

--210724 from version statsoncsv_next.lua => statsoncsv_next2.lua
--allows via a GUI the fields filtering after pre-loading  of huge CSV (first xxx lines)
--downsizing of original file (>450Mb for year 2023)

--original file requiring changes since statsoncsv_next.lua
--OPEN_MEDIC_2023.CSV  (from SNDS)
--url = https://open-data-assurance-maladie.ameli.fr/medicaments/download_file2.php?file=Open_MEDIC_Base_Complete/OPEN_MEDIC_2023.zip

-----including sort of "pre-selection query" on fields with GUI buttons : 
--[[ use 
       if Fl.event_inside(abutton[i]) == 1 then
          activate_fct = i
          break
       end
]]--

i=0

stats = require "statistics"

find = string.find
--gfind = string.gfind
sub = string.sub
gsub=string.gsub

read_data = "" --tampon de lecture
write_data = "" --tampon ecriture CSV département
size_eol = 0 -- varie selon Unix (MacOs) ou Windows

legend_data={} --text legends from original CSV
new_legend={} --new text legends from transformed-downsized-filtered CSV
table_data={} --main data model table = colons
transftable_data={} --downsized table (built from previous)
cat_values={} --catalogue des valeurs
occ_values={} --occurences des valeurs précédentes
max={}
min={}
moyenne={}
median={} --mediane des valeurs précédentes
variance={} --variance des valeurs précédentes
nb_lines=0
nb_bytes=0
total_bytes=0

--interface
selbuttons={} --selbuttons[i]:color(2) means "selected field/column", :color(1) means "NOT selected field/column"
selcol={}
keyword=nil -- GUI input objects for catching query values
clearbutton=nil
selvalbutton={}
selval={"","","","",""} --values related to cols of table_data, used to query on original table and make a downsizing
selval_select={}

--tampons d'écriture pour les fichiers texte et csv de sauvegarde
--csv_buffer = "" -- local
separator = ";"

--Charts
type_chart = { fltk.FL_BAR_CHART, fltk.FL_LINE_CHART, fltk.FL_FILLED_CHART, fltk.FL_SPIKE_CHART, fltk.FL_PIE_CHART, fltk.FL_SPECIALPIE_CHART, fltk.FL_HORBAR_CHART}
label_chart = { "FL_HORBAR_CHART", "FL_LINE_CHART", "FL_FILLED_CHART", "FL_SPIKE_CHART", "FL_PIE_CHART", "FL_SPECIALPIE_CHART", "FL_BAR_CHART" }
type_graphics = 4

filename=""

osName="OS=" .. murgaLua.getHostOsName()
print(osName)
t00=0
t11=0

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

function separator_csv(first_two_lines)    
  local st=""
  local nbl,nbl2=0,0
  
  local f = 0
  local i,j,k = 0,0,0
  local pos=1
  local str,c1,c2,d1,d2
  local line_data
  
  if first_two_lines == nil then
      return
  end
  -- separator decision1
  -- for 2 first lines, we compare nb of "," and ";"
  pos=1
  nbl2=0
  while 1 do
      i = find(first_two_lines,"\n",pos)
      if i then
	     line_data = sub(first_two_lines, pos, i-1)
         if nbl2 == 0 then
--print("Legende = " .. line_data)
            --first line : legende
		    if line_data  then
               _,c1 = gsub(line_data, ",", "")
               _,d1 = gsub(line_data, ";", "")
--print("Occurrences ' = " .. c1 .. "\nOccurrences ; = " .. d1)
            else
               break
            end
         elseif nbl2 == 1 then
            --2nd line
		    if line_data  then
               _,c2 = gsub(line_data, ",", "")
               _,d2 = gsub(line_data, ";", "")
--print("Deuxieme ligne\nOccurrences , = " .. c1 .. "\nOccurrences ; = " .. d1)
            else
               break
            end
         else
            break
         end
         pos = i+2
         nbl2=nbl2+1
      else
         break
      end
  end
  if c1 == c2 and c1 > d1 then
     i=c1
     separator = ","
  end
  if d1 == d2 and d1 > c1 then
     i=d1
     separator = ";"
  end
  str = "CSV Separator seems to be \"" .. separator .. "\""
  print(str)
  --st = str .. "\nAnd assuming first line contains names of columns"
  --fltk:fl_alert(st)
end --end function

function sorting()
 local i, st
 local s1_classed={}
 for i=1,#table_data[3] do
       s1_classed[i] = { id1=i, num1=table_data[3][i]}
 end
 st=""
 for i=1,2000 do
       st = st .. s1_classed[i].id1  .. "/" .. s1_classed[i].num1 .. "* " 
 end
 print(st)
 table.sort(s1_classed, function(a,b) return a.num1 < b.num1 end)
 st="Post sorting... \n"
 for i=1,2000 do
       st = st .. s1_classed[i].id1  .. "/" .. s1_classed[i].num1 .. "* " 
 end
 print(st)
end --end function

function process2(line_data)
  local line_data_model={}
  local ldlocal, i
 --this function agregates two previous fcts process() and get_data_from_line_DP() and is used in replacement
 
if line_data then
   ldlocal = line_data
   i = find(ldlocal,"\n",1,true)
   if i then
      ldlocal = sub(ldlocal, 1, i-2) -- according to OpSys and size of EOL
      --ldlocal = sub(ldlocal, 1, i-size_eol) 
   end
   for str in string.gmatch(ldlocal, "([^" .. separator .."]+)") do
        if str then 
           table.insert(line_data_model, str)
        else
           return nil
        end
        --table.insert(line_data_model, str)
    end
    return line_data_model
else
     return nil
end
end   --end function

function rapport_base()
 local i,j,k,st,m,st2
 local buffer=""
 
  print("#transftable_data = " .. #transftable_data .. " x " .. #transftable_data[1])
  for i=1,#transftable_data do
       buffer=" "
	   occ_values[i]={}
       if type(transftable_data[i][1] )== "number" then
	      cat_values[i]={} -- pour les nombres, pas de catalogue de valeurs
          --sauf si ...
          for j=1,transftable_data[i] do
               st=" " .. transftable_data[i][j] .. " "
               if find(buffer, st,1,true)  then
                  --rien
                  --trouver le Num occur
                   for k=1,#cat_values[i] do
                        if transftable_data[i][j] == cat_values[i][k] then
                           occ_values[i][k] = occ_values[i][k]+1
                           break
                        end
                   end
	           else
				  buffer = buffer  .. transftable_data[i][j] .. " "
				  table.insert(cat_values[i],transftable_data[i][j])
                  table.insert(occ_values[i],1)
               end
          end
          median[ i ] = stats.series.median(transftable_data[i])
          moyenne[i] = stats.series.mean(transftable_data[i])
          variance[i] = stats.series.variance(transftable_data[i])
          min[i],max[i] = stats.series.getExtremes(transftable_data[i])
           --init table
--print("#buffer = " .. #buffer .. "\n#cat_values[" .. i .. "] = "  .. #cat_values[i])
--print("Nb de valeurs possibles  = "  .. #cat_values[i])

       elseif type(transftable_data[i][1] )== "string" then
	       cat_values[i]={} -- pour les chaines de car, catalogue des valeurs possibles
           for j=1,#transftable_data[i] do
               if find(buffer, transftable_data[i][j],1,true)  then
                  --rien
               else
                  buffer = buffer .. " " .. transftable_data[i][j]
				  table.insert(cat_values[i],transftable_data[i][j])
               end
          end
		  --init table
		  --for j=1,#cat_values[i] do
		      --occ_values[i]={}
		  --end
		  if #cat_values[i] > 1 then
             table.sort(cat_values[i]) -- pour avoir les valeurs possibles triées par valeur/par ordre alpha
--		     print("Catalogue des valeurs = " .. table.concat(cat_values[i],"//") .. "\nNb de valeurs possibles = " .. #cat_values[i])
             st=table.concat(transftable_data[i])
			 for j=1,#cat_values[i] do
                 _, occ_values[i][j] = st:gsub(cat_values[i][j],"")
			 end
		  end
       else
           --rien
       end
  end
end  --end function

function transform(old_table_data)
  --2 apply filters on selected fields  and on selected values in fields
  local transformed_table_data={}
  local i

  for i=1,#old_table_data do
       if selcol[i] == 2 then
          table.insert(transformed_table_data, old_table_data[i])
       end
  end
  return( transformed_table_data )
end  --end function

function build_new_base_CB() 
 --CB stands for Circular Buffer
  local i,j,k,l
  local buffer_size=400000
  local st,st2,sel,sel2
  local pos=1
  local new_table_data={}
  local read_buffer_a=""
  local closing=0
  local table_data_local={}
  
  --1 read data lines from original file (circular buffer)
  --2 apply filters on selected fields  and on selected values in fields
  --3 write line in new buffer var "csv_buffer" (not in new file = too long) = Assuming there is enough RAM for this buffer
  --4 build in RAM "table_data" for next stats
  --5 (OPTIONAL) update graphic progression bar
  
  nb_bytes=0
  --csv_buffer="" -- -------------------------->optimization 040824
if filename then
    f = io.open(filename,"rb")
    if f then
print("File " .. filename .. " opened !")
       --new legends processing (with applied exclusion fields filters)
       read_buffer_a = f:read("*line") --1st line = legend_data
       read_buffer_a = read_buffer_a .. "\n"
       legend_data = process2(read_buffer_a)
       new_legend = transform( legend_data )
       if new_legend then
          --for i=1, #new_legend do
          --     transftable_data[i]={}
          --end
          --table.insert(transftable_data[1], new_legend )
          table.insert(transftable_data, new_legend )
--print("transftable_data[1] = " .. table.concat(transftable_data[1],separator) .. "(new_legend=" ..  table.concat(new_legend,"//") .. ")")
--st="Bien Vu ?"
--fltk:fl_alert(st)

          --transftable_data[1] = new_legend 
          --csv_buffer = csv_buffer .. table.concat(new_legend, separator) .. "\n" -- -------------------------->optimization 040824
--print("Legend = " .. table.concat(new_legend, separator) )
       end
       while 1 do  --buffering reading-in-file while
           if closing == 1 then
              io.close(f)
              break
           end
           read_buffer_a = f:read(buffer_size,"*line")
          -- read_buffer_a = read_buffer_a .. "\n" -- -------------------------------------------> added 040824 ---> removed 050824 (added on last line = NOSENSE
           if #read_buffer_a <buffer_size then
              closing = 1 
           end
		   nb_bytes=nb_bytes+#read_buffer_a
           --global filtering criteria here, applied on the whole buffer
          --added 300724
--read_buffer_a = string.upper( read_buffer_a )
	      sel=0
	      l=1
          while 1 do
             if find(read_buffer_a, selval_select[l], 1, true) then 
                sel=1
	            break
             end
             l=l+1
	         if l > #selval_select then
	            break
	         end
          end
    if sel == 1 then  
          pos=1
          while 1 do  --processing-in-ram while
             j = find(read_buffer_a,"\n",pos)
             if j then
	            line_data = sub(read_buffer_a, pos, j)
		        if line_data  then
--print("line_data (direct from buffer) = " .. line_data)
                   --test criterias on "as is" line_data
--line_data = string.upper( line_data )
	               sel2=0
	               l=1
                   while 1 do
                      if find(line_data, selval_select[l], 1, true) then 
                         sel2=1
                         break
                      end
                      l=l+1
	                  if l > #selval_select then
	                     break
	                  end
                   end
                   if sel2 == 1 then 
                      table_data_local = process2( line_data)
                      new_table_data = transform(table_data_local)
                      if new_table_data then
                         table.insert(transftable_data, new_table_data ) --OPTIMIZATION
                         --csv_buffer = csv_buffer .. table.concat(new_table_data,separator) .. "\n" -- -------------------------->optimization 040824
                      end
                   end
                      pos = j+1
                      --nb_bytes=nb_bytes+#read_buffer_a --> bad place
                else
st = "line_data est nulle !"
print(st)
--fltk:fl_alert(st)
	                break
	            end
             else
--print("no more \"\\n\" car found in read_buffer_a ! Quitting while reading loop")
                 break
             end
          end --end processing-in-ram while
--old prog bar here
  end --global filtering criteria here, applied on the whole buffer
k=nb_bytes*100/total_bytes
progress_bar:value(k)
progress_bar:draw()
st = string.format('%.1f', k).."%"
progress_bar:label(st)
Fl:check()
      end --end reading-in-file while
    else
       print("Lecture impossible du CSV " .. filename)
	   fltk:fl_alert("Lecture impossible du fichier CSV ")
    end
 else
	 fltk:fl_alert("Lecture impossible du fichier CSV ")
 end 
end  --end function

function build_new_csv() 
 --CB stands for Circular Buffer
  local i,j,k
  local f, fn, st, str
  local nb_bytes=0
  local size_bufwr_lines=5000
  local csv_buffer=""
  --From table_data table, write line in buffer var "csv_buffer" = Assuming there is enough RAM for this buffer
  
  if new_legend then
    i,_ = find(string.lower(filename), ".csv",1,true)
    fn = sub(filename,1,(i-1)) .. "_downsized.csv"
    f = io.open(fn,"wb")
    if f then
       --csv_buffer = csv_buffer .. table.concat(new_legend, separator) .. "\n" --unused because new_legend is 1st line of transftable_data
       for i=1,#transftable_data do
            if transftable_data[i] then
               csv_buffer = csv_buffer .. table.concat(transftable_data[i],separator) .. "\n"
if i%5000 == 0 or i == #transftable_data then 
--print("Ligne " .. i)
k=i*100/#transftable_data
progress_bar2:value(k)
progress_bar2:draw()
st = string.format('%.1f', k).."%"
progress_bar2:label(st)
Fl:check()
--circular buffer writing
f:write(csv_buffer)
nb_bytes=nb_bytes+#csv_buffer
csv_buffer = ""
end
            else
print("Problemo with line in csv_buffer")
               return
            end
       end --end for
       io.close(f)
print("File " .. fn .. " successfully saved !")
    else --if f // file       
print("Error while Backup of new downsized CSV file " .. fn)
        fn=nil
    end
  else
  print("Problemo with legend in csv_buffer")
     return
  end
end  --end function

function downsize()
  local i
  
  --build new table selval_select
  for i=1,#selval do
       if selval[i] == "" then
		  selval_select[i] = nil
		  break
       else
          selval_select[i] = selval[i]
       end
  end

  --remove "table_data", as previous contains data/fieds/cols 5-lines sample from original CSV before downsizing
  table_data=nil  --release RAM
  --new table "transftable_data" will handle new dowsized and filtered data
  
  --new version with circular buffer => time processing optimization
  build_new_base_CB()
  print("build_new_base_CB() Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")
--[[
  print("#transftable_data = " .. #transftable_data)
  print("transftable_data[1] = " .. table.concat(transftable_data[1],separator) )
  print("transftable_data[2] = " .. table.concat(transftable_data[2],separator) )
  print("transftable_data[3] = " .. table.concat(transftable_data[3],separator) )
  print("...")
  print("transftable_data[#transftable_data-2] = " .. table.concat(transftable_data[#transftable_data-2],separator) )  print("transftable_data[#transftable_data-1] = " .. table.concat(transftable_data[#transftable_data-1],separator) )
  print("transftable_data[#transftable_data] = " .. table.concat(transftable_data[#transftable_data],separator) ) 
]]--   
  build_new_csv()
  print("build_new_csv() Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")
  
  rapport_base()
  print("rapport_base() Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")
end  --end function

function select_field_fct()
local i
  for i=1,#selbuttons do
       if Fl.event_inside(selbuttons[i]) == 1 then
          if selbuttons[i]:color() == 2 then
             --2 means green means selected
             selbuttons[i]:color(1)
             selcol[i] = 1
--print("selcol[" .. i .. "] = " .. selcol[i])
             --1 means red means de-selected
             selbuttons[i]:label( "DSEL" )
             selbuttons[i]:tooltip( "De-selected field" )
             selbuttons[i]:show()
          else
             --1 means red means de-selected
             selbuttons[i]:color(2) 
             selcol[i] = 2
--print("selcol[" .. i .. "] = " .. selcol[i])
             --2 means green means selected
             selbuttons[i]:label( "SEL" )
             selbuttons[i]:tooltip( "Selected field" )
             selbuttons[i]:show()
          end
       else
          selcol[i] = selbuttons[i]:color()
       end
  end
  return                                              
end  --end function

function select_val_fct()
  local i,st

  st = string.upper(keyword:value())
  for i=1,#selvalbutton do
       if selvalbutton[i]:label() == "" then
          selvalbutton[i]:label(st)
          selval[i]=st
print( i .. ". selval[" .. i .. "]=" .. selval[i])
          break
       end
  end
  --erase text
  keyword:value("")
end --end function

function clear_val_fct()
  local i
  keyword:value()
  for i=1,#selvalbutton do
       selvalbutton[i]:label("")
       selval[i]=""
       selval_select[i] = nil
  end
end --end function

function disp_sample2()
 --GUI selecting fields to be analysed
  local i,j,cx,cy,post
  local st,st1,st2,st3
  local cell0=nil
  local histo=nil
  local co=#table_data
  local li=#table_data[1]
  local table_stats={"NB VAL","MIN","MAX","MOY","MED","VAR","SIGMA"} --legendes abregees pour les stats
  local table_stats_ib={"Nb de valeurs distinctes","Valeur minimale","Valeur maximale","Moyenne","Médiane","Variance","Ecart-type"} --legendes completes (infobulle) pour les stats
  local table_stats_val={}

  if twindow then
     twindow:hide()
     twindow:clear()
  end

  --fenetre graphique pour la restitution du tableau CSV
  width_twindow = 1024
  height_twindow = 450
  twindow = fltk:Fl_Window(width_twindow, height_twindow, "Tableau CSV")
  --width_button = 120
  width_button = math.floor(width_twindow/(co+1)) --ajout d'une colonne "legende" (stats)
  height_button = 20
  --nb_car = width_button/10 --nb cars affichables dans la largeur du bouton
  nb_car = math.floor(width_button/11) --nb cars affichables dans la largeur du bouton

  t_quit = fltk:Fl_Button(10, height_twindow-30, width_button, 25, "Quit")
  t_quit:tooltip("Fermer cette fenetre")
  t_quit:callback(quit_t)
  t_downs = fltk:Fl_Button(10+width_button, height_twindow-30, width_button, 25, "Down")
  t_downs:tooltip("Downsize original data with selected items ans save it")
  t_downs:callback(downsize)
  
  -- progress bar N1 : build table
  progress_bar = fltk:Fl_Progress(10+(2*width_button), height_twindow-30, 5*width_button, 25, "0")
  progress_bar:maximum(100)
  progress_bar:minimum(1)
  progress_bar:selection_color(fltk.FL_GREEN)
  info_button1 = fltk:Fl_Button(10+(2*width_button), height_twindow-55, 5*width_button, 25, "Building new downsized table")
  
-- progress bar N2 : build and save csv
  progress_bar2 = fltk:Fl_Progress(10+(7*width_button), height_twindow-30, 5*width_button, 25, "0")
  progress_bar2:maximum(100)
  progress_bar2:minimum(1)
  progress_bar2:selection_color(fltk.FL_GREEN)
  info_button2 = fltk:Fl_Button(10+(7*width_button), height_twindow-55, 5*width_button, 25, "Saving new downsized CSV")
  
  --affichage legendes + 2 premières lignes de table_data
  --table legendes
  cx, cy=0,0
  cell0= fltk:Fl_Button(cx, cy, width_button, height_button, "LABELS" )
  cell0:labelfont( fltk.FL_SCREEN )
  cell0:tooltip( "Labels des champs" )
  for j=1,co do
      selval[j]={"","","","",""}
      cy = 0
      cx = j*width_button
      st = legend_data[ j ]
      if type(st) == "string" then
         st = sub(st, 1, nb_car)
      end
      cell0= fltk:Fl_Button(cx, cy, width_button, height_button, st )
      cell0:labelfont( fltk.FL_SCREEN )
      cell0:tooltip( legend_data[ j ] )
  end
  --ligne type des donnees
  cx, cy=0,height_button
  cell0= fltk:Fl_Button(cx, cy, width_button, height_button, "TYPE" )
  cell0:labelfont( fltk.FL_SCREEN )
  cell0:tooltip( "Type de donnees" )
  for j=1,co do
      cy = height_button
      cx = j*width_button
      st1 = gsub(table_data[ j ][1],",",".")
      if type(st1) == "string" and type(tonumber(st1)) == "number" then
         st = "number"
         st2 = "nb"
      else 
         st="string"
         st2 = "str"
      end
      cell0= fltk:Fl_Button(cx, cy, width_button, height_button, st2 )
      cell0:labelfont( fltk.FL_SCREEN )
      cell0:color(fltk.FL_RED)
      cell0:tooltip( st )
  end

--table table_data : echantillon/sample
  cx, cy=0,0
  for i=1,5 do
      for j=1,co do
	  cy = (i+1)*height_button
      cx = j*width_button
	  st = table_data[ j ][i]
      st2 = sub((st .. ""), 1, nb_car)
      cell0=fltk:Fl_Button(cx, cy, width_button, height_button, st2 )
      cell0:labelfont( fltk.FL_SCREEN )
      cell0:color(20)
	  cell0:tooltip( table_data[ j ][i] )
      end 
  end
                                                 
--column selection buttons 
  cx, cy=0,0
  i=6
  for j=1,co do
      selcol[i]=2
	  cy = (i+1)*height_button
      cx = j*width_button
--selection buttons
      table.insert(selbuttons, fltk:Fl_Button(cx, cy, width_button, height_button, "SEL" ) )
      selbuttons[#selbuttons]:labelfont( fltk.FL_SCREEN )
      selbuttons[#selbuttons]:color(2)
	  selbuttons[#selbuttons]:tooltip( "Selected col" )
      selbuttons[#selbuttons]:callback(select_field_fct)
  end  
  
--histogram buttons
i=7
cy = (i+1)*height_button
 for j=1,co do
      cx = j*width_button
      st = "Hist" .. j
	  histo= fltk:Fl_Button(cx, cy, width_button, height_button, st )
	  histo:labelfont( fltk.FL_SCREEN )
      histo:color(12)
	  histo:tooltip( "Histogram" )
      histo:callback(histo_fct)
  end
  
--area for catching query values
  keyword = fltk:Fl_Input(width_button, (cy+(2*height_button)), (2*width_button), height_button)
  keyword:value("")
  keyword:callback(select_val_fct)
--clear button
  clearbutton = fltk:Fl_Button(width_button, (cy+(3*height_button)), (2*width_button), height_button, "CLEAR ALL" )
  clearbutton:callback(clear_val_fct)
   cx, cy=0,0
  i=6
  for i=1,5 do
  	  cy = (8+i)*height_button
      cx = 5*width_button
       table.insert(selvalbutton, fltk:Fl_Button(cx, cy, width_button, height_button) )
       selvalbutton[#selvalbutton]:label("")
       selval[i]=""
  end
  
  Fl:check()
  twindow:show()
end  --end function                  

function preopen_csv_file(fn) 
  local f, i, j, st
  local read_buffer_a=""
  local first_two_lines=""
  local p_lines=0
  local table_data_local={}
  total_bytes=0
  
 if fn then
--print("File name = " .. fn) 
    f = io.open(fn,"rb")
    if f then
print("File " .. fn .. " opened !") 
       while 1 do
          read_buffer_a = f:read("*line")
--print("Line read_buffer_a = " .. read_buffer_a ) 
	      if read_buffer_a == nil then
	   	     --ending : quit
		     io.close(f)
		     nb_lines = p_lines
--print("Nb of data Lines = " .. nb_lines .. "\nNb of bytes = " .. total_bytes) 
	         break
	      end
          if p_lines == 0 then
print("Original creator OpSys = " .. define_textfile_origin(read_buffer_a))
             st = read_buffer_a .. "\n"
             first_two_lines = first_two_lines .. read_buffer_a .. "\n"
			 p_lines = p_lines+1
          elseif p_lines == 1 then
             first_two_lines = first_two_lines .. read_buffer_a .. "\n"
             --read_data = first_two_lines
             separator_csv(first_two_lines)
             legend_data = process2(st)
             if legend_data then
                for i=1, #legend_data do
                     --init buffer tables
                     table_data[i]={}
                end
             end
			 p_lines = p_lines+1
print("Legends of CSV = " .. table.concat(legend_data, "/") )
          elseif p_lines >1 and p_lines <= 6 then
             --read_buffer_a = read_buffer_a .. "\n"
             table_data_local = process2(read_buffer_a)
             for i=1,#table_data_local do
--print("Process table_data_local[" ..  i .. "]" .. table.concat(table_data_local, "/") )
                  if table_data_local[i] then
                     k = tonumber(table_data_local[i])
                     if k then 
                        table.insert(table_data[i], k )
                     else
                        table.insert(table_data[i], table_data_local[i] )
                     end
                 end
             end
			 p_lines = p_lines+1
		  else
			total_bytes = f:seek("end")
print("total_bytes = " .. total_bytes)
			io.close(f)
			break
		  end
       end --end while
    else
       print("Lecture impossible du CSV " .. fn)
	   fltk:fl_alert("Lecture impossible du fichier CSV ")
    end
 else
	 fltk:fl_alert("Lecture impossible du fichier CSV ")
 end
end  --end function

function save_new_csv_file() 
  local f, fn, i, j, st, str
  
  i,_ = find(string.lower(filename), ".csv",1,true)
  fn = sub(filename,1,(i-1)) .. "_downsized.csv"
  
  f = io.open(fn,"wb")
  if f then
     f:write(csv_buffer)
     print(fn .. " sauvegarde, taille=" .. #csv_buffer .. " octets.")
     io.close(f)
	 --st = filename .. " sauvegarde !"
	 --fltk:fl_alert(st)
  else
     print("Error while Backup of new downsized CSV file " .. fn)
     fn=nil
	 --fltk:fl_alert(st)
  end
end --end function

function quit_t()
  if twindow then
     twindow:hide()
     twindow:clear()
     twindow = nil
     if pwindow then
        pwindow:hide()
        pwindow:clear()
        pwindow = nil
     end
     if cwindow then
        cwindow:hide()
        cwindow:clear()
        cwindow = nil
     end
  end
end --end function

function quit_c()
  if cwindow then
     cwindow:hide()
     cwindow:clear()
     cwindow = nil
  end
end --end function

function quit_callbackapp()
  if pwindow then
     pwindow:hide()
     pwindow:clear()
     pwindow = nil
  end
end --end function

function disp_histo(h)
 local st=""
 local decx_chart   = 20
 local decy_chart   = 0
 local width_chart  = 450
 local height_chart = 450
 local width_pwindow = 500
 local height_pwindow = 500
 local width_button = 160
 local dec_button = 0
 local i,j,k

 --type_graphics=1
  type_graphics=4
  --fenetre graphique pour la representation graphique et dynamique
  st = "Histo " .. legend_data[ h ]
  pwindow = fltk:Fl_Window(width_pwindow, height_pwindow, st)
  
  --centrage du bouton en bas de la fenetre pwindow
  width_button = 100
  quit = fltk:Fl_Button(dec_button+10, height_pwindow-30, width_button, 25, "Quit")
  quit:tooltip("Quitter cette appli!")
  quit:callback(quit_callbackapp)
  --chart
  pie = fltk:Fl_Chart(0, 0, 5, 5, nil)
  pie:position(decx_chart, decy_chart+20)
  pie:size(width_chart, height_chart)
  pie:label(legend_data[ h ])
  pie:type( type_chart[type_graphics] )
  pie:box(1)
  pie:labelcolor(0)
  for i=1,#cat_values[h] do
      if #cat_values[h]>=15 then
         j = math.floor(#cat_values[h]/15)
         if (i % j) == 0 then
            st = cat_values[h][i]  .. "\n" .. occ_values[h][i]
         else
            st = ""
         end
         color=4
      else
         st = cat_values[h][i]  .. "\n" .. occ_values[h][i]
         color=4
      end
      pie:add(occ_values[h][i], st, color)
  end
  --pie:show()
  Fl:check()
  pwindow:show()
end --end function

function histo_fct()
 local i,h,width_button, width_twindow

 width_twindow = twindow:w()
 width_button = math.floor(width_twindow/(#transftable_data+1))                                       
 h=0
 h=math.floor(Fl.event_x()/width_button)
--print("X mouse, Y mouse = " .. Fl.event_x() .. "," .. Fl.event_y())
--print("Bouton histo[" .. h .. "] a ete clique ")
--[[ code to keep for syntax purpose
 for i=1,#histo do
       if Fl.event_inside(histo[i]) == 1 then
          h=i
          break
       end
 end
 ]]--
 if h ~= 0 then
    if selcol[h] then
       if selcol[h] == 2 then
          disp_histo(h)
       end
    end
 end
end  --end function


 t00=0
 t11=0

 t00 = os.time() --top chrono
 osName="OS=" .. murgaLua.getHostOsName()
  --version FLTK
 print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. "." .. fltk.FL_PATCH_VERSION)
                                                 
 --for later usage
 -- filename = fltk.fl_file_chooser("SELECTION du FICHIER (CSV)", "CSV Files (*.{csv,CSV})", SINGLE, nil)

 if find(osName, "linux",1,true) then
      filename="/home/terras/Téléchargements/opendata_2024/OPEN_MEDIC_2023.CSV"
 else
    --windows, i suppose
	filename="P:\\dsl-not\\murgalua\\bin\\windows\\OPEN_MEDIC_2023.CSV"
 end
 print("RAM used BEFORE opData by  gcinfo() = " .. gcinfo())

 preopen_csv_file(filename)
 st="Pre-Ouverture Ok !\nColonnes = " .. #table_data .. "\nLignes (echantillon)= " .. #table_data[3]
print(st)
 --fltk:fl_alert(st)
 disp_sample2()

 --previous stages/function calls
 --open_csv_file(filename) 
 --separator_csv()
 --build_base()
 --rapport_base()
 --disp_sample_csv()
 --disp_corr()
 --[[
 if #csv_buffer >0 then
    save_new_csv_file()
 end
]]--

 print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")

  --print("Free RAM by collectgarbage(\"count\") = " .. collectgarbage("count"))
  print("RAM used AFTER opData by  gcinfo() = " .. gcinfo())
                                                 
 --print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")

Fl:check()
Fl:run()
--console correlations stats after "quitting" GUI
--disp_corr_txt()

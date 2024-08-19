#!/bin/murgaLua

--this murgaLua script has been tested with version 0750 https://github.com/igame3dbill/MurgaLua_0.7.5
--thanks igame3dbill !!!
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
table_data={} --main data model table = columns
transftable_data={} --downsized table (built from previous)
type_new_data={} --type of colums for new downsized table (transftable_data)
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
f_downsize=0 --flag to declare downsizing done / value=1

--interface
twindow=nil--window for original table
pwindow=nil --window for histogram chart
selbuttons={} --selbuttons[i]:color(2) means "selected field/column", :color(1) means "NOT selected field/column"
selcol={}
histo={} --histo buttons
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

function catval_sorting()
 --problem: sort table "cat_values" and keep related occurence values in table occ_values
 local i,j,k,l,m
 local new_sorted_catval={}
 local new_sorted_occval={}

--print("Function catval_sorting() in progress, #cat_values = " .. #cat_values)
 for i=1,#cat_values do
      new_sorted_catval = {}
      new_sorted_occval = {} --added 150824 : if not present, table "occurence values" and "possible values" are no more related
      new_sorted_catval=cat_values[i]
      for j=1,#new_sorted_catval do
           m = tonumber(new_sorted_catval[j])
           if m then
              new_sorted_catval[j] = m
           end
      end
      if #cat_values[i] > 0 then
         table.sort(new_sorted_catval)
      end
--print("table.concat(new_sorted_catval) = " .. table.concat(new_sorted_catval, "//"))
      --reassort sorted possible values (cat_values) and nb of occurences (occ_values)
      for k=1,#new_sorted_catval do
          for j=1,#cat_values[i] do
               if new_sorted_catval[k]  == cat_values[i][j] then
                  new_sorted_occval[k] = occ_values[i][j]
                  break
               end
          end
      end
 
--print("new_legend[" .. i .. "] = " .. new_legend[i] .. "#new_sorted_catval = " .. #new_sorted_catval)

      --apply changes
      cat_values[i] = new_sorted_catval
      occ_values[i] = new_sorted_occval
--reporting (debugging purpose)
--      for j=1,#cat_values[i] do
--print("cat_values[" .. i .. "][" .. j .. "]=" .. cat_values[i][j] .. " // occurences = " .. occ_values[i][j])
--      end
 end --for i
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
 local i,j,k,st,st1,st2
 local buffer="" --buffer for possible values (one column at a time)
 local co=#new_legend --colums of table (transftable_data)
 local li=#transftable_data

--print("#transftable_data = " .. #transftable_data .. " x " .. #transftable_data[1])
  
  for i=1,co do
--print(new_legend[i] .. " processing possible values in progress ....")
       buffer=" " --column buffer / possible values
	   occ_values[i]={}
       st1 = gsub(transftable_data[ 2 ][ i ],",",".")
       if type(st1) == "string" and type(tonumber(st1)) == "number" then
          st = "number"
       else 
          st="string"
       end
       --insert type of data in (type_new_data) table
       table.insert(type_new_data, st)
--print("type_new_data[" .. i .. "] = " .. type_new_data[i])
	   --type_new_data
       if type_new_data[i] == "number" then
	      cat_values[i]={} -- For numbers no possible values catalog, EXCEPT IF nb of possible values < threshold 
          for j=2,#transftable_data do -- j = lines
               st=" " .. transftable_data[j][i] .. " "
               st1 = tonumber(transftable_data[j][i])
               if find(buffer, st,1,true)  then
                  --trouver le Num occur
                   for k=1,#cat_values[i] do
                        if st1 == cat_values[i][k] then
                           if occ_values[i][k] then
                              occ_values[i][k] = occ_values[i][k]+1
                           else
                              occ_values[i][k] = 1
                           end
                           break
                        end
                   end

	           else
				  --buffer = buffer  .. transftable_data[j][i] .. " "
				  buffer = buffer  .. st
--print("Possible value for cat_values[" .. i .. "] = " .. st1)
				  table.insert(cat_values[i], st1)
                  table.insert(occ_values[i],1)
--print("#cat_values[" .. i .. "] = " .. cat_values[i][j-1])
               end
               if #cat_values[i] > 100 then
                  --aborting : too many values to be displayed
--print(new_legend[i] .. " too many possible numeric values => aborting catalog build")
                  while 1 do 
                      if #cat_values[i]>0 then
                         table.remove(cat_values[i])
                      else
                         break
                      end
                  end
                  break --new column
               end
          end
          --NONSENSE at 120824 : transftable_data[i] is a line, NOT a column <= needs working on this
          --median[ i ] = stats.series.median(transftable_data[i])
          --moyenne[i] = stats.series.mean(transftable_data[i])
          --variance[i] = stats.series.variance(transftable_data[i])
          --min[i],max[i] = stats.series.getExtremes(transftable_data[i])
           --init table
--print("#buffer = " .. #buffer .. "\n#cat_values[" .. i .. "] = "  .. #cat_values[i])
print(new_legend[i] .. " : Possible values = "  .. #cat_values[i])
       elseif type_new_data[i] == "string" then
	       cat_values[i]={} -- pour les chaines de car, catalogue des valeurs possibles
           --for j=1,#transftable_data do
           for j=2,#transftable_data do
               st1 = transftable_data[j][i]
               if find(buffer, st1,1,true)  then
                  --trouver le Num occur
                   for k=1,#cat_values[i] do
                        if st1 == cat_values[i][k] then
                           if occ_values[i][k] then
                              occ_values[i][k] = occ_values[i][k]+1
                           else
                              occ_values[i][k] = 1
                           end
                           break
                        end
                   end
               else
                  buffer = buffer .. " " .. st1
				  table.insert(cat_values[i],st1)
				  table.insert(occ_values[i],1)
				  
				  if #cat_values[i] > 100 then
                     --aborting : too many values to be displayed
print(new_legend[i] .. " too many possible string values => aborting catalog build")
                     while 1 do 
                         if #cat_values[i]>0 then
                            table.remove(cat_values[i])
                         else
                            break
                         end
                     end
                     break --new column
                  end
               end
          end
 print(new_legend[i] .. " : Possible values = "  .. #cat_values[i])
       else
           --rien
       end
       --occurences computing : keep commented code "for history"
--        if #cat_values > 0 then
--           if #cat_values[i] > 1 then
--              table.sort(cat_values[i]) -- pour avoir les valeurs possibles triées par valeur/par ordre alpha
-- print("Catalogue des valeurs = " .. table.concat(cat_values[i],"//") .. "\nNb de valeurs possibles = " .. #cat_values[i])
-- 		     for j=1,#cat_values[i] do
--                    _, occ_values[i][j] = st:gsub(cat_values[i][j],"")
--                     _, occ_values[i][j] = global_buffer:gsub(cat_values[i][j],"")
-- 		     end
--           end
--        end

k=i*100/co
progress_bar3:value(k)
progress_bar3:draw()
st = string.format('%.1f', k).."%"
progress_bar3:label(st)
Fl:check()

  end -- end for i

  --print("#occ_values = " .. #occ_values .. "\n#cat_values = " .. #cat_values)
--debugging block
--   for i=1,co do
-- print(new_legend[i])
--        for j=1,#cat_values[i] do
--             print("value=" .. cat_values[i][j] .. " // occurences = " .. occ_values[i][j])
--        end
--   end
--end debugging block
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
  
  t00 = os.time() --top chrono
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

  build_new_csv()
  print("build_new_csv() Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")
  
  rapport_base()
  print("rapport_base() Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")
  
  f_downsize=1
  catval_sorting() --sorting 2 tables possible values and nb of occurences for each possible value
  
  disp_sample3()
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
--print( i .. ". selval[" .. i .. "]=" .. selval[i])
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
 
function clear_t()
 local i,j
 --clearing widgets from previous display according to function disp_sample2()
 --mass destruction of buttons, progress_bars, text boxes ...
 t_quit=nil

 t_downs=nil
 
 progress_bar=nil
 info_button1=nil
 progress_bar2=nil
 info_button2=nil
 progress_bar3=nil
 info_button3=nil
 
  j = #selbuttons
  for i=j,1,-1 do
      selbuttons[i]=nil
  end
  selbuttons=nil
  keyword=nil
  clearbutton=nil  
  j = #selvalbutton
  for i=j,1,-1 do
       selvalbutton[i]=nil
  end
  selvalbutton=nil
  collectgarbage()
end --end function

function disp_sample2()
 --GUI selecting fields to be analysed
  local i,j,cx,cy,post
  local st,st1,st2,st3
  local cell0=nil
  --local histo=nil
  local co=#table_data
  local li=#table_data[1]
  --local table_stats={"NB VAL","MIN","MAX","MOY","MED","VAR","SIGMA"} --legendes abregees pour les stats
  --local table_stats_ib={"Nb de valeurs distinctes","Valeur minimale","Valeur maximale","Moyenne","Médiane","Variance","Ecart-type"} --legendes completes (infobulle) pour les stats
  --local table_stats_val={}
  local stage2=nil

  if twindow then
     twindow:hide()
     twindow:clear()
  end
  
  --window for initial table
  width_twindow = 1024
  height_twindow = 450
  twindow = fltk:Fl_Window(width_twindow, height_twindow, "CSV Table")
  --width_button = 120
  width_button = math.floor(width_twindow/(co+1)) --ajout d'une colonne "legende" (stats)
  height_button = 20
  --nb_car = width_button/10 --nb cars affichables dans la largeur du bouton
  nb_car = math.floor(width_button/11) --nb cars affichables dans la largeur du bouton

  t_quit = fltk:Fl_Button(10, height_twindow-30, width_button, 25, "Quit")
  t_quit:tooltip("Quit")
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

-- progress bar N3 : processing possible values for each fields
  progress_bar3 = fltk:Fl_Progress(10+(12*width_button), height_twindow-30, 5*width_button, 25, "0")
  progress_bar3:maximum(100)
  progress_bar3:minimum(1)
  progress_bar3:selection_color(fltk.FL_GREEN)
  info_button3 = fltk:Fl_Button(10+(12*width_button), height_twindow-55, 5*width_button, 25, "Processing possible values")
  
  --affichage legendes + 2 premières lignes de table_data
  --table legendes
  cx, cy=0,0
  cell0= fltk:Fl_Button(cx, cy, width_button, height_button, "LAB" )
  cell0:labelfont( fltk.FL_SCREEN )
  cell0:tooltip( "Labels of fields" )
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
  cell0= fltk:Fl_Button(cx, cy, width_button, height_button, "TYP" )
  cell0:labelfont( fltk.FL_SCREEN )
  cell0:tooltip( "Data type" )
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
      cell0:color(6) --pale blue
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
      selcol[j]=2
	  cy = (i+1)*height_button
      cx = j*width_button
--selection buttons
      table.insert(selbuttons, fltk:Fl_Button(cx, cy, width_button, height_button, "SEL" ) )
      selbuttons[#selbuttons]:labelfont( fltk.FL_SCREEN )
      selbuttons[#selbuttons]:color(2)
	  selbuttons[#selbuttons]:tooltip( "Selected col" )
      selbuttons[#selbuttons]:callback(select_field_fct)
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

function query_fct(ax1, ax2, context1, valse)
  local i,j,k
  local spe_table={}
  local keepcr=0 --keep this criteria-friendly cell
  local keepco=0 --keep this context-friendly cell
  local indexc=0
  local indexa1,indexa2=0,0
  local nb_criterias=0
  local nb_contexts=0
  local current_context
  local str,str2,unit
  
  if context1 ~= " " then
     --one chart per context=per possible value for a single column
     --find context1 index in new_legend{} and then number of contexts
     for i=1,#new_legend do
          if context1 == new_legend[i] then
              indexc=i --context1 is the label, indexc is the context's index in table "new_legend" = the number of the column to read in table "transftable_data"
              break
          end
     end
     nb_contexts = #cat_values[indexc]
  else
     --ONE ONLY agregate chart
     nb_contexts = 1
     indexc=1 --factice value
  end
  --find index of ax1 in new_legend
  for i=1,#new_legend do
       if ax1 == new_legend[i] then
          indexa1=i
print("Criteria nb 1 = " .. ax1 .. "// index new_legend = " .. indexa1)
          break
      end
  end
  nb_a1 = #cat_values[indexa1]
  --find index of ax2 in new_legend
   for i=1,#new_legend do
        if ax2 == new_legend[i] then
           indexa2=i
print("Criteria nb 2 = " .. ax2 .. "// index new_legend = " .. indexa2)
           break
        end
  end
  nb_a2 = #cat_values[indexa2]
  --find number of criteria in valselect
   for k=1,#valse do
         if valse[k] ~= " " then
            nb_criterias=nb_criterias+1
         end
   end
   
  --GO! the final result is table described by an histogram with y-axis lines=nb_a1 = #cat_values[indexa1]
  --and ONE column=some agregate cells of transftable_data
  for i=1,nb_contexts do --nb of successive charts to draw
       current_context = tostring(cat_values[indexc][i]) --convert to char
--print("current_context (" .. new_legend[indexc] .. ")= " .. current_context .. "// nb contexts=" .. nb_contexts .. "\nCriterias number = " .. nb_criterias)

--reinit table for re-using
      spe_table=nil
      spe_table={}
      for j=1,nb_a1 do
           table.insert(spe_table, 0)
      end
      
       for j=1,#transftable_data do
            --lines scan
            --test context
            keepco=0
          if nb_contexts>1 then
            if tostring(transftable_data[j][indexc]) == current_context then
               keepco=1
               --test criterias
               keepcr=0
               --for k=1,#new_legend do
               for k=1,#valse do
                    --apply valse criterias to colums
                    str=tostring(transftable_data[j][k])
                    str2=valse[k]
                    if str == str2 then
                       --keep line / this cell
                       keepcr=keepcr+1
--print("(Criterias condition) transftable_data[" .. j .. "][" .. k .. "]=" .. valse[k] .. "// UNIT=" .. transftable_data[j][indexa2] .. "// keepcr=" .. keepcr .. "// keepco=" .. keepco)
                    end
               end --end for k
               if keepcr == nb_criterias then
                  str=tostring(transftable_data[j][indexa1])
                  unit=tonumber(transftable_data[j][indexa2])
--print("Matching criterias for transftable_data[" .. j .. "][" .. indexa1 .. "] = " .. transftable_data[j][indexa1] .. " // boites=" .. unit)
                  for k=1,nb_a1 do
                       str2=tostring(cat_values[indexa1][k])
                       if str == str2 then
                          spe_table[k] = spe_table[k]+unit
                       end
                  end
               end
            end --end if keeopco==1
         else  --ONE context=hyper-agregate & specialized histogram
            keepcr=0
            for k=1,#valse do
                 --apply valse criterias to colums
                 str=tostring(transftable_data[j][k])
                 str2=valse[k]
                 if str == str2 then
                    --keep line / this cell
                    keepcr=keepcr+1
                 end
            end --end for k
            if keepcr == nb_criterias then
               str=tostring(transftable_data[j][indexa1])
               unit=tonumber(transftable_data[j][indexa2])
               for k=1,nb_a1 do
                    str2=tostring(cat_values[indexa1][k])
                    if str == str2 then
                       spe_table[k] = spe_table[k]+unit
                    end
               end
            end
         end --end if nb_contexts>1
       end --end for j (lines)
--validating function code results with CALC & SOMMEPROD()

--display special histo here
--debugging block
print("Lines= new_legend[" .. indexa1 .. "] = " .. new_legend[indexa1] .. "// Columns= new_legend[" .. indexa2 .. "] = " .. new_legend[indexa2])
   for j=1, nb_a1 do
print(j .. ". spe_table[" .. j .. "] = " .. spe_table[j])
   end
fltk:fl_alert("Pause!") 
--end debugging block

  end --end for i (context)
end  --end function

function disp_sample3()
 --GUI : selecting fields with criteria to be analysed
  local i,j,k,cx,cy
  local st,st1,st2,st3
  local cell1=nil
  local u_quit=nil
  local uwindow=nil
  local histo={}
  local valselect={}
  local co=#new_legend
  local axis1,axis2,context1
  local spe_chart=nil
  local valse={}

  if f_downsize ~= 1 then
     return
  end
  clear_t()
  quit_t()
  twindow=nil
  legend_data=nil
  table_data=nil
  collectgarbage()
  
  --fenetre graphique pour la restitution du tableau CSV
  width_twindow = 1024
  height_twindow = 450
  width_button = math.floor(width_twindow/(co+1)) --ajout d'une colonne "legende" (stats)
  height_button = 20
  nb_car = math.floor(width_button/11) --nb cars affichables dans la largeur du bouton
  
  --window for dowsized table
  width_twindow = 1024
  height_twindow = 450
  uwindow = fltk:Fl_Window(width_twindow, height_twindow, "Downsized CSV")   
  width_button = math.floor(width_twindow/(co+1)) --ajout d'une colonne "legende" (stats)
  u_quit = fltk:Fl_Button(10, height_twindow-30, width_button, 25, "Quit")
  u_quit:tooltip("Quit this application")
  --u_quit:callback(quit_u)
  u_quit:callback(function (quit_u)
     uwindow:hide()
     uwindow:clear()
     uwindow = nil
  end)
--print("Fct disp_sample3(), var f_downsize = " .. f_downsize .. "\ncolumns = " .. co .. " // lines #transftable_data = " .. #transftable_data)

  --table legendes
  cx, cy=0,0
  cell1= fltk:Fl_Button(cx, cy, width_button, height_button, "LABELS" )
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:tooltip( "Field's labels" )
  for j=1,co do
      selval[j]={"","","","",""}
      cy = 0
      cx = j*width_button
      st = new_legend[ j ]
      if type(st) == "string" then
         st = sub(st, 1, nb_car)
      end
      cell1= fltk:Fl_Button(cx, cy, width_button, height_button, st )
      cell1:labelfont( fltk.FL_SCREEN )
      cell1:tooltip( new_legend[ j ] )
--print("new_legend[ " .. j .. " ] = " .. new_legend[ j ])
  end
  --ligne type des donnees
  cx, cy=0,height_button
  cell1= fltk:Fl_Button(cx, cy, width_button, height_button, "TYPE" )
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:tooltip( "Data type" )
  for j=1,co do
      cy = height_button
      cx = j*width_button
      st = type_new_data[j]
      if st == "number" then
         st2 = "nb"
      else 
         st2 = "str"
      end
      cell1= fltk:Fl_Button(cx, cy, width_button, height_button, st2 )
      cell1:labelfont( fltk.FL_SCREEN )
      cell1:color(6) --pale blue
      cell1:tooltip( st )
  end
  
  --left-most button "values" (no callback, just displaying purpose)
  cx,cy=0, (2*height_button)
  cell1= fltk:Fl_Button(cx, cy, width_button, (5*height_button), "5\nfirst lines\nValues" )
  cell1:labelfont( fltk.FL_SCREEN )
--table transftable_data : echantillon/sample
  cx, cy=0,0
  for i=1,5 do -- line 1 = legend, data beginning at line 2
      for j=1,co do
	  cy = (i+1)*height_button
      cx = j*width_button
	  st = transftable_data[ i+1 ][j]
      st2 = sub((st .. ""), 1, nb_car)
      cell1=fltk:Fl_Button(cx, cy, width_button, height_button, st2 )
      cell1:labelfont( fltk.FL_SCREEN )
      cell1:color(20)
	  cell1:tooltip( transftable_data[ i+1 ][j] )
      end 
  end
  
--histogram buttons
i=6
cy = (i+1)*height_button
 for j=1,co do
      cx = j*width_button
      st = "Hist" .. j
      table.insert(histo, fltk:Fl_Button(cx, cy, width_button, height_button, st ) )
	  histo[#histo]:labelfont( fltk.FL_SCREEN )
      histo[#histo]:color(12)
      st="click here to display Histogram of possible values for column \"" .. new_legend[j] .. "\""
	  histo[#histo]:tooltip( st )
--print("disp_sample3(), putting histo button number " .. #histo)
	  if #cat_values[#histo] == 0 then
	     histo[#histo]:deactivate()
	  end
      histo[#histo]:callback(function (histo_fct)
        local h=0
        local i
        for i=1,#histo do
             if Fl.event_inside(histo[i]) == 1 then
                h=i
                disp_histo(h)
                break
             end
        end
        end) --end local function

      --text legend for line "nb of possible values"
      if j ==1 then
         -- this text legend button should NOT be multi-defined in this loop
         cx=0
         st="Nb values"
         st2="Nb of possible values for this column"
         cell1=fltk:Fl_Button(cx, cy+height_button, width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
      end
      cx = j*width_button
      st = #cat_values[j] .. ""
      st2 = #cat_values[j] .. " possible values"
      cell1=fltk:Fl_Button(cx, cy+height_button, width_button, height_button, st )
      cell1:labelfont( fltk.FL_SCREEN )
	  cell1:tooltip( st2 )
	  
      --WHERE GUI version 2
      --now, (conditionnal) displaying a "menu button" handling possible values
      --legend text for these selection tools
      if j ==1 then
         st="Where"
         st2="Set a possible value (or none) to each column as a restrictive condition to get one or several specialized chart"
         cell1=fltk:Fl_Button((3*width_button), (11*height_button), width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
      end

	  if #cat_values[j] > 0 then
	     st = new_legend[j] .. " ="
         cell1=fltk:Fl_Button((3*width_button), ((11+j)*height_button), width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
	     --st = new_legend[j]
	     table.insert(valselect, fltk:Fl_Choice((4*width_button), ((11+j)*height_button), width_button, height_button) )
         valselect[#valselect]:labelfont( fltk.FL_SCREEN )
	     --and now adding menu items
	     valselect[#valselect]:add(" ") -- 1st line is "a space alone" => no selection
	     for k=1,#cat_values[j] do
	           if cat_values[j][k] then
	              valselect[#valselect]:add( cat_values[j][k] )
               end
	     end
      else
         st = new_legend[j] .. " ="
         cell1=fltk:Fl_Button((3*width_button), ((11+j)*height_button), width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
         table.insert(valselect, fltk:Fl_Choice((4*width_button), ((11+j)*height_button), width_button, height_button) )
         valselect[#valselect]:labelfont( fltk.FL_SCREEN )
         valselect[#valselect]:add(" ")
	     valselect[#valselect]:deactivate()
      end	

  end --end for j

  --cross-table visual query (chart)
  --left-most button "values" (no callback, just displaying purpose)
  cx=0
  cy = cy+(4*height_button)
  cell1= fltk:Fl_Button(cx, cy, width_button, height_button, "New chart" )
  cell1:labelfont( fltk.FL_SCREEN )
  --context1 : (for each) XOR (for all)
  cell1= fltk:Fl_Button(cx+(2*width_button), cy, width_button, height_button, "For each/all" )
  cell1:labelfont( fltk.FL_SCREEN )
  st = "For each = one histogram charts for each value of selected column // For all = one only aggregated histogram charts for all values (no selected column)"
  cell1:tooltip( st )
  --table.insert(context1, fltk:Fl_Choice(cx+(2*width_button), (cy+height_button), width_button, height_button) )
  context1 = fltk:Fl_Choice(cx+(2*width_button), (cy+height_button), width_button, height_button)
  st = "Histogram chart for each possible value of this column (agregated for all values if no selection). Number of possible values = nb of charts"
  context1:tooltip( st )
  context1:add( " " ) --adding empty string = "no selection option"
  for k=1,#new_legend do
       if #cat_values[k] ~= 0 then
          context1:add( new_legend[k] )
       end
  end


  cell1= fltk:Fl_Button(cx+width_button, cy+height_button, width_button, height_button)
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:box(fltk.FL_DOWN_BOX)
  --set 1st dim of table
  axis1 = fltk:Fl_Choice(cx, (cy+height_button), width_button, height_button)
  st = "Set a field for the Y-axis of table/chart"
  axis1:tooltip( st )
  for k=1,#new_legend do
        axis1:add( new_legend[k] )
  end
  --set 2nd dim of table
  cx=width_button
  axis2 = fltk:Fl_Choice(cx, cy, width_button, height_button)
  st = "Set a field for the X-axis of table/chart. PAY ATTENTION ! This field Has to be SUMABLE and will be handle as a Measure's Unit. If not, displayed values wouldn't make no sense !"
  axis2:tooltip( st )
  for k=1,#new_legend do
        axis2:add( new_legend[k] )
  end
  --set main callback for specialized charts
  cx=0
  st = "Launch query and get chart(s)"
  spe_chart= fltk:Fl_Button(cx, cy+(2*height_button), width_button, height_button, "Launch query" )
  spe_chart:labelfont( fltk.FL_SCREEN )
  spe_chart:tooltip( st )
  spe_chart:color(12)
  spe_chart:callback(function (query_launch)
        local i, msg
        local ax1, ax2, c1=axis1:text(), axis2:text(), context1:text()
--debugging block
        print("axis1:text() = " .. axis1:text() .. "\naxis2:text() = " .. axis2:text() )
        if context1:text() then
           print("context1:text()=" .. context1:text())
        else
           print("context1:text()= none")
           c1=" "
        end
        for i=1,#new_legend do
             if valselect[i]:text() then
                 print("valselect[" .. i .. "]:text()=" .. valselect[i]:text())
             end
        end
--end debugging block
        --1_consistency_checking
        --rule one
        if ax1 ~= 0 and ax2 ~= 0 then
           --ok
        else
            --problemo!
            msg="Both Axis variables must be set to non-nil !!!"
print(msg)
fltk:fl_alert(msg)
            return
        end
        --rule two
        if ax1 ~= ax2 and ax2 ~= c1 and ax1 ~= c1 then
           --ok           
        else
            --problemo!
            msg="Axis and Context variables have to be distinct !!!"
print(msg)
fltk:fl_alert(msg)
            return
        end
        --rule three
        --consistency ax1, ax2, c1 and valselect[#valselect] ???

        --2_GUI fonction
        --valse{} is related to table of Fl_Choice
        for i=1,#new_legend do
             if valselect[i]:text() then
                table.insert(valse, valselect[i]:text() )
             else
                table.insert(valse, " ")
             end   
        end
        query_fct(ax1, ax2, c1, valse)
        end) --end local function

  Fl:check()
  uwindow:show()
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
     quit_callbackapp() --close & clear pwindow
     twindow:hide()
     twindow:clear()
     twindow = nil
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
 local maxv=0
 local minv=9999999
 local idxmax,idxmin
 
 --how to save image contents of the chart window (needs to be tested) ?
-- fl_begin_offscreen(offs)
-- data = fl_read_image(uchar *p, int X, int Y, int W, int H, int alpha = 0)
-- fl_end_offscreen()
-- png_write(data, ...) => this function does not exist in all version


  type_graphics=4
  --GUI for histogram chart
  if pwindow then
     pwindow:hide()
     pwindow:clear()
  end
  st = "Histo " .. new_legend[ h ]
  pwindow = fltk:Fl_Window(width_pwindow, height_pwindow, st)
  
  --centrage du bouton en bas de la fenetre pwindow
  width_button = 100
  quit = fltk:Fl_Button(dec_button+10, height_pwindow-30, width_button, 25, "Quit")
  quit:tooltip("Quit")
  quit:callback(quit_callbackapp)
  --chart
  pie = fltk:Fl_Chart(0, 0, 5, 5, nil)
  pie:position(decx_chart, decy_chart+20)
  pie:size(width_chart, height_chart)
  pie:label(new_legend[ h ])
  --pie:type( type_chart[type_graphics] )
  pie:type( fltk.FL_HORBAR_CHART )
  --pie:box(1)
  pie:box(fltk.FL_SHADOW_BOX)
  pie:labelcolor(0)
  pie:autosize(1)
  
  for i=1,#cat_values[h] do
      if occ_values[h][i] > maxv then
         maxv = occ_values[h][i]
         idxmax=i
      end
      if occ_values[h][i] < minv then
         minv = occ_values[h][i]
         idxmin=i
      end
      if #cat_values[h]>=15 then --managing display according to nb of cars
         --j = math.floor(#cat_values[h]/15)
         j = math.floor(#cat_values[h]/10)
         if (i % j) == 0 then
            st = cat_values[h][i]  .. "-" .. occ_values[h][i]
         else
            st = ""
         end
         color=4
      else
         st = cat_values[h][i]  .. "-" .. occ_values[h][i]
         color=4
      end
      pie:add(occ_values[h][i], st, color)
  end
  st = cat_values[h][idxmin]  .. "-" .. occ_values[h][idxmin]
  pie:replace(idxmin, occ_values[h][idxmin], st, 2)
  st = cat_values[h][idxmax]  .. "-" .. occ_values[h][idxmax]
  pie:replace(idxmax, occ_values[h][idxmax], st, 1)
  
  --change chart type
  --code to retrive/adjest from murgaLua docs & examples
  --/home/terras/murgaLua/examples/widgets_demo/script/chart.lua

  --save chart image to file
  --code to retrieve from murgaLua docs & examples
  --/home/terras/murgaLua/examples/new/readImageTest.lua

  Fl:check()
  pwindow:show()
end --end function

 t00=0
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

 print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")

  --print("Free RAM by collectgarbage(\"count\") = " .. collectgarbage("count"))
  print("RAM used AFTER opData by  gcinfo() = " .. gcinfo())
                                                 
 --print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")

Fl:check()
Fl:run()
--console correlations stats after "quitting" GUI
--disp_corr_txt()

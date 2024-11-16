#!/bin/murgaLua

--this murgaLua script has been tested with version 0750 https://github.com/igame3dbill/MurgaLua_0.7.5
--thanks to igame3dbill for this upgrade!!!
--fork from 21/07/2024 statsoncsv_next.lua => statsoncsv_next2.lua
--allows via a GUI the fields filtering after pre-loading  of huge CSV (first xxx lines)
--downsizing of original file (>450Mb for year 2023)
--and giving some statistics and charts
--original file to process OPEN_MEDIC_2023.CSV  (from SNDS)
--url = https://open-data-assurance-maladie.ameli.fr/medicaments/download_file2.php?file=Open_MEDIC_Base_Complete/OPEN_MEDIC_2023.zip


i=0

--stats = require "statistics"

find = string.find
--gfind = string.gfind
sub = string.sub
gsub=string.gsub

osName="OS=" .. murgaLua.getHostOsName()

read_data = "" --tampon de lecture
write_data = "" --tampon ecriture CSV département
size_eol = 0 -- varie selon Unix (MacOs) ou Windows

annee=0 --year of open_medic data
legend_data={} --text legends from original CSV
new_legend={} --new text legends from transformed-downsized-filtered CSV
clib_new_legend={} --complete text from previous table without acronyms
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
width_pwindow = 500
height_pwindow = 500
twindow=nil--window for original table

pwindow=object --window for histogram chart, global var if system is linux, local var if system is windows
pie=object --charts : rather global object if pwindow is global
--spe_table={} --values of bar charts (local)

selbuttons={} --selbuttons[i]:color(2) means "selected field/column", :color(1) means "NOT selected field/column"
unitbuttons={} --if selected, related field is handled as the UNIQUE unit of measurement
selcol={} --related to selbuttons table
selunit={} --related to unitbuttons table
label_unit="" --string var = label of the field set as unit measurement
index_unit=0--index of string var "label_unit" in downsized table "new_legend"
selcross={} --lists items of new_legend indexes table and sets to 1 if field is selected for a cross-analyse with others or 0 if not
keyword=nil -- GUI input objects for catching query values
clearbutton=nil
selvalbutton={}
selval={"","","","",""} --values related to cols of table_data, used to query on original table and make a downsizing
selval_select={}
title="" --title of pwindow, special histogram-chart
x,y,w,h=0,0,0,0

--html export
html_buffer="<!DOCTYPE html><html lang='en'><head><title>OPENMEDIC stats</title><style>table, th, td {border: 1px solid black;   border-collapse: collapse; } </style></head><body>\n<TABLE><TR><TH>BAR CHART</TH><TH>VALUES</TH><TH>PIE CHART</TH></TR>"

--specialist dictionnary
lib_spe_ps ={'MEDECINE GENERALE LIBERALE',
'ANESTHESIOLOGIE - REANIMATION LIBERALE',
'PATHOLOGIE CARDIO-VASCULAIRE LIBERALE',
'CHIRURGIE LIBERALE',
'DERMATOLOGIE ET VENEROLOGIE LIBERALE',
'RADIOLOGIE LIBERALE',
'GYNECOLOGIE OBSTETRIQUE LIBERALE',
'GASTRO-ENTEROLOGIE ET HEPATOLOGIE LIBERALE',
'MEDECINE INTERNE LIBERALE',
'OTO RHINO-LARYNGOLOGIE LIBERALE',
'PEDIATRIE LIBERALE',
'PNEUMOLOGIE LIBERALE',
'RHUMATOLOGIE LIBERALE',
'OPHTALMOLOGIE LIBERALE',
'PSYCHIATRIE LIBERALE',
'STOMATOLOGIE LIBERALE',
'CHIRURGIE DENTAIRE',
'MEDECINE PHYSIQUE ET DE READAPTATION LIBERALE',
'NEUROLOGIE LIBERALE',
'NEPHROLOGIE LIBERALE',
'CHIRURGIE DENTAIRE (SPECIALISTE O.D.F.)',
'ANATOMIE-CYTOLOGIE-PATHOLOGIQUE LIBERALE',
'DIRECTEUR LABORATOIRE MEDECIN LIBERAL',
'ENDOCRINOLOGIE ET METABOLISMES LIBERAL',
'PRESCRIPTEURS SALARIES',
'PRESCRIPTEURS DE VILLE AUTRES QUE MEDECINS (Dentistes, Auxiliaires medicaux, Laboratoires, Sages-Femmes)',
'VALEUR INCONNUE'}
lib_small_SPE={'MGLIB',
'ANEST',
'CARDIO',
'CHIR',
'DERM',
'RADIOL',
'GYNOB',
'GASTR',
'MEDINT',
'ORL',
'PED',
'PNEUM',
'RHUM',
'OPH',
'PSY',
'STO',
'CDENT',
'MPR',
'NEUR',
'NEPHR',
'CDENTO',
'ANAP',
'DIRLAB',
'ENDOC',
'PSALARIES',
'PVILAU',
'INC?'}
indx_spe = {1,2,3,4,5,6,7,8,9,11,12,13,14,15,17,18,19,31,32,35,36,37,38,42,90,98,99}
indx_spe2={}
for k,v in pairs(indx_spe) do
   indx_spe2[v]=k
end
--for i=1,#indx_spe do
--     print(indx_spe[i] .. " = " .. lib_small_SPE[i])
--end

--region dictionnary
lib_region ={--'Inconnu1',
                'Regions et Departements d\'outre-mer',
                'Ile-de-France',
                'Centre-Val de Loire',
                'Bourgogne-Franche-Comte',
                'Normandie',
                'Nord-Pas-de-Calais-Picardie',
                'Alsace-Champagne-Ardenne-Lorraine',
                'Pays de la Loire',
                'Bretagne',
                'Aquitaine-Limousin-Poitou-Charentes',
                'Languedoc-Roussillon-Midi-Pyrenees',
                'Auvergne-Rhone-Alpes',
                'Provence-Alpes-Cote d\'Azur et Corse',
                'Inconnu'}
lib_small_region ={--'INC1?',
                'DOMTOM',
                'IDF',
                'CVLOIR',
                'BRGNFC',
                'NRMND',
                'NORPDC',
                'ALSLRC',
                'PLOIRE',
                'BRET',
                'NVLAQ',
                'OCCIT',
                'ARA',
                'PACAC',
                'INC'}
--indx_region ={0,5,11,24,27,28,32,44,52,53,75,76,84,93,99}
indx_region ={5,11,24,27,28,32,44,52,53,75,76,84,93,99}
indx_region2={}
for k,v in pairs(indx_region) do
   indx_region2[v]=k
end
--for i=1,#indx_region do
--     print(indx_region[i] .. " = " .. lib_small_region[i])
--end

--sex dictionnary
lib_sex ={'MASCULIN','FEMININ','VALEUR INCONNUE'}
indx_sex = {1,2,9}
indx_sex2={}
for k,v in pairs(indx_sex) do
   indx_sex2[v]=k
end

--age dictionnary
lib_age ={'0-19','20-59','+60','INCONNU'}
indx_age = {0,20,60,99}
indx_age2={}
for k,v in pairs(indx_age) do
   indx_age2[v]=k
end

--create & init summing tables
--summing tables
boites_REG={}
for i=1,#indx_region do
     table.insert(boites_REG,0)
end
boites_SEXE={}
for i=1,#indx_sex do
     table.insert(boites_SEXE,0)
end
boites_AGE={}
for i=1,#indx_age do
     table.insert(boites_AGE,0)
end
boites_SPE={}
for i=1,#indx_spe do
     table.insert(boites_SPE,0)
end

--tampons d'écriture pour les fichiers texte et csv de sauvegarde
--csv_buffer = "" -- local
separator = ";"

--Charts
type_chart = { fltk.FL_BAR_CHART, fltk.FL_LINE_CHART, fltk.FL_FILLED_CHART, fltk.FL_SPIKE_CHART, fltk.FL_PIE_CHART, fltk.FL_SPECIALPIE_CHART, fltk.FL_HORBAR_CHART}
label_chart = { "FL_HORBAR_CHART", "FL_LINE_CHART", "FL_FILLED_CHART", "FL_SPIKE_CHART", "FL_PIE_CHART", "FL_SPECIALPIE_CHART", "FL_BAR_CHART" }
type_graphics = 4
--
filename=""

--charts images saving
fltk.fl_register_images() --needed for saving chart image with fct read_Image()
image2=nil
imageString=nil

osName="OS=" .. murgaLua.getHostOsName()
print(osName)
t00=0
t11=0

function palmares_sorting(spe_table)
--sorting spe_table[i] by value
 local spe_table_temp1={}
 --local spe_table_temp1=spe_table --WRONG method, sorting spe_table_temp1 will sort spe_table, too (NO WAY!)
 local idx={} -- local index of spe_table : 1 means unprocessed, other values=already processed
 local spe_table_palm={} -- values of table will be index of spe_table, sorted by spe_table value
 local i,j
 
 for i=1,#spe_table do
       table.insert(spe_table_temp1, spe_table[i])
       table.insert(idx,1)
 end
 --print("Before = " .. table.concat(spe_table,"//"))
 table.sort(spe_table_temp1) --ONLY table spe_table_temp1 is now sorted by (increasing) values, table spe_table_temp1 is NOT sorted
 --print("After sorting spe_table_temp1 = " .. table.concat(spe_table_temp1,"//")) --ONLY table spe_table_temp1 is now sorted by (increasing) values, table spe_table_temp1 is NOT sorted
 --print("spe_table = " .. table.concat(spe_table,"//"))

 for i=#spe_table_temp1,1,-1 do
      for j=1,#spe_table do
           if idx[j] == 1 then
              if spe_table[j] == spe_table_temp1[i] then
                 table.insert(spe_table_palm, j) --similar to spe_table_palm[i] = j
                 idx[j]=-1
              end
           end
      end
 end
 return spe_table_palm
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
  local i,st,st1,st2

  for i=1,#old_table_data do
       if selcol[i] == 2 then
          if find(old_table_data[i],".",1,true) and find(old_table_data[i],",",1,true) then
              --1st stage replace thousand's separator "." with nothing ""
             st = gsub(old_table_data[i],"[.]","")
             --2nd stage replace decimal's separator "," with "."
             st1 = gsub(st,"[,]",".")
             --third stage convert to number (if number)
             if tonumber(st1) then
                st2 = tonumber(st1)
             else
                st2 = st1
             end
--print(". and , in same field : " .. old_table_data[i] .. ", 1st transform=" .. st .. ", 2nd transform=" .. st1 .. ", sent by transform() = " .. st2)
             --table.insert(transformed_table_data, old_table_data[i])
             table.insert(transformed_table_data, st2)
          elseif find(old_table_data[i],",",1,true) then
             --1st stage replace comma "," with point "."
             st = gsub(old_table_data[i],"[,]",".")
             if tonumber(st) then
                st2 = tonumber(st)
             else
                st2 = st
             end
             table.insert(transformed_table_data, st2)
          else
             --no conversion needed
             table.insert(transformed_table_data, old_table_data[i])
          end
       end
  end
  return( transformed_table_data )
end  --end function

function build_new_base_CB() 
 --CB stands for Circular Buffer
  local i,j,k,l
  local i1,i2,i3,i4
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
                         --computing here : tables for boites/BEN_REG, boites/SEX, boites/AGE, boites/SPE
                         i1 = indx_age2[ new_table_data[15] ] --AGE
                         i2 = indx_sex2[ new_table_data[16] ] --SEXE
                         i3 = indx_region2[ new_table_data[17] ] --REGION
                         i4 = indx_spe2[ new_table_data[18] ] --SPE
                         k1 = new_table_data[19] --BOITES
                         if k1 == nil then
                            k1=0
                         else
                            boites_AGE[i1] = boites_AGE[i1]+k1
                            boites_SEXE[i2] = boites_SEXE[i2]+k1
                            boites_REG[i3] = boites_REG[i3]+k1
                            boites_SPE[i4] = boites_SPE[i4]+k1
                         end
                         table.insert(transftable_data, new_table_data ) --OPTIMIZATION
                         --csv_buffer = csv_buffer .. table.concat(new_table_data,separator) .. "\n" -- -------------------------->optimization 040824
                      end
                   end
                      pos = j+1
                      --nb_bytes=nb_bytes+#read_buffer_a --> bad place
                else
st = "line_data is NULL !"
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
  local i, msg
  
  if label_unit == "" then
     msg = "No field is set as unique UNIT of measurement (REQUIRED) : no other processing can be done\nThis choice can be done with the buttons under those which de/select fields for downsizing process."
     print(msg)
     fltk:fl_alert(msg)
     return
  end
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
  --defining complete libelle of legend instead of (too) small libelles
  for i=1,#new_legend do
       if new_legend[i] == "ATC5" then
          table.insert(clib_new_legend, "Code ATC5 medicament")
       elseif new_legend[i] == "l_cip13" then
          table.insert(clib_new_legend, "Libelle medicament")
       elseif new_legend[i] == "age" then
          table.insert(clib_new_legend, "tranche age patient")
       elseif new_legend[i] == "sexe" then
          table.insert(clib_new_legend, "sexe patient")
       elseif new_legend[i] == "BEN_REG" then
          table.insert(clib_new_legend, "Region du Beneficiaire")
       elseif new_legend[i] == "PSP_SPE" then
          table.insert(clib_new_legend, "Specialite prescripteur")
       elseif new_legend[i] == "BOITES" then
          table.insert(clib_new_legend, "Unite=boites")
       end
       print(i .. ". small legend=" .. new_legend[i] .. " // " .. clib_new_legend[i])
  end

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

function select_unit_field_fct()
  --choose a UNIQUE fied as unit of measurement
 local i,j
  for i=1,#unitbuttons do
       if Fl.event_inside(unitbuttons[i]) == 1 then
          if unitbuttons[i]:label() == "" then
             --empy label means previously deselected
             label_unit = legend_data[i]
             index_unit = i
print("label_unit set to " .. label_unit)
             unitbuttons[i]:label( "UNIT" )
             unitbuttons[i]:tooltip( "This field is set as UNIQUE unit of measurement" )
             unitbuttons[i]:show()
             selunit[i] = 1
--print("selunit[" .. i .. "] = " .. selunit[i])
             --reseting other unit buttons
             for j=1,#unitbuttons do
                  if j ~= i then
                     selunit[j] = 0
                     unitbuttons[j]:label( "" )
                     unitbuttons[j]:tooltip( "Click here to set this fied as UNIQUE unit of measurement" )
                     unitbuttons[j]:show()
                  end
             end
          else
             --reseting ALL unit buttons
             for j=1,#unitbuttons do
                  selunit[j] = 0
                  unitbuttons[j]:label( "" )
                  unitbuttons[j]:tooltip( "Click here to set this fied as UNIQUE unit of measurement" )
                  unitbuttons[j]:show()
             end
             label_unit = ""
             index_unit = 0
print("label_unit set to " .. label_unit)
--print("selunit[" .. i .. "] = " .. selunit[i])
          end
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

function preselection()
 local i,j
 local button2deselect={1,2,3,4,5,6,7,8,10,11,13,14,20,21}
 local button2select={1,2,3,4,5,6,7,8,10,11,13,14,20,21}
 
-- select the two keywords N05 & N06 (or only one !)
  --First clear previous values (if any)
  clear_val_fct()
  --st="N05AX"
  st="N05A"
  selvalbutton[1]:label(st)
  selval[1]=st
  --st="N06"
  --selvalbutton[2]:label(st)
  --selval[2]=st
  
--deselect fields : list of buttons to deselect
  for i=1,#button2deselect do
       j = button2deselect[i]
       selbuttons[j]:color(1)
       selcol[j] = 1
       --1 means red means de-selected
       selbuttons[j]:label( "DSEL" )
       selbuttons[j]:tooltip( "De-selected field" )
       selbuttons[j]:show()
  end
--select expected fields
  for i=1,#button2select do
       j = button2select[i]
       selbuttons[j]:color(2) 
       selcol[j] = 2
       --2 means green means selected
       selbuttons[j]:label( "SEL" )
       selbuttons[j]:tooltip( "Selected field" )
       selbuttons[j]:show()
       selbuttons[j]:color(1)
       selcol[j] = 1
       selbuttons[j]:show()
  end
  --select field set as "unit of measurement"
  for i=1,#selunit do
       selunit[i]=0
       unitbuttons[i]:label( "" )
       unitbuttons[i]:tooltip( "" )
       unitbuttons[i]:show()
  end
  selunit[19] = 1 --DEFAULT UNIT FIELD in this preselection is "BOITES" field
  unitbuttons[19]:label( "UNIT" )
  unitbuttons[19]:tooltip( "This field is set as UNIQUE unit of measurement" )
  unitbuttons[19]:show()
  label_unit = legend_data[19]
print("label_unit set to " .. label_unit) 
  downsize()
end --end function

function countdown()
--create/open a modal window for "seconds" (can be either a function-local-var, or a global var, countdown being a widget's callback)
local cmwindow = fltk:Fl_Window(width_pwindow,0, 128, 128, "Countdown Window")
local cmbox = fltk:Fl_Box(0, 0, 128, 128, "3")
local t000,t001
local oldst,st="-1",""
local start_countdown=1
 cmbox:labelsize(64)
 cmwindow:show()
 cmwindow:set_modal()
 Fl:check()
 t000=os.time()
 while 1 do
     t001=start_countdown-os.difftime(os.time(), t000)
     st=string.format('%1d', t001)
     if st ~= oldst then
        cmbox:label(st)
        cmbox:redraw()
        cmwindow:show()
        Fl:check()
        oldst = st
     end
     if t001<0 then
        break
     end
 end
 cmwindow:set_non_modal()
 cmwindow:hide()
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
  t_downs:tooltip("Downsize original data with selected items and save it")
  t_downs:callback(downsize)
  
  -- progress bar N1 : build table
  progress_bar = fltk:Fl_Progress(10+(2*width_button), height_twindow-30, 5*width_button, 25, "0")
  progress_bar:maximum(100)
  progress_bar:minimum(1)
  progress_bar:selection_color(fltk.FL_GREEN)
  info_button1 = fltk:Fl_Box(10+(2*width_button), height_twindow-55, 5*width_button, 25, "Building new downsized table")
  info_button1:box(fltk.FL_BORDER_BOX)
  
-- progress bar N2 : build and save csv
  progress_bar2 = fltk:Fl_Progress(10+(7*width_button), height_twindow-30, 5*width_button, 25, "0")
  progress_bar2:maximum(100)
  progress_bar2:minimum(1)
  progress_bar2:selection_color(fltk.FL_GREEN)
  info_button2 = fltk:Fl_Box(10+(7*width_button), height_twindow-55, 5*width_button, 25, "Saving new downsized CSV")
  info_button2:box(fltk.FL_BORDER_BOX)
  
-- progress bar N3 : processing possible values for each fields
  progress_bar3 = fltk:Fl_Progress(10+(12*width_button), height_twindow-30, 5*width_button, 25, "0")
  progress_bar3:maximum(100)
  progress_bar3:minimum(1)
  progress_bar3:selection_color(fltk.FL_GREEN)
  info_button3 = fltk:Fl_Box(10+(12*width_button), height_twindow-55, 5*width_button, 25, "Processing possible values")
  info_button3:box(fltk.FL_BORDER_BOX)
  
  --affichage legendes + 2 premières lignes de table_data
  --table legendes
  cx, cy=0,0
  cell0= fltk:Fl_Box(cx, cy, width_button, height_button, "LAB" )
  cell0:labelfont( fltk.FL_SCREEN )
  cell0:tooltip( "Labels of fields" )
  cell0:box(fltk.FL_BORDER_BOX)
  for j=1,co do
      selval[j]={"","","","",""}
      cy = 0
      cx = j*width_button
      st = legend_data[ j ]
      if type(st) == "string" then
         st = sub(st, 1, nb_car)
      end
      cell0= fltk:Fl_Box(cx, cy, width_button, height_button, st )
      cell0:labelfont( fltk.FL_SCREEN )
      cell0:tooltip( legend_data[ j ] )
      cell0:box(fltk.FL_BORDER_BOX)
  end
  --ligne type des donnees
  cx, cy=0,height_button
  cell0= fltk:Fl_Box(cx, cy, width_button, height_button, "TYP" )
  cell0:labelfont( fltk.FL_SCREEN )
  cell0:tooltip( "Data type" )
  cell0:box(fltk.FL_BORDER_BOX)
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
      cell0= fltk:Fl_Box(cx, cy, width_button, height_button, st2 )
      cell0:labelfont( fltk.FL_SCREEN )
      cell0:color(43) --some grey
      cell0:tooltip( st )
      cell0:box(fltk.FL_BORDER_BOX)
  end

--table table_data : echantillon/sample
  cx, cy=0,0
  for i=1,5 do
      for j=1,co do
	  cy = (i+1)*height_button
      cx = j*width_button
	  st = table_data[ j ][i]
      st2 = sub((st .. ""), 1, nb_car)
      cell0=fltk:Fl_Box(cx, cy, width_button, height_button, st2 )
      cell0:labelfont( fltk.FL_SCREEN )
      cell0:color(20)
	  cell0:tooltip( table_data[ j ][i] )
	  cell0:box(fltk.FL_BORDER_BOX)
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
      --adding UNIQUE unit of measurement  selector
      table.insert(unitbuttons, fltk:Fl_Button(cx, cy+height_button, width_button, height_button, "" ) )
      unitbuttons[#unitbuttons]:labelfont( fltk.FL_SCREEN )
      unitbuttons[#unitbuttons]:labelcolor( 1 ) --default color for string label=RED
	  unitbuttons[#unitbuttons]:tooltip( "Click here to set this fied as UNIQUE unit of measurement" )
      unitbuttons[#unitbuttons]:callback(select_unit_field_fct)
  end  

--area for catching query values
  keyword = fltk:Fl_Input(width_button, (cy+(2*height_button)), (2*width_button), height_button)
  keyword:value("")
  st="type here keywords (one at a time, one per case, max keywords=5). Presence of -at least- a keyword ensures that line will be selected in downsized file"
  keyword:tooltip(st)
  keyword:callback(select_val_fct)
--clear button
  clearbutton = fltk:Fl_Button(width_button, (cy+(3*height_button)), (2*width_button), height_button, "CLEAR ALL" )
  st="Remove all recorded keywords (in you made a mistake in one, that's the thing to do!)"
  clearbutton:tooltip(st)
  clearbutton:callback(clear_val_fct)
   cx, cy=0,0
  i=6
  for i=1,5 do
  	  cy = (8+i)*height_button
      cx = 5*width_button
       table.insert(selvalbutton, fltk:Fl_Box(cx, cy, width_button, height_button) )
       selvalbutton[#selvalbutton]:label("")
       selvalbutton[#selvalbutton]:box(fltk.FL_BORDER_BOX)
       selval[i]=""
  end
--preselect button
  preselbutton = fltk:Fl_Button(width_button, (cy+(4*height_button)), (2*width_button), height_button, "PRESEL_MT" )
  st="All-ready M.TERRAS-Preselection-button : select lines with 'N05' and fields 'ATC5', 'l_cip13', 'age', 'sexe', 'BEN_REG', 'PSP_SPE','BOITES'"
  preselbutton:tooltip(st)
  preselbutton:callback(preselection)
--countdown modal window : testing purpose only
  cmwinbutton = fltk:Fl_Button(3*width_button, (cy+(4*height_button)), (2*width_button), height_button, "CD" )
  st="This button calls a Countdown Modal Window"
  cmwinbutton:tooltip(st)
  cmwinbutton:callback(countdown)
  cmwinbutton:deactivate()
  Fl:check()
  twindow:show()
end --end function

function read_Image()
   pwindow:make_current()
   -- x,y,w,h are global var and define (local) pie chart dimensions
   imageString = fltk.fl_read_image(x,y,w,h)
   Fl:check()
   Fl:flush()
   --print(" #imageString = " .. #imageString)
   image2 = fltk:Fl_RGB_Image(imageString, w, h, 3)
   Fl:check()
   Fl:flush()
   pwindow:redraw()
   Fl:flush()
   Fl:check()
   --print("image2.w() = " .. image2:w() .. " // image2.h() = " .. image2:h() .. " // image2.d() = " .. image2:d() )
   fileName = title .. ".png"
   image2:saveAsPng(fileName)
   Fl:flush()
   Fl:check()
   --murgaLua.sleep(100)
end --end function

function find_slib_from(context1, current_context, small)
  local i, option
  
  if small then
     if small == 1 then
        option=1 --default = small libelle -if available-
     elseif small == 2 then
        option=2 --plain libelle
     else
        option=0 --no libelle, but code
     end
  else
    option=0 --no libelle, but code
  end
  --returns small_libelle (if relevant) from current_context
  if context1 == "BEN_REG" then
     for i=1, #indx_region do
          if (current_context .. "") == (indx_region[ i ] .. "") then
             if option == 1 then
                return lib_small_region[ i ]
             elseif option == 2 then
                return lib_region[ i ]
             else
                return current_context 
             end
          end
     end
  elseif context1 == "PSP_SPE" then
     for i=1, #indx_spe do
          if (current_context .. "")  == (indx_spe[ i ] .. "") then
             if option == 1 then
                return lib_small_SPE[ i ]
             elseif option == 2 then
                return lib_spe_ps[ i ]
             else
                return current_context
             end
          end
     end
  elseif context1 == "age" then
     for i=1, #indx_age do
          if (current_context .. "")  == (indx_age[ i ] .. "") then
             if option == 1 then
                return lib_age[ i ]
             elseif option == 2 then
                return lib_age[ i ]
             else
                return current_context
             end
          end
     end
  elseif context1 == "sexe" then
     for i=1, #indx_sex do
          if (current_context .. "")  == (indx_sex[ i ] .. "") then
             if option == 1 then
                return lib_sex[ i ]
             elseif option == 2 then
                return lib_sex[ i ]
             else
                return current_context 
             end
          end
     end
  else
     return current_context 
  end
  return current_context
end --end function

function disp_piechart(ax1,indexa1, ax2, indexa2, context1, current_context, valse, spe_table, label_legend)
 --sort_option arg always=1 =>sorting
 local st,st1,st2
 local decx_chart   = 20
 local decy_chart   = 20
 local width_chart  = 450
 local height_chart = 450
 --local width_button = 160
 local dec_button = 0
 local i,j,k
 local sum=0
 local nbcriteria=0
 local spe_table_palm={} --table of spe_table indexes, sorted by decreasing value in this table
 local percent=0
 local cell=object --table for text-legend
 local boxcol={}
 local cumul=0
 
  --file_save=0 --flag for saved file with charts'image
  type_graphics=fltk.FL_SPECIALPIE_CHART
  --GUI for histogram chart
  if pwindow then
     pwindow:hide()
     pwindow:clear()
  end
  
  if context1 then     
     if context1 ~= " " then
        title = "Pie_" .. ax2 .. "_per_" .. ax1 .. "_" .. context1 .. "_" .. current_context
     else
        title = "Pie_" .. ax2 .. "_per_" .. ax1 .. "_no_context"
     end
  else
     title = "Pie_" .. ax2 .. "_per_" .. ax1 .. "_no_context"
  end
  pwindow = fltk:Fl_Window(0,0,width_pwindow, height_pwindow, title)
  pwindow:label(title)
  --centrage du bouton en bas de la fenetre pwindow
  --width_button = 45
  --chart
  pie = fltk:Fl_Chart(0, 0, 5, 5, nil)
  pie:position(decx_chart, decy_chart)
  pie:size(width_chart, height_chart)

  if context1 then  
     st = ax1 .. " // " .. ax2 .. "(" .. context1 .. " =" .. current_context .. ")"
  else
     st = ax1 .. " // " .. ax2 .. "(no context)"
  end
  
  spe_table_palm = palmares_sorting(spe_table) --SORTED TABLE
  
  if #spe_table>5 then 
     pie:type( fltk.FL_SPECIALPIE_CHART )
  else
     pie:type( fltk.FL_PIE_CHART ) --this choice makes the chart more compact with less slices
  end
  
  pie:box(fltk.FL_SHADOW_BOX)
  pie:labelcolor(0)
  --pie:autosize(1)
  --pie:labelfont( fltk.FL_SCREEN )
  pie:labelfont( fltk.FL_HELVETICA )
  pie:labelsize( 8 )
  sum=0
  --for sizing/formatting chart's bars and setting labels positions, extrema and sums are needed before processing
  for i=1,#spe_table do
      sum=sum+spe_table[i]
  end
  --end of sizing, now prepare displaying chart
  --box for text-legend in upper chart-area
  cell = fltk:Fl_Box(decx_chart, decy_chart, width_chart, 64, "")
  cell:labelfont( fltk.FL_HELVETICA )
  cell:labelsize( 8 )
  cell:color( fltk.FL_WHITE )
  cell:box(fltk.FL_BORDER_BOX)
  cell:align(fltk.FL_ALIGN_INSIDE+fltk.FL_ALIGN_LEFT)

  for i=1,#spe_table do
      j = spe_table_palm[i] --always sorting data, decreasing order      
      --5 first items display in special pie chart -- or less than 5, according to number of possible values
      if i<6 then
         --color=87+i
         color=179+i
         st1 = spe_table[ j ] .. ""
         if ax1 == "BEN_REG" then
            --st1 = lib_small_region[ j ] .. "\n" .. st1
            st1 = lib_small_region[ j ] .. "-" .. st1
         elseif ax1 == "PSP_SPE" then
            --st1 = lib_small_SPE[ j ] .. "\n" .. st1
            st1 = lib_small_SPE[ j ] .. "-" .. st1
         else --no "small libelles", so display code "as is"
            --st1 = cat_values[indexa1][ j ] .. "\n" .. st1
            st1 = cat_values[indexa1][ j ] .. "-" .. st1
         end
         percent=string.format("%2.1f",(spe_table[ j ]*100/sum)) .. "%"
         --st1 = st1 .. "\n" .. percent
         st1 = "Number " .. i .. ". " .. st1 .. ", ie " .. percent
         --display range, name, value and % in a excel-sheet-look
         st = cell:label() .. "        " .. st1 .. "\n" --spaces are expected to leave some place for a mini-graphic box with color related to item's range
         cell:label( st )
         table.insert(boxcol,  fltk:Fl_Box(decx_chart+10, decy_chart+2+(10*(i-1)), 9, 9, "") ) --box with color related to item's range
         boxcol[ #boxcol ]:color( color )
         boxcol[ #boxcol ]:box(fltk.FL_BORDER_BOX)
         st1 = i .. ""   --displaying within pie-chart
         pie:add(spe_table[ j ], st1, color)
         if i == #spe_table then 
            --display is quasi-made, but nb of items is lower than 5
            for k=#spe_table,5 do
                 --adding newline for increasing the legend-text's offset (empty text)
                 st = cell:label() .. "\n"
                 cell:label( st )
           end
         end
      else
        cumul = cumul+spe_table[ j ]
        st1=""
        color=12 --default color for chart bars, kind of blue
        if i == #spe_table then
           percent=string.format("%2.1f",(cumul*100/sum)) .. "%"
           st1 = "Other data. " .. cumul .. ", ie " .. percent
           --display range, name, value and % in a excel-sheet-look
           st = cell:label() .. "        " .. st1 .. "\n" --spaces are expected to leave some place for a mini-graphic box with color related to item's range
           cell:label( st )
           table.insert(boxcol,  fltk:Fl_Box(decx_chart+10, decy_chart+2+(10*(6-1)), 9, 9, "") ) --box with color related to item's range
           boxcol[ #boxcol ]:color( color )
           boxcol[ #boxcol ]:box(fltk.FL_BORDER_BOX)
           pie:add(cumul, st1, color)
        end
      end
  end

  --have to add in pie label the optional criteria(s) (if defined)
  st=""
  if valse then
     for i=1,#new_legend do
          if valse[i] ~= " " then
             st = st .. new_legend[i] .. "=" .. valse[i] ..", "
             nbcriteria=nbcriteria+1
             if nbcriteria>3 then
                st=st .. "\n"
             end
          end
     end
  end
  if st == "" then
     st = "No optional criteria"
  end
  
  if context1 then     
     if context1 ~= " " then
        --st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. "_" .. context1 .. "_" .. current_context
        --if relevant, find var current_context in catalog of small_libelle and replace it with small libelle
        st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. " (" .. context1 .. "=" .. find_slib_from(context1, current_context, 2).. ")" --2 means "plain libelle"
     else
        st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. " (no_context)"
     end
  else
	 st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. " (no_context)"
  end

  --text legend of chart bottom-displayed
  st1=label_legend .. " -- " .. st1 .. " (total lines=" .. sum .. "), " .. st
  
  pie:label(st1)
  pie:labelsize(8)
  pie:align(fltk.FL_ALIGN_WRAP + fltk.FL_ALIGN_BOTTOM) --chart's label alignment
  pie:color(fltk.FL_WHITE)
  
  --magical action to transform pie chart in donut chart
  --i=decx_chart+(width_chart/2)
  --j=decy_chart+(height_chart/2)
  --local ray=100
  --fltk.fl_color(1)
  --fltk.fl_circle(i, j, ray)

  Fl:check()
  pwindow:show()
  pwindow:redraw()
  Fl:flush()
  Fl:check()
  
  countdown()
  x,y,w,h=pie:x(), pie:y(), pie:w(), (pie:h()+30)
  read_Image()
  countdown()
end --end function

function disp_spe_histo(ax1,indexa1, ax2, indexa2, context1, current_context, valse, spe_table, label_legend, sort_option)
 --sort_option arg is a number : 0 => no sorting, 1 =>sorting
 local st,st1,st2
 local decx_chart   = 20
 local decy_chart   = 20
 local width_chart  = 450
 local height_chart = 450
 local width_button = 160
 local dec_button = 0
 local i,j,k
 local sum=0
 local maxv=-1
 local minv=9999999
 local idxmax,idxmin
 local nbcriteria=0
 local height_bar, width_bar, x_text, y_text, pixbar
 local barvalue=object
 local spe_table_palm={} --table of spe_table indexes, sorted by decreasing value in this table
 
  --file_save=0 --flag for saved file with charts'image
  type_graphics=4
  --GUI for histogram chart
  if pwindow then
     pwindow:hide()
     pwindow:clear()
  end
  
  if context1 then     
     if context1 ~= " " then
        title = "Bar_" .. ax2 .. "_per_" .. ax1 .. "_" .. context1 .. "_" .. current_context
     else
        title = "Bar_" .. ax2 .. "_per_" .. ax1 .. "_no_context"
     end
  else
     title = "Bar_" .. ax2 .. "_per_" .. ax1 .. "_no_context"
  end
  pwindow = fltk:Fl_Window(0,0,width_pwindow, height_pwindow, title)
  pwindow:label(title)
  --centrage du bouton en bas de la fenetre pwindow
  width_button = 45
  --chart
  pie = fltk:Fl_Chart(0, 0, 5, 5, nil)
  pie:position(decx_chart, decy_chart)
  pie:size(width_chart, height_chart)     
  if context1 then  
     st = ax1 .. " // " .. ax2 .. "(" .. context1 .. " =" .. current_context .. ")"
  else
     st = ax1 .. " // " .. ax2 .. "(no context)"
  end
  if sort_option == 1 then
     spe_table_palm = palmares_sorting(spe_table) --TESTING SORTED TABLE -----------------------------------------------------------------------------------
  else
     spe_table_palm = nil --NOT SORTED
  end
  -- --pie:type( type_chart[type_graphics] )
  pie:type( fltk.FL_HORBAR_CHART )
  pie:box(fltk.FL_SHADOW_BOX)
  pie:labelcolor(0)
  pie:autosize(1)
  --pie:labelfont( fltk.FL_SCREEN )
  pie:labelfont( fltk.FL_HELVETICA )
  pie:labelsize( 8 )
  --height_bar=height_chart/#spe_table
  height_bar=math.floor(height_chart/#spe_table) --height of bar chart in pixel, needing for drawing value at y position (computed)
  sum=0
  --for sizing/formatting chart's bars and setting labels positions, extrema and sums are needed before processing
  for i=1,#spe_table do
      if spe_table[i] > maxv then
         maxv = spe_table[i]
         idxmax=i
      end
      if spe_table[i] < minv then
         minv = spe_table[i]
         idxmin=i
      end
      sum=sum+spe_table[i]
  end
  pixbar = width_chart/spe_table[idxmax]
  --end of sizing, now prepare displaying chart
  for i=1,#spe_table do
      if sort_option == 1 then
         j = spe_table_palm[i] --sorting data, decreasing order
      else
         j=i --no sorting data
      end
      if spe_table[ j ] == maxv then
	     color=9 --max value, kind of red
	  elseif spe_table[ j ] == minv then
	     color=10 --min value, kind of green
	  else
	     color=12 --default color for chart bars, kind of blue
      end
      pie:add(spe_table[ j ], "", color)
      width_bar=pixbar*spe_table[ j ]
      --compute text position giving value IN chart bar
      st1 = spe_table[ j ] .. ""
      if ax1 == "BEN_REG" then
         st1 = lib_small_region[ j ] .. "-" .. st1
      elseif ax1 == "PSP_SPE" then
         st1 = lib_small_SPE[ j ] .. "-" .. st1
      else --no "small libelles", so display code "as is"
         st1 = cat_values[indexa1][ j ] .. "-" .. st1
      end

      x_text = width_bar
      y_text = ((i-1)*height_bar)+1
      if width_bar<(0.25*width_chart) then
         barvalue = fltk:Fl_Box(10, decx_chart+y_text, 12+width_bar, height_bar, st1 ) --defines a text box : text will be displayed aligned within box
         barvalue:align(fltk.FL_ALIGN_RIGHT)
      else
         barvalue = fltk:Fl_Box(0, decx_chart+y_text, width_bar, height_bar, st1 ) --defines a text box : text will be displayed aligned within box
         barvalue:align(fltk.FL_ALIGN_INSIDE)
      end
      barvalue:labelsize(8)
      --barvalue:box(fltk.FL_BORDER_BOX) --debuggin' purpose
  end

  --have to add in pie label the optional criteria(s) (if defined)
  st=""
  if valse then
     for i=1,#new_legend do
          if valse[i] ~= " " then
             st = st .. new_legend[i] .. "=" .. valse[i] ..", "
             nbcriteria=nbcriteria+1
             if nbcriteria>3 then
                st=st .. "\n"
             end
          end
     end
  end
  if st == "" then
     st = "No optional criteria"
  end
  
  if context1 then     
     if context1 ~= " " then
        --st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. "_" .. context1 .. "_" .. current_context
        --if relevant, find var current_context in catalog of small_libelle and replace it with small libelle
        st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. " (" .. context1 .. "=" .. find_slib_from(context1, current_context, 2) .. ")" --2 means plain libelle
     else
        st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. " (no_context)"
     end
  else
	 st1 = clib_new_legend[indexa2] .. " / " .. clib_new_legend[indexa1] .. " (no_context)"
  end

  --text legend of chart bottom-displayed
  st1=label_legend .. " -- " .. st1 .. " (total lines=" .. sum .. "), " .. st
  
  pie:label(st1)
  pie:labelsize(8)
  pie:align(fltk.FL_ALIGN_WRAP + fltk.FL_ALIGN_BOTTOM) --chart's label alignment
  pie:color(fltk.FL_WHITE)
  
  Fl:check()
  pwindow:show()
  pwindow:redraw()
  Fl:flush()
  Fl:check()
  
  countdown()
  x,y,w,h=pie:x(), pie:y(), pie:w(), (pie:h()+30)
  read_Image()
  countdown()
end --end function

function disp_table_report(ax1, indexa1, ax2, indexa2, context1, current_context, valse, spe_table,label_legend)
  local i
  
  html_buffer = html_buffer .. "<TD><CENTER><TABLE>"
  html_buffer = html_buffer .. "<TR><TH COLSPAN=2>" .. context1 .. "(" .. find_slib_from(context1, current_context, 2) .. ") </TH></TR>"
  html_buffer = html_buffer .. "<TR><TH>LABELS</TH><TH>VALUES</TH></TR>"
  for i=1,#spe_table do
       html_buffer = html_buffer .. "<TR><TD>" .. cat_values[indexa1][ i ] .. "</TD>"
       html_buffer = html_buffer .. "<TD style='text-align: right;'>" .. spe_table[i] .. "</TD></TR>"
  end
  html_buffer = html_buffer .. "</TABLE></CENTER></TD>"
end --end function

function query_fct(ax1, indexa1, ax2, indexa2, context1, indexc1, valse, sort_option,report)
  local i,j,k
  local spe_table={}
  local keepcr=0 --keep this criteria-friendly cell
  --local keepco=0 --keep this context-friendly cell
  local indexc=0
  local nb_criterias=0
  local nb_contexts=0
  local current_context
  local str,str2,unit,st2
  local label_legend
  
  --debug block
--print("query_fct() => context1 = " .. context1 .. "(#=" .. #context1 .. "// indexc1=" .. indexc1)
  --end debug block
  
  if context1 ~= " " then
     --one chart per context=per possible value for a single column
     indexc=indexc1
     if indexc then
        nb_contexts = #cat_values[indexc]
     else
        nb_contexts = 1
        indexc=1 --factice value
     end   
  else
     --ONE ONLY agregate chart
     nb_contexts = 1
     indexc=1 --factice value
  end
  nb_a1 = #cat_values[indexa1]
  if indexa2>0 then
     nb_a2 = #cat_values[indexa2]
     --else
  end
  --find number of criteria in valselect
  if valse then
      for k=1,#valse do
            if valse[k] ~= " " then
               nb_criterias=nb_criterias+1
            end
      end
   end
   
   --label_legend is the same part for all "multi-context" charts, and displays year of openmedic file and selections keys
  st2=""
  for i=1,#selval_select do
       if selval_select[i] then
          if selval_select[i] ~= "" then 
             st2 = st2 .. selval_select[i] .. ", "
          end
       end
  end
  if annee then
     label_legend="Year " .. annee .. ", downsize keywords selection=" .. st2
  else
     label_legend="Unknown OPENMEDIC year, downsize keywords selection=" .. st2
  end

  
  --GO! the final result is table described by an histogram with y-axis lines=nb_a1 = #cat_values[indexa1]
  --and ONE column=some agregate cells of transftable_data
  for i=1,nb_contexts do --nb of successive charts to draw  
       --file_save=0 --flag for saved file with charts'image
       current_context = tostring(cat_values[indexc][i]) --convert to char
print("current_context (" .. new_legend[indexc] .. ")= " .. current_context .. "// nb contexts=" .. nb_contexts .. "// Criterias number = " .. nb_criterias)

--reinit table for re-using
      spe_table=nil
      spe_table={}
      for j=1,nb_a1 do
           table.insert(spe_table, 0)
      end
      
       for j=1,#transftable_data do
            --lines scan
            --test context
            --keepco=0
          if nb_contexts>1 then
            if tostring(transftable_data[j][indexc]) == current_context then
               --keepco=1
               --test criterias
               keepcr=0
               if valse then
                  for k=1,#valse do
                       --apply valse criterias to colums
                       str=tostring(transftable_data[j][k])
                       str2=valse[k]
                       if str == str2 then
                          --keep line / this cell
                          keepcr=keepcr+1
                       end
                  end --end for k
               end
               unit=0
               if keepcr == nb_criterias then
                  str=tostring(transftable_data[j][indexa1])
                  unit=tonumber(transftable_data[j][indexa2])
--print("Matching criterias for transftable_data[" .. j .. "][" .. indexa1 .. "] = " .. transftable_data[j][indexa1])
--print("Matching criterias for transftable_data[" .. j .. "][" .. indexa2 .. "] = " .. ", label_unit =" .. label_unit)
                  for k=1,nb_a1 do
                       str2=tostring(cat_values[indexa1][k])
                       if str == str2 then
                          spe_table[k] = spe_table[k]+unit
                       end
                  end
               end --end if keepcr 
            end --end if [...] current_context
         else  --nb_contexts<=1   ====== ONE context=hyper-agregate & specialized histogram
            keepcr=0
            if valse then
               for k=1,#valse do
                    --apply valse criterias to colums
                    str=tostring(transftable_data[j][k])
                    str2=valse[k]
                    if str == str2 then
                       --keep line / this cell
                       keepcr=keepcr+1
                    end
               end --end for k
            end
            unit=0
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
--results of this function have been validated with with LibreOfficeCALC & some SUMPRODUCT() -or SOMMEPROD()-
   --preparing table legend text for same groups : same context
     imageString, image2 = nil, nil
     disp_spe_histo(ax1, indexa1, ax2, indexa2, context1, current_context, valse, spe_table,label_legend, sort_option) --last arg "sorting actived=1 or not=0"
     fileName = title .. ".png"
     if report == "report" then
        html_buffer = html_buffer .. "\n<TR><TD><IMG SRC='" .. fileName .. "'></TD>"
     end
     --print("retour en fct query_fct")
     if pwindow then
        pwindow:hide() --close last charts' window
     end
     if report == "report" then
        --adding a table with values and text labels in the middle column
        disp_table_report(ax1, indexa1, ax2, indexa2, context1, current_context, valse, spe_table,label_legend)
     end
     imageString, image2 = nil, nil
     disp_piechart(ax1, indexa1, ax2, indexa2, context1, current_context, valse, spe_table,label_legend)
     if pwindow then
        pwindow:hide() --close last charts' window
     end
     fileName = title .. ".png"
     if report == "report" then
        html_buffer = html_buffer .. "\n<TD><IMG SRC='" .. fileName .. "'></TD></TR>\n"
     end
     --test if file exists
     f = io.open(fileName,"rb")
     if f then
        print("File " .. fileName .. " exists in default path.") 
        io.close(f)
     else
        print("File " .. fileName .. " DOES NOT exist in default path.") 
     end
    end --end for i (context)
end  --end function

function consistency_checking(ax1, ax2, c1)
  local i, indexa2, indexa1
  --rule one
  if ax1 ~= 0 and ax2 ~= 0 then
     --ok
  else
     --problemo!
     msg="Both Axis variables must be set to non-nil !!!"
     print(msg)
     fltk:fl_alert(msg)
     return (nil)
  end
  --rule two
  if ax1 ~= ax2 and ax2 ~= c1 and ax1 ~= c1 then
     --ok           
  else
     --problemo!
     msg="Axis and Context variables have to be distinct !!!"
     print(msg)
     fltk:fl_alert(msg)
     return(nil)
  end
  --rule two and a half
  for i=1,#new_legend do
       if ax1 == new_legend[i] then
          indexa1=i
print("Criteria nb 1 = " .. ax1 .. "// index new_legend = " .. indexa1)
          --additional condition = nb of possible value has to be <>0
          if #cat_values[ indexa1 ] == 0 then
print("Criteria " .. ax1 .. " has too much possible values => no dataviz provided !")
             return(nil)
          end
          break
       end
  end  
 
  --rule three
  --axis2 variable's type MUST BE "number"
  --find index of ax2 in new_legend
  for i=1,#new_legend do
        if ax2 == new_legend[i] then
           indexa2=i
print("Criteria nb 2 = " .. ax2 .. "// index new_legend = " .. indexa2)
           break
        end
  end
  if type_new_data[indexa2] == "number" then
     --ok
     print("Criteria nb 2 : type value= " .. type_new_data[indexa2] )
  else
     --problemo!
     msg="Axis2 variable is not a number (REQUIRED) !!!"
     print(msg)
     fltk:fl_alert(msg)
     return(nil)
  end
  return(indexa2)
end  --end function

function compute_index(ax1, c1, valselect, report)
  --compute index of other sent variables
  --find index of ax1 in new_legend
  local i, indexa1, indexc1,valse0=0,nil,nil,{}
  
  --info zero
--print("Args passed to compute_index()\nax1 = " .. ax1 .. ", c1=" .. c1)
  --info one
  if report then
     if report == "report" then
print("Reporting context in function compute_index()")
     else
print("No reporting context  in function compute_index()")
     end
  else
print("No reporting context  in function compute_index()")
  end
  for i=1,#new_legend do
       if ax1 == new_legend[i] then
          indexa1=i
          print("Criteria nb 1 = " .. ax1 .. "// index new_legend = " .. indexa1)
          --additional condition = nb of possible value has to be <>0
          break
       end
 end       
 --find context1 index in new_legend{} and then number of contexts
 for i=1,#new_legend do
      if c1 == new_legend[i] then
         indexc1=i --context1 is the label, indexc is the context's index in table "new_legend" = the number of the column to read in table "transftable_data"
         break
      end
  end
  if indexc1 then
print("Context1 = " .. c1 .. "// index new_legend = " .. indexc1)
  else
print("Context1 = none")
  end
  --valse0{} is related to table of Fl_Choice
  if  valselect then
     for i=1,#new_legend do
          if valselect[i]:text() then
             table.insert(valse0, valselect[i]:text() )
          else
             table.insert(valse0, " ")
          end   
      end
  else 
      valse0=nil
print("Valselect table passed to compute_index() WAS NIL !")
  end
  return indexa1, indexc1, valse0
end  --end function

function disp_sample3()
 --GUI : selecting fields with criteria to be analysed
  local i,j,k,cx,cy
  local st,st1,st2,st3
  local cellq,cellr,cell1=nil,nil,nil
  local u_quit=nil
  local uwindow=nil
  local valselect={}
  local co=#new_legend
  local axis1,context1
  local spe_chart=nil
  local spe_report=nil
  local valse={}
  local sort_option=1
  local cross={}
  
  if f_downsize ~= 1 then
     return
  end
  clear_t()
  quit_t()
  twindow=nil
  legend_data=nil
  table_data=nil
  collectgarbage()
  
  --table selcross init
  for i=1,#new_legend do
       table.insert(selcross, 0) --default = no cross-analyse for current field
  end
  
  --fenetre graphique pour la restitution du tableau CSV
  width_twindow = 1024
  height_twindow = 450
  width_button = math.floor(width_twindow/(co+1)) --ajout d'une colonne "legende" (stats)
  height_button = 20
  nb_car = math.floor(width_button/11) --nb cars affichables dans la largeur du bouton
  
  --window for downsized table
  width_twindow = 1024
  height_twindow = 450
  uwindow = fltk:Fl_Window(width_twindow, height_twindow, "Downsized CSV")   
  width_button = math.floor(width_twindow/(co+1)) --ajout d'une colonne "legende" (stats)
  --u_quit = fltk:Fl_Button(10, height_twindow-30, width_button, 25, "Quit")
  u_quit = fltk:Fl_Button(0, (8*height_button), width_button, height_button, "Quit")
  u_quit:color(fltk.FL_RED)
  u_quit:tooltip("Quit this application")
  --u_quit:callback(quit_u)
  u_quit:callback(function (quit_u)
     uwindow:hide()
     uwindow:clear()
     uwindow = nil
     os.exit()
  end)
--print("Fct disp_sample3(), var f_downsize = " .. f_downsize .. "\ncolumns = " .. co .. " // lines #transftable_data = " .. #transftable_data)
 
 --first group box for individual Query
  cy = (10*height_button)
  -- group box for individual query ---
  cellq= fltk:Fl_Box(cx, cy-height_button, (5.5*width_button), (20*height_button), "GUI Area for Individual Query" )
  cellq:labelfont(fltk.FL_SCREEN )
  cellq:box(fltk.FL_DOWN_BOX)
  cellq:align(fltk.FL_ALIGN_TOP+fltk.FL_ALIGN_CENTER+fltk.FL_ALIGN_INSIDE)
  cellq:tooltip("GUI Area for Individual Query")
  --end 1st group box
  -- group box for automatic reporting ---
  cx=(5.5*width_button)+5
  cellr= fltk:Fl_Box(cx, cy-height_button, (3*width_button), (20*height_button), "GUI Area for Automatic reporting" )
  cellr:labelfont(fltk.FL_SCREEN )
  cellr:box(fltk.FL_DOWN_BOX)
  cellr:align(fltk.FL_ALIGN_TOP+fltk.FL_ALIGN_CENTER+fltk.FL_ALIGN_INSIDE)
  cellr:tooltip("GUI Area for Automatic reporting")
  --end 2nd group box
  
  
  --table legendes
  cx, cy=0,0
  cell1= fltk:Fl_Box(cx, cy, width_button, height_button, "LABELS" )
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:tooltip( "Field's labels" )
  cell1:box(fltk.FL_BORDER_BOX)
  for j=1,co do
      selval[j]={"","","","",""}
      cy = 0
      cx = j*width_button
      st = new_legend[ j ]
      if type(st) == "string" then
         st = sub(st, 1, nb_car)
      end
      cell1= fltk:Fl_Box(cx, cy, width_button, height_button, st )
      cell1:labelfont( fltk.FL_SCREEN )
      cell1:tooltip( new_legend[ j ] )
      cell1:box(fltk.FL_BORDER_BOX)
--print("new_legend[ " .. j .. " ] = " .. new_legend[ j ])
  end
  --ligne type des donnees
  cx, cy=0,height_button
  cell1= fltk:Fl_Box(cx, cy, width_button, height_button, "TYPE" )
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:tooltip( "Data type" )
  cell1:box(fltk.FL_BORDER_BOX)
  for j=1,co do
      cy = height_button
      cx = j*width_button
      st = type_new_data[j]
      if st == "number" then
         st2 = "nb"
      else 
         st2 = "str"
      end
      cell1= fltk:Fl_Box(cx, cy, width_button, height_button, st2 )
      cell1:labelfont( fltk.FL_SCREEN )
      cell1:color(43) --some grey
      cell1:tooltip( st )
      cell1:box(fltk.FL_BORDER_BOX)
  end
  
  --left-most button "values" (no callback, just displaying purpose)
  cx,cy=0, (2*height_button)
  cell1= fltk:Fl_Box(cx, cy, width_button, (5*height_button), "5\nfirst lines\nValues" )
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:box(fltk.FL_BORDER_BOX)
--table transftable_data : echantillon/sample
  cx, cy=0,0
  for i=1,5 do -- line 1 = legend, data beginning at line 2
      for j=1,co do
	  cy = (i+1)*height_button
      cx = j*width_button
	  st = transftable_data[ i+1 ][j]
      st2 = sub((st .. ""), 1, nb_car)
      cell1=fltk:Fl_Box(cx, cy, width_button, height_button, st2 )
      cell1:labelfont( fltk.FL_SCREEN )
      cell1:color(20)
	  cell1:tooltip( transftable_data[ i+1 ][j] )
	  cell1:box(fltk.FL_BORDER_BOX)
      end 
  end
  
--"nb values" and "unit" buttons (two lines)
i=6
cy = (i+1)*height_button
 for j=1,co do
      cx = j*width_button
      --text legend for line "nb of possible values"
      if j ==1 then
         -- this text legend button should NOT be multi-defined in this loop
         cx=0
         st="Nb values"
         st2="Nb of possible values for this column"
         cell1=fltk:Fl_Box(cx, cy, width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
         cell1:box(fltk.FL_BORDER_BOX)
      end
      cx = j*width_button
      st = #cat_values[j] .. ""
      st2 = #cat_values[j] .. " possible values"
      cell1=fltk:Fl_Button(cx, cy, width_button, height_button, st )
      cell1:labelfont( fltk.FL_SCREEN )
	  cell1:tooltip( st2 )
	  cell1:box(fltk.FL_BORDER_BOX)
	  --display field set as unit measurement 
	  if label_unit == new_legend[j] then
	     cell1=fltk:Fl_Button(cx, cy+height_button, width_button, height_button, "UNIT" )
         cell1:labelfont( fltk.FL_SCREEN )
	     cell1:tooltip( "This field is set as UNIT of measurement" )
	     cell1:labelcolor( 1 ) --RED
	     cell1:box(fltk.FL_BORDER_BOX)
	  end
      --WHERE GUI version 2
      --now, (conditionnal) displaying a "menu button" handling possible values
      --legend text for these selection tools
      if j ==1 then
         st="Where"
         st2="Set a possible value (or none) to each column as a restrictive condition to get one or several specialized chart"
         cell1=fltk:Fl_Box((3*width_button), (11*height_button), width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
         cell1:box(fltk.FL_BORDER_BOX)
      end

	  if #cat_values[j] > 0 then
	     st = new_legend[j] .. " ="
         cell1=fltk:Fl_Box((3*width_button), ((11+j)*height_button), width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
         cell1:box(fltk.FL_BORDER_BOX)
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
         cell1=fltk:Fl_Box((3*width_button), ((11+j)*height_button), width_button, height_button, st )
         cell1:labelfont( fltk.FL_SCREEN )
         cell1:tooltip( st2 )
         cell1:box(fltk.FL_BORDER_BOX)
         table.insert(valselect, fltk:Fl_Choice((4*width_button), ((11+j)*height_button), width_button, height_button) )
         valselect[#valselect]:labelfont( fltk.FL_SCREEN )
         valselect[#valselect]:add(" ")
	     valselect[#valselect]:deactivate()
      end	

  end --end for j

  --cross-table visual query (chart)
  --left-most button "values" (no callback, just displaying purpose)
  cx=0
  --cy = cy+(4*height_button)
  cy = cy+(3*height_button)
  cell1= fltk:Fl_Box(cx, cy, width_button, height_button, "Charts' Y axis" )
  cell1:labelfont(fltk.FL_SCREEN )
  cell1:box(fltk.FL_BORDER_BOX)
  cell1= fltk:Fl_Box(cx+(2*width_button), cy, width_button, height_button, "For each/all" )
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:box(fltk.FL_BORDER_BOX)
  st = "For each = one histogram charts for each value of selected column // For all = one only aggregated histogram charts for all values (no selected column)"
  cell1:tooltip( st )
  context1 = fltk:Fl_Choice(cx+(2*width_button), (cy+height_button), width_button, height_button)
  st = "Histogram chart for each possible value of this column (agregated for all values if no selection). Number of possible values = nb of charts"
  context1:tooltip( st )
  context1:add( " " ) --adding space string = "no selection option"
  for k=1,#new_legend do
       if #cat_values[k] ~= 0 then
          if label_unit ~= new_legend[k] then
             --exclude field set as "unit of measurement"
             context1:add( new_legend[k] )
          end
       end
  end
  
  --defining catalog menu for Charts' Y axis
  cell1= fltk:Fl_Button(cx+width_button, cy+height_button, width_button, height_button)
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:box(fltk.FL_DOWN_BOX)
  --set 1st dim of table
  axis1 = fltk:Fl_Choice(cx, (cy+height_button), width_button, height_button)
  st = "Set a field for the Y-axis of table/chart"
  axis1:tooltip( st )
  for k=1,#new_legend do
       if #cat_values[k] ~= 0 then
          if label_unit ~= new_legend[k] then
             --exclude field set as "unit of measurement"
             axis1:add( new_legend[k] )
          end
       end
  end
  --set 2nd dim of table
  cx=width_button
  cell1= fltk:Fl_Box(cx, cy, width_button, height_button, "Charts' X axis" )
  cell1:labelfont(fltk.FL_SCREEN )
  cell1:box(fltk.FL_BORDER_BOX)
  st = "This field is a SUMABLE number and will be handled as a Measure's Unit (If not, displayed values would make no sense !)"
  cell1:tooltip(st)
  
  cell1= fltk:Fl_Box(cx, cy+height_button, width_button, height_button, label_unit )
  cell1:labelfont(fltk.FL_SCREEN )
  cell1:box(fltk.FL_BORDER_BOX)
  st = "This field is a SUMABLE number and will be handled as a Measure's Unit (If not, displayed values would make no sense !)"
  cell1:tooltip(st)

  --set main callback for specialized charts
  --select option : sorting data or NOT (default=yes)
  cx=0
  st = "Select here by clicking if charts have sorting data (default) enabled or not"
  sortbut= fltk:Fl_Button(cx, cy+(3*height_button), width_button, height_button, "sorting data" )
  sortbut:labelfont( fltk.FL_SCREEN )
  sortbut:tooltip( st )
  sortbut:color(2) --prev color=14
  sortbut:callback(function (selsortdata)
          local st = sortbut:label()
          if st == "sorting data" then
             st = "NO sorting data"
             sort_option=0
          else
             st = "sorting data"
             sort_option=1
          end
          sortbut:label(st)
          sortbut:redraw()
          end) --end local function
  cx=0
  st = "Reset ALL query's criterias"
  cell1= fltk:Fl_Button(cx, cy+(4*height_button), width_button, height_button, "Reset" )
  cell1:labelfont( fltk.FL_SCREEN )
  cell1:tooltip( st )
  cell1:color(2) --prev color=14
  cell1:callback(function (reset)
          local i
          axis1:value(0)
          --axis2:value(0)
          context1:value(0)
          for i=1,#valselect do
                valselect[i]:value(0)
          end
          for i=1,#valse do
                table.remove(valse)
          end
          end) --end local function
  st = "Launch query and get chart(s)"
  spe_chart= fltk:Fl_Button(cx, cy+(2*height_button), width_button, height_button, "Launch query" )
  spe_chart:labelfont( fltk.FL_SCREEN )
  spe_chart:tooltip( st )
  spe_chart:color(1) --prev color=12
  --new code for function
  spe_chart:callback(function (query_launch)
        local i, msg
        local ax1, ax2, c1=axis1:text(), label_unit, context1:text()
        local indexa1,indexa2,indexc1
        --1_consistency_checking
        indexa2 = consistency_checking(ax1, ax2, c1)
        if indexa2 then
           --continue
           indexa1, indexc1, valse =  compute_index(ax1, c1, valselect, nil)
           --3_GUI fonction
           query_fct(ax1, indexa1, ax2, indexa2, c1, indexc1, valse, sort_option)
           --second launching of this function for a "last agregrate chart" -ONLY IF previous chart was not already "agregate chart"
           if c1 ~= " " then
              c1=" "
              indexc1=nil
              query_fct(ax1, indexa1, ax2, indexa2, " ", nil, valse, sort_option)
           end
        end
        end) --end local function
        
  --cosmetic GUI for automatic report
  cx=(6*width_button)
  cy = (10*height_button)
  for k=1,#new_legend do
             cmdbox = fltk:Fl_Box(cx, cy, width_button, height_button, new_legend[k])
             cmdbox:box(fltk.FL_DOWN_BOX)
             cmdbox:labelfont( fltk.FL_SCREEN )
             cmdbox:labelsize( 8 )
             cmdbox:color( fltk.FL_WHITE )
             table.insert( cross, fltk:Fl_Button((cx+width_button), cy, 32, height_button, " "))
             cross[ #cross ]:labelcolor( fltk.FL_RED )
             cross[ #cross ]:tooltip( "Click here for a crossed-analyse of this field with the other" )
             if (#cat_values[k] == 0) or (label_unit == new_legend[k]) then
                cross[ #cross ]:deactivate()
                cross[ #cross ]:tooltip( "Not available!" )
                cmdbox:color(16)
             end
             cross[ #cross ]:callback(function (sel_cross)
               local i
               for i=1,#cross do
                    if Fl.event_inside(cross[ i ]) == 1 then
                       if cross[ i ]:label() == " " then
                          cross[ i ]:label("@-5circle")
                          selcross[i] = 1
                       else
                          cross[ i ]:label(" ")
                          selcross[i] = 0
                       end
                       break
                    end
               end
               end) --end local function
             cy = cy+height_button
  end
  --launch automatic reporting with one click
  st = "Launch automatic reporting, all charts and tables in HTML-format document"
  --spe_report= fltk:Fl_Button(cx, cy+(5*height_button), width_button, height_button, "Launch report" )
  spe_report= fltk:Fl_Button(cx, cy, width_button, height_button, "Launch report" )
  spe_report:labelfont( fltk.FL_SCREEN )
  spe_report:tooltip( st )
  spe_report:color(1) --prev color=12
  spe_report:callback(function (report_launch)
        local i, j,data, context,j,k,allow
        local ax2, indexa2=label_unit, index_unit
        local ax1, c1
        local indexa1,indexc1
        local f,fn
        --defines depth of reporting : how many fields (and which one) are crossed-analysed ?
        
        if label_unit then
           --compute global var index_unit
           for i=1,#new_legend do
              if label_unit == new_legend[i] then
                 index_unit = i
                 indexa2=index_unit
                 break
              end
           end
        else
           msg="No unit of measurement defined = no reporting is possible. \nPlease Define one unit !"
           fltk:fl_alert(msg)
           return
        end
        
        for data=1, #new_legend do
             if selcross[ data ] == 1 then
                ax1=new_legend[ data ]
                for context=1, #new_legend do
                    indexa2 = consistency_checking(ax1, ax2, c1,"report")
                    if context ~= data then
                       c1 = new_legend[ context ]
                       --indexa1, indexc1, valse =  compute_index(ax1, c1, valselect,"report")
                       indexa1=data
                       indexc1=context
                       valse=nil
                       --3_GUI fonction
                       query_fct(ax1, indexa1, label_unit, index_unit, c1, indexc1, nil, sort_option,"report")
                --second launching of this function for a "last agregrate chart" -ONLY IF previous chart was not already "agregate chart"
                    end --if context
                end --end for context
                if c1 ~= " " then
                   c1=" "
                   indexc1=nil
                   query_fct(ax1, indexa1, ax2, indexa2, " ", nil, valse, sort_option,"report")
                end
                
          end --end if selcross
        end --end for data
        --now save html report
        if annee then
           fn = "Report_OpenMedic" .. annee .. ".html"
        else
           fn = "Report_OpenMedic" .. annee_inconnue .. ".html"
        end
        f = io.open(fn,"wb")
        if f then
           --adding HTML footer
           html_buffer = html_buffer .. "\n</TABLE>\n</body></HTML>"
           f:write(html_buffer)
           print(fn .. " HTML report saved, size is " .. #html_buffer .. " bytes.")
           io.close(f)
        end
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
 if filename then
    annee = tonumber( sub(filename,-8,-5) )
    print("Year of open_medic data (according to name of file) = " .. annee)
 end
 print("RAM used BEFORE opData by  gcinfo() = " .. gcinfo())
 
 preopen_csv_file(filename)
 st="Pre-Opening Ok !\nColumns = " .. #table_data .. "\nLines (sample)= " .. #table_data[3]
print(st)
 --fltk:fl_alert(st)
 disp_sample2()

 print("Processing in " .. os.difftime(os.time(), t00) .. " seconds, ie  " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, ie " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " hours")

  --print("Free RAM by collectgarbage(\"count\") = " .. collectgarbage("count"))
  print("RAM used AFTER opData by  gcinfo() = " .. gcinfo())
                                                 
 --print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")

Fl:check()
Fl:run()

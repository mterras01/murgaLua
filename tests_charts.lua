#!/bin/murgaLua
i=0
f=0

--type_chart = { fltk.FL_BAR_CHART, fltk.FL_FILLED_CHART, fltk.FL_HORBAR_CHART, fltk.FL_LINE_CHART, fltk.FL_SPECIALPIE_CHART, fltk.FL_SPIKE_CHART, fltk.FL_PIE_CHART}

--sorted table, by values 
type_chart = { fltk.FL_BAR_CHART, fltk.FL_LINE_CHART, fltk.FL_FILLED_CHART, fltk.FL_SPIKE_CHART, fltk.FL_PIE_CHART, fltk.FL_SPECIALPIE_CHART, fltk.FL_HORBAR_CHART}
label_chart = { "FL_HORBAR_CHART", "FL_LINE_CHART", "FL_FILLED_CHART", "FL_SPIKE_CHART", "FL_PIE_CHART", "FL_SPECIALPIE_CHART", "FL_BAR_CHART" }

separator = ";"
legendes = {}
table_data={}
type_data={}
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

function quit_t()
  if twindow then
     twindow:hide()
     twindow:clear()
     twindow = nil
  end
end --end function

function disp_sample_csv()
  local i,j,cx,cy,post
  local cell={}

  
  --fenetre graphique pour la restitution du tableau CSV
  width_twindow = 1024
  height_twindow = 250
  twindow = fltk:Fl_Window(width_twindow, height_twindow, "Tableau CSV")
  width_button = 120
  height_button = 20
  nb_car = width_button/10 --nb cars affichables dans la largeur du bouton
  
  t_quit = fltk:Fl_Button(10, height_twindow-30, width_button, 25, "Quitter")
  t_quit:tooltip("Fermer cette fenetre")
  t_quit:callback(quit_t)
  --affichage legendes + 2 premières lignes de table_data
  --table legendes
  cx, cy=0,0
  for j=1,co do
      cy = 0
      cx = (j-1)*width_button
      st = legendes[ j ]
      if type(st) == "string" then
         st = sub(st, 1, nb_car)
      end
      table.insert(cell, fltk:Fl_Button(cx, cy, width_button, height_button, st ))
      cell[ #cell ]:labelfont( fltk.FL_SCREEN )
      cell[ #cell ]:tooltip( legendes[ j ] )
  end
  --ligne type des donnees
  cx, cy=0,0
  for j=1,co do
      cy = height_button
      cx = (j-1)*width_button
      st = type_data[ j ]
      table.insert(cell, fltk:Fl_Button(cx, cy, width_button, height_button, st ))
      cell[ #cell ]:labelfont( fltk.FL_SCREEN )
      cell[#cell]:color(fltk.FL_RED)
      cell[ #cell ]:tooltip( legendes[ j ] )
  end
  
  
  --table table_data
  cx, cy=0,0
  for i=1,5 do
      for j=1,co do
	  cy = (i+1)*height_button
	  cx = (j-1)*width_button
	  post=(i*co)+j
	  st = table_data[ post ]
	  if type(st) == "string" then
	     st = sub(st, 1, nb_car)
	  end
	  table.insert(cell, fltk:Fl_Button(cx, cy, width_button, height_button, st ))
	  cell[ #cell ]:labelfont( fltk.FL_SCREEN )
	  cell[#cell]:color(fltk.FL_WHITE)
	  cell[#cell]:tooltip( table_data[ post ] )
      end 
  end
  --st = table.concat(legendes, "/")
  --print("legendes\n" .. st)
  
  --calculer les types par colonne
  --calculer les champs non vides
  
  Fl:check()
  twindow:show()
end --end function

function find_type(st)
  local t_st
  
  if tonumber(st) then
     t_st = tonumber(st)
     if t_st .. "" == st then
        return "numeric"
     else
        return "string"
     end
  else
    return "string"
  end
end --end function

function pertinence_separator(data)
  --check if every lines has same number of separators
  local lines = 0
  local cols={}
  local j,k,m,st,d,nb_sep
 
  st=""
  d=1
  
  while 1 do
    j = find(data,"\n",d)
    if j then
       st = sub(data, d, j-1)
       m=1
       nb_sep=0
       while 1 do
	   k = find(st, separator, m)
	   if k then
	      m=k+1
	      nb_sep=nb_sep+1
	   else
	      break
	   end
       end
       table.insert(cols, nb_sep)
       if #cols > 1 then
	  if cols[#cols] == cols[ #cols-1] then
	  else
             st = "La pertinence du separateur " .. separator .. " est compromise (ligne " .. lines .. ")"
             fltk:fl_alert(st)
             quit_callback_app()
	  end
       end
       lines = lines+1
       d = j+size_eol
    else
       break
    end
  end
  st = "La pertinence du separateur " .. separator .. " est validee pour les " .. lines .. " lignes."
  print(st)
end --end function

function stats_0_csv()
  local i,j,k,col,lig,rang
  local vides={}
  local moyenne={}
  local mediane_buffer={}
  local mediane={}
  local nb_valeurs_str={}
  local nb_valeurs_num={}
  local nb_valeurs_diff={}
  local buffer={}
  
  if #table_data <=1 then
     return 0
  end
  if co and li then
     --initialisations des tables de stats
     for i=1,co do
         vides[i] = 0
         moyenne[i] = 0
         mediane[i] = 0
	 nb_valeurs_num[i] = 0
	 nb_valeurs_str[i] = 0
	 nb_valeurs_diff[i] = 0
     end
     --debut analyse
     for col=1,co do
         buffer = "" -- RAZ pour chaque colonne
         for lig=1,li do
	     rang = ((lig-1)*co)+col
	     if table_data[ rang ] == "" then
	        vides[ col ] = vides[ col ]+1
	     end
	     k = tonumber(table_data[ rang ] )
	     if k then
                moyenne[ col ] = moyenne[ col ]+table_data[ rang ]
		table.insert(mediane_buffer, table_data[ rang ])
                nb_valeurs_num[ col ] = nb_valeurs_num[ col ] +1
	     end
             if k == nil then
                nb_valeurs_str[ col ] = nb_valeurs_str[ col ] +1
	     end
--[[ -- A OPTIMISER
             if find(buffer, table_data[ rang ]) then
	        --valeur deja enregistree
	     else
	        buffer = buffer .. "*" .. table_data[ rang ]
                nb_valeurs_diff[ col ] = nb_valeurs_diff[ col ] +1
	     end]]

	 end
	 if (#mediane_buffer % 2) == 1 then
	    mediane[ col ] = mediane_buffer[ math.ceil(#mediane_buffer/2) ]
	 else 
	    if #mediane_buffer ~= 0 then
	       i = math.floor(#mediane_buffer/2)
	       j = i+1
	       mediane[ col ] = (mediane_buffer[ i ] + mediane_buffer[ j ])/2
	    else
	       mediane[ col ] = "NC"
	    end
	 end
	 if nb_valeurs_num[ col ] then
	    if nb_valeurs_num[ col ] >0 then
	       moyenne [ col ] = moyenne [ col ]/nb_valeurs_num[ col ]
	    end
	 end
--print("Fin colonne " .. col)
     end
  else
     return 0
  end
  print("legendes = " .. table.concat(legendes, "//") )
  print("vides = " .. table.concat(vides, "//") )
  print("moyenne = " .. table.concat(moyenne, "//") )
  print("mediane = " .. table.concat(mediane, "//") )
  print("Nb val num = " .. table.concat(nb_valeurs_num, "//") )
  print("Nb val str = " .. table.concat(nb_valeurs_str, "//") )
  --print("Nb val diff = " .. table.concat(nb_valeurs_diff, "//") )
  
end -- end function

function find_col_lines_csv(data)
  local cols,lines = 0,0
  local i,j,k,l,m,n,st,d,st2,st3
  local pos,posc = 1,1
  local pos1,pos2 = 1,1
  local pos_l
  
  st=""
  
  -- LEGENDES a recuperer
  l = find(data, "\n", 1) ---premiere fin de ligne
  --premier item/legende
  pos1 = find(data, separator, 1)
  st = sub(data,1,pos1-1)
  table.insert(legendes,st)
      
  while 1 do
     pos1 = find(data, separator, pos1)
     pos2 = find(data, separator, pos1+1)
     if pos1 then
        if pos1 < l then
           if pos2 then
              if pos2 == pos1+1 then
                 if pos2 < l then
                    st=""
                 end
              else
                 if pos2 < l then
                    st = sub(data, pos1+1,pos2-1)
                 else
                    st = sub(data, pos1+1,l-1)
                    table.insert(legendes,st)
                    break
                 end
              end
              table.insert(legendes,st)
              pos1 = pos2
           else -- dernier champ du fichier
              st = sub(data, pos1+1,l-1)
              table.insert(legendes,st)
              break
           end
        else
           break
        end
     else
        break
     end
  end

  st = table.concat(legendes, "/")
  print(st)
  if legendes then
     cols = #legendes
  end
  
  --suite des données
  d=1
  while 1 do
    j = find(data,"\n",d)
    if j then
       st = sub(data, d, j-1)
       m=1
       for i=1,cols-1 do
	   k = find(st, separator, m)
	   if k then
	      if (k-m) >=1 then
		 st2 = sub(st, m, k-1)
		 st3 = find_type(st2)
	         table.insert(table_data, sub(st, m, k-1) )
		 if lines == 1 then 
		    table.insert(type_data, st3)
		 end
	      else
		 st2=""
		 st3 = find_type(st2)
		 table.insert(table_data, "" )
		 if lines == 1 then 
		    table.insert(type_data, st3)
		 end
	      end
	      m=k+1
	   end
       end
       if (#st-m) >= 1 then
	  st2 = sub(st, m)
	  st3 = find_type(st2)
          table.insert(table_data, sub(st, m) )
	  if lines == 1 then 
	     table.insert(type_data, st3)
	 end
       else
	  st2=""
	  st3 = find_type(st2)
	  table.insert(table_data, "" )
	  if lines == 1 then 
	     table.insert(type_data, st3)
	  end
       end
       lines = lines+1
       d = j+size_eol
    else
       break
    end
  end

 
  
print("Nb de lignes = " .. lines .. "\nNb de colonnes = " .. cols .. "\nNb de cellules = " .. #table_data)  
  return lines, cols
end --end function

function load_data()
  local st, sysfile = "", ""
  local nbl,nbc = 0, 0

--[[  
  if osName == "OS=linux" then
     --filename = "/home/terras/scripts-murgaLua/database_80.csv"
     --filename = "/home/terras/scripts-murgalua/fileactive_2017.csv"
     --filename = "/home/terras/Téléchargements/Documentation-DIM/_0_ACTIONS/gestion_deces_SCA_2020/DC_HM-ONEFILE_1970_2019.csv"
    filename = "/home/terras/DC_HM-ONEFILE_1970_2019.csv"
     --NIPP NOMUSUPRENOM NOMNAISPRENOM SEXE DATENAIS DATEDCHM DATEDCINSEE NIR_HM

  end
  if osName == "OS=windows" then
     filename = "G:\\Dim\\dsl-not\\scripts-murgaLua\\export_150420.csv"
  end
  ]]--
  
  filename = fltk.fl_file_chooser("selecteur de fichier", "CSV Files (*.{csv,CSV})", SINGLE, nil) --place de SINGLE ?
  
  local f = 0
  local i = 0
  local j = 0
  local k = 0
  local pos=1
  local posc=1
  read_data = ""
  local str
  if filename then
     f = io.open(filename,"rb")
     if f then
        read_data = f:read("*all")
        read_data = string.upper(read_data)
        print("Lecture reussie pour le fichier " .. filename .. ", taille=" .. #read_data .. " octets")
        io.close(f)
        sysfile = define_textfile_origin(read_data)
        print("Origine systeme du fichier = " .. sysfile )
        nbl, nbc = find_col_lines_csv(read_data)
	
	pertinence_separator(read_data) --check if separator is the good one
	
        return nbl, nbc
     else
        print("Inexistence du fichier " .. filename)
        return nil, nil
     end
  else
    return nil, nil
  end
end --end function

function change_diagr()
  local i, type_diag, st
  
  if pwindow and pie then
     i = pie:type()
     if i<6 then
        pie:type(i+1)
     else
        pie:type(0)
     end
     pie:redraw()
     pie:show()
     Fl:check()
  end
  type_graphics = i+1
  nextbutton:label(label_chart[type_graphics])
  nextbutton:redraw()
  
  pwindow:show()
end --end function

function quit_callback_app()
  if pwindow then
     pwindow:hide()
     pwindow:clear()
     if twindow then
        twindow:hide()
        twindow:clear()
     end
     print("Quiting?")
     os.exit(0)
  end
end --end function

  t00 = os.time() --top chrono

  --version FLTK
  print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. fltk.FL_PATCH_VERSION)
  --premiere partie : chargement des données  
  li, co = load_data()
  if li and co then
     print("cols=" .. co .. " // lines=" .. li)
     stats_0_csv()
     disp_sample_csv()
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

  --fenetre graphique pour les diagrammes
  pwindow = fltk:Fl_Window(width_pwindow, height_pwindow, "Analyse graphique par diagrammes")
  
  --centrage du bouton en bas de la fenetre pwindow
  --i = (width_pwindow/2)-(width_button/2)
  width_button = 100
  quit = fltk:Fl_Button(dec_button+10, height_pwindow-30, width_button, 25, "Quitter")
  quit:tooltip("Quitter cette appli!")
  quit:callback(quit_callback_app)
  
  width_button = 180
  nextbutton = fltk:Fl_Button(dec_button+115, height_pwindow-30, width_button, 25, "type diagr")
  nextbutton:tooltip("Changer le diagramme!")
  nextbutton:callback(change_diagr)
  nextbutton:label(label_chart[type_graphics])
  
  width_button = 30
  dec_button = dec_button+115+190
  testbutton1 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@filesave")
  dec_button = dec_button+35
  testbutton2 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@search")
  dec_button = dec_button+35
  testbutton3 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@fileprint")
  dec_button = dec_button+35
  testbutton4 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@refresh")
  dec_button = dec_button+35
  testbutton5 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@fileopen")
  
  
  pie = fltk:Fl_Chart(0, 0, 5, 5, nil)

--[[
  --st="Ceci est un test de message d'alerte"
  st=""
  for i=1,#type_chart do
    st = st .. "type[" .. i .. "] = " .. type_chart[i] .. ", "
  end
  fltk:fl_alert(st)
  ]]

  pie:position(decx_chart, decy_chart)
  pie:size(width_chart, height_chart)
  pie:label("label de pie")
  pie:type( type_chart[type_graphics] )
  pie:box(3)
  pie:labelcolor(1)
  for i=1,10 do
      st = "[" .. i .. "] " .. demo_table[i]
      pie:add(demo_table[i], st, i) -- ORDRE = value, label and colour
  end

  --Fl:check()
  pwindow:show()
  
Fl:check()
Fl:run()

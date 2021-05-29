#!/bin/murgaLua
i=0
f=0

--sorted table, by values 
type_chart = { fltk.FL_BAR_CHART, fltk.FL_LINE_CHART, fltk.FL_FILLED_CHART, fltk.FL_SPIKE_CHART, fltk.FL_PIE_CHART, fltk.FL_SPECIALPIE_CHART, fltk.FL_HORBAR_CHART}
--label_chart = { "FL_HORBAR_CHART", "FL_LINE_CHART", "FL_FILLED_CHART", "FL_SPIKE_CHART", "FL_PIE_CHART", "FL_SPECIALPIE_CHART", "FL_BAR_CHART" }
label_chart = { "FL_BAR_CHART", "FL_LINE_CHART", "FL_FILLED_CHART", "FL_SPIKE_CHART", "FL_PIE_CHART", "FL_SPECIALPIE_CHART", "FL_HORBAR_CHART" }

sep_end="\n"
sep_begin="------------------"
  
keyword={ "SELECT", "FROM ", "WHERE ", "GROUP BY", "ORDER BY ", "JOIN ", " AS ", "(SELECT ", "SUM(CASE WHEN", "COUNT(", "HAVING SUM(", "HAVING COUNT(", "WITH "}
hm_tables={"ide_patient", "ide_sejour", "bas_catalogue_gen", "bas_catalogue_pers","bas_type_info","ide_etablissement_exterieur",
           "bas_etablissement", "Bas_prof_appl_util","bas_profil","bas_utilisateur","Ide_medecin","Ide_adresse","Ide_telephone",
	   "Bas_ville","ide_mouvement","Pms_evenement","Ide_ald",
	   
           "Med_isolement_registre","med_isolement_mesure","med_isolement_contention",

	   "bas_uf","Bas_utilisateur","Bas_util_uf_visu","Bas_util_uf_init","pad_lit_poste","pad_chambre_salle","bas_parametre","Pad_fermeture",
	   
           "Pre_prescription_acte_examen","pre_prescription_ligne","pre_prescription_liste","pre_prescription_periode","pre_prescription_detail",
	   "Pre_produit_medic_cip13","Bas_param_acte_medical","Pre_livret","pha_fiche_produit","pre_plan_soins_unitaire",
	   
	   "med_fic_observation","bas_param_uf_ficobs",
	   
	   "Frm_instance_formulaire","frm_formulaire","Frm_valeur","Bas_catalogue_util_data","frm_instance_rubrique","frm_formulaire_rubrique",
	   "bas_document","Bur_document_compo","bur_document_rattachement","bur_modele_type","bur_document_signataire","Bas_entite_etat","bur_document_des",
	   "pms_edgar","pms_edgar_acte","pms_raa","pms_edgar_medecin","sad_recueil","bas_uf","sad_diag_saisi","pms_mode_legal","Pms_rps_ps","sad_um","bas_secteur","pms_presence_ps","pms_presence_jour_ps",
	   
	   "Scl_trace","Bas_trace_action",
	   
	   "Ide_fusion_patient",
	   
	   "pre_constante","Soi_constante_cat","soi_constante_dictionnaire",
	   
	   "bas_competence","bas_role","bas_param_acte_nomenclature","bas_param_acte_plateau",
	   
	   "ser_groupe_resultat","ser_resultat", "ser_valeur",
	   
	   "Sid_psy_calendar"
	   }
print("Nb de tables indexées = " .. #hm_tables)

table_domains={"gestion patients/utilisateurs",
               "isolement, contention",
	       "gestion unites",
	       "prescriptions",
	       "observations",
	       "formulaires",
	       "bureautique",
	       "PMSI",
	       "supervisions",
	       "identito",
	       "constantes",
	       "HM agenda",
	       "HM biologie",
	       "dimension temps"
               }
bornes_tables_domaines={17,20,28,38,40,46,53,66,68,69,72,76,79,80}
nb_query_domain={}

--print("Nb de domaines fonctionnels = " .. #table_domains/2)
print("Nb de domaines fonctionnels = " .. #table_domains)

for i=1,#table_domains do
    nb_query_domain[i] = 0
end

comments={"/*", "--"}
potential_errors={"=>"}

query={}
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
upper = string.upper

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

  if twindow then
     twindow:hide()
     twindow:clear()
  end
  --fenetre graphique pour la restitution du tableau CSV
  width_twindow = 1024
  height_twindow = 250
  twindow = fltk:Fl_Window(width_twindow, height_twindow, "Tableau CSV")
  --width_button = 120
  width_button = math.floor(width_twindow/co)
  height_button = 20
  --nb_car = width_button/10 --nb cars affichables dans la largeur du bouton
  nb_car = width_button/11 --nb cars affichables dans la largeur du bouton
  
  t_quit = fltk:Fl_Button(10, height_twindow-30, width_button, 25, "Quitter")
  t_quit:tooltip("Fermer cette fenetre")
  t_quit:callback(quit_t)
  
  t_quote = fltk:Fl_Button(width_button+12, height_twindow-30, width_button, 25, "Dispo")
  t_quote:tooltip("Dispo")

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
      st = type_data[ j ] .. "\n" .. type_date[ j ]
      cell[ #cell ]:tooltip( st )
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
  
  Fl:check()
  twindow:show()
end --end function

function is_date(st, cols)
  local lines, pos
  local size,dd,mm,yy
   --size of data and original type of data is important
   --line 1 "legendes" excuded

   size = #st
   if size == 6 then
      --2 options ddmmyy or yymmdd
      mm = tonumber( sub(st,3,4) )
      --option ddmmyy
      dd = tonumber( sub(st,1,2) )
      yy = tonumber( sub(st,5,6) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=0 and yy<=99 then
           type_date[ cols ] = "ddmmyy"
	   return 1
         end
      end
      --option yymmdd
      dd = tonumber( sub(st,5,6) )
      yy = tonumber( sub(st,1,2) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=0 and yy<=99 then
            type_date[ cols ] = "yymmdd"
	    return 1
         end
      end
  elseif size == 8 then
      --4 options ddmmyyyy or yyyymmdd or yy-mm-dd or dd-mm-yy
      --ddmmyyyy
      dd = tonumber( sub(st,1,2) )
      mm = tonumber( sub(st,3,4) )
      yy = tonumber( sub(st,5,8) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=1800 and yy<=2100 then
            type_date[ cols ] = "ddmmyyyy"
	    return 1
         end
      end
      --yyyymmdd
      dd = tonumber( sub(st,7,8) )
      mm = tonumber( sub(st,5,6) )
      yy = tonumber( sub(st,1,4) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=1800 and yy<=2100 then
            type_date[ cols ] = "yyyymmdd"
	    return 1
         end
      end
      --yy-mm-dd
      dd = tonumber( sub(st,7,8) )
      mm = tonumber( sub(st,4,5) )
      yy = tonumber( sub(st,1,2) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=0 and yy<=99 then
            type_date[ cols ] = "yy-mm-dd"
	    return 1
         end
      end
      --dd-mm-yy
      dd = tonumber( sub(st,1,2) )
      mm = tonumber( sub(st,4,5) )
      yy = tonumber( sub(st,7,8) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=0 and yy<=99 then
            type_date[ cols ] = "dd-mm-yy"
	    return 1
         end
      end
   elseif size == 10 then
      --2 options dd-mm-yyyy or yyyy-mm-dd
      --dd-mm-yyyy
      dd = tonumber( sub(st,1,2) )
      mm = tonumber( sub(st,4,5) )
      yy = tonumber( sub(st,7,10) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=1800 and yy<=2100 then
	    type_date[ cols ] = "dd-mm-yyyy"
	    return 1
         end
      end
      --yyyy-mm-dd
      dd = tonumber( sub(st,9,10) )
      mm = tonumber( sub(st,6,7) )
      yy = tonumber( sub(st,1,4) )
      if dd and mm and yy then
         if dd>=1 and dd<=31 and mm>=1 and mm<=12 and yy>=1800 and yy<=2100 then
	    type_date[ cols ] = "yyyy-mm-dd"
	    return 1
         end
      end
  else
      --not date
      type_date[ cols ] = ""
      return nil
  end 

end --end function

function stats_0_csv()
  local i,j,k,l
  local query_key={}
  local table_used={}
  local query_ok={}
  local query_domains={}
  local st1,st2,st3
  
  
  if #query <=1 then
     return 0
  end

  --initialisations des tables de stats
  for i=1,#query do
      query_key[ i ] = "*"
      table_used[ i ] = "*"
      query_domains[ i ] = "*"
      query_ok[ i ] = 0
  end
  --debut analyse
  for i=1, #query do
      st1 = upper(query[ i ])
      if find(st1, "NICKEL",1,true) then
	 query_ok[ i ] = 1
      elseif find(st1, ":OK",1,true) then
	 query_ok[ i ] = 1
      elseif find(st1, " OK",1,true) then
	query_ok[ i ] = 1
      else
	query_ok[ i ] = 0
      end
      for j=1,#keyword do
         st2 = upper(keyword[ j ])
         if find( st1, st2,1,true) then
            query_key[ i ] = query_key[ i ] .. j .. "*"
         end
      end
      for j=1,#hm_tables do
          st2 = upper(hm_tables[ j ])
          if find( st1, st2,1,true) then
             table_used[ i ] = table_used[ i ] .. j .. "*"
	     --search domain's table
	     for k=1,#bornes_tables_domaines do
	         st3 = "*" .. k .. "*"
	         if k==1 then
		    if j <= bornes_tables_domaines[ k ] then
		       if find(query_domains[ i ],st3,1,true) then
			  --nothing
		       else
		          query_domains[ i ] = query_domains[ i ] .. k .. "*"
			  nb_query_domain[k] = nb_query_domain[k]+1
		       end
		    end
		 else
		    if j>bornes_tables_domaines[ k-1 ] and j<=bornes_tables_domaines[ k ] then
		       if find(query_domains[ i ],st3,1,true) then
			  --nothing
		       else
		          query_domains[ i ] = query_domains[ i ] .. k .. "*"
			  nb_query_domain[k] = nb_query_domain[k]+1
		       end
		    end
		 end
	     end
          end     
      end
  end
--[[
  for i=1,#query do
      print("query[ " .. i .. " ] (taille=" .. #query[i] .. "), query_key = " .. query_key[ i ] .. ", table_used = " .. table_used[ i ] .. ", req. fonctionnelle=" .. query_ok[ i ] .. ", domaines requete=" .. query_domains[ i ])
  end]]
end -- end function

function find_queries(data)
  local i,st
  local pos1,pos2,pos3 = 1,1,1
  lines_req=0
  lines=0
  
  sep_end="\n"
  sep_begin="------------------"
  
  st=""  
  pos1 = 1
  while 1 do
     pos1 = find(data, sep_end, pos1, true)
     if pos1 then
        pos2 = find(data, sep_begin, pos1+1, true)
        if pos2 then
	   pos3 = find(data, "\n", pos2, true)
           st = sub(data, pos1+1,pos2-1)
	   if #st > 0 then
              table.insert(query,st)
--print("Nb of queries " .. #query .. ", current query = " .. query[ #query ])
	   end
           pos1 = pos3+1
        else -- last query
           st = sub(data, pos1+1)
           table.insert(query,st)
           break
        end
     else
        break
     end
  end
  
print("Nb de requetes = " .. #query)
--[[
  for i=1,#query do
print("query[" .. i .. "] = " .. query[ i ])
  end]]
  
  return
end --end function

function load_data()
  local st, sysfile = "", ""
  local linecmd, res, f, buffer
  filename=nil
  
  if osName == "OS=linux" then
     linecmd = "hostname > temp.txt";
     res = os.execute(linecmd)
     if res == 0 then
        f = io.open("temp.txt", "rb")
        if f then
           buffer = f:read("*all")
print("Hostname ? " .. buffer)
	   if find(buffer, "terras-Aspire-5733Z",1,true) then
	      filename = "/home/terras/scripts-murgalua/requetes_HQL_for_analyse_240521.txt" -- ACER
	   elseif find(buffer, "HP6200",1,true) then
	      filename = "/home/terras/scripts-murgaLua/requetes_HQL_for_analyse_240521.txt" --HP
	   else
	      filename=nil
	   end
           io.close(f)
	end
     end
  end
  if osName == "OS=windows" then
     filename = "G:\\Dim\\dsl-not\\scripts-murgaLua\\requetes_HQL_for_analyse_240521.txt"
  end
  
  --bypassing file_chooser
  --filename = fltk.fl_file_chooser("selecteur de fichier", "CSV Files (*.{csv,CSV})", SINGLE, nil) --place de SINGLE ?
  --filename = fltk.fl_file_chooser("selecteur de fichier", "TXT Files (*.{txt,TXT})", SINGLE, filename) --place de SINGLE ?
  
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
     if table_data then
        table_data = nil
        table_data={}
     end
      
     f = io.open(filename,"rb")
     if f then
        read_data = f:read("*all")
        read_data = string.upper(read_data)
        print("Lecture reussie pour le fichier " .. filename .. ", taille=" .. #read_data .. " octets")
        io.close(f)
        sysfile = define_textfile_origin(read_data)
        print("Origine systeme du fichier = " .. sysfile )
        find_queries(read_data)
	stats_0_csv()
        return
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

function sort_chart_tables(legend, tabl)
  local i, j, st, st2, valmax, idxmax
  local leg={}
  local tab={}
  buffer_processed = "*"
  
  --classifier code
  for i=1,#tabl do
      st = "*" .. i .. "*"
      if find(buffer_processed, st,1,true) == nil then
         valmax = tabl[ i ]
         idxmax = i
         for j=1,#tabl do
	     if j ~= i then
	        if tabl[j] > valmax then
		   st2 = "*" .. j .. "*"
		   if find(buffer_processed, st2,1,true) == nil then
	              valmax = tabl[ j ]
		      idxmax = j
		   end
	        end
	     end
	 end
	 if idxmax then
            table.insert(tab, tabl[ idxmax ])
            table.insert(leg, legend[ idxmax ])
            buffer_processed = buffer_processed .. idxmax .. "*"
	 end
      end
  end
  for i=1,#tab do
      print("tab[" .. i .. "] = " .. tab[i])
  end
  print("buffer_processed = " .. buffer_processed)
  return leg,tab
end --end function 

function disp_chart(titre, titrecolor, legend, tabl, type_graphics)
  local i, j, st
  local leg={}
  local tab={}

  --before visualization, sort both tables tabl AND legend "Descending order"
  leg,tab = sort_chart_tables(legend, tabl)
  
  pie = fltk:Fl_Chart(0, 0, 5, 5, nil)
  pie:position(decx_chart, decy_chart)
  pie:size(width_chart, height_chart)
  if titre then
     pie:label(titre)
  end
  pie:type( type_chart[type_graphics] )
  pie:box(3)
  pie:labelcolor(256)--title color
  
  --print("table.concat(legend) = " .. table.concat(legend,'*') .. " // table.concat(tabl) = " .. table.concat(tabl,'*'))
  --[[
  for i=1,#legend do
      if tabl[i] then
	 if math.log( tabl[i] ) then
	    --j = math.floor(math.log( tabl[i] ))
	    j = tabl[i]
	 else
	    j = tabl[i]
	 end
      else
	j = 0
      end
      st = legend[ i ] .. ", " .. j
      pie:add(j, st, i) -- ORDER = value, label and colour
  end]]
  for i=1,#leg do
      if tab[i] then
	 if math.log( tab[i] ) then
	    --j = math.floor(math.log( tabl[i] ))
	    j = tab[i]
	 else
	    j = tab[i]
	 end
      else
	j = 0
      end
      st = leg[ i ] .. ", " .. j
      pie:add(j, st, i) -- ORDER = value, label and colour
  end
  
end --end function

function quit_callback_app()
  --[[
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
  end]]
  os.exit(0)
end --end function

  t00 = os.time() --top chrono

  --version FLTK
  print("Fltk version "  .. fltk.FL_MAJOR_VERSION .. "." .. fltk.FL_MINOR_VERSION .. fltk.FL_PATCH_VERSION)
  --premiere partie : chargement des données  
  load_data()
  if #query > 1 then
     --disp_sample_csv()
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
  testbutton2:tooltip("Visualiser la structure du CSV")
  testbutton2:callback(disp_sample_csv)
  dec_button = dec_button+35
  testbutton3 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@fileprint")
  dec_button = dec_button+35
  testbutton4 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@refresh")
  dec_button = dec_button+35
  testbutton5 = fltk:Fl_Button(dec_button, height_pwindow-30, width_button, 25, "@fileopen")
  testbutton5:tooltip("Ouvrir un autre fichier")
  testbutton5:callback(load_data)

--[[
  --st="Ceci est un test de message d'alerte"
  st=""
  for i=1,#type_chart do
    st = st .. "type[" .. i .. "] = " .. type_chart[i] .. ", "
  end
  fltk:fl_alert(st)
  ]]  
  
  type_graphics = 7
--print("#table_domains = " .. #table_domains .. ", table.concat(nb_query_domain) = " .. table.concat(nb_query_domain,"//"))
  disp_chart("Nb of distincts values Histogram, by cols", textcolor, table_domains, nb_query_domain, type_graphics)
--for i=1,#table_domains do
--    nb_query_domain[i] = 0
--end

  --Fl:check()
  pwindow:show()
  
Fl:check()
Fl:run()

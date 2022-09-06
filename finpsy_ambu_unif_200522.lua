#!/bin/murgaLua
--Calculs pour le FINANCEMENT PSY MAI 2022-AMBULATOIRE ETAB
-- calculer les exclusions : > 730 actes cumulés
--                          >= 15 actes journaliers
--integration des 3eme et 4eme criteres PECI : 
----> 3 semaines actives pour les 15 actes
----> suppression le 110722 de la fonction calcul_peci(buffer_dates_peci), obsolète
----> 2 intervenants au moins pour CHACUN des 15 actes : NON, pas sur cette version !!!
------------> implémentation d'un critère PECI de 2 intervenants AU MOINS sur la période des 15 actes le 300722
------------> présence de 2 intervenants AU MOINS sur une des 3 semaines actives (actes avec 2 intervenants de la même catégorie professionnelle inclus)

version_pluri_intervenant="PLURI_INTERV" -- autre valeur="PLURI_INTERV" / "PLURI_CAT_PRO"
 
i=0

find = string.find
sub = string.sub

read_data = "" --tampon de lecture
size_eol = 0 -- varie selon Unix (MacOs) ou Windows

format_RAA = ""
Annee_RAA=0


ipp={}						---------------- MAJEURS
ipp_730actes={}
ipp_exclus_15aj={}
ipp_ega_HORS_06_09_10_HS={}
ipp_ega_HORS_06_09_10_HS_2i={} -- actes EGA 2 intervenants
ipp_ega_HLS_HS={}
ipp_ega_DR_HS={}
ipp_ega_peci={}  --patients avec au moins 15 actes effectués sur 3 semaines avec au moins 12 jours actifs et au moins 2 intervenants 
--dernier tableau files actives et actes L06, L09 et L10
ipp_L06={} --centre pénitentiaire
ipp_L09={} --psy de liaison
ipp_L10={} --SAU
nb_RAA_L06, nb_RAA_L09, nb_RAA_L10 = 0,0,0

buffer_dates_peci="" --tampon pour les date d'actes = au moins 12 jours distincts
buffer_weeks_peci="" --tampon pour les semaines d'actes = au moins 3 semaines distinctes (N° de semaine de l'annee)

nb_ipp_ega_HORS_06_09_10_HS=0
nb_ipp_ega_HORS_06_09_10_HS_2i=0
nb_ipp_exclus_730a=0
total_actes_ega_HORS_06_09_10_HS=0

ipp_min={}					---------------- MINEURS
ipp_730actes_min={}
ipp_exclus_15aj_min={}
ipp_ega_HORS_06_09_10_HS_min={}
ipp_ega_HORS_06_09_10_HS_2i_min={} -- actes EGA 2 intervenants
ipp_ega_HLS_HS_min={}
ipp_ega_DR_HS_min={}
ipp_ega_peci_min={}   --patients avec au moins 15 actes effectués sur 3 semaines avec au moins 12 jours actifs et au moins 2 intervenants 

nb_ipp_ega_HORS_06_09_10_HS_min=0
nb_ipp_ega_HORS_06_09_10_HS_2i_min=0
nb_ipp_exclus_730a_min=0
total_actes_ega_HORS_06_09_10_HS_min=0


buffer_ipp=""
nbpati=0 -- nb de patients distincts
buffer_ipp_min=""
nbpati_min=0 -- nb de patients distincts
buffer_ipp_L06=""
buffer_ipp_L09=""
buffer_ipp_L10=""

filename=""

borne={1,3,7,13,25,37,53}
--1er  intervalle >=2 et <3
--2ème intervalle >=3 et <7
--3ème intervalle >=7 et <13
--etc...
--7 intervalles correspondants = 1-2, 3-6, 7-12, 13-24, 25-36, 37-52, 53 et plus 
effectifs_gr={}
actes_gr={}
peci_gr={}
pati_gr_HLS={}
actes_gr_HLS={}
pati_gr_DR={}
actes_gr_DR={}
effectifs_gr_min={}
actes_gr_min={}
peci_gr_min={}
pati_gr_HLS_min={}
actes_gr_HLS_min={}
pati_gr_DR_min={}
actes_gr_DR_min={}
for i=1,#borne do
    effectifs_gr[i]=0
    actes_gr[i]=0
    peci_gr[i]=0
    pati_gr_HLS[i]=0
    actes_gr_HLS[i]=0
    pati_gr_DR[i]=0
    actes_gr_DR[i]=0
    effectifs_gr_min[i]=0
    actes_gr_min[i]=0
    peci_gr_min[i]=0
    pati_gr_HLS_min[i]=0
    actes_gr_HLS_min[i]=0
    pati_gr_DR_min[i]=0
    actes_gr_DR_min[i]=0
end

--tampons d'écriture pour les fichiers texte et csv de sauvegarde
txt_buffer = ""
csv_buffer = ""
separator = ";"






osName="OS=" .. murgaLua.getHostOsName()

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
     size_eol=2 -- for windows remove CR+LF at end of line
     return("windows")
  else
--print("Ce fichier a ete genere par un Unix-like => size_eol=1")
     size_eol=1 -- for unixes remove only LF(?)
     return("unix")
  end
end --end function

function get_years_between_acte_and_birth(date_acte, date_nais)
  local d,y,m
  local reference1,reference2,daysfrom, wholedays, age_year
  
  if date_acte then
     d=tonumber(sub(date_acte,1,2))
     m=tonumber(sub(date_acte,3,4))
     y=tonumber(sub(date_acte,5,8))
     reference2 = os.time{day=d, year=y, month=m}
  end
  if date_nais then
     d=tonumber(sub(date_nais,1,2))
     m=tonumber(sub(date_nais,3,4))
     y=tonumber(sub(date_nais,5,8))
     reference1 = os.time{day=d, year=y, month=m}
  end
  age_year = os.difftime(reference1, reference2) / (24*60*60*365.25) -- seconds in a year
  return(age_year) 
end  --end function  

function get_weeknumber_from_day(passed_date)
local d1,m1,y1,ref1,ref2,w

--st = " fonction get_weeknumber_from_day"
--fltk:fl_alert(st)

d1=tonumber(sub(passed_date,1,2))
m1=tonumber(sub(passed_date,3,4))
y1=tonumber(sub(passed_date,5,8))
ref1 = os.time{day=d1, year=y1, month=m1}
ref2 = os.time{day=1, year=y1, month=1}
w = math.floor( os.difftime(ref1, ref2) / (24*60*60*7) ) -- delta en semaines entre les dates
--week = "*" .. string.format('%02d', math.floor(w) )

return(w)
end -- end function

function get_RAA_format()
 local j, line_raa

 --analyse de la premiere ligne qui contient les infos de format et d'annee
 j = find(read_data,"\n",1)
 if j then
    line_raa = sub(read_data, 1, j-1)
	format_RAA = sub(line_raa,19,21)
	if format_RAA == 'P10' or format_RAA == 'P09' then
	   Annee_RAA = sub(line_raa,72,75) --on extrait l'année du premeier acte position 68 à 75
	elseif format_RAA == 'P14' then
	   Annee_RAA = sub(line_raa,74,77) --on extrait l'année du premeier acte position 68 à 75
	else 
	   format_RAA=""
	   Annee_RAA=0
	end
	
 end
 if format_RAA ~= "" and Annee_RAA ~= 0 then
     st = "Format de fchier RAA " .. format_RAA .. "\nAnnee des actes " .. Annee_RAA
    fltk:fl_alert(st)
 else
    st = "Format de fchier RAA inconnu !\nAbandon"
    fltk:fl_alert(st)
	exit(0)
 end
end --end function

function get_data_from_line_RAA( line_raa )
 local ipp_local,date_nais_local,sexe_local,date_acte_local,nature_acte_local,lieu_acte_local,catprof_local, nb_intervenants
 if format_RAA == 'P14' then
    ipp_local = sub(line_raa,22,27) --ATTENTION format RAA PO14
    date_nais_local = sub(line_raa,42,49)
    --sexe_local = sub(line_raa,50,50)
    date_acte_local = sub(line_raa,70,77)
    nature_acte_local = sub(line_raa,78,79)
    lieu_acte_local = sub(line_raa,80,82)
    --modalite_acte_local = sub(line_raa,83,83)
    catprof_local = sub(line_raa,84,84)
    nb_intervenants = tonumber( sub(line_raa,85,85) )
    age_acte = math.floor(get_years_between_acte_and_birth(date_nais_local, date_acte_local))
 end
 if format_RAA == 'P10' then
    ipp_local = sub(line_raa,22,27) --ATTENTION format RAA 2021 = P10
    date_nais_local = sub(line_raa,42,49)
    --sexe_local = sub(line_raa,50,50)
    date_acte_local = sub(line_raa,68,75)
    nature_acte_local = sub(line_raa,76,76)
    lieu_acte_local = sub(line_raa,77,79)
    --modalite_acte_local = sub(line_raa,80,80)
    catprof_local = sub(line_raa,81,81)
    nb_intervenants = tonumber( sub(line_raa,82,82) )
	age_acte = math.floor(get_years_between_acte_and_birth(date_nais_local, date_acte_local))
 end
 if format_RAA == 'P09' then
    ipp_local = sub(line_raa,22,27) --ATTENTION format RAA 2018 = P09
    date_nais_local = sub(line_raa,42,49)
    --sexe_local = sub(line_raa,50,50)
    date_acte_local = sub(line_raa,68,75)
    nature_acte_local = sub(line_raa,76,76)
    lieu_acte_local = sub(line_raa,77,79)
    --modalite_acte_local = sub(line_raa,80,80)
    catprof_local = sub(line_raa,80,80)
    nb_intervenants = tonumber( sub(line_raa,81,81) )
	age_acte = math.floor(get_years_between_acte_and_birth(date_nais_local, date_acte_local))
 end
 return ipp_local,date_nais_local,date_acte_local,nature_acte_local,lieu_acte_local,catprof_local, nb_intervenants, age_acte
end --end function

function calcul_peci3(buffer_jours_peci_comp)
local i, j, k, l, m, n,p,q
local  sem, date_acte, str, str2, code_sem, nb_actes
local buffer_week=""
local buffer_week_multipro=""
local buffer_day=""
local nb_jours=0
local s1,s2,s3
local plurimono="M"
local nb_jours_distincts_semaine=0
local buffer_week_details=""
local jours_distincts_d_actes_semaine={}
local actes_distincts_semaine={}
local semaine_pluri_mono={}

--initialisation tables
for i=0,54 do
    jours_distincts_d_actes_semaine[i]=0
    actes_distincts_semaine[i]=0
    semaine_pluri_mono[i]="M" --par défaut => mono-professionnel
end

--print("buffer_jours_peci_comp = " .. buffer_jours_peci_comp)

-- on va transformer ce buffer "jours d'acte" en buffer semaine avec les infos suivantes :
-- *01P0405
-- * = caractère de début de semaine,
--01 = (%02d) = N° de semaine dans l'année
--P = au moins un acte Pluriprofessionnel, sinon M
--04 = (%02d) = nb d'actes effectués dans la semaine (sans double compte)
--05 = (%02d) = nb de jours actifs de la semaine = avec au moins un acte

m = #buffer_jours_peci_comp-(14*10) -- taille date_PECI=10, on remonte à 14 jours avant la fin du buffer
--st = " fonction calcul_peci"
--fltk:fl_alert(st)

-- construction la plus récente --------------------------
for i=1,#buffer_jours_peci_comp,10 do
     str = sub(buffer_jours_peci_comp,i+1, i+8) -- jour d'acte
     plurimono = sub(buffer_jours_peci_comp,i+9, i+9) -- "P" pour pluri, "M" pour mono
     
     if str then
        sem = get_weeknumber_from_day(str)
        code_sem = "*" .. string.format('%02d', sem)
        if plurimono == "P" then
           semaine_pluri_mono[ sem ] = "P"
        end
        if find(buffer_week, code_sem) then
           --on ne fait rien pour le tampon, code semaine deja present dans le tampon
        else
           buffer_week = buffer_week .. code_sem
        end
        --on incrémente le nb d'actes de la semaine
        actes_distincts_semaine[ sem ]=actes_distincts_semaine[ sem ]+1
        
        str2 = "*" .. str
        if find(buffer_day, str2) then
           --on ne fait rien, jour deja present dans le tampon
        else
           buffer_day = buffer_day .. str2
           --nb_jours = nb_jours+1
           --on incrémente le nb de jours distincts actifs  de la semaine
           jours_distincts_d_actes_semaine[ sem ] = jours_distincts_d_actes_semaine[ sem ]+1
        end
     end
end
--construction la plus récente du tampon semaine du patient (IPP)
for i=0,54 do
     if jours_distincts_d_actes_semaine[ i ] ~= 0 then
        buffer_week_details = buffer_week_details .. "*" .. string.format("%02d", i) .. semaine_pluri_mono[ i ] .. string.format("%02d",actes_distincts_semaine[ i ]) .. string.format("%02d",jours_distincts_d_actes_semaine[ i ])
     end
end
--print("buffer_week_details = " .. buffer_week_details)

-- -- analyse de ce buffer ---------------------------------------
for i=1,#buffer_week_details,8 do
     s1_num = tonumber( sub(buffer_week_details, i+1, i+2) )
     s1_pluri = sub(buffer_week_details, i+3, i+3)
     s1_actes = tonumber( sub(buffer_week_details, i+4, i+5) )
     s1_jours = tonumber( sub(buffer_week_details, i+6, i+7) )
     
     if #buffer_week_details <= (i +24) then
        s2_num = tonumber( sub(buffer_week_details, i+9, i+10) )
        s2_pluri = sub(buffer_week_details, i+11, i+11)
        s2_actes = tonumber( sub(buffer_week_details, i+12, i+13) )
        s2_jours = tonumber( sub(buffer_week_details, i+14, i+15) )

        s3_num = tonumber( sub(buffer_week_details, i+17, i+18) )
        s3_pluri = sub(buffer_week_details, i+19, i+19)
        s3_actes = tonumber( sub(buffer_week_details, i+20, i+21) )
        s3_jours = tonumber( sub(buffer_week_details, i+22, i+23) )
        --critères finaux PECI
        if s2_num == (s1_num+1) and s3_num == (s1_num+2) then --3 semaines consécutives
           if s1_pluri == "P" or s2_pluri == "P" or s3_pluri == "P" then --au moins 2 intervenants
              if (s1_actes + s2_actes + s3_actes) >= 15 then --au moins 15 actes
                 if (s1_jours + s2_jours + s3_jours) >= 12 then --au moins 12 jours actifs
print("PECI !!! " .. s1_num,s2_num,s3_num)              -------------------------------------------------------------------------------- PT CONTROLE 
	                return(1) --3 semaines consecutives
                 end
              end
           end
        end
--    else
--          break
     end
end
return(0)
-- FIN construction la plus récente --------------------------

end --end function

function process(line_raa)
 local i,str,pos,age
 local idx=1
 local ipp_local,date_nais_local,sexe_local,date_acte_local,nature_acte_local,lieu_acte_local,catprof_local, nb_intervenants
 --local modalite_acte_local
 
--st = line_raa .. " envoyee a la fonction process()"
--fltk:fl_alert(st)
 
  if line_raa then 
     ipp_local,date_nais_local,date_acte_local,nature_acte_local,lieu_acte_local,catprof_local, nb_intervenants, age_acte = get_data_from_line_RAA( line_raa )
  end
  
  str = "*" .. ipp_local
  
  if age_acte >= 18 then 
     pos = find(buffer_ipp, str, 1, true)
     if pos then
        --ipp deja comptabilise : trouver l'index table (methode 1)
        idx = (pos+6)/7
     else
        --nouveau patient
        --ajout ipp au buffer et à la table + initialisation des compteurs patient
        nbpati = nbpati+1
        buffer_ipp = buffer_ipp .. "*" .. ipp_local
--print(buffer_ipp)
        table.insert(ipp, ipp_local)
        table.insert(ipp_ega_HORS_06_09_10_HS, 0)
		table.insert(ipp_ega_HORS_06_09_10_HS_2i, 0)
        table.insert(ipp_ega_HLS_HS, 0)
        table.insert(ipp_ega_DR_HS,0)
        idx = #ipp
--st = idx .. " = rang nouveau patient"
--fltk:fl_alert(st)
     end
--st = idx .. " /" .. nbpati .. " /".. #ipp .. " = index patient / nb_patients / #ipp  etape 2 : nouveau patient ou pas ?"
--fltk:fl_alert(st)
  
     if sub(nature_acte_local,1,1) == 'E' or sub(nature_acte_local,1,1) == 'G' or sub(nature_acte_local,1,1) == 'A' then
	--if lieu_acte_local == 'L01' or lieu_acte_local == 'L02' or lieu_acte_local == 'L11' then
        if lieu_acte_local ~= 'L09' and lieu_acte_local ~= 'L10' and lieu_acte_local ~= 'L06' then
           if catprof_local ~= 'S' then
              ipp_ega_HORS_06_09_10_HS[ idx ] = ipp_ega_HORS_06_09_10_HS[ idx ] +1
			  if nb_intervenants >=2 then 
			     ipp_ega_HORS_06_09_10_HS_2i[ idx ] = ipp_ega_HORS_06_09_10_HS_2i[ idx ] +1
			  end
           end 
        end	 
     end
     ---calcul bonus HORS LIEUX DE SOINS L03,L04,L05,L07,L08
     if sub(nature_acte_local,1,1) == 'E' or sub(nature_acte_local,1,1) == 'G' or sub(nature_acte_local,1,1) == 'A' then
        if find("L03 L04 L05 L07 L08", lieu_acte_local) then
           if catprof_local ~= 'S' then
              ipp_ega_HLS_HS[ idx ] = ipp_ega_HLS_HS[ idx ] +1
           end 
        end	 
     end
     ---calcul bonus COORDINATION
     if sub(nature_acte_local,1,1) == 'D' or sub(nature_acte_local,1,1) == 'R' then
        if lieu_acte_local ~= 'L09' and lieu_acte_local ~= 'L10' and lieu_acte_local ~= 'L06' then
           if catprof_local ~= 'S' then
              ipp_ega_DR_HS[ idx ] = ipp_ega_DR_HS[ idx ] +1
           end 
        end	 
     end
	 
  else
     pos = find(buffer_ipp_min, str, 1, true)
     if pos then
        --ipp deja comptabilise : trouver l'index table (methode 1)
        idx = (pos+6)/7
     else
        --nouveau patient
        --ajout ipp au buffer et à la table + initialisation des compteurs patient
        nbpati_min = nbpati_min+1
        buffer_ipp_min = buffer_ipp_min .. "*" .. ipp_local
--print(buffer_ipp)
        table.insert(ipp_min, ipp_local)
        table.insert(ipp_ega_HORS_06_09_10_HS_min, 0)
		table.insert(ipp_ega_HORS_06_09_10_HS_2i_min, 0)
        table.insert(ipp_ega_HLS_HS_min, 0)
        table.insert(ipp_ega_DR_HS_min,0)
        idx = #ipp_min
--st = idx .. " = rang nouveau patient"
--fltk:fl_alert(st)
     end
--st = idx .. " /" .. nbpati .. " /".. #ipp .. " = index patient / nb_patients / #ipp  etape 2 : nouveau patient ou pas ?"
--fltk:fl_alert(st)
  
     if sub(nature_acte_local,1,1) == 'E' or sub(nature_acte_local,1,1) == 'G' or sub(nature_acte_local,1,1) == 'A' then
	    --if lieu_acte_local == 'L01' or lieu_acte_local == 'L02' or lieu_acte_local == 'L11' then
        if lieu_acte_local ~= 'L09' and lieu_acte_local ~= 'L10' and lieu_acte_local ~= 'L06' then
           if catprof_local ~= 'S' then
              ipp_ega_HORS_06_09_10_HS_min[ idx ] = ipp_ega_HORS_06_09_10_HS_min[ idx ] +1
			  if nb_intervenants >=2 then 
			     ipp_ega_HORS_06_09_10_HS_2i_min[ idx ] = ipp_ega_HORS_06_09_10_HS_2i_min[ idx ] +1
			  end
           end 
        end	 
     end
     ---calcul bonus HORS LIEUX DE SOINS L03,L04,L05,L07,L08
     if sub(nature_acte_local,1,1) == 'E' or sub(nature_acte_local,1,1) == 'G' or sub(nature_acte_local,1,1) == 'A' then
        if find("L03 L04 L05 L07 L08", lieu_acte_local) then
           if catprof_local ~= 'S' then
              ipp_ega_HLS_HS_min[ idx ] = ipp_ega_HLS_HS_min[ idx ] +1
           end 
        end	 
     end
     ---calcul bonus COORDINATION
     if sub(nature_acte_local,1,1) == 'D' or sub(nature_acte_local,1,1) == 'R' then
        if lieu_acte_local ~= 'L09' and lieu_acte_local ~= 'L10' and lieu_acte_local ~= 'L06' then
           if catprof_local ~= 'S' then
              ipp_ega_DR_HS_min[ idx ] = ipp_ega_DR_HS_min[ idx ] +1
           end 
        end	 
     end	 
  end

  --calcul des activités spécifiques L06, L09, L10 : l'age N'EST PAS pris en compte
  if sub(nature_acte_local,1,1) == 'E' or sub(nature_acte_local,1,1) == 'G' or sub(nature_acte_local,1,1) == 'A' then
     if lieu_acte_local == 'L06' then
        pos = find(buffer_ipp_L06, str, 1, true) --PENITENTIAIRE
        nb_RAA_L06 = nb_RAA_L06+1
        if pos then
           --ipp deja comptabilise : rien à faire
        else
           buffer_ipp_L06 = buffer_ipp_L06 .. "*" .. ipp_local
           table.insert(ipp_L06, ipp_local)
        end
     end
     if lieu_acte_local == 'L09' then
        pos = find(buffer_ipp_L09, str, 1, true) --PSY DE LIAISON
        nb_RAA_L09 = nb_RAA_L09+1
        if pos then
           --ipp deja comptabilise : rien à faire
        else
           buffer_ipp_L09 = buffer_ipp_L09 .. "*" .. ipp_local
           table.insert(ipp_L09, ipp_local)
        end
     end
     if lieu_acte_local == 'L10' then
        pos = find(buffer_ipp_L10, str, 1, true) --SAU
        nb_RAA_L10 = nb_RAA_L10+1
        if pos then
           --ipp deja comptabilise : rien à faire
        else
           buffer_ipp_L10 = buffer_ipp_L10 .. "*" .. ipp_local
           table.insert(ipp_L10, ipp_local)
        end
     end
  end
  
end   --end function  

function build_base() 
  local i,j
  local nbl=1
  local str    
  local pos=1
  
  get_RAA_format()
--print( sub(read_data,1,1000) )
--fltk:fl_alert("read_data")
  while 1 do
      j = find(read_data,"\n",pos)
      if j then
	     line_raa = sub(read_data, pos, j-1)
		 if line_raa then
  	        process(line_raa)
	        pos = j+size_eol
	        nbl = nbl+1
--print("nbl = " .. nbl)
		 else
st = "line_raa est nulle !"
fltk:fl_alert(st)
		 end
	  else
	     break
	  end
  end
end  --end function  
  
function load_database()
  local st=""
  local nbl=0
  
  local f = 0
  local i = 0
  local j = 0
  local pos=1
  local str
  
  filename = fltk.fl_file_chooser("SELECTION de FICHIER RAA", "TXT Files (*.{txt,TXT})", SINGLE, nil)
  f = io.open(filename,"rb")
  if f then
     read_data = f:read("*all")
     print("Lecture reussie pour le fichier " .. filename .. ", taille=" .. #read_data .. " octets")
     io.close(f)
     while 1 do
        j = find(read_data,"\n",pos)
        if j then
	       pos = j+2
	       nbl = nbl+1
	    else
	       break
	    end
     end
print("Nb de lignes (RAA)= " .. nbl)
     return filename, nbl
  else
     print("Pas de fichier " .. filename .. " dans le dossier par defaut ")
     return filename, null
  end
end --end function

function save_csv_file() 
  local f, filename, st
  
  filename = "FINPSY_RAA_" .. Annee_RAA .. "_" ..  format_RAA .. ".csv"
  f = io.open(filename,"wb")
  if f then
     f:write(csv_buffer)
     print(filename .. " sauvegarde, taille=" .. #csv_buffer .. " octets.")
     io.close(f)
	 st = filename .. " sauvegarde !"
	 fltk:fl_alert(st)
  else
    filename=nil
	 st = "Sauvegarde impossible du CSV!"
	 fltk:fl_alert(st)
  end
end --end function

function create_csv_file() 
  local i,b1,b2,legende_csv
  local str
  
  csv_buffer = ""
  legende_csv = "MAJEURS\n" .. "bornes groupe (actes)" .. separator .. "patients EGA" .. separator .. "actes EGA" .. separator .. "patients PECI" .. separator .. "dont patients HLS" .. separator .. "actes HLS" .. separator .. "%actes HLS" .. separator .. "dont patients DR" .. separator .. "actes DR\n"
  csv_buffer = csv_buffer .. "version_pluri_intervenant (PECI) =" .. version_pluri_intervenant .. "\nAnnee_RAA " .. Annee_RAA .. "___FORMAT RAA " ..  format_RAA .. "\n\n" .. legende_csv
  
  for i=1,#borne do
      b1 = borne[i] .. "-"
      if i == #borne then
         b2 = "+"
      else
         b2 = (borne[i+1]-1) .. ""
      end
      st = b1 .. "-" .. b2
      str = st .. separator .. effectifs_gr[i] .. separator .. actes_gr[i] .. separator .. peci_gr[i] ..  separator .. pati_gr_HLS[i] .. separator .. actes_gr_HLS[i] .. separator .. string.format('%.2f',(actes_gr_HLS[i]*100/actes_gr[i])) .. separator .. pati_gr_DR[i] .. separator .. actes_gr_DR[i] ..  "\n"
      csv_buffer = csv_buffer .. str
  end

  legende_csv = "MINEURS\n" .. "bornes groupe (actes)" .. separator .. "patients EGA"  .. separator .. "actes EGA" .. separator .. "patients PECI" .. separator .. "dont patients HLS" .. separator .. "actes HLS" .. separator .. "%actes HLS" .. separator .. "dont patients DR" .. separator .. "actes DR\n"
  csv_buffer = csv_buffer .. "\n\n" .. legende_csv
  
  for i=1,#borne do
      b1 = borne[i] .. "-"
      if i == #borne then
         b2 = "+"
      else
         b2 = (borne[i+1]-1) .. ""
      end
      st = b1 .. "-" .. b2
      str = st .. separator .. effectifs_gr_min[i] .. separator .. actes_gr_min[i] .. separator .. peci_gr_min[i] .. separator .. pati_gr_HLS_min[i] .. separator .. actes_gr_HLS_min[i] .. separator .. string.format('%.2f',(actes_gr_HLS_min[i]*100/actes_gr_min[i])) .. separator .. pati_gr_DR_min[i] .. separator .. actes_gr_DR_min[i] .. "\n"
      csv_buffer = csv_buffer .. str
  end
  
  --LISTING PECI ADULTES
  legende_csv = "\n\nMAJEURS\n" .. "IPP AVEC PECI" .. separator .. "NB ACTES EGA MI\n"
  csv_buffer = csv_buffer .. legende_csv
  for i=1,#ipp do
      if ipp_ega_peci[ i ] == 1 then 
         str = ipp[ i ]  .. separator .. ipp_ega_HORS_06_09_10_HS_2i[ i ] .. "\n"
	 csv_buffer = csv_buffer .. str
      end
  end
  
  --LISTING PECI MINEURS
  legende_csv = "\n\nMINEURS\n" .. "IPP AVEC PECI" .. separator .. "NB ACTES EGA MI\n"  
  csv_buffer = csv_buffer .. legende_csv
  for i=1,#ipp_min do
      if ipp_ega_peci_min[ i ] == 1 then 
         str = ipp_min[ i ]  .. separator .. ipp_ega_HORS_06_09_10_HS_2i_min[ i ] .. "\n"
         csv_buffer = csv_buffer .. str
      end
  end
 

  legende_csv = "\n\nL06-AMBULATOIRE PENITENTIAIRE\n" .. "PATIENTS" .. separator .. "RAA\n"  
  csv_buffer = csv_buffer .. legende_csv
  str = #ipp_L06  .. separator .. nb_RAA_L06 .. "\n"
  csv_buffer = csv_buffer .. str
  legende_csv = "\nL09-AMBULATOIRE PSY LIAISON\n" .. "PATIENTS" .. separator .. "RAA\n"  
  csv_buffer = csv_buffer .. legende_csv
  str = #ipp_L09  .. separator .. nb_RAA_L09 .. "\n"
  csv_buffer = csv_buffer .. str
  legende_csv = "\nL10-AMBULATOIRE SAU\n" .. "PATIENTS" .. separator .. "RAA\n"  
  csv_buffer = csv_buffer .. legende_csv
  str = #ipp_L10  .. separator .. nb_RAA_L10 .. "\n"
  csv_buffer = csv_buffer .. str
  
end --end function

t00 = os.time() --top chrono

  if osName == "OS=linux" then
     filename = "/home/terras/scripts-murgaLua/RAA_M32022.txt"
  else
     filename = "RAA_M32022.txt"
  end

--st = filename .. " va etre ouvert !"
--fltk:fl_alert(st)

  filename, nbl = load_database()
if nbl then
   str = define_textfile_origin( read_data )
   --st = filename .. " a ete ouvert avec succes et contient " .. nbl .. " lignes (systeme d'origine du fichier=" .. str .. ")."
   --fltk:fl_alert(st)
else
   st = filename .. " n'a pu etre ouvert : merci de revoir les noms et chemins pour ce fichier !"
   fltk:fl_alert(st)
   exit(0)
end
  build_base()

  --controles & stats ---MAJEURS
for i=1,#ipp do
    if ipp_ega_HORS_06_09_10_HS[ i ] > 0 then
       nb_ipp_ega_HORS_06_09_10_HS = nb_ipp_ega_HORS_06_09_10_HS +1
    end
    if ipp_730actes[ i ] == 1 then
       nb_ipp_exclus_730a = nb_ipp_exclus_730a+1
    end
end
for i=1,#ipp do
    total_actes_ega_HORS_06_09_10_HS = total_actes_ega_HORS_06_09_10_HS + ipp_ega_HORS_06_09_10_HS[ i ]
end

--controles & stats ---MINEURS
for i=1,#ipp_min do
    if ipp_ega_HORS_06_09_10_HS_min[ i ] > 0 then
       nb_ipp_ega_HORS_06_09_10_HS_min = nb_ipp_ega_HORS_06_09_10_HS_min +1
    end
    if ipp_730actes_min[ i ] == 1 then
       nb_ipp_exclus_730a_min = nb_ipp_exclus_730a_min+1
    end
end
for i=1,#ipp_min do
    total_actes_ega_HORS_06_09_10_HS_min = total_actes_ega_HORS_06_09_10_HS_min + ipp_ega_HORS_06_09_10_HS_min[ i ]
end

st = "Total IPP MAJEURS = " .. #ipp .. "\n"
st = st .. "nb_ipp_ega_HORS_06_09_10_HS = " .. nb_ipp_ega_HORS_06_09_10_HS .. ", total_actes_ega_HORS_06_09_10_HS=".. total_actes_ega_HORS_06_09_10_HS .. "\n"
st = st .. "Exclus plus de 730 actes = " .. nb_ipp_exclus_730a .. "\n\n"

st = st .. "Total IPP MINEURS = " .. #ipp_min .. "\n"
st = st .. "nb_ipp_ega_HORS_06_09_10_HS_min = " .. nb_ipp_ega_HORS_06_09_10_HS_min .. ", total_actes_ega_HORS_06_09_10_HS_min=".. total_actes_ega_HORS_06_09_10_HS_min .. "\n"
st = st .. "Exclus plus de 730 actes = " .. nb_ipp_exclus_730a_min .. "\n\n"
st = st .. "\nTraitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures"

fltk:fl_alert(st)

--groupage MAJEURS par nb d'actes Hors lieu L06-L09-L10 hors catégorie S
for i=1,#borne do
    for j=1,#ipp do	
        if ipp_ega_HORS_06_09_10_HS[ j ] < 730 then 
           ipp_730actes[ j ] = 0
        else 
           ipp_730actes[ j ] = 1 -- patient exclu
        end
        if ipp_ega_HORS_06_09_10_HS[ j ] > 0 then 
           if i == #borne then
              if ipp_ega_HORS_06_09_10_HS[ j ] >= borne[i] then
                 effectifs_gr[i] = effectifs_gr[i]+1
                 actes_gr[i] = actes_gr[i] + ipp_ega_HORS_06_09_10_HS[ j ]
                 if ipp_ega_HLS_HS[ j ] > 0 then
                    pati_gr_HLS[i] = pati_gr_HLS[i]+1
                    actes_gr_HLS[i] = actes_gr_HLS[i]+ipp_ega_HLS_HS[ j ]
                 end
                 if ipp_ega_DR_HS[ j ] > 0 then
                    pati_gr_DR[i] = pati_gr_DR[i]+1
                    actes_gr_DR[i] = actes_gr_DR[i]+ipp_ega_DR_HS[ j ]
                 end
              end
           else
              if ipp_ega_HORS_06_09_10_HS[ j ] >= borne[i] and ipp_ega_HORS_06_09_10_HS[ j ] < borne[i+1] then
                 effectifs_gr[i] = effectifs_gr[i]+1
                 actes_gr[i] = actes_gr[i] + ipp_ega_HORS_06_09_10_HS[ j ]
                 if ipp_ega_HLS_HS[ j ] > 0 then
                    pati_gr_HLS[i] = pati_gr_HLS[i]+1
                    actes_gr_HLS[i] = actes_gr_HLS[i]+ipp_ega_HLS_HS[ j ]
                 end
                if ipp_ega_DR_HS[ j ] > 0 then
                   pati_gr_DR[i] = pati_gr_DR[i]+1
                   actes_gr_DR[i] = actes_gr_DR[i]+ipp_ega_DR_HS[ j ]
                 end
              end
           end
        end
    end
end

--groupage MINEURS par nb d'actes Hors lieu L06-L09-L10 hors catégorie S
for i=1,#borne do
    for j=1,#ipp_min do
        if ipp_ega_HORS_06_09_10_HS_min[ j ] < 730 then 
           ipp_730actes_min[ j ] = 0
        else 
           ipp_730actes_min[ j ] = 1 -- patient exclu
        end
        if ipp_ega_HORS_06_09_10_HS_min[ j ] > 0 then 
           if i == #borne then
              if ipp_ega_HORS_06_09_10_HS_min[ j ] >= borne[i] then
                 effectifs_gr_min[i] = effectifs_gr_min[i]+1
                 actes_gr_min[i] = actes_gr_min[i] + ipp_ega_HORS_06_09_10_HS_min[ j ]
                 if ipp_ega_HLS_HS_min[ j ] > 0 then
                    pati_gr_HLS_min[i] = pati_gr_HLS_min[i]+1
                    actes_gr_HLS_min[i] = actes_gr_HLS_min[i]+ipp_ega_HLS_HS_min[ j ]

                 end
                 if ipp_ega_DR_HS_min[ j ] > 0 then
                    pati_gr_DR_min[i] = pati_gr_DR_min[i]+1
                    actes_gr_DR_min[i] = actes_gr_DR_min[i]+ipp_ega_DR_HS_min[ j ]
                 end
              end
           else
              if ipp_ega_HORS_06_09_10_HS_min[ j ] >= borne[i] and ipp_ega_HORS_06_09_10_HS_min[ j ] < borne[i+1] then
                 effectifs_gr_min[i] = effectifs_gr_min[i]+1
                 actes_gr_min[i] = actes_gr_min[i] + ipp_ega_HORS_06_09_10_HS_min[ j ]
                 if ipp_ega_HLS_HS_min[ j ] > 0 then
                    pati_gr_HLS_min[i] = pati_gr_HLS_min[i]+1
                    actes_gr_HLS_min[i] = actes_gr_HLS_min[i]+ipp_ega_HLS_HS_min[ j ]
                 end
                if ipp_ega_DR_HS_min[ j ] > 0 then
                   pati_gr_DR_min[i] = pati_gr_DR_min[i]+1
                   actes_gr_DR_min[i] = actes_gr_DR_min[i]+ipp_ega_DR_HS_min[ j ]
                 end
              end
           end
        end
    end
end

st="effectifs groupes EGA HLS et DR calcules"
fltk:fl_alert(st)

---- ttts "PECI Prise En Charge Intensives" -- MAJEURS
---- patients avec au moins 15 actes effectués sur 3 semaines avec au moins 12 jours actifs et au moins 2 intervenants
for j=1,#ipp do
    --nouveau patient eligible au bonus PECI, à rechercher dans les RAA
    buffer_dates=""
    buffer_dates_peci="" --jours d'acte eligibles PECI sans double compte
    buffer_jours_peci="" --TOUS les jours d'acte eligibles PECI, avec double compte
    buffer_jours_peci_comp="" --TOUS les jours d'acte eligibles PECI, avec double compte, avec nb interv
    buffer_weeks_peci=""
    nb_actes=0
    
    nbic = 0 --nb cumulés des intervenants, si supérieur au nb d'actes, il y a 2 intervenants sur au mois un acte
   if ipp_730actes[ j ] == 0 then
    if ipp_ega_HORS_06_09_10_HS_2i[ j ] > 14 then 
       pos=1
       while 1 do
         i = find(read_data,"\n",pos)
         if i then
            line_raa = sub(read_data, pos, i-1)
            if line_raa then
               ipp_local = sub(line_raa,22,27)
               if ipp_local == ipp[j] then
			      ipp_local,date_nais_local,date_acte_local,nature_acte_local,lieu_acte_local,catprof_local, nb_intervenants, age_acte = get_data_from_line_RAA( line_raa )
                  
		          nbi = tonumber(nb_intervenants)
                  if age_acte >= 18 then
                     nb_actes = nb_actes+1
				     buffer_dates = buffer_dates .. "*" .. date_acte_local --sert pour le calcul d'exclusion 15 actes/j
                        w = get_weeknumber_from_day(date_acte_local)
			            week = "*" .. string.format('%02d', math.floor(w) )
			            buffer_jours_peci = buffer_jours_peci .. "*" .. date_acte_local
                        --autre méthodo possible pour les PECI : 
                        ---------> au moins 2 intrevenants = au moins 2 catégorie professionnelle (catprof_local="X" ou "Y")
                        ---------> on peut remplacer la condition if nbi >=2 par if (catprof_local=="X" or catprof_local=="Y") then  insérer en remplacement de "P"
                        if version_pluri_intervenant == "PLURI_INTERV" then
                           if nbi >= 2 then
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "P" --taille=10, P=acte pluri-professionnel
                           else
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "M" --taille=10, M=acte mono-professionnel
                           end
                        else
                           -- version_pluri_intervenant == "PLURI_CAT_PRO"
                           if (catprof_local=="X" or catprof_local=="Y") then
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "P" --taille=10, P=acte pluri-professionnel
                           else
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "M" --taille=10, M=acte mono-professionnel
                           end
                        end
			            if find(buffer_weeks_peci, week) then
                           --rien à faire: week est déjà dans le tampon semaine
                        else
                           buffer_weeks_peci = buffer_weeks_peci .. week
                           --nb entier de semaines eligibles PECI = (#buffer_weeks_peci+2)/3
                        end
                        if find(buffer_dates_peci, date_acte_local) then
                           --rien
                        else
                           buffer_dates_peci = buffer_dates_peci .. "*" .. date_acte_local
                           --nb entier d'actes eligibles PECI = (#buffer_dates_peci+8)/9
			            end
		          end
               end
            end
            pos = i+size_eol
         else
            break
         end
       end
    end
    --premier tri : éliminer les patients qui n'ont pas 3 semaines actives et/ou pas  12 jours actifs
    if #buffer_weeks_peci >= 9 and (#buffer_dates_peci/9) >= 12 then 
--print("ipp_local = " .. ipp_local)
        --le premier 9 = au moins 3 semaines actives (codées sur 3 caractères)
        --le deuxième 12 = au moins 12 jours actifs distincts (codés sur 9 caractères)
	-- actes sur au moins sur 3 semaines consécutives et 12 jours actifs
--print("buffer_weeks_peci = " .. buffer_weeks_peci)
--print("buffer_dates_peci = " .. buffer_dates_peci)
       --ipp_ega_peci[j] = math.floor( (#buffer_dates_peci+8)/9 )
	   --fonction calcul_peci
	   --ipp_ega_peci[j] = calcul_peci2(buffer_jours_peci, buffer_weeks_peci)
       ipp_ega_peci[j] = calcul_peci3(buffer_jours_peci_comp)
       if ipp_local == "134332" then
           fltk:fl_alert("Point d'arret IPP TEST 134332!")
       end
    else
       ipp_ega_peci[j] = 0
    end
    ipp_exclus_15aj[ j ] = 0
    p2 = 1
    while 1 do
        s1 = sub(buffer_dates, p2, p2+8)
        local _, count = string.gsub(buffer_dates, s1, "")
        if count >= 15 then
           ipp_exclus_15aj[ j ] = 1 --- patient exclus
           break
        end
	p2 = p2+9
	if p2>=#buffer_dates then 
	   break
	end
    end
   end
end
--groupage PECI pour CSV
for i=1,#borne do
    for j=1,#ipp do
      if ipp_730actes[ j ] == 0 and ipp_exclus_15aj[ j ] == 0 then
         if i == #borne then
            if ipp_ega_HORS_06_09_10_HS_2i[ j ] >= borne[i] then
			   if ipp_ega_peci[j] == 1 then
                  peci_gr[i] = peci_gr[i]+1
               end
			end
         else
            if ipp_ega_HORS_06_09_10_HS_2i[ j ] >= borne[i] and ipp_ega_HORS_06_09_10_HS_2i[ j ] < borne[i+1] then
			   if ipp_ega_peci[j] == 1 then
                  peci_gr[i] = peci_gr[i]+1
               end
            end
        end
      end
    end
end
j=0
for i=1,#ipp do
    j = j + ipp_exclus_15aj[i]
end
st="effectifs groupes et actes PECI majeurs calcules \nexclus plus de 15 actes journaliers = " .. j
fltk:fl_alert(st)


---- ttts "PECI Prise En Charge Intensives" -- MINEURS
---- patients avec au moins 15 actes effectués sur 3 semaines avec au moins 12 jours actifs et au moins 2 intervenants
for j=1,#ipp_min do	
   --nouveau patient eligible au bonus PECI, à rechercher dans les RAA
   buffer_dates=""
   buffer_dates_peci="" --jours d'acte eligibles PECI sans double compte
   buffer_jours_peci="" --TOUS les jours d'acte eligibles PECI, avec double compte
   buffer_jours_peci_comp="" --TOUS les jours d'acte eligibles PECI, avec double compte, avec nb interv
   buffer_weeks_peci=""
   nb_actes=0
   
   nbic = 0 --nb cumulés des intervenants, si supérieur au nb d'actes, il y a 2 intervenants sur au mois un acte
   if ipp_730actes_min[ j ] == 0 then
    if ipp_ega_HORS_06_09_10_HS_2i_min[ j ] > 14 then 
       pos=1
       while 1 do
         i = find(read_data,"\n",pos)
         if i then
            line_raa = sub(read_data, pos, i-1)
            if line_raa then
               ipp_local = sub(line_raa,22,27)
               if ipp_local == ipp[j] then
			      ipp_local,date_nais_local,date_acte_local,nature_acte_local,lieu_acte_local,catprof_local, nb_intervenants, age_acte = get_data_from_line_RAA( line_raa )
		          nbi = tonumber(nb_intervenants)
                  --autre méthodo possible pour les PECI : 
                  ---------> au moins 2 intrevenants = au moins 2 catégorie professionnelle (catprof_local="X" ou "Y")
                  ---------> on peut remplacer la condition if nbi >=2 par if (catprof_local=="X" or catprof_local=="Y") then  insérer en remplacement de "P"
                  if age_acte < 18 then
		             buffer_dates = buffer_dates .. "*" .. date_acte_local --sert pour le calcul d'exclusion 15 actes/j
                        w = get_weeknumber_from_day(date_acte_local)
			            week = "*" .. string.format('%02d', math.floor(w) )
			            buffer_jours_peci = buffer_jours_peci .. "*" .. date_acte_local
                        --autre méthodo possible pour les PECI : 
                        ---------> au moins 2 intrevenants = au moins 2 catégorie professionnelle (catprof_local="X" ou "Y")
                        ---------> on peut remplacer la condition if nbi >=2 par if (catprof_local=="X" or catprof_local=="Y") then  insérer en remplacement de "P"
                         if version_pluri_intervenant == "PLURI_INTERV" then
                           if nbi >= 2 then
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "P" --taille=10, P=acte pluri-professionnel
                           else
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "M" --taille=10, M=acte mono-professionnel
                           end
                        else
                           -- version_pluri_intervenant == "PLURI_CAT_PRO"
                           if (catprof_local=="X" or catprof_local=="Y") then
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "P" --taille=10, P=acte pluri-professionnel
                           else
                              buffer_jours_peci_comp = buffer_jours_peci_comp .. "*" .. date_acte_local .. "M" --taille=10, M=acte mono-professionnel
                           end
                        end
			            if find(buffer_weeks_peci, week) then
                           --rien à faire: week est déjà dans le tampon semaine
                        else
                           buffer_weeks_peci = buffer_weeks_peci .. week
                           --nb entier de semaines eligibles PECI = (#buffer_weeks_peci+2)/3 --obsolète
                        end
                        if find(buffer_dates_peci, date_acte_local) then
                           --rien
                        else
                           buffer_dates_peci = buffer_dates_peci .. "*" .. date_acte_local
                           --nb de jours distincts de realisation des actes eligibles PECI = (#buffer_dates_peci+8)/9
                        end
                  end
               end
            end
            pos = i+size_eol
         else
            break
         end
       end
    end
    --premier tri : éliminer les patients qui n'ont pas 3 semaines actives et/ou pas  12 jours actifs
    if #buffer_weeks_peci >= 9 and (#buffer_dates_peci/9) >= 12 then 
--print("ipp_local = " .. ipp_local)
        --le premier 9 = au moins 3 semaines actives (codées sur 3 caractères)
        --le deuxième 12 = au moins 12 jours actifs distincts (codés sur 9 caractères)
	-- actes sur au moins sur 3 semaines consécutives et 12 jours actifs
--print("buffer_weeks_peci = " .. buffer_weeks_peci)
       --ipp_ega_peci_min[j] = math.floor( (#buffer_dates_peci+8)/9 )
	   --fonction calcul_peci
	   --ipp_ega_peci_min[j] = calcul_peci2(buffer_jours_peci, buffer_weeks_peci)
       ipp_ega_peci_min[j] = calcul_peci3(buffer_jours_peci_comp)
    else
       ipp_ega_peci_min[j] = 0
    end
    ipp_exclus_15aj_min[ j ] = 0
    p2 = 1
    while 1 do
        s1 = sub(buffer_dates, p2, p2+8)
        local _, count = string.gsub(buffer_dates, s1, "")
        if count >= 15 then
           ipp_exclus_15aj_min[ j ] = 1 --- patient exclus
           break
        end
        p2 = p2+9
        if p2>=#buffer_dates then 
           break
        end
    end
   end
end
--groupage PECI mineurs pour CSV
for i=1,#borne do
    for j=1,#ipp_min do	
      if ipp_730actes_min[ j ] == 0 and ipp_exclus_15aj_min[ j ] == 0 then
        if i == #borne then
           if ipp_ega_HORS_06_09_10_HS_2i_min[ j ] >= borne[i] then
			  if ipp_ega_peci_min[j] == 1 then
                 peci_gr_min[i] = peci_gr_min[i]+1
              end
		   end
        else
           if ipp_ega_HORS_06_09_10_HS_2i_min[ j ] >= borne[i] and ipp_ega_HORS_06_09_10_HS_2i_min[ j ] < borne[i+1] then
			  if ipp_ega_peci_min[j] == 1 then
                 peci_gr_min[i] = peci_gr_min[i]+1
              end
           end
        end
      end
    end
end
j=0
for i=1,#ipp_min do
    j = j + ipp_exclus_15aj_min[i]
end
st="effectifs groupes et actes PECI mineurs calcules \nexclus plus de 15 actes journaliers = " .. j
fltk:fl_alert(st)

--st="effectifs groupes EGA calcules"
--fltk:fl_alert(st)

create_csv_file()
if #csv_buffer >0 then
   save_csv_file()
end

print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")

Fl:check()
Fl:run()

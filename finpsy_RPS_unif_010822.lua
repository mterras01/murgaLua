#!/bin/murgaLua
--Calculs pour le FINANCEMENT PSY AOUT 2022-HOSPITALISATION complète et partielle ETAB

 
i=0

find = string.find
sub = string.sub

read_data = "" --tampon de lecture
size_eol = 0 -- varie selon Unix (MacOs) ou Windows

format_RPS = ""
Annee_RPS=0

--catalogue PMSI mode legal
--[[
1=SL
3=SDRE L3213-1+L3213-2+L3213-6
4=pénalement irresponsables L3213-7 CSP et 706-135 CPP
5=OPP
6=Détenus D398 CPP et L3214-3 du CSP
7=DT et PU (DT-3212-1-II-1 et 3212-3)
8=PI
]]--

ipp={}						---------------- MAJEURS
ipp_temps_plein={}
ipp_temps_plein_ssc={}
ipp_temps_plein_ssc_sdre={}
ipp_temps_plein_ssc_sdt={}
ipp_temps_plein_isolement={}
ipp_temps_plein_journees={}
ipp_temps_plein_journees_ssc={}
ipp_temps_plein_journees_isolement={}
--criteres d'exclusion
ipp_temps_plein_seq_plus_92j={}
ipp_temps_plein_journees_seq_plus_92j={}
 --jeunes adultes >=18 ans et <26 ans
--géronto >64 ans
ipp_temps_plein_jeunes_ad={}
ipp_temps_plein_journees_jeunes_ad={}
ipp_temps_plein_geronto={}
ipp_temps_plein_journees_geronto={}
--temps partiel
ipp_temps_partiel_hdj={}
ipp_temps_partiel_hdj_ssc={}
ipp_temps_partiel_hdj_journees={}
ipp_temps_partiel_hdj_demi_journees={}
ipp_temps_partiel_hdj_journees_ssc={}
ipp_temps_partiel_hdj_demi_journees_ssc={}

--st = "Tables ipp majeurs ok"
--fltk:fl_alert(st)

ipp_min={}					---------------- MINEURS
ipp_min_temps_plein={}	
ipp_min_temps_plein_ssc={}
ipp_min_temps_plein_ssc_sdre={}
ipp_min_temps_plein_ssc_sdt={}
ipp_min_temps_plein_isolement={}
ipp_min_temps_plein_journees={}
ipp_min_temps_plein_journees_ssc={}
ipp_min_temps_plein_journees_isolement={}
--criteres d'exclusion
ipp_min_temps_plein_seq_plus_92j={}
ipp_min_temps_plein_journees_seq_plus_92j={}
--temps partiel
ipp_min_temps_partiel_hdj={}
ipp_min_temps_partiel_hdj_ssc={}
ipp_min_temps_partiel_hdj_journees={}	
ipp_min_temps_partiel_hdj_demi_journees={}
ipp_min_temps_partiel_hdj_journees_ssc={}
ipp_min_temps_partiel_hdj_demi_journees_ssc={}

--st = "Tables ipp mineurs ok"
--fltk:fl_alert(st)

--MAJEURS
buffer_ipp=""
nbpati=0 -- nb de patients distincts
buffer_ipp_temps_plein=""
buffer_ipp_temps_plein_jeunead=""
buffer_ipp_temps_plein_geronto=""
buffer_ipp_temps_plein_isolement=""
buffer_ipp_temps_plein_ssc=""
buffer_ipp_temps_plein_ssc_spdre=""
buffer_ipp_temps_plein_ssc_spdt=""
buffer_ipp_temps_partiel_hdj=""
buffer_ipp_temps_partiel_hdj_ssc=""
--MINEURS
buffer_ipp_min=""
nbpati_min=0 -- nb de patients distincts
buffer_ipp_min_temps_plein=""
buffer_ipp_min_temps_plein_ssc=""
buffer_ipp_min_temps_plein_ssc_spdre=""
buffer_ipp_min_temps_plein_ssc_spdt=""
buffer_ipp_min_temps_plein_isolement=""
buffer_ipp_min_temps_partiel_hdj=""
buffer_ipp_min_temps_partiel_hdj_ssc=""

-- AGREGATS -----------------
--- TEMPS PLEIN
-- ADULTES
ad_journees_temps_plein=0
ad_journees_temps_plein_isolement=0
ad_journees_temps_plein_ssc=0
ad_journees_temps_plein_sl=0
-- MINEURS
min_journees_temps_plein=0
min_journees_temps_plein_isolement=0
min_journees_temps_plein_ssc=0
min_journees_temps_plein_sl=0
--- TEMPS PARTIEL
-- ADULTES
ad_journees_temps_partiel_hdj=0
ad_journees_temps_partiel_hdj_ssc=0
ad_demi_journees_temps_partiel_hdj=0
ad_demi_journees_temps_partiel_hdj_ssc=0
-- MINEURS
min_journees_temps_partiel_hdj=0
min_journees_temps_partiel_hdj_ssc=0
min_demi_journees_temps_partiel_hdj=0
min_demi_journees_temps_partiel_hdj_ssc=0



filename=""

borne_ad={0,1,3,6,10,15,20,28,39,59,113}
--1er  intervalle = 0 journée
--2ème  intervalle >=1 et <3
--etc...
--dernier 113 journées et +
--11 intervalles correspondants = 0, 1-2, 3-5, 6-9, 10-14, 15-19, 20-27, 28-38, 39-58, 59-112, 113 et plus 
borne_min={0,1,3,6,9,12,16,22,31,46,79}
--1er  intervalle = 0 journée
--2ème  intervalle >=1 et <3
--etc...
--dernier 79 journées et +
--11 intervalles correspondants = 0, 1-2, 3-5, 6-8, 9-11, 12-15, 16-21, 22-30, 31-45, 46-78, 79 et plus 

---tables adultes
effectifs_gr={}
journees_gr={}
effectifs_gr_jeunes_ad={}
journees_gr_jeunes_ad={}
effectifs_gr_geronto={}
journees_gr_geronto={}
effectifs_gr_seq_plus_92j={}
journees_gr_seq_plus_92j={}
---tables mineurs
effectifs_gr_min={}
journees_gr_min={}
effectifs_gr_min_seq_plus_92j={}
journees_gr_min_seq_plus_92j={}
--initialisation
for i=1,#borne_ad do
     effectifs_gr[i]=0
     journees_gr[i]=0
     effectifs_gr_jeunes_ad[i]=0
     journees_gr_jeunes_ad[i]=0
     effectifs_gr_geronto[i]=0
     journees_gr_geronto[i]=0
     effectifs_gr_seq_plus_92j[i]=0
     journees_gr_seq_plus_92j[i]=0
end
for i=1,#borne_min do
    effectifs_gr_min[i]=0
    journees_gr_min[i]=0
    effectifs_gr_min_seq_plus_92j[i]=0
    journees_gr_min_seq_plus_92j[i]=0
end
--"tableaux" à une seule ligne = une seule variable par colonne
--ADULTES
effectifs_gr_ad_hdj = 0
journees_gr_ad_hdj = 0
demi_journees_gr_ad_hdj = 0
equivalent_journees_gr_ad_hdj=0
effectifs_gr_ad_hdj_0_venue=0
--MINEURS
effectifs_gr_min_hdj = 0
journees_gr_min_hdj = 0
demi_journees_gr_min_hdj = 0
equivalent_journees_gr_min_hdj=0
effectifs_gr_min_hdj_0_venue=0

--tampons d'écriture pour les fichiers texte et csv de sauvegarde
txt_buffer = ""
csv_buffer = ""
separator = ";"

osName="OS=" .. murgaLua.getHostOsName()
print(osName)
--st = osName
--fltk:fl_alert(st)

t00=0
t11=0

modules={}
modules[#modules+1] = require "date" --https://github.com/LuaDist/luadate/blob/master/date.lua

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

function get_years_between_sequence_and_birth(date_nais, date_debut_sequence)
  local d,y,m,d2,m2,y2
  local reference1,reference2,daysfrom, wholedays, age_year
  local dobj1, dobj2
  local str, nb_years

  --[[   https://stackoverflow.com/questions/28550413/compare-dates-in-lua
  os.time (under Windows, at least) is limited to years from 1970 and up. If, for example, you need a general solution to also find ages in days for people born before 1970, this won't work.
  ]]--
  
  if OsName == "OS=linux" then
    if date_debut_sequence then
       d=tonumber(sub(date_debut_sequence,1,2))
       m=tonumber(sub(date_debut_sequence,3,4))
       y=tonumber(sub(date_debut_sequence,5,8))
       reference2 = os.time{day=d, year=y, month=m}
    end
    if date_nais then
       d=tonumber(sub(date_nais,1,2))
       m=tonumber(sub(date_nais,3,4))
       y=tonumber(sub(date_nais,5,8))
       reference1 = os.time{day=d, year=y, month=m}
    end
    age_year = os.difftime(reference1, reference2) / (24*60*60*365.25) -- seconds in a year
  else
    if date_debut_sequence then
       d2=tonumber(sub(date_debut_sequence,1,2))
       m2=tonumber(sub(date_debut_sequence,3,4))
       y2=tonumber(sub(date_debut_sequence,5,8))
	end
    if date_nais then
       d=tonumber(sub(date_nais,1,2))
       m=tonumber(sub(date_nais,3,4))
       y=tonumber(sub(date_nais,5,8))
    end
	str = string.format("%02d/%02d/%04d 00:00:00",d,m,y)
    dobj1 = date(str)
	str = string.format("%02d/%02d/%04d 00:00:00",d2,m2,y2)
    dobj2 = date(str)
    nb_years =  date.diff(dobj1, dobj2)
	age_year = nb_years:spandays()/365.25
  end
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

function get_RPS_format()
 local j, line_rps

 --analyse de la premiere ligne qui contient les infos de format et d'annee
 j = find(read_data,"\n",1)
 if j then
    line_rps = sub(read_data, 1, j-1)
	format_RPS = sub(line_rps,19,21)
	if format_RPS == 'P08' then
	   Annee_RPS = sub(line_rps,121,124) --on extrait l'année de sortie de la première séquence
	elseif format_RPS == 'P12' then
	   Annee_RPS = sub(line_rps,123,126) --on extrait l'année de sortie de la première séquence
	else 
	   format_RPS=""
	   Annee_RPS=0
	end
	
 end
 if format_RPS ~= "" and Annee_RPS ~= 0 then
     st = "Format de fchier RPS " .. format_RPS .. "\nAnnee des sequences " .. Annee_RPS
    fltk:fl_alert(st)
 else
    st = "Format de fchier RPS inconnu !\nAbandon"
    fltk:fl_alert(st)
	exit(0)
 end
end --end function

function get_data_from_line_RPS( line_rps )
 local ipp_local,date_nais_local,sexe_local,date_debut_sequence,date_fin_sequence,nature_acte_local,lieu_acte_local,catprof_local, nb_intervenants
 if format_RPS == 'P12' then
    ipp_local = sub(line_rps,22,27) --ATTENTION format RPS 2022 PO12
    date_nais_local = sub(line_rps,42,49)
    --sexe_local = sub(line_rps,50,50)
    forme_activite = sub(line_rps,56,59)  -- attention conversion en nombre problématique pour "20S" modif le 060922
    date_debut_sequence = sub(line_rps,111,118)
	--date_fin_sequence = sub(line_rps,119,126)
    mode_legal_soins = tonumber(sub(line_rps,109,109))
    nb_jours_presence = tonumber( sub(line_rps,127,129) )
    nb_demi_journees_presence = tonumber( sub(line_rps,130,132) )
    nb_jours_isolement = tonumber( sub(line_rps,133,135) )
    age_sequence = get_years_between_sequence_and_birth(date_debut_sequence, date_nais_local)
 end
 if format_RPS == 'P08' then
    ipp_local = sub(line_rps,22,27) --ATTENTION format RPS 2018-2021 = P08
    date_nais_local = sub(line_rps,42,49)
    --sexe_local = sub(line_rps,50,50)
    forme_activite = sub(line_rps,56,57) -- attention conversion en nombre problématique pour "20S"  modif le 060922
    date_debut_sequence = sub(line_rps,109,116)
	--date_fin_sequence = sub(line_rps,117,124)
    mode_legal_soins = tonumber(sub(line_rps,107,107))
    nb_jours_presence = tonumber( sub(line_rps,125,127) )
    nb_demi_journees_presence = tonumber( sub(line_rps,128,130) )
    nb_jours_isolement = tonumber( sub(line_rps,131,133) )
	age_sequence = get_years_between_sequence_and_birth(date_debut_sequence, date_nais_local)
 end
 return ipp_local,date_nais_local,forme_activite,date_debut_sequence,mode_legal_soins,nb_jours_presence,nb_demi_journees_presence,nb_jours_isolement, age_sequence
end --end function

function process(line_rps)
 local i,str,pos,age
 local posplein, pospleinssc, pospleinisolement,pospleinmin,pospleinsscsdre,pospleinsscsdt
 local pospartiel_hdj, pospartiel_hdj_ssc
 local idx=1
 local idxplein=1
 local idxpleinssc=1
 local idxpleinisolement=1
 local idxpleinmin=1
 local idxpartiel_hdj=1
 local idxpartielhdjssc=1,1
 local ipp_local,date_nais_local,forme_activite,date_debut_sequence,mode_legal_soins,nb_jours_presence,nb_demi_journees_presence,nb_jours_isolement, age_sequence
 local pospleinjeunead, pospleingeronto, idxpleinjeunead, idxpleingeronto
 --local modalite_acte_local
 
--st = line_rps .. " envoyee a la fonction process()"
--fltk:fl_alert(st)
 
  if line_rps then 
     ipp_local,date_nais_local,forme_activite,date_debut_sequence,mode_legal_soins,nb_jours_presence,nb_demi_journees_presence,nb_jours_isolement, age_sequence = get_data_from_line_RPS( line_rps )
  end
--print("IPP " .. ipp_local .. "// datenais=".. date_nais_local .. "// debseq=" .. date_debut_sequence .. "// age_sequence = " .. age_sequence)
  str = "*" .. ipp_local
  
  if age_sequence >= 18 then 
     pos = find(buffer_ipp, str, 1, true)

     if pos then
        --ipp deja comptabilise : trouver l'index table (methode 1)
        idx = (pos+6)/7
     else
         --nouveau patient
        --ajout ipp au buffer et à la table + initialisation des compteurs patient
        --nbpati = nbpati+1
        buffer_ipp = buffer_ipp .. "*" .. ipp_local
--print(buffer_ipp)
        table.insert(ipp, ipp_local)
     end
        if tonumber(forme_activite) == 1 then ---------------------------------------------------------------- TEMPS PLEIN
           posplein = find(buffer_ipp_temps_plein, str, 1, true)
           if posplein then
              --ipp deja comptabilise : trouver l'index table (methode 1)
               idxplein = (posplein+6)/7
               ipp_temps_plein_journees[ idxplein ] =  ipp_temps_plein_journees[ idxplein ]+nb_jours_presence
           else
               buffer_ipp_temps_plein = buffer_ipp_temps_plein .. "*" .. ipp_local
               table.insert(ipp_temps_plein, ipp_local)
               table.insert(ipp_temps_plein_journees, nb_jours_presence)
           end
           if age_sequence>=18 and age_sequence < 26 then
              pospleinjeunead = find(buffer_ipp_temps_plein_jeunead, str, 1, true)
              if pospleinjeunead then
                 --ipp deja comptabilise : trouver l'index table (methode 1)
                  idxpleinjeunead = (pospleinjeunead+6)/7
                  ipp_temps_plein_journees_jeunes_ad[ idxpleinjeunead ] = ipp_temps_plein_journees_jeunes_ad[ idxpleinjeunead ]+nb_jours_presence
              else
                  buffer_ipp_temps_plein_jeunead = buffer_ipp_temps_plein_jeunead .. "*" .. ipp_local
                  table.insert(ipp_temps_plein_jeunes_ad, ipp_local)
                  table.insert(ipp_temps_plein_journees_jeunes_ad, nb_jours_presence)
              end
           end
           if age_sequence >=65 then
              pospleingeronto = find(buffer_ipp_temps_plein_geronto, str, 1, true)
              if pospleingeronto then
                  --ipp deja comptabilise : trouver l'index table (methode 1)
                  idxpleingeronto = (pospleingeronto+6)/7
                  ipp_temps_plein_journees_geronto[ idxpleingeronto ] =  ipp_temps_plein_journees_geronto[ idxpleingeronto ]+nb_jours_presence
              else
                  buffer_ipp_temps_plein_geronto = buffer_ipp_temps_plein_geronto .. "*" .. ipp_local
                  table.insert(ipp_temps_plein_geronto, ipp_local)
                  table.insert(ipp_temps_plein_journees_geronto, nb_jours_presence)
              end
           end
           if mode_legal_soins ~= 1 then
              pospleinssc = find(buffer_ipp_temps_plein_ssc, str, 1, true)
              if pospleinssc then
                 --ipp deja comptabilise : trouver l'index table (methode 1)
                 idxpleinssc = (pospleinssc+6)/7
                 ipp_temps_plein_journees_ssc[ idxpleinssc ] =  ipp_temps_plein_journees_ssc[ idxpleinssc ]+nb_jours_presence
              else
                 buffer_ipp_temps_plein_ssc = buffer_ipp_temps_plein_ssc .. "*" .. ipp_local
                 table.insert(ipp_temps_plein_ssc, ipp_local)
                 table.insert(ipp_temps_plein_journees_ssc, nb_jours_presence)
              end
              if mode_legal_soins == 3 then
                 --SPDRE
                 pospleinsscsdre = find(buffer_ipp_temps_plein_ssc_spdre, str, 1, true)
                 if pospleinsscsdre then
                    --rien
                 else
                     table.insert(ipp_temps_plein_ssc_sdre, ipp_local)
                     buffer_ipp_temps_plein_ssc_spdre = buffer_ipp_temps_plein_ssc_spdre .. "*" .. ipp_local
                 end
              end
              if mode_legal_soins == 7 then
                 --SPDT
                 pospleinsscsdt = find(buffer_ipp_temps_plein_ssc_spdt, str, 1, true)
                 if pospleinsscsdt then
                    --rien
                 else
                    table.insert(ipp_temps_plein_ssc_sdt, ipp_local)
                    buffer_ipp_temps_plein_ssc_spdt = buffer_ipp_temps_plein_ssc_spdt .. "*" .. ipp_local
                 end
              end
           end
           if nb_jours_isolement > 0 then
              pospleinisolement = find(buffer_ipp_temps_plein_isolement, str, 1, true)
              if pospleinisolement then
                 --ipp deja comptabilise : trouver l'index table (methode 1)
                  idxpleinisolement = (pospleinisolement+6)/7
                  ipp_temps_plein_journees_isolement[ idxpleinisolement ] =  ipp_temps_plein_journees_isolement[ idxpleinisolement ]+nb_jours_isolement
              else
                  buffer_ipp_temps_plein_isolement = buffer_ipp_temps_plein_isolement .. "*" .. ipp_local
                  table.insert(ipp_temps_plein_isolement, ipp_local)
                  table.insert(ipp_temps_plein_journees_isolement, nb_jours_isolement)
              end
           end
        end
        if tonumber(forme_activite) == 20 then ---------------------------------------------------------------- TEMPS PARTIEL HDJ
           pospartiel_hdj = find(buffer_ipp_temps_partiel_hdj, str, 1, true)
           if pospartiel_hdj then
              --ipp deja comptabilise : trouver l'index table (methode 1)
               idxpartiel_hdj = (pospartiel_hdj+6)/7
               ipp_temps_partiel_hdj_journees[ idxpartiel_hdj ] = ipp_temps_partiel_hdj_journees[ idxpartiel_hdj ]+nb_jours_presence
               ipp_temps_partiel_hdj_demi_journees[ idxpartiel_hdj ] = ipp_temps_partiel_hdj_demi_journees[ idxpartiel_hdj ]+nb_demi_journees_presence
           else
               --nouveau patient
               buffer_ipp_temps_partiel_hdj = buffer_ipp_temps_partiel_hdj .. "*" .. ipp_local
               table.insert(ipp_temps_partiel_hdj, ipp_local)
               table.insert(ipp_temps_partiel_hdj_journees, nb_jours_presence)
               table.insert(ipp_temps_partiel_hdj_demi_journees, nb_demi_journees_presence)
           end
           if mode_legal_soins ~= 1 then
              pospartiel_hdj_ssc = find(buffer_ipp_temps_partiel_hdj_ssc, str, 1, true)
              if pospartiel_hdj_ssc then
                 --ipp deja comptabilise : trouver l'index table (methode 1)
                 idxpartielhdjssc = (pospartiel_hdj_ssc+6)/7
                 ipp_temps_partiel_hdj_journees_ssc[ idxpartielhdjssc ] =  ipp_temps_partiel_hdj_journees_ssc[ idxpartielhdjssc ]+nb_jours_presence
                 ipp_temps_partiel_hdj_demi_journees_ssc[ idxpartielhdjssc ] =  ipp_temps_partiel_hdj_demi_journees_ssc[ idxpartielhdjssc ]+nb_demi_journees_presence
              else
                 --nouveau patient
                 buffer_ipp_temps_partiel_hdj_ssc = buffer_ipp_temps_partiel_hdj_ssc .. "*" .. ipp_local
                 table.insert(ipp_temps_partiel_hdj_ssc, ipp_local)
                 table.insert(ipp_temps_partiel_hdj_journees_ssc, nb_jours_presence)
                 table.insert(ipp_temps_partiel_hdj_demi_journees_ssc, nb_demi_journees_presence)
              end
           end
        end
  
  else  ----------------------------------------------------------------    MINEURS -----------------------------------------------------------------------
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
        idx = #ipp_min
--st = idx .. " = rang nouveau patient"
--fltk:fl_alert(st)
     end
     
        if tonumber(forme_activite) == 1 then ---------------------------------------------------------------- TEMPS PLEIN
           posplein = find(buffer_ipp_min_temps_plein, str, 1, true)
           if posplein then
              --ipp deja comptabilise : trouver l'index table (methode 1)
               idxpleinmin = (posplein+6)/7
               --ipp_min_temps_plein_journees[ idxplein ] =  ipp_min_temps_plein_journees[ idxplein ]+nb_jours_presence --bad index, fixed 070922
			   ipp_min_temps_plein_journees[ idxpleinmin ] =  ipp_min_temps_plein_journees[ idxpleinmin ]+nb_jours_presence
           else
               buffer_ipp_min_temps_plein = buffer_ipp_min_temps_plein .. "*" .. ipp_local
               table.insert(ipp_min_temps_plein, ipp_local)
               table.insert(ipp_min_temps_plein_journees, nb_jours_presence)
           end
           if mode_legal_soins ~= 1 then
              pospleinssc = find(buffer_ipp_min_temps_plein_ssc, str, 1, true)
              if pospleinssc then
                 --ipp deja comptabilise : trouver l'index table (methode 1)
                 idxpleinssc = (pospleinssc+6)/7
                 ipp_min_temps_plein_journees_ssc[ idxpleinssc ] =  ipp_min_temps_plein_journees_ssc[ idxpleinssc ]+nb_jours_presence
              else
                 buffer_ipp_min_temps_plein_ssc = buffer_ipp_min_temps_plein_ssc .. "*" .. ipp_local
                 table.insert(ipp_min_temps_plein_ssc, ipp_local)
                 table.insert(ipp_min_temps_plein_journees_ssc, nb_jours_presence)
              end
              if mode_legal_soins == 3 then
                 --SPDRE
                 pospleinsscsdre = find(buffer_ipp_min_temps_plein_ssc_spdre, str, 1, true)
                 if pospleinsscsdre then
                    --rien
                 else
                     table.insert(ipp_min_temps_plein_ssc_sdre, ipp_local)
                     buffer_ipp_min_temps_plein_ssc_spdre = buffer_ipp_min_temps_plein_ssc_spdre .. "*" .. ipp_local
                 end
              end
              if mode_legal_soins == 7 then
                 --SPDT
                 pospleinsscsdt = find(buffer_ipp_min_temps_plein_ssc_spdt, str, 1, true)
                 if pospleinsscsdt then
                    --rien
                 else
                    table.insert(ipp_min_temps_plein_ssc_sdt, ipp_local)
                    buffer_ipp_min_temps_plein_ssc_spdt = buffer_ipp_min_temps_plein_ssc_spdt .. "*" .. ipp_local
                 end
              end
           end
           if nb_jours_isolement > 0 then
              pospleinisolement = find(buffer_ipp_min_temps_plein_isolement, str, 1, true)
              if pospleinisolement then
                 --ipp deja comptabilise : trouver l'index table (methode 1)
                  idxpleinisolement = (pospleinisolement+6)/7
                  ipp_min_temps_plein_journees_isolement[ idxpleinisolement ] =  ipp_min_temps_plein_journees_isolement[ idxpleinisolement ]+nb_jours_isolement
              else
                  buffer_ipp_min_temps_plein_isolement = buffer_ipp_min_temps_plein_isolement .. "*" .. ipp_local
                  table.insert(ipp_min_temps_plein_isolement, ipp_local)
                  table.insert(ipp_min_temps_plein_journees_isolement, nb_jours_isolement)
              end
           end
        end
        if tonumber(forme_activite) == 20 then ---------------------------------------------------------------- TEMPS PARTIEL HDJ
           pospartiel_hdj = find(buffer_ipp_min_temps_partiel_hdj, str, 1, true)
           if pospartiel_hdj then
              --ipp deja comptabilise : trouver l'index table (methode 1)
               idxpartiel_hdj = (pospartiel_hdj+6)/7
               ipp_min_temps_partiel_hdj_journees[ idxpartiel_hdj ] = ipp_min_temps_partiel_hdj_journees[ idxpartiel_hdj ]+nb_jours_presence
               ipp_min_temps_partiel_hdj_demi_journees[ idxpartiel_hdj ] = ipp_min_temps_partiel_hdj_demi_journees[ idxpartiel_hdj ]+nb_demi_journees_presence
           else
               buffer_ipp_min_temps_partiel_hdj = buffer_ipp_min_temps_partiel_hdj .. "*" .. ipp_local
               table.insert(ipp_min_temps_partiel_hdj, ipp_local)               
               table.insert(ipp_min_temps_partiel_hdj_journees, nb_jours_presence)
               table.insert(ipp_min_temps_partiel_hdj_demi_journees, nb_demi_journees_presence)
           end
           if mode_legal_soins ~= 1 then
              pospartiel_hdj_ssc = find(buffer_ipp_min_temps_partiel_hdj_ssc, str, 1, true)
              if pospartiel_hdj_ssc then
                 --ipp deja comptabilise : trouver l'index table (methode 1)
                  idxpartielhdjssc = (pospartiel_hdj_ssc+6)/7
                  ipp_min_temps_partiel_hdj_journees_ssc[ idxpartielhdjssc ] =  ipp_min_temps_partiel_hdj_journees_ssc[ idxpartielhdjssc ]+nb_jours_presence
                  ipp_min_temps_partiel_hdj_demi_journees_ssc[ idxpartielhdjssc ] =  ipp_min_temps_partiel_hdj_demi_journees_ssc[ idxpartielhdjssc ]+nb_demi_journees_presence
              else
                  buffer_ipp_temps_partiel_hdj_ssc = buffer_ipp_temps_partiel_hdj_ssc .. "*" .. ipp_local
                  table.insert(ipp_min_temps_partiel_hdj_ssc, ipp_local)
                  table.insert(ipp_min_temps_partiel_hdj_journees_ssc, nb_jours_presence)
                  table.insert(ipp_min_temps_partiel_hdj_demi_journees_ssc, nb_demi_journees_presence)
              end
           end
        end

     
--st = idx .. " /" .. nbpati .. " /".. #ipp .. " = index patient / nb_patients / #ipp  etape 2 : nouveau patient ou pas ?"
--fltk:fl_alert(st)
  

  end

end   --end function  

function build_base() 
  local i,j
  local nbl=1
  local str    
  local pos=1
  
  get_RPS_format()
  while 1 do
      j = find(read_data,"\n",pos)
      if j then
	     line_rps = sub(read_data, pos, j-1)
		 if line_rps then
  	        process(line_rps)
	        pos = j+size_eol
	        nbl = nbl+1
		 else
st = "line_rps est nulle !"
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
  
  filename = fltk.fl_file_chooser("SELECTION de FICHIER RPS", "TXT Files (*.{txt,TXT})", SINGLE, nil)
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
print("Nb de lignes (RPS)= " .. nbl)
     return filename, nbl
  else
     print("Pas de fichier " .. filename .. " dans le dossier par defaut ")
     return filename, null
  end
end --end function

function save_csv_file() 
  local f, filename, st
  
  filename = "FINPSY_RPS_" .. Annee_RPS .. "_" ..  format_RPS .. ".csv"
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
  local sum_col1,sum_col2,sum_col3,sum_col4,sum_col5,sum_col6=0,0,0,0,0,0
  
  csv_buffer = ""
  legende_csv = "MAJEURS TEMPS PLEIN\n" .. "bornes groupe (journees)" .. separator .. "patients" .. separator .. "Journees" .. separator .. "jeunes ad" .. separator ..  "journees jeunes ad" .. separator .. "geronto" .. separator .. "journees geronto\n"
  csv_buffer = csv_buffer .. "Annee_RPS " .. Annee_RPS .. "___FORMAT RPS " ..  format_RPS .. "\n\n" .. legende_csv
  
  for i=1,#borne_ad do
      b1 = borne_ad[i] .. "-"
      if i == #borne_ad then
         b2 = "+"
      else
         b2 = (borne_ad[i+1]-1) .. ""
      end
      st = b1 .. "-" .. b2
      str = st .. separator .. effectifs_gr[i] .. separator .. journees_gr[i] .. separator .. effectifs_gr_jeunes_ad[i] ..  separator .. journees_gr_jeunes_ad[i] .. separator .. effectifs_gr_geronto[i] .. separator .. journees_gr_geronto[i] ..  "\n"
      csv_buffer = csv_buffer .. str
      sum_col1 = sum_col1+effectifs_gr[i]
      sum_col2 = sum_col2+journees_gr[i]
      sum_col3 = sum_col3+effectifs_gr_jeunes_ad[i]
      sum_col4 = sum_col4+journees_gr_jeunes_ad[i]
      sum_col5 = sum_col5+effectifs_gr_geronto[i]
      sum_col6 = sum_col6+journees_gr_geronto[i]
  end
  --TOTAUX
  str = "TOTAUX" .. separator .. sum_col1 .. separator .. sum_col2 .. separator .. sum_col3 ..  separator .. sum_col4 .. separator .. sum_col5 .. separator .. sum_col6 ..  "\n"
  csv_buffer = csv_buffer .. str
  
  legende_csv = "MINEURS TEMPS PLEIN\n" .. "bornes groupe (journees)" .. separator .. "patients"  .. separator .. "journees\n"
  csv_buffer = csv_buffer .. "\n\n" .. legende_csv
 
  sum_col1=0
  sum_col2=0
  for i=1,#borne_min do
      b1 = borne_min[i] .. "-"
      if i == #borne_min then
         b2 = "+"
      else
         b2 = (borne_min[i+1]-1) .. ""
      end
      st = b1 .. "-" .. b2
      str = st .. separator .. effectifs_gr_min[i] .. separator .. journees_gr_min[i] .. "\n"
      csv_buffer = csv_buffer .. str      
      sum_col1 = sum_col1+effectifs_gr_min[i]
      sum_col2 = sum_col2+journees_gr_min[i]
  end
  --TOTAUX
  str = "TOTAUX" .. separator .. sum_col1 .. separator .. sum_col2 ..  "\n\n"
  csv_buffer = csv_buffer .. str

  --MAJEURS TEMPS PARTIEL HDJ : zéro venue
  for i=1,#ipp_temps_partiel_hdj do
       if ipp_temps_partiel_hdj_journees[ i ] and ipp_temps_partiel_hdj_demi_journees[ i ] then
          if ipp_temps_partiel_hdj_journees[ i ] == 0 and ipp_temps_partiel_hdj_demi_journees[ i ] == 0 then
             effectifs_gr_ad_hdj_0_venue = effectifs_gr_ad_hdj_0_venue+1
          end
       end
  end
  --MINEURS TEMPS PARTIEL HDJ : zéro venue
  for i=1,#ipp_min_temps_partiel_hdj do
       if ipp_min_temps_partiel_hdj_journees[ i ] and ipp_min_temps_partiel_hdj_demi_journees[ i ] then
          if ipp_min_temps_partiel_hdj_journees[ i ] == 0 and ipp_min_temps_partiel_hdj_demi_journees[ i ] == 0 then
             effectifs_gr_min_hdj_0_venue = effectifs_gr_min_hdj_0_venue+1
          end
       end
  end
  
  legende_csv = "MAJEURS TEMPS PARTIEL HDJ\n" .. "patients"  .. separator .. "journees"  .. separator .. "demi-journees" .. separator .. "equivalent journees" .. separator .. "patients zero venue\n"
  csv_buffer = csv_buffer .. "\n\n" .. legende_csv
  str = effectifs_gr_ad_hdj .. separator .. journees_gr_ad_hdj .. separator .. demi_journees_gr_ad_hdj .. separator .. (journees_gr_ad_hdj+math.ceil(demi_journees_gr_ad_hdj/2)) .. separator .. effectifs_gr_ad_hdj_0_venue .. "\n"
  csv_buffer = csv_buffer .. str
  
  --MINEURS TEMSP PARTIEL HDJ
  legende_csv = "MINEURS TEMPS PARTIEL HDJ\n" .. "patients"  .. separator .. "journees"  .. separator .. "demi-journees" .. separator .. "equivalent journees" .. separator .. "patients zero venue\n"
  csv_buffer = csv_buffer .. "\n\n" .. legende_csv
  str = effectifs_gr_min_hdj .. separator .. journees_gr_min_hdj .. separator .. demi_journees_gr_min_hdj .. separator .. (journees_gr_min_hdj+math.ceil(demi_journees_gr_min_hdj/2)) .. separator .. effectifs_gr_min_hdj_0_venue .. "\n"
  csv_buffer = csv_buffer .. str
  
  --MAJEURS SPDRE / SPDT
  legende_csv = "MAJEURS SPDRE/SPDT\n" .. "patients SPDRE"  .. separator .. "patients SPDT\n"
  csv_buffer = csv_buffer .. "\n\n" .. legende_csv
  str = #ipp_temps_plein_ssc_sdre .. separator .. #ipp_temps_plein_ssc_sdt .. "\n"
  csv_buffer = csv_buffer .. str
  
  --MINEURS SPDRE / SPDT
  legende_csv = "MINEURS SPDRE/SPDT\n" .. "patients SPDRE"  .. separator .. "patients SPDT\n"
  csv_buffer = csv_buffer .. "\n\n" .. legende_csv
  str = #ipp_min_temps_plein_ssc_sdre .. separator .. #ipp_min_temps_plein_ssc_sdt .. "\n"
  csv_buffer = csv_buffer .. str
  
 end  --end function  
    
function create_csv_ipp_jtplein()

  local i, str
  
  csv_buffer = ""
  csv_buffer = "IPP Adulte" .. separator .. "journees temps plein Adultes\n"
  for i=1,#ipp_temps_plein do
      str = ipp_temps_plein[i] .. separator .. ipp_temps_plein_journees[i] ..  "\n"
      csv_buffer = csv_buffer .. str
  end
  csv_buffer = csv_buffer .. "----------------------------------------------\n\n\nIPP Mineurs" .. separator .. "journees temps plein Mineurs\n"
   for i=1,#ipp_min_temps_plein do
      str = ipp_min_temps_plein[i] .. separator .. ipp_min_temps_plein_journees[i] ..  "\n"
      csv_buffer = csv_buffer .. str
  end
  
  csv_buffer = csv_buffer .. "----------------------------------------------\n\n\nBuffer IPP Adultes temps plein\n" .. buffer_ipp_temps_plein
  
  csv_buffer = csv_buffer .. "----------------------------------------------\n\n\nBuffer IPP Mineurs temps plein\n" .. buffer_ipp_min_temps_plein
  
  
end -- end function

function save_csv_ipp_jtplein()
  local f, filename, st
  
  filename = "TABLE_IPP_JOURNEES_TPLEIN_FINPSY_RPS_" .. Annee_RPS .. "_" ..  format_RPS .. ".csv"
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

-- 2nd backup
  filename = "BUFFER_IPP_TPLEIN_FINPSY_RPS_" .. Annee_RPS .. "_" ..  format_RPS .. ".txt"
  f = io.open(filename,"wb")
  csv_buffer = "Buffer adultes temps plein\n" .. buffer_ipp_temps_plein
  csv_buffer = csv_buffer .. "\n\n\nBuffer mineurs temps plein\n" .. buffer_ipp_min_temps_plein
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
  
end -- end function

t00 = os.time() --top chrono

  if osName == "OS=linux" then
     filename = "/home/terras/scripts-murgaLua/RPS_M6_2022.txt"
  else
     filename = "RPS_M32022.txt"
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
local j,k,l,m,n,o,p=0,0,0,0,0,0,0
for i=1,#ipp_temps_plein_journees do
    j = j+ipp_temps_plein_journees[ i ]
end
for i=1,#ipp_temps_plein_journees_ssc do
    k = k+ipp_temps_plein_journees_ssc[ i ]
end
for i=1,#ipp_temps_plein_journees_isolement do
    l = l+ipp_temps_plein_journees_isolement[ i ]
end
for i=1,#ipp_temps_partiel_hdj_journees do
    m = m+ipp_temps_partiel_hdj_journees[ i ]
end
for i=1,#ipp_temps_partiel_hdj_demi_journees do
    n = n+ipp_temps_partiel_hdj_demi_journees[ i ]
end
for i=1,#ipp_temps_partiel_hdj_journees_ssc do
    o = o+ipp_temps_partiel_hdj_journees_ssc[ i ]
end
for i=1,#ipp_temps_partiel_hdj_demi_journees_ssc do
    p = p+ipp_temps_partiel_hdj_demi_journees_ssc[ i ]
end

st = "Total IPP MAJEURS = " .. #ipp .. "\n"
st = st .. "Dont IPP Majeurs temps plein / SSC / isolement = " .. #ipp_temps_plein .. "/" .. #ipp_temps_plein_ssc .. "/" .. #ipp_temps_plein_isolement .. "\n"
st = st .. "journees Majeurs temps plein / SSC / isolement= " .. j .. "/" .. k .. "/" .. l .. "\n"
st = st .. "Dont IPP Majeurs temps partiel HDJ/ SSC = " .. #ipp_temps_partiel_hdj .. "/" .. #ipp_temps_partiel_hdj_ssc .. "\n"
st = st .. "journees / demi-journees Majeurs temps partiel HDJ = " .. m .. "/" .. n .. "\n"
st = st .. "journees / demi-journees Majeurs temps partiel HDJ SSC = " .. o .. "/" .. p .. "\n"


--tableau à une seule ligne ADULTES A TEMPS PARTIEL HDJ
effectifs_gr_ad_hdj = #ipp_temps_partiel_hdj
journees_gr_ad_hdj = m
demi_journees_gr_ad_hdj = n

--controles & stats ---MINEURS
local j,k,l,m,n,o,p=0,0,0,0,0,0,0
for i=1,#ipp_min_temps_plein_journees do
    j = j+ipp_min_temps_plein_journees[ i ]
end
for i=1,#ipp_min_temps_plein_journees_ssc do
    k = k+ipp_min_temps_plein_journees_ssc[ i ]
end
for i=1,#ipp_min_temps_plein_journees_isolement do
    l = l+ipp_min_temps_plein_journees_isolement[ i ]
end
for i=1,#ipp_min_temps_partiel_hdj_journees do
    m = m+ipp_min_temps_partiel_hdj_journees[ i ]
end
for i=1,#ipp_min_temps_partiel_hdj_demi_journees do
    n = n+ipp_min_temps_partiel_hdj_demi_journees[ i ]
end
for i=1,#ipp_min_temps_partiel_hdj_journees_ssc do
    o = o+ipp_min_temps_partiel_hdj_journees_ssc[ i ]
end
for i=1,#ipp_min_temps_partiel_hdj_demi_journees_ssc do
    p = p+ipp_min_temps_partiel_hdj_demi_journees_ssc[ i ]
end
st = st .. "Total IPP MINEURS = " .. #ipp_min .. "\n"
st = st .. "Dont IPP Mineurs temps plein / SSC / isolement = " .. #ipp_min_temps_plein .. "/" .. #ipp_min_temps_plein_ssc .. "/" .. #ipp_min_temps_plein_isolement .. "\n"
st = st .. "journees Mineurs temps plein / SSC / isolement= " .. j .. "/" .. k .. "/" .. l .. "\n"
st = st .. "Dont IPP Mineurs temps partiel HDJ/ SSC = " .. #ipp_min_temps_partiel_hdj .. "/" .. #ipp_min_temps_partiel_hdj_ssc .. "\n"
st = st .. "journees / demi-journees Mineurs temps partiel HDJ = " .. m .. "/" .. n .. "\n"
st = st .. "journees / demi-journees Mineurs temps partiel HDJ SSC = " .. o .. "/" .. p .. "\n\n"
st = st .. "\nTraitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures"

fltk:fl_alert(st)

--tableau à une seule ligne MINEURS A TEMPS PARTIEL HDJ
effectifs_gr_min_hdj = #ipp_min_temps_partiel_hdj
journees_gr_min_hdj = m
demi_journees_gr_min_hdj = n

--groupage MAJEURS temps plein ------------------------------------------------------------------
for i=1,#borne_ad do
     for j=1,#ipp_temps_plein do
          if i == #borne_ad then
              if ipp_temps_plein_journees[ j ] >= borne_ad[i] then
                 effectifs_gr[i] = effectifs_gr[i]+1
                 journees_gr[i] = journees_gr[i] + ipp_temps_plein_journees[ j ]
              end
           else
              if ipp_temps_plein_journees[ j ] >= borne_ad[i] and ipp_temps_plein_journees[ j ] < borne_ad[i+1] then
                  effectifs_gr[i] = effectifs_gr[i]+1
                  journees_gr[i] = journees_gr[i] + ipp_temps_plein_journees[ j ]
              end
          end
     end
     for j=1,#ipp_temps_plein_jeunes_ad do
          --jeunes adultes
          if i == #borne_ad then
              if ipp_temps_plein_journees_jeunes_ad[ j ] >= borne_ad[i] then
                 effectifs_gr_jeunes_ad[i] = effectifs_gr_jeunes_ad[i]+1
                 journees_gr_jeunes_ad[i] = journees_gr_jeunes_ad[i] + ipp_temps_plein_journees_jeunes_ad[ j ]
              end
           else
              if ipp_temps_plein_journees_jeunes_ad[ j ] >= borne_ad[i] and ipp_temps_plein_journees_jeunes_ad[ j ] < borne_ad[i+1] then
                  effectifs_gr_jeunes_ad[i] = effectifs_gr_jeunes_ad[i]+1
                  journees_gr_jeunes_ad[i] = journees_gr_jeunes_ad[i] + ipp_temps_plein_journees_jeunes_ad[ j ]
              end
          end
     end
     for j=1,#ipp_temps_plein_geronto do
          --geronto
          if i == #borne_ad then
              if ipp_temps_plein_journees_geronto[ j ] >= borne_ad[i] then
                 effectifs_gr_geronto[i] = effectifs_gr_geronto[i]+1
                 journees_gr_geronto[i] = journees_gr_geronto[i] + ipp_temps_plein_journees_geronto[ j ]
              end
           else
              if ipp_temps_plein_journees_geronto[ j ] >= borne_ad[i] and ipp_temps_plein_journees_geronto[ j ] < borne_ad[i+1] then
                  effectifs_gr_geronto[i] = effectifs_gr_geronto[i]+1
                  journees_gr_geronto[i] = journees_gr_geronto[i] + ipp_temps_plein_journees_geronto[ j ]
              end
          end
     end
     
end

--groupage MINEURS temps plein
for i=1,#borne_min do
--print("borne_min[" .. i .. "] = " .. borne_min[i])
     for j=1,#ipp_min_temps_plein do
          if i == #borne_min then
              if ipp_min_temps_plein_journees[ j ] >= borne_min[i] then
                 effectifs_gr_min[i] = effectifs_gr_min[i]+1
                 journees_gr_min[i] = journees_gr_min[i] + ipp_min_temps_plein_journees[ j ]
              end
           else
              if ipp_min_temps_plein_journees[ j ] >= borne_min[i] and ipp_min_temps_plein_journees[ j ] < borne_min[i+1] then
--print("ipp_min_temps_plein_journees[ " .. j .." ] = " .. ipp_min_temps_plein_journees[ j ])
                  effectifs_gr_min[i] = effectifs_gr_min[i]+1
                  journees_gr_min[i] = journees_gr_min[i] + ipp_min_temps_plein_journees[ j ]
              end
          end
     end
end


--st="effectifs groupes EGA calcules"
--fltk:fl_alert(st)

create_csv_file()
if #csv_buffer >0 then
   save_csv_file()
end

--print("buffer_ipp_temps_plein_geronto = " .. buffer_ipp_temps_plein_geronto .. "\n #ipp_temps_plein_geronto = " .. #ipp_temps_plein_geronto)
st = "#buffer_ipp_temps_plein_jeunead = " .. #buffer_ipp_temps_plein_jeunead .. "\n #ipp_temps_plein_jeunes_ad = " .. #ipp_temps_plein_jeunes_ad
st = st .. "\n\n#buffer_ipp_temps_plein_geronto = " .. #buffer_ipp_temps_plein_geronto .. "\n #ipp_temps_plein_geronto = " .. #ipp_temps_plein_geronto
fltk:fl_alert(st)

--[[
create_csv_ipp_jtplein()
save_csv_ipp_jtplein()
]]--

print("Traitement en " .. os.difftime(os.time(), t00) .. " secondes, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/60)) .. " mn, soit en " .. string.format('%.2f',(os.difftime(os.time(), t00)/3600)) .. " heures")

Fl:check()
Fl:run()

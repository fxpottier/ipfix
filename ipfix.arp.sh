#!/bin/bash
# ipfix.arp.sh

# Récupération des variables de configuration
source .ipfix

echo `date "+%d-%m-%Y %H:%M:%S%z"` " Début interrogation des routeurs " 

# Récupération de la table ARP
# . Correction de l'écriture des adresses MAC (ex: 0:0:a:1b:f:e0 --> 00:00:0a:1b:0f:e0)
# . Suppression des entrées de broadcast (ff:ff:ff:ff:ff:ff)
# . Sortie des données au format "MAC IP DATE"
# . Tri numérique sur les 3 derniers octets de l'IP
# . Suppression des lignes en double si présentes (ne devrait pas)

while read ROUTEUR TYPE SNMP
do
	#echo "test:snmpbulkwalk "${ROUTEURS[${routeur}]} $routeur
	#echo "test:snmpbulkwalk "$SNMP $ROUTEUR $TYPE
	# TODO: n=split($1,ip,".");aip=ip[n-3]"."ip[n-2]"."ip[n-1]"."ip[n]
	( snmpbulkwalk $SNMP $ROUTEUR ipNetToMediaPhysAddress | \
		awk 'BEGIN{"date '+%Y%m%d_%H%M'" | getline date ;} { \
			a=""; \
			nb=split($4,arr,":"); \ 
			for (i=1;i<=nb;i++) { \
				a=sprintf("%s:%02x",a,"0x"arr[i]) \
			}; \
			sub(/^:/,"",a); \
			split($1,ip,"."); \
			if (a!~/ff:ff:ff:ff:ff:ff/) print a, ip[3]"."ip[4]"."ip[5]"."ip[6], date;}' | \
		sort -V -t. -k2,2 -k3,3 -k4,4 | \
		uniq > arp.$ROUTEUR 
	)&
done < <(awk '(NF>1) && !(/^( |\t)*#/) {print $0}' .routeurs.list | tr -d '\r' )
# Attendons que les équipements aient tous terminés de répondre.
wait

echo `date "+%d-%m-%Y %H:%M:%S%z"` " Fin interrogation des routeurs. Début mise à jour du fichier de référence (arp.ref)" 
# Pour chaque coupe mac/ip récupéré sur les routeurs, 
# si l'ip ou la mac est présente, les lignes y faisant référence sont supprimées. 
# Ensuite nous ajoutons les nouvelles informations. 
while read ROUTEUR
do
	while read mac ip time; do 
		if [[ -n "$mac" && -n "$ip" ]]; then 
			sed -i "/$ip/d ; /$mac/d" arp.ref; 
			echo "$mac $ip $time " >> arp.ref;
		fi; 
	done < arp.$ROUTEUR ; rm arp.$ROUTEUR ;
done < <( tr -d '\r' < .routeurs.list | awk '(NF>1) && !(/^( |\t)*#/) {print $1}' )

# refaisons le tri sur l'IP
sort -V -t. -k2,2 -k3,3 -k4,4 -o arp.ref arp.ref

echo `date "+%d-%m-%Y %H:%M:%S%z"` " Fin mise à jour du fichier de référence ARP."

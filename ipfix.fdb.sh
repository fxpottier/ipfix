#!/bin/bash
# ipfix.fdb.sh

# Récupération des variables de configuration
source .ipfix

# OID utilisés :
# BRIDGE-MIB::dot1dTpFdbAddress
# BRIDGE-MIB::dot1dTpFdbPort
# IF-MIB::ifName.242 = STRING: ifc242 (Slot: 4 Port: 50)
# .1.3.6.1.4.1.2272.1.3.3.1.4 (tag 1:Untag  2:Tagged 5:UntagPvidOnly)
# .1.3.6.1.4.1.2272.1.3.3.1.7 vlanPortDefaultVlanId
# .1.3.6.1.4.1.2272.1.4.10.1.1.11 portAutoNegotiate (booléen 1=autoneg true(1), false(2))
# .1.3.6.1.4.1.2272.1.4.10.1.1.12 portAdminDuplex (1=half, 2=full)
# .1.3.6.1.4.1.2272.1.4.10.1.1.13 portOperDuplex (1=half, 2=full)
# .1.3.6.1.4.1.2272.1.4.10.1.1.14 portAdminSpeed ( none(0), mbps10(1), mbps100(2) )
# .1.3.6.1.4.1.2272.1.4.10.1.1.15 portOperSpeed ( INTEGER )
# .1.3.6.1.4.1.2272.1.4.10.1.1.17 portLocked ( booléen true(1), false(2) )
#snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.4.10.1.1.17 | \
#	awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.portLocked
# .1.3.6.1.4.1.2272.1.4.10.1.1.35 portName ( String )
#snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.4.10.1.1.35 | \
#	awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.portName

echo `date "+%d-%m-%Y %H:%M:%S%z"` " Début interrogation des équipements."
while read DNS IP SNMP
do
	#echo "Interrogation de $DNS [ $IP ] $SNMP"
	
	# Contrôle du nom dns fournit. S'il ne renvoit pas une IP valide, on utilise l'IP. 
	[[ "$(host $DNS | awk '{x=$NF}END{print x}')" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || DNS=$IP 

	## Pour valider la liste des équipements fournit :
	#SYSDESCR=`snmpget $SNMP $DNS system.sysDescr.0 | tr  [:upper:] [:lower:]` ; echo "TEST : $DNS [ $IP ] $SYSDESCR"

	(
		# Les MIB sont différentes selon le constructeur. Donc nous testons le modèle/constructeur 
		SYSDESCR=`snmpget $SNMP $DNS system.sysDescr.0 | tr  [:upper:] [:lower:]` 
		case $SYSDESCR in

		*blade*hp*|*hp*blade*) #echo "blade HP: "$SYSDESCR 
			#echo "blade HP: "$SYSDESCR"\nVERIF:snmpbulkwalk -t $TIMEOUT $DNS $SNMP"
			# MIB: http://www.circitor.fr/Mibs/Html/BLADETYPE4-NETWORK-MIB.php
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS IF-MIB::ifName |awk 'BEGIN{i=0;}{ \
                                n=split($1,ifIndex,"."); i++; if(ifIndex[n]<10000) print i,"'$DNS'."i}' > $DNS.ifName
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS SNMPv2-SMI::enterprises.11.2.3.7.11.33.4.2.1.1.2.2.1.3 | \
				awk ' {if($4=="3")vtag="U";if($4=="2")vtag="T"; \ 
				n=split($1,ifIndex,"."); print ifIndex[n],vtag;}' > $DNS.vlanPortType
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS SNMPv2-SMI::enterprises.11.2.3.7.11.33.4.2.1.1.2.2.1.6 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.vlanPortDefaultVlanId
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS SNMPv2-SMI::enterprises.11.2.3.7.11.33.4.2.1.1.2.2.1.11 | \
				awk '{if($4=="2")aneg="auto";if($4=="3")aneg="fixe"; \
				n=split($1,ifIndex,"."); print ifIndex[n],aneg;}' > $DNS.portAutoNegotiate
			# agPortCurCfgGigEthMode: full-duplex(2), half-duplex(3), full-or-half-duplex(4)
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS SNMPv2-SMI::enterprises.11.2.3.7.11.33.4.2.1.1.2.2.1.13 | \
				awk '{if($4=="2")aduplex="F";if($4=="3")aduplex="H";if($4=="4")aduplex="?";
				n=split($1,ifIndex,"."); print ifIndex[n],aduplex;}' > $DNS.portAdminDuplex
			# The current operational mode of the port: full-duplex(2), half-duplex(3)
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS SNMPv2-SMI::enterprises.11.2.3.7.11.33.4.2.1.3.2.1.1.3 | \
				awk '{if($4=="2")oduplex="F";if($4=="3")oduplex="H"; \
				n=split($1,ifIndex,"."); print ifIndex[n],oduplex;}' > $DNS.portOperDuplex
			# admin speed: mbs10(2), mbs100(3), any(4), mbs1000(5)
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS SNMPv2-SMI::enterprises.11.2.3.7.11.33.4.2.1.1.2.2.1.12 | \
				awk '{if($4=="2")aspeed="10";if($4=="3")aspeed="100";if($4=="4")aspeed="any";if($4=="5")aspeed="1000"; \
				n=split($1,ifIndex,"."); print ifIndex[n],aspeed;}' > $DNS.portAdminSpeed
			# oper speed: mbs10(2), mbs100(3), mbs1000(4), any(5) 
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.4.1.11.2.3.7.11.33.4.2.1.2.3.3.1.3 | \
				awk '{if($4=="2")ospeed="10";if($4=="3")ospeed="100";if($4=="4")ospeed="1000";if($4=="5")ospeed="any"; \
				n=split($1,ifIndex,"."); print ifIndex[n],ospeed;}' > $DNS.portOperSpeed
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.2.1.17.4.3.1.2 | \
				awk '{ n=split($1,mac,"."); printf("%s %02x:%02x:%02x:%02x:%02x:%02x\n",$4,mac[n-5],mac[n-4],mac[n-3],mac[n-2],mac[n-1],mac[n])}' > $DNS.dot1dTpFdbPort

	                awk -v dns=$DNS 'BEGIN{"date '+%Y%m%d_%H%M'" | getline date;} \
        	                F==1 {ifname[$1]=$2;} \
        	                F==2 {vtag[$1]=$2;} \
                        	F==3 {pvid[$1]=$2;} \
                        	F==4 {aneg[$1]=$2;} \
        	                F==5 {aduplex[$1]=$2;} \
                	        F==6 {oduplex[$1]=$2;} \
                        	F==7 {aspeed[$1]=$2;} \
             		        F==8 {ospeed[$1]=$2;} \
                	        F==9 {nb[$1]++} \
                        	F==10 {arp[$1]=$2;} \
               	        	 F==11 {if((nb[$1]<'$MMPP')&&($1!=0)) \
                	          print $1,ifname[$1]" ("pvid[$1]"["vtag[$1]"])["aneg[$1]"]("ospeed[$1]"["aspeed[$1]"]/"oduplex[$1]"["aduplex[$1]"])",$2,(arp[$2])?arp[$2]:"0.0.0.0",date}' \
            		        F=1 $DNS.ifName \
                	        F=2 $DNS.vlanPortType \
                        	F=3 $DNS.vlanPortDefaultVlanId \
   	                   	F=4 $DNS.portAutoNegotiate \
        	                F=5 $DNS.portAdminDuplex \
                	        F=6 $DNS.portOperDuplex \
                        	F=7 $DNS.portAdminSpeed \
             	           	F=8 $DNS.portOperSpeed \
                	        F=9 $DNS.dot1dTpFdbPort \
                        	F=10 arp.ref \
                        	F=11 $DNS.dot1dTpFdbPort | sort -n > $DNS.ref

		;;
#		*blade*ibm*|*ibm*blade*) #echo "blade IBM: "$SYSDESCR 
#			# MIB: http://www.circitor.fr/Mibs/Html/ALTEON-CHEETAH-SWITCH-MIB.php
## verifier ces 2 lignes
##			snmpbulkwalk -t $TIMEOUT $SNMP $DNS IF-MIB::ifName |awk 'BEGIN{i=0;}{ \
##                                n=split($1,ifIndex,"."); if(ifIndex[n]<10000) print ifIndex[n],"'$DNS'."i++}' > $DNS.ifName
#			# agPortCurCfgVlanTag: 1.3.6.1.4.1.1872.2.5.1.1.2.2.1.3 ; tagged(2), untagged(3)
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.4.1.1872.2.5.1.1.2.2.1.3 | \
#				awk ' {if($4=="3")vtag="U";if($4=="2")vtag="T"; \ 
#				n=split($1,ifIndex,"."); print ifIndex[n],vtag;}' > $DNS.vlanPortType
#			# agPortCurCfgPVID: 1.3.6.1.4.1.1872.2.5.1.1.2.2.1.6
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.4.1.1872.2.5.1.1.2.2.1.6 | \
#				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.vlanPortDefaultVlanId
#			# agPortCurCfgGigEthAutoNeg 1.3.6.1.4.1.1872.2.5.1.1.2.2.1.11 ; on(2), off(3)
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.4.1.1872.2.5.1.1.2.2.1.11 | \
#				awk '{if($4=="2")aneg="auto";if($4=="3")aneg="fixe"; \
#				n=split($1,ifIndex,"."); print ifIndex[n],aneg;}' > $DNS.portAutoNegotiate
#			# agPortCurCfgFastEthMode 1.3.6.1.4.1.1872.2.5.1.1.2.2.1.9 : full-duplex(2), half-duplex(3), full-or-half-duplex(4)
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS  1.3.6.1.4.1.1872.2.5.1.1.2.2.1.9 | \
#				awk '{if($4=="2")aduplex="F";if($4=="3")aduplex="H";if($4=="4")aduplex="?";
#				n=split($1,ifIndex,"."); print ifIndex[n],aduplex;}' > $DNS.portAdminDuplex
#			# The current operational mode of the port: full-duplex(2), half-duplex(3)
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS  1.3.6.1.4.1.1872.2.5.1.3.2.1.1.3 | \
#				awk '{if($4=="2")oduplex="F";if($4=="3")oduplex="H"; \
#				n=split($1,ifIndex,"."); print ifIndex[n],oduplex;}' > $DNS.portOperDuplex
#			# admin speed: mbs10(2), mbs100(3), mbs10or100(4)
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS  1.3.6.1.4.1.1872.2.5.1.1.2.2.1.8 | \
#				awk '{if($4=="2")aspeed="10";if($4=="3")aspeed="100";if($4=="4")aspeed="any";if($4=="5")aspeed="1000"; \
#				n=split($1,ifIndex,"."); print ifIndex[n],aspeed;}' > $DNS.portAdminSpeed
#			# oper speed: mbs10(2), mbs100(3), mbs1000(4), any(5)
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.4.1.1872.2.5.1.3.2.1.1.2 | \
#				awk '{if($4=="2")ospeed="10";if($4=="3")ospeed="100";if($4=="4")ospeed="1000";if($4=="5")ospeed="any"; \
#				n=split($1,ifIndex,"."); print ifIndex[n],ospeed;}' > $DNS.portOperSpeed
#			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.2.1.17.4.3.1.2 | \
#				awk '{ n=split($1,mac,"."); printf("%s %02x:%02x:%02x:%02x:%02x:%02x\n",$4,mac[n-5],mac[n-4],mac[n-3],mac[n-2],mac[n-1],mac[n])}' > $DNS.dot1dTpFdbPort
#
#	                awk -v dns=$DNS 'BEGIN{"date '+%Y%m%d_%H%M'" | getline date;} \
#        	                F==1 {ifname[$1]=$2;} \
#        	                F==2 {vtag[$1]=$2;} \
#                        	F==3 {pvid[$1]=$2;} \
#                        	F==4 {aneg[$1]=$2;} \
#        	                F==5 {aduplex[$1]=$2;} \
#                	        F==6 {oduplex[$1]=$2;} \
#                        	F==7 {aspeed[$1]=$2;} \
#             		        F==8 {ospeed[$1]=$2;} \
#                	        F==9 {nb[$1]++} \
#                        	F==10 {arp[$1]=$2;} \
#               	        	 F==11 {if((nb[$1]<'$MMPP')&&($1!=0)) \
#                	          print $1,ifname[$1]" ("pvid[$1]"["vtag[$1]"])["aneg[$1]"]("ospeed[$1]"["aspeed[$1]"]/"oduplex[$1]"["aduplex[$1]"])",$2,(arp[$2])?arp[$2]:"0.0.0.0",date}' \
#            		        F=1 $DNS.ifName \
#                	        F=2 $DNS.vlanPortType \
#                        	F=3 $DNS.vlanPortDefaultVlanId \
#   	                   	F=4 $DNS.portAutoNegotiate \
#        	                F=5 $DNS.portAdminDuplex \
#                	        F=6 $DNS.portOperDuplex \
#                        	F=7 $DNS.portAdminSpeed \
#             	           	F=8 $DNS.portOperSpeed \
#                	        F=9 $DNS.dot1dTpFdbPort \
#                        	F=10 arp.ref \
#                        	F=11 $DNS.dot1dTpFdbPort | sort -n > $DNS.ref
#		;;

		*nortel*|*avaya*) #echo "TEST:snmpbulkwalk -t $TIMEOUT $DNS ${SNMP%?} IF-MIB::ifName"
			#echo "nortel: "$SYSDESCR"\nVERIF:snmpbulkwalk -t $TIMEOUT $DNS $SNMP"
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS IF-MIB::ifName |awk '{ \ 
				n=split($1,ifIndex,"."); split($8,p,")"); if(ifIndex[n]<10000) print ifIndex[n],"'$DNS'-"$6"."p[1]; }' > $DNS.ifName

			snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.3.3.1.4 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.vlanPortType
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.3.3.1.7 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.vlanPortDefaultVlanId
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.4.10.1.1.11 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.portAutoNegotiate
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.4.10.1.1.12 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.portAdminDuplex
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.4.10.1.1.13 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.portOperDuplex
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.4.10.1.1.14 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.portAdminSpeed
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS .1.3.6.1.4.1.2272.1.4.10.1.1.15 | \
				awk '{n=split($1,ifIndex,"."); print ifIndex[n],$4;}' > $DNS.portOperSpeed
			snmpbulkwalk -t $TIMEOUT $SNMP $DNS 1.3.6.1.2.1.17.4.3.1.2 | \
				awk '{ n=split($1,mac,"."); printf("%s %02x:%02x:%02x:%02x:%02x:%02x\n",$4,mac[n-5],mac[n-4],mac[n-3],mac[n-2],mac[n-1],mac[n])}' > $DNS.dot1dTpFdbPort
		
		# Le traitement suivant devrait être fait après le case, comme cela on ne l'écrit qu'une seule fois (plus simple à maintenir) 
		# Mais pour cela il faut qu'il soit identique pour les 3 cas 
		# => les réécritures des valeurs (ex: 2 => "autoneg") doivent être passées directement au niveau des retours de commande snmp.
                awk -v dns=$DNS 'BEGIN{"date '+%Y%m%d_%H%M'" | getline date;} \
                        F==1 {ifname[$1]=$2;} \
                        F==2 {if($2=="1")vtag[$1]="U";if($2=="2")vtag[$1]="T";if($2=="5")vtag[$1]="P";} \
                        F==3 {pvid[$1]=$2;} \
                        F==4 {if($2=="1")aneg[$1]="auto";if($2=="2")aneg[$1]="fixe";} \
                        F==5 {if($2=="1")aduplex[$1]="H";if($2=="2")aduplex[$1]="F";} \
                        F==6 {if($2=="1")oduplex[$1]="H";if($2=="2")oduplex[$1]="F";} \
                        F==7 {aspeed[$1]=$2;if($2=="1")aspeed[$1]="10";if($2=="2")aspeed[$1]="100";if($2=="3")aspeed[$1]="1000";if($2=="4")aspeed[$1]="10000";} \
                        F==8 {ospeed[$1]=$2;} \
                        F==9 {nb[$1]++} \
                        F==10 {arp[$1]=$2;} \
                        F==11 {if((nb[$1]<'$MMPP')&&($1!=0)) \
                          print $1,ifname[$1]" ("pvid[$1]"["vtag[$1]"])["aneg[$1]"]("ospeed[$1]"["aspeed[$1]"]/"oduplex[$1]"["aduplex[$1]"])",$2,(arp[$2])?arp[$2]:"0.0.0.0",date}' \
                        F=1 $DNS.ifName \
                        F=2 $DNS.vlanPortType \
                        F=3 $DNS.vlanPortDefaultVlanId \
                        F=4 $DNS.portAutoNegotiate \
                        F=5 $DNS.portAdminDuplex \
                        F=6 $DNS.portOperDuplex \
                        F=7 $DNS.portAdminSpeed \
                        F=8 $DNS.portOperSpeed \
                        F=9 $DNS.dot1dTpFdbPort \
                        F=10 arp.ref \
                        F=11 $DNS.dot1dTpFdbPort | sort -n > $DNS.ref
		;;
		esac

		# un peu de ménage
		rm $DNS.ifName $DNS.vlan* $DNS.port* $DNS.dot1dTpFdbPort
	) &
done < <(awk '(NF>1) && !(/^( |\t)*#/) {print $0}' .switches.list | tr -d '\r' )
# Attendons que les equipements aient tous répondus ou passés le timeout
wait
echo `date "+%d-%m-%Y %H:%M:%S%z"` " Fin interrogation des équipements. Début de la consolidation des données."

# Maintenant mettons à jour les données du fichier de références fdb.ref
# FX : ici nous supprimons toutes les entrées existantes concernant soit le port soit la mac, avant d'injecter la ligne mac/port.
while read DNS IP SNMP
do

	[[ "$(host $DNS | awk '{x=$NF}END{print x}')" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || DNS=$IP 

	# 1. on commence par supprimer les données obsolètes.
	awk '$2 ! /^$/ && $4 ! /^$/ {print "/"$2" /d\n/"$4" /d"}' $DNS.ref | sed -i -f - $PDIR/fdb.ref

	# 2. on boucle à nouveau insérer les nouvelles données.
	while read idx port parametres mac ip date; do
		if [[ -n "$mac" && -n "$port" ]]; then
			# On récupère le FQDN du client pour lequel on a une IP. Si IP inconnue dans le DNS on le spécifie
			fqdn=`host $ip |cut -d" " -f 5 |awk '{if($1~/\./) {print $1;} else print "INCONNU";}'`
			echo "$port $parametres $mac $ip $fqdn $date" >> $PDIR/fdb.ref
		fi;
	done < $DNS.ref ; rm $DNS.ref ;

done < <(awk '(NF>1) && !(/^( |\t)*#/) {print $0}' .switches.list | tr -d '\r' )
#done < <( tr -d '\r' < .switches.list | awk '(NF>1) && !(/^( |\t)*#/) {print $0}' )

echo `date "+%d-%m-%Y %H:%M:%S%z"` " Fin de la mse à jour des données FDB." 
